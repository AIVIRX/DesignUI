import { SEMANTIC_INTENT_MAX_TOKENS, STANDARD_TOKENS_MODEL, callOpenAI } from "./openai.ts";
import { SEMANTIC_INTENT_RESPONSE_FORMAT } from "./structured-output.ts";
import type { InteractionModel, SemanticDomain, SemanticIntent, SlotType, UICapability } from "./types.ts";
import { isJsonParseError, isObject, parseJsonSafe } from "./utils.ts";

const DOMAINS: SemanticDomain[] = [
    "productivity", "social", "media", "commerce", "finance", "transport", "travel",
    "health", "education", "utility", "lifestyle", "creative", "general",
];
const INTERACTIONS: InteractionModel[] = [
    "dashboard", "list_first", "map_first", "form_flow", "feed", "comparison",
    "detail", "media_browse", "search_results",
];
const CAPABILITIES: UICapability[] = [
    "live_context_surface", "map_surface", "location_flow", "compare_options", "status_tracking",
    "identity_header", "content_feed", "settings_controls", "media_playback", "data_summary",
    "search_refinement", "commerce_listing", "timeline_flow",
];
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

const SEMANTIC_INTENT_SYSTEM_PROMPT = `Extract a reusable semantic UI intent from the product prompt.
Return only structured data.

Focus on:
- domain
- dominant interaction model
- concrete entities the screen must organize
- reusable UI capabilities
- which slot should anchor the screen
- which slots would support the flow
- which slots would distort the flow

Think in product behavior, not just visual style or brand references.`;

export async function extractSemanticIntent(prompt: string): Promise<SemanticIntent> {
    const fallback = inferSemanticIntentFallback(prompt);
    const response = await callOpenAI({
        model: STANDARD_TOKENS_MODEL,
        messages: [
            { role: "system", content: SEMANTIC_INTENT_SYSTEM_PROMPT },
            { role: "user", content: prompt },
        ],
        temperature: 0.1,
        maxTokens: SEMANTIC_INTENT_MAX_TOKENS,
        responseFormat: SEMANTIC_INTENT_RESPONSE_FORMAT,
    });
    if (!response.ok) return fallback;
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) return fallback;
    return normalizeSemanticIntent(parsed.value as Record<string, unknown>, fallback);
}

function normalizeSemanticIntent(value: Record<string, unknown>, fallback: SemanticIntent): SemanticIntent {
    const stringArray = (input: unknown): string[] =>
        Array.isArray(input) ? input.filter((item): item is string => typeof item === "string").map((item) => item.trim()).filter(Boolean) : [];

    const domain = typeof value.domain === "string" && DOMAINS.includes(value.domain as SemanticDomain)
        ? value.domain as SemanticDomain
        : fallback.domain;
    const interactionModel = typeof value.interactionModel === "string" && INTERACTIONS.includes(value.interactionModel as InteractionModel)
        ? value.interactionModel as InteractionModel
        : fallback.interactionModel;
    const capabilities = stringArray(value.capabilities).filter((item): item is UICapability => CAPABILITIES.includes(item as UICapability));
    const preferredSupportSlots = stringArray(value.preferredSupportSlots).filter((item): item is SlotType => SLOT_TYPES.includes(item as SlotType));
    const avoidSlots = stringArray(value.avoidSlots).filter((item): item is SlotType => SLOT_TYPES.includes(item as SlotType));
    const preferredFocalSlot = typeof value.preferredFocalSlot === "string" && SLOT_TYPES.includes(value.preferredFocalSlot as SlotType)
        ? value.preferredFocalSlot as SlotType
        : fallback.preferredFocalSlot;

    return {
        domain,
        interactionModel,
        primaryGoal: typeof value.primaryGoal === "string" && value.primaryGoal.trim().length > 0 ? value.primaryGoal.trim() : fallback.primaryGoal,
        entities: (() => {
            const entities = stringArray(value.entities).slice(0, 8);
            return entities.length > 0 ? entities : fallback.entities;
        })(),
        capabilities: capabilities.length > 0 ? capabilities : fallback.capabilities,
        preferredFocalSlot,
        preferredSupportSlots: preferredSupportSlots.length > 0 ? preferredSupportSlots.slice(0, 4) : fallback.preferredSupportSlots,
        avoidSlots: avoidSlots.length > 0 ? avoidSlots.slice(0, 5) : fallback.avoidSlots,
    };
}

function inferSemanticIntentFallback(prompt: string): SemanticIntent {
    const p = prompt.toLowerCase();
    if (/\bmap\b|\bpickup\b|\bdestination\b|\broute\b|\beta\b|\bdriver\b|\bnearby\b/.test(p)) {
        return {
            domain: /\btrip\b|\btravel\b/.test(p) ? "travel" : "transport",
            interactionModel: "map_first",
            primaryGoal: "help the user understand location context and choose the best next option",
            entities: ["pickup", "destination", "eta", "driver", "option"],
            capabilities: ["map_surface", "location_flow", "compare_options", "status_tracking"],
            preferredFocalSlot: "map_preview",
            preferredSupportSlots: ["form_section", "content_list", "action_bar"],
            avoidSlots: ["hero_banner", "stat_group"],
        };
    }
    if (/\bsettings?\b|\bnotifications?\b|\bdark mode\b|\btoggle\b|\bswitch\b/.test(p)) {
        return {
            domain: "utility",
            interactionModel: "list_first",
            primaryGoal: "let the user inspect and change preferences quickly",
            entities: ["setting", "toggle", "preference"],
            capabilities: ["settings_controls", "identity_header"],
            preferredFocalSlot: "settings_list",
            preferredSupportSlots: ["app_header"],
            avoidSlots: ["hero_banner", "stat_group"],
        };
    }
    return {
        domain: "general",
        interactionModel: /\bsearch\b|\bresults?\b/.test(p) ? "search_results" : "dashboard",
        primaryGoal: "show the most relevant information for the requested screen",
        entities: [],
        capabilities: /\bsearch\b|\bresults?\b/.test(p) ? ["search_refinement", "content_feed"] : ["data_summary", "content_feed"],
        preferredFocalSlot: undefined,
        preferredSupportSlots: ["content_list"],
        avoidSlots: [],
    };
}
