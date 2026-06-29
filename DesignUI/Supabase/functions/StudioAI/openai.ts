// ─── Model routing ───────────────────────────────────────────────────────────
export const THEME_MODEL = "gpt-4o-mini";
export const ARCHETYPE_MODEL = "gpt-4o-mini";
export const SLOT_PLANNER_MODEL = "gpt-4o";
export const SLOT_GENERATOR_MODEL = "gpt-4o";    // prioritize first-pass visual quality
export const STANDARD_TOKENS_MODEL = "gpt-4o-mini";
export const SELECTION_MODEL = "gpt-4o";
export const REPAIR_MODEL = "gpt-4o-mini";
export const EMBEDDING_MODEL = "text-embedding-3-small";

export const REPAIR_MAX_TOKENS = 2400;
export const SELECTION_MAX_TOKENS = 900;
export const STYLE_PATCH_MAX_TOKENS = 400;
export const ARCHETYPE_MAX_TOKENS = 200;
export const SLOT_PLANNER_MAX_TOKENS = 800;
export const SLOT_GENERATOR_MAX_TOKENS = 3000;
export const FULL_CANVAS_SLOT_PLANNER_MAX_TOKENS = 1100;
export const FULL_CANVAS_SLOT_GENERATOR_MAX_TOKENS = 4200;
export const THEME_EXTRACT_MAX_TOKENS = 600;
export const OPENAI_TIMEOUT_MS = 14000;
export const EMBEDDING_TIMEOUT_MS = 6000;
export const GENERATION_DEADLINE_MS = 30000;
export const SLOT_BATCH_SIZE = 3;
export const FULL_CANVAS_SLOT_BATCH_SIZE = 4;
export const SLOT_BATCH_GRACE_MS = 1200;
export const SLOT_GENERATION_MAX_ATTEMPTS = 2;
export const FULL_CANVAS_SLOT_GENERATION_MAX_ATTEMPTS = 3;
export const MAX_GENERATION_SLOTS = 6;
export const SLOT_DESIGN_PASSES = 1;
export const FULL_CANVAS_SLOT_DESIGN_PASSES = 2;
export const GEN_V3_SKETCH_RENDER = false;
export const GEN_V3_CONTRACTS_AS_PLANS = true;

export const openaiApiKey = Deno.env.get("OPENAI_API_KEY");

// ─── OpenAI client ───────────────────────────────────────────────────────────

export async function callOpenAI(params: {
    model: string;
    messages: Array<Record<string, unknown>>;
    temperature: number;
    maxTokens?: number;
    responseFormat?: { type: "json_object" };
    timeoutMs?: number;
}) {
    const controller = new AbortController();
    const timeoutMs = params.timeoutMs ?? OPENAI_TIMEOUT_MS;
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    let response: Response;
    try {
        response = await fetch("https://api.openai.com/v1/chat/completions", {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${openaiApiKey}` },
            body: JSON.stringify({ model: params.model, messages: params.messages, temperature: params.temperature, max_tokens: params.maxTokens, response_format: params.responseFormat ?? { type: "json_object" } }),
            signal: controller.signal,
        });
    } catch (err) {
        clearTimeout(timer);
        const msg = err instanceof Error ? err.message : String(err);
        return { ok: false as const, error: msg.toLowerCase().includes("abort") ? `OpenAI request timed out after ${timeoutMs}ms` : `OpenAI network error: ${msg}` };
    }
    clearTimeout(timer);
    if (!response.ok) return { ok: false as const, error: await response.text() };
    let data: any;
    try { data = await response.json(); } catch (err) { return { ok: false as const, error: `OpenAI JSON decode error: ${err instanceof Error ? err.message : String(err)}` }; }
    const content = data?.choices?.[0]?.message?.content;
    if (!content || typeof content !== "string") return { ok: false as const, error: "OpenAI returned empty content" };
    return { ok: true as const, content };
}
