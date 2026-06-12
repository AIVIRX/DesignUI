import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { AnyComponent, GenerationMode } from "./types.ts";
import { buildEmergencyGeneratedScreen, buildGeneratedScreen, postProcessComponents } from "./assembler.ts";
import { applyDeterministicModifierEdits, applyStylePatch, buildSelectionSystemPrompt } from "./editing.ts";
import { classifyIntent, isFullCanvasPrompt, promptExplicitlyChangesText } from "./manifest.ts";
import { compileWithRepairMessages } from "./repair.ts";
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
        const { prompt, selected_component, context } = await req.json();
        const safePrompt = typeof prompt === "string" ? prompt : "";
        const makeReset = () => new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1)).toISOString();
        const makeQuota = (count: number) => ({ remaining: Math.max(0, dailyLimit - count), limit: dailyLimit, reset: makeReset(), rate_limit_seconds: RATE_LIMIT_SECONDS });

        if (safePrompt.trim().toLowerCase() === "quota check" && !selected_component) return json({ quota: makeQuota(currentCount) });
        const lastRequestAt = usage?.last_request_at ? new Date(usage.last_request_at) : null;
        if (lastRequestAt && (now.getTime() - lastRequestAt.getTime()) / 1000 < RATE_LIMIT_SECONDS) return json({ error: `Rate limit: 1 request every ${RATE_LIMIT_SECONDS}s`, retry_after: Math.ceil(RATE_LIMIT_SECONDS - ((now.getTime() - lastRequestAt.getTime()) / 1000)), quota: makeQuota(currentCount) }, 429);
        if (currentCount >= dailyLimit) return json({ error: "Daily AI limit reached", quota: makeQuota(currentCount) }, 429);

        let resolvedSelection = normalizeSelectedComponent(selected_component);
        if (!resolvedSelection && isObject(context)) resolvedSelection = normalizeSelectedComponent((context as Record<string, unknown>).selected_component_json);
        const forceFullCanvas = isFullCanvasPrompt(safePrompt);
        const hasSelection = resolvedSelection != null && !forceFullCanvas;
        const selectedComponentType = isObject(resolvedSelection) && typeof resolvedSelection.type === "string" ? String(resolvedSelection.type) : null;
        await logPrompt(supabaseAdmin, userId, safePrompt, selectedComponentType, hasSelection, forceFullCanvas, currentCount, dailyLimit, now);
        if (!openaiApiKey) return json({ error: "OpenAI API key not configured" }, 500);
        const saveUsage = (count: number) => supabaseAdmin.from("ai_usage").upsert({ user_id: userId, day, count, last_request_at: now.toISOString(), updated_at: now.toISOString() }, { onConflict: "user_id,day" });

        if (!hasSelection) {
            const generationMode: GenerationMode = forceFullCanvas ? "full_canvas" : "standard";
            const generated = await buildGeneratedScreen(supabaseAdmin, safePrompt, context, generationMode).catch((err) => { console.error("Generation pipeline timed out; returning emergency fallback", err); return buildEmergencyGeneratedScreen(safePrompt); });
            const normalizedComponents = postProcessComponents(generated.components, generated.canvas_settings?.canvasColorScheme);
            const newCount = currentCount + 1;
            await saveUsage(newCount);
            return json({ components: normalizedComponents, mode: generationMode === "full_canvas" ? "full_canvas" : "blocks", canvas_settings: generated.canvas_settings, ...(generated.theme ? { theme: { appName: generated.theme.appName, accentColor: generated.theme.accentColor, secondaryColor: generated.theme.secondaryColor, voiceTone: generated.theme.voiceTone, cornerRadiusScale: generated.theme.cornerRadiusScale } } : {}), quota: makeQuota(newCount) });
        }

        const selectedComponent = resolvedSelection as AnyComponent;
        const intent = classifyIntent(safePrompt);
        if (intent !== "structure" && intent !== "content" && intent !== "wrap" && intent !== "canvas") {
            const deterministicPatched = applyDeterministicModifierEdits(selectedComponent, safePrompt);
            if (deterministicPatched) return await componentResponse(deterministicPatched, selectedComponent, safePrompt, currentCount, saveUsage, makeQuota);
        }
        if (intent === "style" && !["Stack", "VStack", "HStack", "ZStack", "ScrollView", "Button"].includes(selectedComponent.type)) {
            const patched = await applyStylePatch(selectedComponent, safePrompt);
            if (patched) return await componentResponse(patched, selectedComponent, safePrompt, currentCount, saveUsage, makeQuota);
        }
        const compileResult = await compileWithRepairMessages({ messages: [{ role: "system", content: buildSelectionSystemPrompt(selectedComponent, intent) }, { role: "system", content: `SELECTED COMPONENT:\n${JSON.stringify(resolvedSelection)}` }, { role: "user", content: safePrompt }], maxAttempts: 2, model: SELECTION_MODEL, maxTokens: SELECTION_MAX_TOKENS });
        if (compileResult.ok === false) return json({ error: `Failed: ${compileResult.error}` }, 500);
        const parsedResult = compileResult.parsed as Record<string, unknown>;
        preserveTextIfNeeded(parsedResult.component as AnyComponent | undefined, resolvedSelection as Record<string, unknown> | undefined, safePrompt);
        const newCount = currentCount + 1;
        await saveUsage(newCount);
        return json({ ...parsedResult, quota: makeQuota(newCount) });
    } catch (err) {
        return json({ error: err instanceof Error ? err.message : String(err) }, 500);
    }
});

function json(body: unknown, status = 200): Response { return new Response(JSON.stringify(body), { status, headers: { ...corsHeaders, "Content-Type": "application/json" } }); }
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
