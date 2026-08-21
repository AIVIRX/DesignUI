import { SCREEN_IR_MAX_TOKENS, STANDARD_TOKENS_MODEL, callOpenAI } from "./openai.ts";
import { SCREEN_IR_RESPONSE_FORMAT } from "./structured-output.ts";
import type { InteractionModel, PromptDesignSpec, ScreenIR, ScreenIRSection, ScreenIRSectionKind, ScreenPlan, SemanticIntent, SlotPlan, SlotPosition, SlotType, ThemeTokens } from "./types.ts";
import { isJsonParseError, isObject, parseJsonSafe } from "./utils.ts";

const SLOT_TYPES: SlotType[] = [
    "app_header", "hero_banner", "stat_group", "content_list", "content_grid",
    "horizontal_rail", "action_bar", "nav_bar", "section_header", "media_player",
    "profile_header", "form_section", "empty_state", "banner_alert", "segmented_tabs",
    "timeline_list", "settings_list", "chart_section", "social_feed_slot", "gallery_grid",
    "onboarding_step", "search_bar", "fab_button", "card_detail", "pricing_table",
    "calendar_strip", "progress_section", "testimonial_rail", "feature_grid",
    "comparison_table", "countdown_timer", "weather_widget", "map_preview",
    "notification_list", "chat_bubble_list", "story_rail", "avatar_group",
    "breadcrumb_nav", "split_view", "floating_card",
];
const SECTION_KINDS: ScreenIRSectionKind[] = [
    "header", "search", "hero", "map_surface", "input_group", "option_list",
    "content_list", "content_grid", "rail", "chart", "progress", "settings_group",
    "feed", "timeline", "profile_summary", "action_strip", "media_controls", "empty_state",
];
const INTERACTIONS: InteractionModel[] = [
    "dashboard", "list_first", "map_first", "form_flow", "feed", "comparison",
    "detail", "media_browse", "search_results",
];

const SCREEN_IR_SYSTEM_PROMPT = `You are a senior product UI architect.
Convert the prompt, semantic intent, and draft slot plan into a reusable screen intermediate representation.

Rules:
- Think in product flow and composition, not brand mimicry.
- Choose sections that express the user's goal with as little filler as possible.
- A map-first transport screen should become map_surface + input_group + option_list + action_strip, not hero/stats/list.
- A settings screen should become header + settings_group, not hero/banner/stat sections.
- Keep the IR reusable and implementation-oriented.`;

export async function extractScreenIR(params: {
    prompt: string;
    theme: ThemeTokens;
    plan: ScreenPlan;
    semanticIntent: SemanticIntent;
    designSpec?: PromptDesignSpec;
}): Promise<ScreenIR> {
    const fallback = buildFallbackScreenIR(params.plan, params.semanticIntent);
    const response = await callOpenAI({
        model: STANDARD_TOKENS_MODEL,
        messages: [
            { role: "system", content: SCREEN_IR_SYSTEM_PROMPT },
            { role: "system", content: `SEMANTIC INTENT:\n${formatSemanticIntent(params.semanticIntent)}\n\nDRAFT SLOT PLAN:\n${JSON.stringify(params.plan.slots, null, 1)}\n\nTHEME:\nappName=${params.theme.appName} surface=${params.theme.surfaceStyle} tone=${params.theme.voiceTone} density=${params.theme.density}` },
            ...(params.designSpec ? [{ role: "system", content: `DESIGN SPEC:\n${JSON.stringify(params.designSpec)}` }] : []),
            { role: "user", content: params.prompt },
        ],
        temperature: 0.15,
        maxTokens: SCREEN_IR_MAX_TOKENS,
        responseFormat: SCREEN_IR_RESPONSE_FORMAT,
    });
    if (!response.ok) return fallback;
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) return fallback;
    return normalizeScreenIR(parsed.value as Record<string, unknown>, fallback);
}

export function compileScreenIRToPlan(screenIR: ScreenIR, fallbackPlan: ScreenPlan): ScreenPlan {
    const slots: SlotPlan[] = screenIR.sections.map((section) => ({
        slotType: section.slotType,
        position: section.position,
        intent: section.goal,
        itemCount: section.itemCount,
        variant_hint: buildVariantHint(section),
    }));

    const deduped: SlotPlan[] = [];
    const seen = new Set<string>();
    for (const slot of slots) {
        const key = `${slot.position}|${slot.slotType}|${slot.intent}`;
        if (seen.has(key)) continue;
        seen.add(key);
        deduped.push(slot);
    }

    return {
        ...fallbackPlan,
        slots: deduped.length > 0 ? deduped : fallbackPlan.slots,
    };
}

function buildFallbackScreenIR(plan: ScreenPlan, semanticIntent: SemanticIntent): ScreenIR {
    return {
        version: "screen_ir_v1",
        layoutMode: semanticIntent.interactionModel,
        primaryGoal: semanticIntent.primaryGoal,
        sections: plan.slots.map((slot, index) => ({
            kind: inferSectionKind(slot.slotType),
            slotType: slot.slotType,
            position: slot.position,
            goal: slot.intent,
            entities: semanticIntent.entities.slice(0, 4),
            emphasis: index === 0 ? "high" : index <= 2 ? "medium" : "low",
            itemCount: slot.itemCount,
            variant: slot.variant_hint,
        })),
    };
}

function normalizeScreenIR(value: Record<string, unknown>, fallback: ScreenIR): ScreenIR {
    const sections = Array.isArray(value.sections) ? value.sections : [];
    const normalizedSections: ScreenIRSection[] = sections.map((item): ScreenIRSection | null => {
        if (!isObject(item)) return null;
        const kind = typeof item.kind === "string" && SECTION_KINDS.includes(item.kind as ScreenIRSectionKind)
            ? item.kind as ScreenIRSectionKind
            : null;
        const slotType = typeof item.slotType === "string" && SLOT_TYPES.includes(item.slotType as SlotType)
            ? item.slotType as SlotType
            : null;
        const position = typeof item.position === "string" && ["top", "body", "bottom", "overlay"].includes(item.position)
            ? item.position as SlotPosition
            : null;
        const emphasis = typeof item.emphasis === "string" && ["low", "medium", "high"].includes(item.emphasis)
            ? item.emphasis as "low" | "medium" | "high"
            : "medium";
        if (!kind || !slotType || !position) return null;
        return {
            kind,
            slotType,
            position,
            goal: typeof item.goal === "string" && item.goal.trim().length > 0 ? item.goal.trim() : fallback.primaryGoal,
            entities: Array.isArray(item.entities) ? item.entities.filter((entry): entry is string => typeof entry === "string").slice(0, 8) : [],
            emphasis,
            itemCount: typeof item.itemCount === "number" ? item.itemCount : undefined,
            variant: typeof item.variant === "string" ? item.variant : undefined,
        };
    }).filter((item): item is ScreenIRSection => item !== null);

    return {
        version: "screen_ir_v1",
        layoutMode: typeof value.layoutMode === "string" && INTERACTIONS.includes(value.layoutMode as InteractionModel)
            ? value.layoutMode as InteractionModel
            : fallback.layoutMode,
        primaryGoal: typeof value.primaryGoal === "string" && value.primaryGoal.trim().length > 0 ? value.primaryGoal.trim() : fallback.primaryGoal,
        sections: normalizedSections.length > 0 ? normalizedSections : fallback.sections,
    };
}

function inferSectionKind(slotType: SlotType): ScreenIRSectionKind {
    switch (slotType) {
    case "app_header":
    case "section_header":
        return "header";
    case "search_bar":
        return "search";
    case "hero_banner":
    case "card_detail":
        return "hero";
    case "map_preview":
        return "map_surface";
    case "form_section":
        return "input_group";
    case "content_list":
        return "option_list";
    case "content_grid":
    case "gallery_grid":
    case "feature_grid":
        return "content_grid";
    case "horizontal_rail":
    case "story_rail":
    case "testimonial_rail":
        return "rail";
    case "chart_section":
        return "chart";
    case "progress_section":
    case "stat_group":
        return "progress";
    case "settings_list":
        return "settings_group";
    case "social_feed_slot":
    case "chat_bubble_list":
    case "notification_list":
        return "feed";
    case "timeline_list":
    case "calendar_strip":
        return "timeline";
    case "profile_header":
        return "profile_summary";
    case "action_bar":
    case "nav_bar":
        return "action_strip";
    case "media_player":
        return "media_controls";
    case "empty_state":
        return "empty_state";
    default:
        return "content_list";
    }
}

function buildVariantHint(section: ScreenIRSection): string {
    const parts = [
        `${section.kind} section`,
        section.variant ?? "",
        section.entities.length > 0 ? `entities: ${section.entities.join(", ")}` : "",
        section.emphasis === "high" ? "primary visual anchor" : section.emphasis === "medium" ? "supporting section with clear hierarchy" : "lightweight supporting section",
    ].filter((part) => part.length > 0);
    return parts.join(" | ");
}

function formatSemanticIntent(intent: SemanticIntent): string {
    return [
        `domain: ${intent.domain}`,
        `interactionModel: ${intent.interactionModel}`,
        `primaryGoal: ${intent.primaryGoal}`,
        `entities: ${intent.entities.join(", ") || "none"}`,
        `capabilities: ${intent.capabilities.join(", ") || "none"}`,
        `preferredFocalSlot: ${intent.preferredFocalSlot ?? "none"}`,
        `preferredSupportSlots: ${intent.preferredSupportSlots.join(", ") || "none"}`,
        `avoidSlots: ${intent.avoidSlots.join(", ") || "none"}`,
    ].join("\n");
}
