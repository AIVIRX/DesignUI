import type { JsonSchemaFormat } from "./schema.ts";

// ─── Model routing ───────────────────────────────────────────────────────────
const DEFAULT_MINI_MODEL = "gpt-5.4-mini";
const DEFAULT_MAIN_MODEL = "gpt-5.4";

export const THEME_MODEL = DEFAULT_MINI_MODEL;
export const ARCHETYPE_MODEL = DEFAULT_MINI_MODEL;
export const SLOT_PLANNER_MODEL = DEFAULT_MAIN_MODEL;
export const SLOT_GENERATOR_MODEL = DEFAULT_MAIN_MODEL;
export const STANDARD_TOKENS_MODEL = DEFAULT_MINI_MODEL;
export const SELECTION_MODEL = DEFAULT_MAIN_MODEL;
export const REPAIR_MODEL = DEFAULT_MINI_MODEL;
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
export const SEMANTIC_INTENT_MAX_TOKENS = 320;
export const SCREEN_IR_MAX_TOKENS = 700;
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
export const GEN_V3_SKETCH_RENDER = Deno.env.get("GEN_V3_SKETCH_RENDER") === "true";
export const GEN_V3_CONTRACTS_AS_PLANS = true;

export const openaiApiKey = Deno.env.get("OPENAI_API_KEY");

// ─── OpenAI client ───────────────────────────────────────────────────────────

export type OpenAIResponseMeta = {
    responseId: string | null;
    status: string | null;
    incompleteReason: string | null;
    refusal: string | null;
    inputTokens: number | null;
    outputTokens: number | null;
    totalTokens: number | null;
};

export function parseOpenAIResponse(data: Record<string, unknown>): {
    content: string | null;
    meta: OpenAIResponseMeta;
} {
    const output = Array.isArray(data.output) ? data.output : [];
    const chunks: string[] = [];
    let refusal: string | null = null;

    if (typeof data.output_text === "string" && data.output_text.length > 0) {
        chunks.push(data.output_text);
    } else {
        for (const item of output) {
            if (!item || typeof item !== "object") continue;
            const content = Array.isArray((item as Record<string, unknown>).content)
                ? (item as Record<string, unknown>).content as Array<Record<string, unknown>>
                : [];
            for (const part of content) {
                if (typeof part?.text === "string" && part.text.length > 0) chunks.push(part.text);
                if (typeof part?.refusal === "string" && part.refusal.length > 0) refusal = part.refusal;
            }
        }
    }

    const incompleteDetails = data.incomplete_details && typeof data.incomplete_details === "object"
        ? data.incomplete_details as Record<string, unknown>
        : null;
    const usage = data.usage && typeof data.usage === "object"
        ? data.usage as Record<string, unknown>
        : null;
    const numberOrNull = (value: unknown): number | null => typeof value === "number" ? value : null;

    return {
        content: chunks.length > 0 ? chunks.join("\n") : null,
        meta: {
            responseId: typeof data.id === "string" ? data.id : null,
            status: typeof data.status === "string" ? data.status : null,
            incompleteReason: typeof incompleteDetails?.reason === "string" ? incompleteDetails.reason : null,
            refusal,
            inputTokens: numberOrNull(usage?.input_tokens),
            outputTokens: numberOrNull(usage?.output_tokens),
            totalTokens: numberOrNull(usage?.total_tokens),
        },
    };
}

export async function callOpenAI(params: {
    model: string;
    messages: Array<Record<string, unknown>>;
    temperature: number;
    maxTokens?: number;
    responseFormat?: { type: "json_object" } | JsonSchemaFormat;
    timeoutMs?: number;
}) {
    const normalizeMessageContent = (value: unknown): string => {
        if (typeof value === "string") return value;
        if (Array.isArray(value)) {
            return value
                .map((item) => {
                    if (typeof item === "string") return item;
                    if (item && typeof item === "object" && "text" in item && typeof item.text === "string") {
                        return item.text;
                    }
                    return "";
                })
                .filter((item) => item.length > 0)
                .join("\n");
        }
        return "";
    };

    const systemMessages = params.messages
        .filter((message) => message.role === "system")
        .map((message) => normalizeMessageContent(message.content))
        .filter((content) => content.length > 0);

    const inputMessages = params.messages
        .filter((message) => message.role !== "system")
        .map((message) => {
            const rawRole = typeof message.role === "string" ? message.role : "user";
            const role = rawRole === "assistant" ? "assistant" : "user";
            return {
                role,
                content: [
                    {
                        type: "input_text",
                        text: normalizeMessageContent(message.content),
                    },
                ],
            };
        })
        .filter((message) => message.content[0].text.length > 0);

    const controller = new AbortController();
    const timeoutMs = params.timeoutMs ?? OPENAI_TIMEOUT_MS;
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    let response: Response;
    try {
        response = await fetch("https://api.openai.com/v1/responses", {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${openaiApiKey}` },
            body: JSON.stringify({
                model: params.model,
                instructions: systemMessages.length > 0 ? systemMessages.join("\n\n") : undefined,
                input: inputMessages.length > 0
                    ? inputMessages
                    : [
                        {
                            role: "user",
                            content: [
                                {
                                    type: "input_text",
                                    text: "Return the requested result.",
                                },
                            ],
                        },
                    ],
                temperature: params.temperature,
                max_output_tokens: params.maxTokens,
                text: { format: params.responseFormat ?? { type: "json_object" } },
                store: false,
            }),
            signal: controller.signal,
        });
    } catch (err) {
        clearTimeout(timer);
        const msg = err instanceof Error ? err.message : String(err);
        return { ok: false as const, error: msg.toLowerCase().includes("abort") ? `OpenAI request timed out after ${timeoutMs}ms` : `OpenAI network error: ${msg}` };
    }
    clearTimeout(timer);
    if (!response.ok) return { ok: false as const, error: await response.text() };
    let data: Record<string, unknown>;
    try { data = await response.json(); } catch (err) { return { ok: false as const, error: `OpenAI JSON decode error: ${err instanceof Error ? err.message : String(err)}` }; }
    const parsed = parseOpenAIResponse(data);
    if (parsed.meta.refusal) {
        return { ok: false as const, error: `OpenAI refusal: ${parsed.meta.refusal}`, meta: parsed.meta };
    }
    if (parsed.meta.status === "incomplete") {
        const reason = parsed.meta.incompleteReason ?? "unknown_reason";
        return { ok: false as const, error: `OpenAI response incomplete: ${reason}`, meta: parsed.meta };
    }
    if (!parsed.content) {
        return { ok: false as const, error: "OpenAI returned empty content", meta: parsed.meta };
    }
    return { ok: true as const, content: parsed.content, meta: parsed.meta };
}
