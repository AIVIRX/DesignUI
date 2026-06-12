import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { Exemplar, VoiceTone, AnyComponent } from "./types.ts";
import { EMBEDDING_MODEL, EMBEDDING_TIMEOUT_MS, openaiApiKey } from "./openai.ts";
import { isObject } from "./utils.ts";

const SEED_SLOT_EXEMPLARS: Exemplar[] = [
    {
        id: "seed_hero_banner_1",
        slot_type: "hero_banner",
        voice_tone: "friendly",
        surface_style: "editorial",
        domain_tags: ["general"],
        description: "Editorial hero with focal value, support copy, and CTA row.",
        component_tree: {
            type: "VStack",
            properties: { alignment: "leading", spacing: 12 },
            modifiers: [
                { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                { type: "Padding", properties: { amount: 16, location: "all" } },
                { type: "Background Color", properties: { color: "blue:0.08" } },
                { type: "Corner Radius", properties: { radius: 18 } },
            ],
            children: [
                { type: "Text", properties: { text: "Weekly momentum" }, modifiers: [{ type: "Font", properties: { fontSize: "caption", fontWeight: "semibold" } }] },
                { type: "Text", properties: { text: "24% growth" }, modifiers: [{ type: "Font", properties: { fontSize: "largeTitle", fontWeight: "bold" } }] },
                { type: "Text", properties: { text: "Performance is trending up across your top segments." }, modifiers: [{ type: "Foreground Color", properties: { color: "secondary:1.0" } }] },
            ],
        },
    },
    {
        id: "seed_stat_group_1",
        slot_type: "stat_group",
        voice_tone: "professional",
        surface_style: "utility",
        domain_tags: ["general"],
        description: "Two-up metric cards with primary + secondary stats and trend label.",
        component_tree: {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            children: [
                {
                    type: "HStack",
                    properties: { spacing: 10, alignment: "top" },
                    children: [
                        { type: "RoundedRectangle", properties: { cornerRadius: 14 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 110 } }, { type: "Fill", properties: { color: "gray:0.10" } }] },
                        { type: "RoundedRectangle", properties: { cornerRadius: 14 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 110 } }, { type: "Fill", properties: { color: "gray:0.10" } }] },
                    ],
                },
            ],
        },
    },
    {
        id: "seed_horizontal_rail_1",
        slot_type: "horizontal_rail",
        voice_tone: "friendly",
        surface_style: "immersive",
        domain_tags: ["media"],
        description: "Poster rail with visual-first cards and concise labels.",
        component_tree: {
            type: "ScrollView",
            properties: { axis: "horizontal", showsIndicators: false },
            children: [
                {
                    type: "HStack",
                    properties: { spacing: 12, alignment: "top" },
                    children: [
                        { type: "RoundedRectangle", properties: { cornerRadius: 12 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 140, heightType: "Custom", height: 190 } }, { type: "Fill", properties: { color: "gray:0.16" } }] },
                        { type: "RoundedRectangle", properties: { cornerRadius: 12 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 140, heightType: "Custom", height: 190 } }, { type: "Fill", properties: { color: "gray:0.16" } }] },
                    ],
                },
            ],
        },
    },
    {
        id: "seed_content_list_1",
        slot_type: "content_list",
        voice_tone: "professional",
        surface_style: "utility",
        domain_tags: ["general"],
        description: "Scannable list rows with icon, title, subtitle, and right-aligned status.",
        component_tree: {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            children: [
                {
                    type: "HStack",
                    properties: { spacing: 10, alignment: "center" },
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.08" } }, { type: "Corner Radius", properties: { radius: 12 } }],
                    children: [
                        { type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 32, heightType: "Custom", height: 32 } }, { type: "Fill", properties: { color: "gray:0.16" } }] },
                        { type: "Text", properties: { text: "Primary row" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Font", properties: { fontSize: "body", fontWeight: "semibold" } }] },
                        { type: "Text", properties: { text: "Open" }, modifiers: [{ type: "Foreground Color", properties: { color: "blue:1.0" } }, { type: "Font", properties: { fontSize: "caption", fontWeight: "bold" } }] },
                    ],
                },
            ],
        },
    },
];

// ─── Retrieval (pgvector + in-memory fallback) ───────────────────────────────

export const EMBEDDING_DIM = 1536;

export async function embedText(text: string): Promise<number[] | null> {
    if (!openaiApiKey) return null;
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), EMBEDDING_TIMEOUT_MS);
    try {
        const res = await fetch("https://api.openai.com/v1/embeddings", {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${openaiApiKey}` },
            body: JSON.stringify({ model: EMBEDDING_MODEL, input: text.slice(0, 2000) }),
            signal: controller.signal,
        });
        clearTimeout(timer);
        if (!res.ok) return null;
        const data = await res.json();
        const v = data?.data?.[0]?.embedding;
        return Array.isArray(v) && v.length === EMBEDDING_DIM ? v : null;
    } catch {
        clearTimeout(timer);
        return null;
    }
}

export async function retrieveSlotExemplars(params: {
    supabase: ReturnType<typeof createClient> | null;
    slotType: string;
    voiceTone: VoiceTone;
    domainTags: string[];
    queryText: string;
    k?: number;
}): Promise<Exemplar[]> {
    const k = params.k ?? 2;
    const seedForSlot = SEED_SLOT_EXEMPLARS
        .filter((ex) => ex.slot_type === params.slotType)
        .slice(0, k);
    if (params.supabase) {
        try {
            const embedding = await embedText(params.queryText);
            if (embedding) {
                const { data, error } = await params.supabase.rpc("match_slot_exemplars", {
                    query_embedding: embedding,
                    target_slot_type: params.slotType,
                    target_voice_tone: params.voiceTone,
                    match_count: k,
                });
                if (!error && Array.isArray(data) && data.length > 0) {
                    return data.map((row: any) => ({
                        id: String(row.id),
                        slot_type: String(row.slot_type),
                        voice_tone: String(row.voice_tone),
                        surface_style: String(row.surface_style ?? ""),
                        domain_tags: Array.isArray(row.domain_tags) ? row.domain_tags : [],
                        description: String(row.description ?? ""),
                        component_tree: isObject(row.component_tree) ? row.component_tree as AnyComponent : { type: "VStack", properties: {}, children: [] },
                        similarity: typeof row.similarity === "number" ? row.similarity : undefined,
                    }));
                }
            }
        } catch (err) {
            console.warn("slot exemplar retrieval failed:", err instanceof Error ? err.message : String(err));
        }
    }
    return seedForSlot;
}
