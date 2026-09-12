import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { AnyComponent, GenerationMode } from "./types.ts";
import { buildEmergencyGeneratedScreen, buildGeneratedScreen, postProcessComponents } from "./assembler.ts";
import { applyDeterministicModifierEdits, applyStylePatch, buildSelectionSystemPrompt } from "./editing.ts";
import { classifyIntent, isFullCanvasPrompt, promptExplicitlyChangesText } from "./manifest.ts";
import { compileWithRepairMessages } from "./slot-generator.ts";
import { SELECTION_MAX_TOKENS, SELECTION_MODEL } from "./openai.ts";
import { isObject, normalizeSelectedComponent } from "./utils.ts";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const supabaseUrl = Deno.env.get("SUPABASE_URL");
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
const RATE_LIMIT_SECONDS = 1;
const FREE_DAILY_LIMIT = 10;
const PRO_DAILY_LIMIT = 100;
const MAX_OUTCOME_SCREEN_BYTES = 600_000;
const MAX_OUTCOME_COMPONENTS = 500;

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    try {
        if (!supabaseUrl || !supabaseServiceKey) return json({ error: "Supabase server configuration missing" }, 500);
        const jwt = (req.headers.get("Authorization") ?? "").replace("Bearer ", "");
        if (!jwt) return json({ error: "Missing Authorization token" }, 401);

        const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
        const { data: userData, error: userError } = await supabaseAdmin.auth.getUser(jwt);
        if (userError || !userData?.user) return json({ error: "Unauthorized" }, 401);

        const userId = userData.user.id;
        const requestBody = await req.json();
        const generationEvent = isObject(requestBody?.generation_event)
            ? requestBody.generation_event as Record<string, unknown>
            : null;
        if (generationEvent) {
            return await recordGenerationEvent(supabaseAdmin, userId, generationEvent);
        }

        let isSubscribed = false;
        try {
            const { data: profile } = await supabaseAdmin.from("profiles").select("is_subscribed, is_premium").eq("id", userId).maybeSingle();
            isSubscribed = Boolean(profile?.is_subscribed || profile?.is_premium);
        } catch (_) { isSubscribed = false; }

        const dailyLimit = isSubscribed ? PRO_DAILY_LIMIT : FREE_DAILY_LIMIT;
        const now = new Date();
        const day = now.toISOString().slice(0, 10);
        const { data: usage } = await supabaseAdmin.from("ai_usage").select("count,last_request_at").eq("user_id", userId).eq("day", day).maybeSingle();
        const currentCount = usage?.count ?? 0;
        const { prompt, selected_component, context } = requestBody;
        const safePrompt = typeof prompt === "string" ? prompt : "";
        const safeContext = isObject(context) ? context as Record<string, unknown> : {};
        const makeReset = () => new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)).toISOString();
        const makeQuota = (count: number) => ({ remaining: Math.max(0, dailyLimit - count), limit: dailyLimit, reset: makeReset(), rate_limit_seconds: RATE_LIMIT_SECONDS });

        if (safePrompt.trim().toLowerCase() === "quota check" && !selected_component) return json({ quota: makeQuota(currentCount) });
        const lastRequestAt = usage?.last_request_at ? new Date(usage.last_request_at) : null;
        if (lastRequestAt && (now.getTime() - lastRequestAt.getTime()) / 1000 < RATE_LIMIT_SECONDS) return json({ error: `Rate limit: 1 request every ${RATE_LIMIT_SECONDS}s`, retry_after: Math.ceil(RATE_LIMIT_SECONDS - ((now.getTime() - lastRequestAt.getTime()) / 1000)), quota: makeQuota(currentCount) }, 429);
        if (currentCount >= dailyLimit) return json({ error: "Daily AI limit reached", quota: makeQuota(currentCount) }, 429);

        let resolvedSelection = normalizeSelectedComponent(selected_component);
        if (!resolvedSelection) resolvedSelection = normalizeSelectedComponent(safeContext.selected_component_json);
        const forceFullCanvas = isFullCanvasPrompt(safePrompt);
        const hasSelection = resolvedSelection != null && !forceFullCanvas;
        const existingComponentCount = typeof safeContext.componentCount === "number" ? safeContext.componentCount : 0;
        const editIntent = classifyIntent(safePrompt);
        const explicitlyTargetsScreen = /\b(app|screen|page|dashboard|ui|interface|template|canvas|full design|whole design|entire design)\b/i.test(safePrompt);
        if (!hasSelection && !forceFullCanvas && existingComponentCount > 0 && editIntent !== "unknown" && !explicitlyTargetsScreen) {
            return json({ error: "Select a layer or name existing text before applying that edit." }, 409);
        }
        const selectedComponentType = isObject(resolvedSelection) && typeof resolvedSelection.type === "string" ? String(resolvedSelection.type) : null;
        await logPrompt(supabaseAdmin, userId, safePrompt, selectedComponentType, hasSelection, forceFullCanvas, currentCount, dailyLimit, now);
        if (!openaiApiKey) return json({ error: "OpenAI API key not configured" }, 500);
        const saveUsage = (count: number) => supabaseAdmin.from("ai_usage").upsert({ user_id: userId, day, count, last_request_at: now.toISOString(), updated_at: now.toISOString() }, { onConflict: "user_id,day" });
        if (!hasSelection) {
            const generationMode: GenerationMode = forceFullCanvas ? "full_canvas" : "standard";
            const generated = await buildGeneratedScreen(supabaseAdmin, safePrompt, safeContext, generationMode).catch((err) => { console.error("Generation pipeline timed out; returning emergency fallback", err); return buildEmergencyGeneratedScreen(safePrompt); });
            const normalizedComponents = postProcessComponents(generated.components, generated.canvas_settings?.canvasColorScheme);
            const generationId = crypto.randomUUID();
            await recordGeneration(supabaseAdmin, {
                id: generationId,
                userId,
                prompt: safePrompt,
                mode: generationMode,
                components: normalizedComponents,
                canvasSettings: generated.canvas_settings,
            });
            const newCount = currentCount + 1;
            await saveUsage(newCount);
            return json({ generation_id: generationId, components: normalizedComponents, generation_quality: "quality" in generated ? generated.quality : [{ code: "fallback", severity: "warning", message: "Generation used the emergency fallback." }], mode: generationMode === "full_canvas" ? "full_canvas" : "blocks", canvas_settings: generated.canvas_settings, ...(generated.theme ? { theme: { appName: generated.theme.appName, accentColor: generated.theme.accentColor, secondaryColor: generated.theme.secondaryColor, voiceTone: generated.theme.voiceTone, cornerRadiusScale: generated.theme.cornerRadiusScale } } : {}), quota: makeQuota(newCount) });
        }

        const selectedComponent = resolvedSelection as AnyComponent;
        const intent = editIntent;
        if (intent !== "structure" && intent !== "content" && intent !== "wrap" && intent !== "canvas") {
            const deterministicPatched = applyDeterministicModifierEdits(selectedComponent, safePrompt);
            if (deterministicPatched) return await componentResponse(deterministicPatched, selectedComponent, safePrompt, currentCount, saveUsage, makeQuota);
        }
        if (intent === "style" && !["Stack", "VStack", "HStack", "ZStack", "ScrollView", "Button"].includes(selectedComponent.type)) {
            const patched = await applyStylePatch(selectedComponent, safePrompt);
            if (patched) return await componentResponse(patched, selectedComponent, safePrompt, currentCount, saveUsage, makeQuota);
        }
        const compileResult = await compileWithRepairMessages({ messages: [{ role: "system", content: buildSelectionSystemPrompt(selectedComponent, intent) }, { role: "system", content: `SELECTED COMPONENT:\n${JSON.stringify(resolvedSelection)}` }, { role: "user", content: safePrompt }], maxAttempts: 2, model: SELECTION_MODEL, maxTokens: SELECTION_MAX_TOKENS });
        if (compileResult.ok === false) {
            console.warn("Selection compiler failed", compileResult.error);
            return json({ error: "AI couldn't complete that edit. Please try again." }, 500);
        }
        const parsedResult = compileResult.parsed as Record<string, unknown>;
        preserveTextIfNeeded(parsedResult.component as AnyComponent | undefined, resolvedSelection as Record<string, unknown> | undefined, safePrompt);
        const newCount = currentCount + 1;
        await saveUsage(newCount);
        return json({ ...parsedResult, quota: makeQuota(newCount) });
    } catch (err) {
        console.error("StudioAI request failed", err);
        return json({ error: "AI couldn't complete that request. Please try again." }, 500);
    }
});

function json(body: unknown, status = 200): Response { return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }); }
async function recordGeneration(supabaseAdmin: ReturnType<typeof createClient>, params: { id: string; userId: string; prompt: string; mode: GenerationMode; components: AnyComponent[]; canvasSettings: unknown }) {
    try {
        const { error } = await supabaseAdmin.from("ai_generations").insert({
            id: params.id,
            user_id: params.userId,
            prompt: params.prompt,
            generation_mode: params.mode,
            generated_screen: { components: params.components, canvas_settings: params.canvasSettings },
            component_count: params.components.length,
        });
        if (error) console.error("ai_generations insert failed", error);
    } catch (error) {
        console.error("ai_generations insert failed", error);
    }
}
async function recordGenerationEvent(supabaseAdmin: ReturnType<typeof createClient>, userId: string, event: Record<string, unknown>): Promise<Response> {
    const generationId = typeof event.generation_id === "string" ? event.generation_id : "";
    const eventType = typeof event.event_type === "string" ? event.event_type : "";
    const allowedEvents = new Set(["applied", "edited", "regenerated", "kept", "undone", "exported"]);
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(generationId) || !allowedEvents.has(eventType)) {
        return json({ error: "Invalid generation event" }, 400);
    }
    const { data: generation, error: lookupError } = await supabaseAdmin
        .from("ai_generations")
        .select("id,generated_screen")
        .eq("id", generationId)
        .eq("user_id", userId)
        .maybeSingle();
    if (lookupError || !generation) return json({ error: "Generation not found" }, 404);

    const editCount = nonNegativeInteger(event.edit_count) ?? 0;
    const elapsedMs = nonNegativeInteger(event.elapsed_ms);
    const timeToFirstEditMs = nonNegativeInteger(event.time_to_first_edit_ms);
    const finalScreenResult = normalizeOutcomeScreen(event.final_screen);
    if (finalScreenResult.ok === false) return json({ error: finalScreenResult.error }, 400);
    const finalScreen = finalScreenResult.screen;
    const structuralChangeScore = finalScreen
        ? calculateStructuralChangeScore(generation.generated_screen, finalScreen)
        : null;
    const outcomeScore = calculateOutcomeScore(eventType, editCount, structuralChangeScore);
    const learningConsent = event.learning_consent === true;
    const metadata = {
        edit_count: editCount,
        elapsed_ms: elapsedMs,
        time_to_first_edit_ms: timeToFirstEditMs,
        has_final_screen: finalScreen != null,
        structural_change_score: structuralChangeScore,
        outcome_score: outcomeScore,
    };
    const { error } = await supabaseAdmin.from("ai_generation_events").insert({
        generation_id: generationId,
        user_id: userId,
        event_type: eventType,
        metadata,
    });
    if (error) {
        console.error("ai_generation_events insert failed", error);
        return json({ error: "Could not record generation event" }, 500);
    }

    const { error: outcomeError } = await supabaseAdmin.from("ai_generation_outcomes").upsert({
        generation_id: generationId,
        user_id: userId,
        ...(finalScreen ? { final_screen: finalScreen } : {}),
        latest_event: eventType,
        edit_count: editCount,
        elapsed_ms: elapsedMs,
        time_to_first_edit_ms: timeToFirstEditMs,
        structural_change_score: structuralChangeScore,
        outcome_score: outcomeScore,
        learning_consent: learningConsent,
        // Promotion requires a separate server-side quality review.
        eligible_for_learning: false,
        updated_at: new Date().toISOString(),
    }, { onConflict: "generation_id" });
    if (outcomeError) {
        console.error("ai_generation_outcomes upsert failed", outcomeError);
        return json({ error: "Could not record generation outcome" }, 500);
    }
    return json({ recorded: true, outcome_score: outcomeScore });
}

function nonNegativeInteger(value: unknown): number | null {
    if (typeof value !== "number" || !Number.isFinite(value)) return null;
    return Math.max(0, Math.min(2_147_483_647, Math.round(value)));
}

function normalizeOutcomeScreen(value: unknown):
    | { ok: true; screen: Record<string, unknown> | null }
    | { ok: false; error: string } {
    if (value == null) return { ok: true, screen: null };
    if (!isObject(value) || !Array.isArray(value.components)) {
        return { ok: false, error: "Invalid final screen" };
    }
    let serialized: string;
    try { serialized = JSON.stringify(value); } catch (_) { return { ok: false, error: "Invalid final screen" }; }
    if (new TextEncoder().encode(serialized).length > MAX_OUTCOME_SCREEN_BYTES) {
        return { ok: false, error: "Final screen is too large" };
    }
    let componentCount = 0;
    const visit = (node: unknown): boolean => {
        if (!isObject(node) || typeof node.type !== "string") return false;
        componentCount += 1;
        if (componentCount > MAX_OUTCOME_COMPONENTS) return false;
        if (node.children != null) {
            if (!Array.isArray(node.children)) return false;
            for (const child of node.children) if (!visit(child)) return false;
        }
        return true;
    };
    for (const component of value.components) {
        if (!visit(component)) return { ok: false, error: "Invalid or oversized final screen" };
    }
    return { ok: true, screen: value };
}

function calculateStructuralChangeScore(initialScreen: unknown, finalScreen: unknown): number {
    const signatures = (screen: unknown): Set<string> => {
        const result = new Set<string>();
        if (!isObject(screen) || !Array.isArray(screen.components)) return result;
        const visit = (node: unknown, path: string) => {
            if (!isObject(node) || typeof node.type !== "string") return;
            result.add(`${path}:${node.type}`);
            if (!Array.isArray(node.children)) return;
            node.children.forEach((child, index) => visit(child, `${path}.${index}`));
        };
        screen.components.forEach((component, index) => visit(component, `root.${index}`));
        return result;
    };
    const initial = signatures(initialScreen);
    const final = signatures(finalScreen);
    const union = new Set([...initial, ...final]);
    if (union.size === 0) return 0;
    let intersectionCount = 0;
    for (const signature of initial) if (final.has(signature)) intersectionCount += 1;
    return Number((1 - (intersectionCount / union.size)).toFixed(4));
}

function calculateOutcomeScore(eventType: string, editCount: number, structuralChangeScore: number | null): number {
    const baseScore: Record<string, number> = {
        applied: 0.35,
        edited: 0.55,
        regenerated: 0.10,
        kept: 0.85,
        undone: 0.05,
        exported: 0.98,
    };
    const structuralPenalty = (structuralChangeScore ?? 0) * 0.35;
    const editPenalty = Math.min(0.18, editCount * 0.015);
    return Number(Math.max(0, Math.min(1, (baseScore[eventType] ?? 0) - structuralPenalty - editPenalty)).toFixed(4));
}
async function logPrompt(supabaseAdmin: ReturnType<typeof createClient>, userId: string, prompt: string, selectedComponentType: string | null, hasSelection: boolean, forceFullCanvas: boolean, currentCount: number, dailyLimit: number, now: Date) {
    const promptForLog = prompt.trim();
    if (!promptForLog) return;
    try { await supabaseAdmin.from("ai_prompts").insert({ user_id: userId, prompt: promptForLog, prompt_length: promptForLog.length, selected_component_type: selectedComponentType, has_selection: hasSelection, generation_mode: forceFullCanvas ? "full_canvas" : "selection_or_standard", daily_count_at_request: currentCount, daily_limit: dailyLimit, created_at: now.toISOString() }); } catch (logError) { console.error("ai_prompts insert failed", logError); }
}
async function componentResponse(component: AnyComponent, selectedComponent: AnyComponent, prompt: string, currentCount: number, saveUsage: (count: number) => Promise<unknown>, makeQuota: (count: number) => unknown): Promise<Response> {
    const fixed = postProcessComponents([component])[0];
    if (fixed?.type === "Text" && selectedComponent?.type === "Text" && !promptExplicitlyChangesText(prompt)) {
        const selectedProps = isObject(selectedComponent.properties) ? selectedComponent.properties as Record<string, unknown> : undefined;
        const selectedText = selectedProps?.["text"];
        if (typeof selectedText === "string" && selectedText.trim().length > 0) {
            if (!isObject(fixed.properties)) fixed.properties = {};
            (fixed.properties as Record<string, unknown>)["text"] = selectedText;
        }
    }
    const newCount = currentCount + 1;
    await saveUsage(newCount);
    return json({ component: fixed, mode: "component", quota: makeQuota(newCount) });
}
function preserveTextIfNeeded(comp: AnyComponent | undefined, sel: Record<string, unknown> | undefined, prompt: string): void {
    if (comp && comp.type === "Text" && sel && sel.type === "Text") {
        const selProps = isObject(sel.properties) ? sel.properties as Record<string, unknown> : undefined;
        const selText = selProps?.["text"];
        if (typeof selText === "string" && !promptExplicitlyChangesText(prompt)) {
            if (!isObject(comp.properties)) comp.properties = {};
            (comp.properties as Record<string, unknown>)["text"] = selText;
        }
    }
}
