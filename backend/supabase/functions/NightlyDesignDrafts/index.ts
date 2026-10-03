import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { buildGeneratedScreen, postProcessComponents } from "../StudioAI/assembler.ts";

const OWNER_ID = "ab52fbc5-e8bc-47e9-82ff-7b8abd970d54";
const DRAFTS_PER_RUN = 5;

const briefPool = [
    { title: "Daily Focus", device: "iPhone 17 Pro", width: 440, height: 956, brief: "A calm daily planning screen with priorities, a focused task, and a restrained progress summary." },
    { title: "Flight Status", device: "iPhone 16 Pro", width: 414, height: 896, brief: "A clear travel flight-status screen with gate, boarding state, timing, and one primary action." },
    { title: "Habit Pulse", device: "Widget Small", width: 170, height: 170, brief: "A glanceable small widget for one habit with a progress ring, streak, and no unnecessary controls." },
    { title: "Now Playing", device: "Widget Medium", width: 364, height: 170, brief: "A medium music widget with album art, track metadata, simple playback state, and strong information hierarchy." },
    { title: "Project Pulse", device: "iPad Pro 11", width: 1194, height: 834, brief: "A focused project overview with metrics, a concise task list, and generous tablet spacing." },
] as const;

serve(async (req) => {
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) return json({ error: "Server configuration missing" }, 500);

    // Supabase Cron reaches the Edge gateway with the public project key, then
    // presents this dedicated secret. Direct privileged service calls remain
    // supported without exposing the cron secret to clients.
    const cronSecret = Deno.env.get("NIGHTLY_DRAFTS_CRON_SECRET");
    const authorizedByCron = Boolean(
        cronSecret && req.headers.get("x-nightly-drafts-secret") === cronSecret,
    );
    const callerKey = req.headers.get("apikey");
    let authorizedByService = false;
    if (callerKey) {
        const caller = createClient(supabaseUrl, callerKey);
        const { error: callerError } = await caller.auth.admin.listUsers({ page: 1, perPage: 1 });
        authorizedByService = !callerError;
    }
    if (!authorizedByCron && !authorizedByService) return json({ error: "Unauthorized" }, 401);

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const runDate = new Date().toISOString().slice(0, 10);
    const body = await req.json().catch(() => ({})) as { draftIndex?: unknown };
    const draftIndex = typeof body.draftIndex === "number" && Number.isInteger(body.draftIndex)
        ? body.draftIndex
        : null;
    const items = draftIndex === null
        ? briefPool.slice(0, DRAFTS_PER_RUN)
        : [briefPool[draftIndex]].filter((item): item is typeof briefPool[number] => Boolean(item));
    if (items.length === 0) return json({ error: "Invalid draft index" }, 400);

    // A scheduled batch uses separate invocations, each with its own execution
    // budget. Avoid regenerating a specific draft if cron retries its job.
    const jobs = items.map(async (item) => {
        const { data: existing } = await admin
            .from("design_drafts")
            .select("id")
            .eq("owner_id", OWNER_ID)
            .eq("title", item.title)
            .gte("created_at", `${runDate}T00:00:00.000Z`)
            .limit(1);
        if (existing && existing.length > 0) return { title: item.title, ok: true, skipped: true };
        const prompt = [
            "Create an original, production-ready SwiftUI interface for DesignUI.",
            item.brief,
            `Target canvas: ${item.device} (${item.width}×${item.height} points).`,
            "Follow Apple Human Interface Guidelines: use clear hierarchy, readable system typography, accessible contrast, meaningful SF Symbols, comfortable spacing, and one obvious primary action.",
            "Keep the visual language refined and native-feeling. Do not copy Apple product screens, use trademarks as content, or invent dense phone layouts for widget canvases.",
        ].join("\n");

        try {
            const generated = await buildGeneratedScreen(admin, prompt, {
                canvasWidth: item.width,
                canvasHeight: item.height,
                canvasColorScheme: "light",
                statusBarVisible: !item.device.startsWith("Widget"),
                statusBarTopSafeArea: !item.device.startsWith("Widget"),
            }, "full_canvas");
            const designJSON = {
                name: item.title,
                description: "Private AI draft generated for review.",
                thumbnail: "blank",
                components: postProcessComponents(generated.components, "light"),
                devicePreset: item.device,
                canvasColorScheme: "light",
                statusBarVisible: generated.canvas_settings.statusBarVisible ?? !item.device.startsWith("Widget"),
                statusBarTopSafeArea: generated.canvas_settings.statusBarTopSafeArea ?? !item.device.startsWith("Widget"),
            };
            const { error } = await admin.from("design_drafts").insert({
                owner_id: OWNER_ID,
                title: item.title,
                prompt,
                device_preset: item.device,
                design_json: designJSON,
            });
            if (error) throw new Error(error.message);
            return { title: item.title, ok: true };
        } catch (error) {
            console.error("Nightly draft failed", item.title, error);
            return { title: item.title, ok: false };
        }
    });

    const results = await Promise.all(jobs);
    return json({ created: results.filter((result) => result.ok).length, results });
});

function json(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
