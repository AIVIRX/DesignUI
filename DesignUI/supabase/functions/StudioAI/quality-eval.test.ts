import { ARCHETYPE_RESPONSE_FORMAT, SCREEN_IR_RESPONSE_FORMAT, SCREEN_PLAN_RESPONSE_FORMAT, SEMANTIC_INTENT_RESPONSE_FORMAT, SLOT_COMPONENT_RESPONSE_FORMAT, THEME_RESPONSE_FORMAT, UI_COMPONENT_SCHEMA_DEFS, UI_COMPONENT_SCHEMA_TYPES, UI_MODIFIER_SCHEMA_TYPES, VALID_COMPONENT_TYPES, VALID_MODIFIER_TYPES } from "./schema.ts";
import { detectLowQualitySlotOutput, findAccessibilityViolations, findSpacingScaleViolations, postProcessComponents, validateSlotAgainstPromptRequirements } from "./postprocess.ts";
import { evaluateComponentQuality, evaluateSlotPlan, PIPELINE_EVAL_CASES } from "./quality-eval.ts";
import type { AnyComponent } from "./types.ts";
import { detectRailVariantFromText } from "./utils.ts";
import { parseOpenAIResponse } from "./openai.ts";
import { buildDesignManifest, classifyIntent, detectPromptRequirements, isFullCanvasPrompt } from "./manifest.ts";
import { normalizeSlotPosition } from "./planner.ts";
import { assembleScreen, removeRepeatedCrossSlotGreetings } from "./assembler.ts";
import { buildBaselineTheme, computeThemeSurfaces } from "./theme.ts";

declare const Deno: { test(name: string, body: () => void): void };

function assert(condition: unknown, message: string): asserts condition {
    if (!condition) throw new Error(message);
}

function assertEqual(actual: unknown, expected: unknown, message: string): void {
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        throw new Error(`${message}\nactual=${JSON.stringify(actual)}\nexpected=${JSON.stringify(expected)}`);
    }
}

function inspectStrictObjects(value: unknown, path = "schema"): void {
    if (!value || typeof value !== "object" || Array.isArray(value)) return;
    const schema = value as Record<string, unknown>;
    if (schema.type === "object") {
        assert(schema.additionalProperties === false, `${path} must set additionalProperties:false`);
        const properties = schema.properties as Record<string, unknown> | undefined;
        const required = schema.required as string[] | undefined;
        assert(properties != null, `${path} object must define properties`);
        assert(Array.isArray(required), `${path} object must define required`);
        assertEqual([...required].sort(), Object.keys(properties).sort(), `${path} must require every property`);
    }
    assert(schema.additionalProperties !== true, `${path} cannot allow arbitrary properties`);
    for (const [key, child] of Object.entries(schema)) inspectStrictObjects(child, `${path}.${key}`);
}

Deno.test("slot component schema is strict and recursive", () => {
    inspectStrictObjects(UI_COMPONENT_SCHEMA_DEFS);
    const serialized = JSON.stringify(UI_COMPONENT_SCHEMA_DEFS);
    assert(serialized.includes('"$ref":"#/$defs/component"'), "component schema must recurse through $defs");
    assert(!serialized.includes('"additionalProperties":true'), "schema must never allow arbitrary keys");
});

Deno.test("every structured output object is closed and requires every field", () => {
    for (const format of [
        ARCHETYPE_RESPONSE_FORMAT,
        THEME_RESPONSE_FORMAT,
        SCREEN_PLAN_RESPONSE_FORMAT,
        SLOT_COMPONENT_RESPONSE_FORMAT,
        SEMANTIC_INTENT_RESPONSE_FORMAT,
        SCREEN_IR_RESPONSE_FORMAT,
    ]) {
        assert(format.strict === true, `${format.name} must use strict:true`);
        inspectStrictObjects(format.schema, format.name);
    }
});

Deno.test("schema vocabulary matches runtime vocabulary", () => {
    assertEqual([...UI_COMPONENT_SCHEMA_TYPES].sort(), [...VALID_COMPONENT_TYPES].sort(), "component types drifted");
    assertEqual([...UI_MODIFIER_SCHEMA_TYPES].sort(), [...VALID_MODIFIER_TYPES].sort(), "modifier types drifted");
});

Deno.test("postprocess preserves Stack and Map and removes nullable placeholders", () => {
    const input: AnyComponent = {
        type: "Stack",
        properties: { stackType: "z", alignment: "center", spacing: 0 },
        modifiers: [],
        children: [{
            type: "Map",
            properties: {
                mapPreset: null,
                latitude: 37.3346,
                longitude: -122.009,
                latitudeDelta: 0.018,
                longitudeDelta: 0.018,
                mapStyle: "standard",
                interactionModes: "all",
                showsCompass: true,
                showsScale: false,
                showsPitchToggle: false,
                showsUserLocation: false,
                showsUserLocationButton: false,
                showsTraffic: false,
                locationName: "Cupertino",
                markers: "",
            },
            modifiers: [],
        }],
    };
    const output = postProcessComponents([input])[0];
    assert(output.type === "Stack", "Stack must remain a Stack");
    assert(output.children?.[0]?.type === "Map", "Map must remain a Map");
    assert(!("mapPreset" in (output.children?.[0]?.properties ?? {})), "null properties must be removed");
});

Deno.test("quality evaluator catches spacing, glass, and generic-copy regressions", () => {
    const bad: AnyComponent = {
        type: "VStack",
        properties: { alignment: "leading", spacing: 7 },
        modifiers: [
            { type: "Glass Effect", properties: { shape: "RoundedRectangle", cornerRadius: 16, tint: null } },
            { type: "Background Color", properties: { color: "gray:0.10" } },
        ],
        children: [
            { type: "Text", properties: { text: "Priority item" }, modifiers: [] },
            { type: "Text", properties: { text: "Follow up" }, modifiers: [] },
        ],
    };
    const report = evaluateComponentQuality(bad);
    assert(!report.passed, "known-bad component must fail quality evaluation");
    assert(report.issues.some((issue) => issue.includes("spacing")), "spacing regression must be reported");
    assert(report.issues.some((issue) => issue.includes("Glass Effect")), "glass regression must be reported");
    assert(report.issues.some((issue) => issue.includes("generic fallback")), "generic copy must be reported");
});

Deno.test("prompt corpus slot expectations are enforceable", () => {
    const rideshare = PIPELINE_EVAL_CASES.find((item) => item.id === "rideshare-map-first");
    assert(rideshare, "rideshare eval case missing");
    const issues = evaluateSlotPlan(
        [{ slotType: "hero_banner" }, { slotType: "stat_group" }, { slotType: "content_list" }],
        rideshare,
    );
    assert(issues.includes("missing expected slot: map_preview"), "missing map must be detected");
    assert(issues.includes("included forbidden slot: stat_group"), "forbidden stats must be detected");
});

Deno.test("rail variant detection has one stable vocabulary", () => {
    assertEqual(detectRailVariantFromText("square album artwork with artist subtitle"), "media_track", "music rail mismatch");
    assertEqual(detectRailVariantFromText("circular creator avatars"), "circular_people", "people rail mismatch");
    assertEqual(detectRailVariantFromText("compact category pills"), "chips", "chip rail mismatch");
    assertEqual(detectRailVariantFromText("wide landscape destinations"), "landscape", "landscape rail mismatch");
    assertEqual(detectRailVariantFromText("tall poster covers"), "poster", "poster rail mismatch");
});

Deno.test("Responses API parser preserves deep structured output and usage", () => {
    const deepJson = JSON.stringify({ component: { type: "ZStack", properties: { alignment: "center" }, modifiers: [], children: [] } });
    const parsed = parseOpenAIResponse({
        id: "resp_deep",
        status: "completed",
        output: [{ content: [{ type: "output_text", text: deepJson }] }],
        usage: { input_tokens: 1200, output_tokens: 840, total_tokens: 2040 },
    });
    assertEqual(parsed.content, deepJson, "deep structured output text mismatch");
    assertEqual(parsed.meta.status, "completed", "response status mismatch");
    assertEqual(parsed.meta.totalTokens, 2040, "usage mismatch");
});

Deno.test("Responses API parser exposes refusal and incomplete reasons", () => {
    const refused = parseOpenAIResponse({
        id: "resp_refused",
        status: "completed",
        output: [{ content: [{ type: "refusal", refusal: "Unable to comply." }] }],
    });
    assertEqual(refused.meta.refusal, "Unable to comply.", "refusal must be preserved");

    const incomplete = parseOpenAIResponse({
        id: "resp_incomplete",
        status: "incomplete",
        incomplete_details: { reason: "max_output_tokens" },
        output: [],
    });
    assertEqual(incomplete.meta.incompleteReason, "max_output_tokens", "incomplete reason must be preserved");
});

Deno.test("accessibility gate catches low contrast and explicit small tap targets", () => {
    const component: AnyComponent = {
        type: "Button",
        properties: { buttonStyle: "plain" },
        modifiers: [{ type: "Frame", properties: { widthType: "Custom", heightType: "Custom", width: 32, height: 32 } }],
        children: [{
            type: "Text",
            properties: { text: "Continue" },
            modifiers: [{ type: "Foreground Color", properties: { color: "gray:0.20" } }],
        }],
    };
    const issues = findAccessibilityViolations(component);
    assert(issues.some((issue) => issue.includes("contrast")), "low contrast must be rejected");
    assert(issues.some((issue) => issue.includes("44pt")), "small tap target must be rejected");
});

Deno.test("postprocess snaps fallback spacing to the approved scale", () => {
    const component: AnyComponent = {
        type: "HStack",
        properties: { spacing: 10, alignment: "center" },
        modifiers: [{ type: "Padding", properties: { amount: 14, location: "all" } }],
        children: [{ type: "Text", properties: { text: "Settings" } }],
    };
    const normalized = postProcessComponents([component])[0];
    assertEqual(normalized.properties.spacing, 12, "10pt stack spacing should snap upward to 12pt");
    assertEqual(normalized.modifiers?.[0]?.properties?.amount, 16, "14pt padding should snap upward to 16pt");
    assertEqual(findSpacingScaleViolations(normalized), [], "normalized output must pass the spacing gate");
});

Deno.test("profile and settings content cannot become sticky top slots", () => {
    assertEqual(normalizeSlotPosition("profile_header", "top"), "body", "profile header belongs in scrolling body content");
    assertEqual(normalizeSlotPosition("settings_list", "top"), "body", "settings list belongs in scrolling body content");
    assertEqual(normalizeSlotPosition("app_header", "body"), "top", "app header remains the only sticky title surface");
});

Deno.test("notification preference prompts compile and validate as grouped controls", () => {
    const prompt = "Build a screen with dark mode and a notification preferences list.";
    const requirement = detectPromptRequirements(prompt).find((item) => item.requirementKey === "settings_toggles");
    assert(requirement != null, "settings requirement must be detected");
    assertEqual(requirement.itemCount, 5, "dark mode plus four notification controls should require five rows");
    assert(requirement.mustInclude.includes("Push Notifications"), "requirement must preserve notification-specific entities");

    const mediocre: AnyComponent = {
        type: "VStack",
        properties: { alignment: "leading", spacing: 8 },
        children: ["Notifications", "Dark Mode", "Sound"].map((label) => ({
            type: "HStack",
            properties: { spacing: 8, alignment: "center" },
            children: [
                { type: "Text", properties: { text: label } },
                { type: "Switch", properties: { isOn: true } },
            ],
        })),
    };
    const issues = validateSlotAgainstPromptRequirements(
        { slotType: "settings_list", position: "body", intent: "notification preferences", itemCount: 5 },
        mediocre,
        [requirement],
    );
    assert(issues.some((issue) => issue.includes("Push Notifications") || issue.includes("push notifications")), "generic notification toggle must fail semantic validation");
    assert(issues.some((issue) => issue.includes("5")), "under-delivered preference count must fail validation");
});

Deno.test("assembly stays inline unless sticky or overlay behavior is explicit", () => {
    const header: AnyComponent = { type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [{ type: "Text", properties: { text: "Settings" } }] };
    const content: AnyComponent = { type: "VStack", properties: { spacing: 8, alignment: "leading" }, children: [{ type: "Text", properties: { text: "Preferences" } }] };
    const slots = [
        { position: "top" as const, slotType: "app_header", component: header },
        { position: "bottom" as const, slotType: "settings_list", component: content },
    ];

    const inline = assembleScreen(slots);
    assertEqual(inline.components[0].type, "VStack", "ordinary screens must not get a root ZStack");
    const sticky = assembleScreen(slots, { stickyTop: true });
    assertEqual(sticky.components[0].type, "ZStack", "explicit sticky headers may use root ZStack");

    assertEqual(buildDesignManifest("Design a settings screen").stickyTopRequested, false, "normal headers are inline");
    assertEqual(buildDesignManifest("Design a settings screen with a pinned header").stickyTopRequested, true, "pinned language enables sticky behavior");
    assertEqual(buildDesignManifest("Design a map with a floating action button").overlayRequested, true, "floating language enables overlay behavior");
});

Deno.test("cross-slot duplicate greetings are removed from later slots", () => {
    const greeting = (): AnyComponent => ({ type: "Text", properties: { text: "Welcome back, Alex" } });
    const slots = removeRepeatedCrossSlotGreetings([
        { position: "top", slotType: "app_header", component: { type: "VStack", properties: { spacing: 8, alignment: "leading" }, children: [greeting()] } },
        { position: "body", slotType: "profile_header", component: { type: "VStack", properties: { spacing: 8, alignment: "leading" }, children: [greeting(), { type: "Text", properties: { text: "Profile" } }] } },
    ]);
    assertEqual(slots[0].component.children?.length, 1, "first greeting remains visible");
    assertEqual(slots[1].component.children?.length, 1, "duplicate greeting is removed from the later slot");
});

Deno.test("semantic surfaces remain adaptive in light and dark mode", () => {
    const theme = buildBaselineTheme({ accentColor: "blue:1.0", surfaceStyle: "utility", density: "regular", fontDesign: "default" });
    const surfaces = computeThemeSurfaces(theme);
    assertEqual(surfaces.cardFill, "secondarySystemBackground:1.0", "cards must use adaptive elevated backgrounds");
    assertEqual(surfaces.rowFill, "tertiarySystemBackground:1.0", "rows must use adaptive nested backgrounds");
    assertEqual(surfaces.subtleFill, "quaternarySystemFill:1.0", "subtle fills must adapt to appearance");

    const legacy: AnyComponent = {
        type: "VStack",
        properties: { alignment: "leading", spacing: 8 },
        modifiers: [{ type: "Background Color", properties: { color: "gray:0.14" } }],
        children: [{
            type: "Text",
            properties: { text: "Adaptive content" },
            modifiers: [{ type: "Foreground Color", properties: { color: "primary:1.0" } }],
        }],
    };
    const normalized = postProcessComponents([legacy])[0];
    assertEqual(normalized.modifiers?.[0]?.properties?.color, "tertiarySystemBackground:1.0", "legacy neutral surfaces should upgrade to semantic tokens");
    assertEqual(findAccessibilityViolations(normalized), [], "semantic text and surfaces must pass contrast in both appearances");
});

Deno.test("backend diagnostics can never become visible UI copy", () => {
    const leaked: AnyComponent = {
        type: "Text",
        properties: { text: "OpenAI request timed out after 14000ms" },
        modifiers: [{ type: "Font", properties: { fontSize: "headline", fontWeight: "bold" } }],
    };
    const issues = detectLowQualitySlotOutput(leaked);
    assert(issues.some((issue) => issue.includes("internal diagnostic")), "raw backend diagnostics must fail slot validation");

    const normalized = postProcessComponents([leaked])[0];
    assertEqual(normalized.properties?.text, "Content unavailable", "final postprocess must sanitize leaked diagnostics");
});

Deno.test("named text color edits are style edits, not screen generation", () => {
    const prompt = "make morning light text orange";
    assertEqual(classifyIntent(prompt), "style", "a named text color request must route through style editing");
    assertEqual(isFullCanvasPrompt(prompt), false, "a targeted text edit must not trigger full-canvas generation");
    assertEqual(classifyIntent("remove shadow from Continue button"), "style", "modifier removal must not become component deletion");
    assertEqual(classifyIntent("delete Continue button"), "structure", "explicit component deletion must remain structural");
});
