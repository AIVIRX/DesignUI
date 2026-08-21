import { SCREEN_ARCHETYPES, SLOT_TYPES } from "./types.ts";

export type JsonSchemaFormat = {
    type: "json_schema";
    name: string;
    description?: string;
    strict?: boolean;
    schema: Record<string, unknown>;
};

export function makeStrictSchemaFormat(
    name: string,
    schema: Record<string, unknown>,
    description?: string,
): JsonSchemaFormat {
    return {
        type: "json_schema",
        name,
        description,
        strict: true,
        schema,
    };
}

export const ARCHETYPE_RESPONSE_FORMAT = makeStrictSchemaFormat(
    "screen_archetype_v1",
    {
        type: "object",
        additionalProperties: false,
        properties: {
            archetype: {
                type: "string",
                enum: [...SCREEN_ARCHETYPES],
            },
        },
        required: ["archetype"],
    },
    "Classify the prompt into exactly one supported screen archetype.",
);

export const THEME_RESPONSE_FORMAT = makeStrictSchemaFormat(
    "theme_tokens_v1",
    {
        type: "object",
        additionalProperties: false,
        properties: {
            accentColor: { type: "string" },
            secondaryColor: { type: "string" },
            surfaceStyle: { type: "string", enum: ["minimal", "editorial", "utility", "immersive", "calm"] },
            density: { type: "string", enum: ["compact", "regular", "airy"] },
            fontDesign: { type: "string", enum: ["default", "serif", "rounded", "monospaced"] },
            cornerRadiusScale: { type: "string", enum: ["sharp", "medium", "pill"] },
            usesGradient: { type: "boolean" },
            appName: { type: "string" },
            voiceTone: { type: "string", enum: ["playful", "calm", "professional", "urgent"] },
            mascotSymbol: { type: "string" },
            itemNoun: { type: "string" },
            ctaVerb: { type: "string" },
            primaryMetricLabel: { type: "string" },
            primaryMetricUnit: { type: "string" },
            sampleItems: {
                type: "array",
                items: { type: "string" },
                minItems: 4,
                maxItems: 4,
            },
            sampleMetrics: {
                type: "array",
                items: { type: "string" },
                minItems: 4,
                maxItems: 4,
            },
            sampleRailItems: {
                type: "array",
                items: { type: "string" },
                minItems: 5,
                maxItems: 5,
            },
            ctaText: { type: "string" },
            domainTags: {
                type: "array",
                items: { type: "string" },
                minItems: 2,
                maxItems: 4,
            },
            sharedFacts: {
                type: "object",
                additionalProperties: false,
                properties: {
                    greeting: { type: "string" },
                    userName: { type: "string" },
                    primaryMetricValue: { type: "string" },
                    secondaryMetricValue: { type: "string" },
                    streakValue: { type: "string" },
                    progressPercent: { type: "number" },
                    todayDate: { type: "string" },
                },
                required: [
                    "greeting",
                    "userName",
                    "primaryMetricValue",
                    "secondaryMetricValue",
                    "streakValue",
                    "progressPercent",
                    "todayDate",
                ],
            },
        },
        required: [
            "accentColor",
            "secondaryColor",
            "surfaceStyle",
            "density",
            "fontDesign",
            "cornerRadiusScale",
            "usesGradient",
            "appName",
            "voiceTone",
            "mascotSymbol",
            "itemNoun",
            "ctaVerb",
            "primaryMetricLabel",
            "primaryMetricUnit",
            "sampleItems",
            "sampleMetrics",
            "sampleRailItems",
            "ctaText",
            "domainTags",
            "sharedFacts",
        ],
    },
    "Extract a complete set of design theme tokens for a mobile UI screen.",
);

export const SCREEN_PLAN_RESPONSE_FORMAT = makeStrictSchemaFormat(
    "screen_plan_v1",
    {
        type: "object",
        additionalProperties: false,
        properties: {
            slots: {
                type: "array",
                minItems: 2,
                maxItems: 7,
                items: {
                    type: "object",
                    additionalProperties: false,
                    properties: {
                        slotType: {
                            type: "string",
                            enum: [...SLOT_TYPES],
                        },
                        position: {
                            type: "string",
                            enum: ["top", "body", "bottom", "overlay"],
                        },
                        intent: { type: "string" },
                        itemCount: { type: "number" },
                        variant_hint: { type: "string" },
                    },
                    required: ["slotType", "position", "intent"],
                },
            },
            canvas_settings: {
                type: "object",
                additionalProperties: false,
                properties: {
                    statusBarVisible: { type: "boolean" },
                    statusBarTopSafeArea: { type: "boolean" },
                    canvasColorScheme: {
                        type: "string",
                        enum: ["light", "dark"],
                    },
                },
            },
        },
        required: ["slots"],
    },
    "Return an ordered, production-ready screen plan composed of valid UI slots.",
);

export const SLOT_COMPONENT_RESPONSE_FORMAT = makeStrictSchemaFormat(
    "slot_component_v1",
    {
        type: "object",
        additionalProperties: false,
        properties: {
            component: {
                type: "object",
                additionalProperties: false,
                properties: {
                    type: { type: "string" },
                    properties: {
                        type: "object",
                        additionalProperties: true,
                    },
                    modifiers: {
                        type: "array",
                        items: {
                            type: "object",
                            additionalProperties: true,
                        },
                    },
                    children: {
                        type: "array",
                        items: {
                            type: "object",
                            additionalProperties: true,
                        },
                    },
                },
                required: ["type"],
            },
        },
        required: ["component"],
    },
    "Return exactly one UI component tree for the requested slot.",
);

export const SEMANTIC_INTENT_RESPONSE_FORMAT = makeStrictSchemaFormat(
    "semantic_intent_v1",
    {
        type: "object",
        additionalProperties: false,
        properties: {
            domain: {
                type: "string",
                enum: ["productivity", "social", "media", "commerce", "finance", "transport", "travel", "health", "education", "utility", "lifestyle", "creative", "general"],
            },
            interactionModel: {
                type: "string",
                enum: ["dashboard", "list_first", "map_first", "form_flow", "feed", "comparison", "detail", "media_browse", "search_results"],
            },
            primaryGoal: { type: "string" },
            entities: {
                type: "array",
                items: { type: "string" },
                maxItems: 8,
            },
            capabilities: {
                type: "array",
                items: {
                    type: "string",
                    enum: ["live_context_surface", "map_surface", "location_flow", "compare_options", "status_tracking", "identity_header", "content_feed", "settings_controls", "media_playback", "data_summary", "search_refinement", "commerce_listing", "timeline_flow"],
                },
                maxItems: 8,
            },
            preferredFocalSlot: {
                type: "string",
                enum: [...SLOT_TYPES],
            },
            preferredSupportSlots: {
                type: "array",
                items: {
                    type: "string",
                    enum: [...SLOT_TYPES],
                },
                maxItems: 4,
            },
            avoidSlots: {
                type: "array",
                items: {
                    type: "string",
                    enum: [...SLOT_TYPES],
                },
                maxItems: 5,
            },
        },
        required: ["domain", "interactionModel", "primaryGoal", "entities", "capabilities", "preferredSupportSlots", "avoidSlots"],
    },
    "Return a semantic UI intent contract for the prompt.",
);

export const SCREEN_IR_RESPONSE_FORMAT = makeStrictSchemaFormat(
    "screen_ir_v1",
    {
        type: "object",
        additionalProperties: false,
        properties: {
            version: {
                type: "string",
                enum: ["screen_ir_v1"],
            },
            layoutMode: {
                type: "string",
                enum: ["dashboard", "list_first", "map_first", "form_flow", "feed", "comparison", "detail", "media_browse", "search_results"],
            },
            primaryGoal: { type: "string" },
            sections: {
                type: "array",
                minItems: 2,
                maxItems: 8,
                items: {
                    type: "object",
                    additionalProperties: false,
                    properties: {
                        kind: {
                            type: "string",
                            enum: ["header", "search", "hero", "map_surface", "input_group", "option_list", "content_list", "content_grid", "rail", "chart", "progress", "settings_group", "feed", "timeline", "profile_summary", "action_strip", "media_controls", "empty_state"],
                        },
                        slotType: {
                            type: "string",
                            enum: [...SLOT_TYPES],
                        },
                        position: {
                            type: "string",
                            enum: ["top", "body", "bottom", "overlay"],
                        },
                        goal: { type: "string" },
                        entities: {
                            type: "array",
                            items: { type: "string" },
                            maxItems: 8,
                        },
                        emphasis: {
                            type: "string",
                            enum: ["low", "medium", "high"],
                        },
                        itemCount: { type: "number" },
                        variant: { type: "string" },
                    },
                    required: ["kind", "slotType", "position", "goal", "entities", "emphasis"],
                },
            },
        },
        required: ["version", "layoutMode", "primaryGoal", "sections"],
    },
    "Return a screen intermediate representation describing the sections and behavior of the UI.",
);
