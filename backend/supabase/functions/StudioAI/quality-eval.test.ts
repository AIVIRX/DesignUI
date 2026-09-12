import { ARCHETYPE_RESPONSE_FORMAT, SCREEN_IR_RESPONSE_FORMAT, SCREEN_PLAN_RESPONSE_FORMAT, SEMANTIC_INTENT_RESPONSE_FORMAT, SLOT_COMPONENT_RESPONSE_FORMAT, THEME_RESPONSE_FORMAT, UI_COMPONENT_SCHEMA_DEFS, UI_COMPONENT_SCHEMA_TYPES, UI_MODIFIER_SCHEMA_TYPES, VALID_COMPONENT_TYPES, VALID_MODIFIER_TYPES } from "./schema.ts";
import { detectLowQualitySlotOutput, findAccessibilityViolations, findSpacingScaleViolations, postProcessComponents, validateSlotAgainstPromptRequirements } from "./postprocess.ts";
import { evaluateComponentQuality, evaluateSlotPlan, PIPELINE_EVAL_CASES } from "./quality-eval.ts";
import type { AnyComponent } from "./types.ts";
import { detectRailVariantFromText } from "./utils.ts";
import { callOpenAI, parseOpenAIResponse } from "./openai.ts";
import { buildDesignManifest, classifyIntent, detectPromptRequirements, isFullCanvasPrompt } from "./manifest.ts";
import { compileScreenIRToPlan, extractScreenIR, normalizeSlotPosition, parseScreenPlan, refineScreenPlan } from "./planner.ts";
import { enforcePlanRequirements } from "./manifest.ts";
import { compileSlotWithRepair, generateSlotsParallel } from "./slot-generator.ts";
import { validateComponentSchema } from "./validation.ts";
import { walkComponentTree } from "./postprocess.ts";
import { resolveViewport } from "./assembler.ts";
import type { ScreenPlan } from "./types.ts";
import { assembleScreen, removeRepeatedCrossSlotGreetings } from "./assembler.ts";
import { buildBaselineTheme, computeThemeSurfaces } from "./theme.ts";
import { auditScreen, reviewScreen, estimatedHeight, unifyScreenStyle } from "./screen-quality.ts";
import type { ScreenSection } from "./screen-quality.ts";
import { DESIGN_PATTERNS } from "./patterns.ts";

declare const Deno: { test(name: string, body: () => void | Promise<void>): void };
const reviewTheme = () => buildBaselineTheme({ accentColor: "blue:1.0", surfaceStyle: "minimal", density: "regular", fontDesign: "default" });

Deno.test("all reusable patterns use supported editable schema nodes", () => {
    for (const pattern of DESIGN_PATTERNS) assertEqual(validateComponentSchema(pattern.component), [], `${pattern.id} must decode in the editor`);
});

Deno.test("chart V2 permits comparison series and rejects misleading donut data", () => {
    const data = [{ label: "Jan", value: 42, series: "Online" }, { label: "Jan", value: 20, series: "Retail", highlighted: true }];
    assertEqual(validateComponentSchema({ type: "Chart", properties: { chartStyle: "Stacked Bar", dataPoints: JSON.stringify(data) } }), [], "Categories may repeat across series");
    for (const points of [[{ label: "A", value: -1 }], [{ label: "A", value: 0 }], data]) {
        assert(validateComponentSchema({ type: "Chart", properties: { chartStyle: "Donut", dataPoints: JSON.stringify(points) } }).length > 0, "Donuts require positive totals and distinct categories");
    }
});

Deno.test("whole-screen review detects duplication and repairs only the affected section", async () => {
    const first: AnyComponent = { type: "VStack", children: ["Recent projects", "Studio", "Travel"].map((text) => ({ type: "Text", properties: { text } })) };
    const sections: ScreenSection[] = [
        { slot: { slotType: "content_list", position: "body", intent: "Recent projects" }, component: first, exemplarIds: [] },
        { slot: { slotType: "content_list", position: "body", intent: "Upcoming deadlines" }, component: structuredClone(first), exemplarIds: [] },
    ];
    const plan: ScreenPlan = { archetype: "dashboard", slots: sections.map((s) => s.slot) };
    const manifest = buildDesignManifest("Project dashboard with recent projects and upcoming deadlines");
    assert(auditScreen(sections, plan, manifest).some((i) => i.code === "duplicate_section" && i.section === 1), "Catch repeated assembled content");
    const calls: string[] = [];
    const result = await reviewScreen({ sections, plan, manifest, theme: reviewTheme(), deadlineAt: Date.now() + 20000, repair: async (section) => {
        calls.push(section.slot.intent);
        return { ...section, component: { type: "VStack", children: ["Upcoming deadlines", "Review mockups", "Friday"].map((text) => ({ type: "Text", properties: { text } })) } };
    } });
    assertEqual(calls, ["Upcoming deadlines"], "Do not regenerate correct sections");
    assertEqual(result.issues.filter((i) => i.code === "duplicate_section"), [], "Repair must resolve the duplicate");
    assertEqual(result.sections[0].component, first, "Correct section remains unchanged");
});

Deno.test("whole-screen review preserves output when a repair is worse or budget is exhausted", async () => {
    const component: AnyComponent = { type: "VStack", children: ["One", "Two", "Three"].map((text) => ({ type: "Text", properties: { text } })) };
    const slot = { slotType: "content_list" as const, position: "body" as const, intent: "Items" };
    const sections = [{ slot, component, exemplarIds: [] }, { slot, component, exemplarIds: [] }];
    let calls = 0;
    const result = await reviewScreen({ sections, plan: { archetype: "dashboard", slots: [slot, slot] }, manifest: buildDesignManifest("Items"), theme: reviewTheme(), deadlineAt: Date.now(), repair: async (section) => { calls++; return section; } });
    assertEqual(calls, 0, "No work after the deadline");
    assert(result.issues.some((i) => i.code === "duplicate_section"), "Unresolved failures stay visible in quality reports");
});

Deno.test("fold estimates flag buried actions and respect explicit section ordering", () => {
    const sections: ScreenSection[] = [
        { slot: { slotType: "chart_section", position: "body", intent: "Overview" }, component: { type: "Chart", modifiers: [{ type: "Frame", properties: { heightType: "Custom", height: 700 } }] }, exemplarIds: [] },
        { slot: { slotType: "action_bar", position: "body", intent: "Primary continue action" }, component: { type: "Button", children: [{ type: "Text", properties: { text: "Continue" } }] }, exemplarIds: [] },
    ];
    const plan: ScreenPlan = { archetype: "dashboard", viewport: { width: 375, height: 812 }, slots: sections.map((s) => s.slot) };
    assert(auditScreen(sections, plan, buildDesignManifest("Keep the primary action visible without scrolling")).some((i) => i.code === "action_below_fold"), "Flag action beyond the viewport estimate");
    assert(estimatedHeight(sections[0].component) >= 700, "Custom heights must affect the fold");
});

Deno.test("shared styling preserves code typography and circular shapes", () => {
    const component: AnyComponent = { type: "VStack", modifiers: [{ type: "Corner Radius", properties: { radius: 24 } }], children: [{ type: "Text", properties: { text: "code" }, modifiers: [{ type: "Font", properties: { fontDesign: "monospaced" } }] }, { type: "Circle", modifiers: [{ type: "Corner Radius", properties: { radius: 999 } }] }] };
    const result = unifyScreenStyle(component, { ...reviewTheme(), cornerRadiusScale: "sharp", fontDesign: "serif" });
    assertEqual((result.modifiers?.[0].properties as any).radius, 12, "Share ordinary card radius");
    assertEqual((result.children?.[0].modifiers?.[0].properties as any).fontDesign, "monospaced", "Preserve code/data typography");
    assertEqual((result.children?.[1].modifiers?.[0].properties as any).radius, 999, "Preserve circles");
});

const formaPrompt = 'Design a premium iPhone fitness dashboard called Forma. Warm off-white background, charcoal text, lime accents. Include a greeting, weekly activity chart, exactly 3 metrics (steps, calories, active minutes), and a “Full Body Strength” card with “25 min” and a “Start Workout” button. Bottom tabs: Today, Explore, Profile. Generous spacing, clear typography, SF Symbols, no gradients. Keep the main action visible.';

Deno.test("Forma request reserves chart, exact metrics, workout action and bottom navigation", () => {
    const manifest = buildDesignManifest(formaPrompt);
    assertEqual(manifest.requirements.map((r) => r.requirementKey).sort(), ["explicit_chart", "explicit_feature", "explicit_metrics", "explicit_navigation"], "All explicit sections must be recognized");
    const plan: ScreenPlan = { archetype: "tracker", slots: [
        { slotType: "app_header", position: "top", intent: "Greeting" },
        { slotType: "chart_section", position: "body", intent: "Chart with all metrics" },
        { slotType: "stat_group", position: "body", intent: "Metrics" },
        { slotType: "stat_group", position: "body", intent: "Repeated metrics" },
        { slotType: "chart_section", position: "body", intent: "Repeated chart" },
        { slotType: "hero_banner", position: "body", intent: "Another metrics overview" },
    ] };
    const protectedPlan = enforcePlanRequirements(plan, manifest.requirements);
    assertEqual(protectedPlan.slots.filter((s) => s.slotType === "chart_section").length, 1, "Do not generate the same chart twice");
    assertEqual(protectedPlan.slots.filter((s) => s.slotType === "stat_group").length, 1, "One owner of metric summary");
    assertEqual(protectedPlan.slots.find((s) => s.slotType === "stat_group")?.itemCount, 3, "Keep exact metrics count");
    assert(protectedPlan.slots.some((s) => s.slotType === "nav_bar" && s.position === "bottom"), "Reserve pinned navigation");
    assert(protectedPlan.slots.find((s) => s.slotType === "hero_banner")?.intent.includes("Start Workout"), "Protect requested action");
    assertEqual(enforcePlanRequirements(protectedPlan, manifest.requirements), protectedPlan, "Enforcement must be idempotent");
});

Deno.test("requested featured actions and tab labels are checked in generated content", () => {
    const requirements = buildDesignManifest(formaPrompt).requirements;
    const missing: AnyComponent = { type: "VStack", children: [{ type: "Text", properties: { text: "Forma" } }] };
    const feature = requirements.find((r) => r.requirementKey === "explicit_feature")!;
    const errors = validateSlotAgainstPromptRequirements({ slotType: "hero_banner", position: "body", intent: feature.mustInclude }, missing, [feature]);
    assert(errors.some((e) => e.includes("Start Workout".toLowerCase())), "Reject missing requested CTA text");
    assert(errors.some((e) => e.includes("Button")), "Reject absent action control");
    const nav = requirements.find((r) => r.requirementKey === "explicit_navigation")!;
    assert(validateSlotAgainstPromptRequirements({ slotType: "nav_bar", position: "bottom", intent: nav.mustInclude }, missing, [nav]).some((e) => e.includes("explore")), "Reject missing tab labels");
});

Deno.test("chart data validates numeric samples, labels and safe rendering limits", () => {
    const chart = (dataPoints: string, extra = {}): AnyComponent => ({ type: "Chart", properties: { dataPoints, ...extra } });
    assertEqual(validateComponentSchema(chart('[{"label":"Mon","value":42},{"label":"Tue","value":-2}]')), [], "Allow labeled values including negatives");
    for (const data of ['broken', '[]', '[{"label":"Mon","value":"42"}]', '[{"label":"Mon","value":1},{"label":"Mon","value":2}]']) {
        assert(validateComponentSchema(chart(data)).length > 0, "Reject invalid or ambiguous chart data");
    }
    assert(validateComponentSchema(chart('', { pointCount: -1, barWidthRatio: 8 })).length >= 2, "Reject unsafe dimensions");
    assertEqual(validateComponentSchema({ type: "Chart", properties: { chartStyle: "Bar", pointCount: 7 } }), [], "Existing saved charts remain valid");
});

function assert(condition: unknown, message: string): asserts condition {
    if (!condition) throw new Error(message);
}

function assertEqual(actual: unknown, expected: unknown, message: string): void {
    if (JSON.stringify(actual) !== JSON.stringify(expected)) {
        throw new Error(`${message}\nactual=${JSON.stringify(actual)}\nexpected=${JSON.stringify(expected)}`);
    }
}

function inspectStrictObjects(value: unknown, path = "schema"): void {
    if (Array.isArray(value)) { value.forEach((child, i) => inspectStrictObjects(child, `${path}[${i}]`)); return; }
    if (!value || typeof value !== "object") return;
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
    assertEqual(normalized.properties?.spacing, 12, "10pt stack spacing should snap upward to 12pt");
    assertEqual((normalized.modifiers?.[0]?.properties as Record<string, unknown>)?.amount, 16, "14pt padding should snap upward to 16pt");
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
    assertEqual((normalized.modifiers?.[0]?.properties as Record<string, unknown>)?.color, "tertiarySystemBackground:1.0", "legacy neutral surfaces should upgrade to semantic tokens");
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

const testTheme = () => buildBaselineTheme({ accentColor: "blue:1.0", surfaceStyle: "utility", density: "regular", fontDesign: "default" });
const testHeader = (): AnyComponent => ({ type: "VStack", properties: { spacing: 8, alignment: "leading" }, modifiers: [], children: [
    { type: "Text", properties: { text: "Your library" }, modifiers: [] },
    { type: "Text", properties: { text: "Find your next great read" }, modifiers: [] },
] });

Deno.test("simple settings plans do not acquire a hero or filler list", () => {
    const plan: ScreenPlan = { archetype: "settings", slots: [{ slotType: "settings_list", position: "body", intent: "Notification preferences with grouped switches" }] };
    assertEqual(refineScreenPlan(plan).slots, plan.slots, "simple screen should stay focused");
});

Deno.test("refinement preserves both title and search", () => {
    const plan: ScreenPlan = { archetype: "reading", slots: [
        { slotType: "app_header", position: "top", intent: "Your library title" },
        { slotType: "search_bar", position: "top", intent: "Search books by title" },
    ] };
    assertEqual(refineScreenPlan(plan).slots, plan.slots, "title must not disappear when search is present");
});

Deno.test("explicit sections survive the six-slot budget without losing content intent", () => {
    const plan: ScreenPlan = { archetype: "reading", slots: Array.from({ length: 6 }, (_, i) => ({ slotType: "content_list", position: "body", intent: `Optional recommendations ${i}` })) };
    const required = enforcePlanRequirements(plan, [{ slotType: "action_bar", position: "bottom", mustInclude: "Reserve The Left Hand of Darkness", sourceIndex: 0 }]);
    assert(required.slots.some((s) => s.intent.includes("The Left Hand of Darkness")), "explicit content must survive truncation");
    assertEqual(required.slots.length, 6, "plan must stay within budget");
});

Deno.test("one requested item remains one and fractional counts normalize", () => {
    const parsed = parseScreenPlan({ slots: [
        { slotType: "content_list", intent: "One featured book", itemCount: 1 },
        { slotType: "content_grid", intent: "Book recommendations", itemCount: 3.6 },
    ] }, "reading", testTheme());
    assertEqual(parsed.slots.map((s) => s.itemCount), [1, 4], "counts must be bounded integers including one");
});

Deno.test("IR compilation preserves accepted sections without another model call", async () => {
    const original = globalThis.fetch;
    globalThis.fetch = () => { throw new Error("IR must not call a model"); };
    try {
        const plan: ScreenPlan = { archetype: "reading", slots: [{ slotType: "content_list", position: "body", intent: "Three mystery novels by Agatha Christie", itemCount: 3, variant_hint: "book jackets beside titles" }] };
        const ir = await extractScreenIR({ prompt: "Mystery library", theme: testTheme(), plan, semanticIntent: { domain: "general", interactionModel: "browse", primaryGoal: "Choose a novel", entities: [], capabilities: [], preferredSupportSlots: [], avoidSlots: [] } as any });
        const result = compileScreenIRToPlan(ir, plan);
        assertEqual(result.slots[0].intent, plan.slots[0].intent, "specific intent must survive");
        assertEqual(result.slots[0].itemCount, 3, "exact count must survive");
        assert(result.slots[0].variant_hint?.includes("book jackets"), "visual hint must survive");
    } finally { globalThis.fetch = original; }
});

Deno.test("repairs retain the original brief and enough output tokens", async () => {
    const original = globalThis.fetch;
    const requests: any[] = [];
    globalThis.fetch = async (_url, init) => {
        requests.push(JSON.parse(String(init?.body)));
        const component = requests.length === 1 ? { type: "UnsupportedCard", properties: {}, modifiers: [] } : testHeader();
        return Response.json({ status: "completed", output_text: JSON.stringify({ component }) });
    };
    try {
        const result = await compileSlotWithRepair({ messages: [{ role: "system", content: "Preserve the reader's personal library theme" }, { role: "user", content: "Create Your library" }], slot: { slotType: "app_header", position: "top", intent: "Library title and subtitle" }, maxAttempts: 2, firstPassMaxTokens: 4200 });
        assert(result.ok, "second valid component should be accepted");
        assert(requests[1].instructions.includes("personal library"), "repair lost design context");
        assert(requests[1].max_output_tokens >= requests[0].max_output_tokens, "repair must not truncate a previously complete tree");
    } finally { globalThis.fetch = original; }
});

Deno.test("expired slot budgets never start new network requests", async () => {
    const original = globalThis.fetch;
    let calls = 0;
    globalThis.fetch = async () => { calls++; throw new Error("unexpected request"); };
    try {
        const result = await compileSlotWithRepair({ messages: [], slot: { slotType: "app_header", position: "top", intent: "Library" }, maxAttempts: 3, deadlineAt: Date.now() - 1 });
        assert(!result.ok, "expired request should fail promptly");
        assertEqual(calls, 0, "no retries after deadline");
    } finally { globalThis.fetch = original; }
});

Deno.test("OpenAI timeout covers a stalled response body", async () => {
    const original = globalThis.fetch;
    globalThis.fetch = async (_url, init) => new Response(new ReadableStream({ start(controller) {
        init?.signal?.addEventListener("abort", () => controller.error(new Error("aborted")), { once: true });
    } }));
    try {
        const result = await callOpenAI({ model: "gpt-5.4", messages: [], temperature: 0, timeoutMs: 10 });
        assert(!result.ok && result.error.includes("timed out"), "body must be covered by abort timer");
    } finally { globalThis.fetch = original; }
});

Deno.test("schema validation rejects unknown types, invalid frames and control ranges", () => {
    assert(validateComponentSchema({ type: "ImaginaryCard", properties: {} }).length > 0, "unknown type must not silently become Text");
    assert(validateComponentSchema({ type: "Slider", properties: { value: 5, min: 10, max: 1 } }).some((i) => i.includes("range")), "invalid range must fail");
    assert(validateComponentSchema({ type: "Text", properties: { text: "Book" }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: null, heightType: "Default" } }] }).some((i) => i.includes("dimension")), "custom frame needs a real dimension");
    assertEqual(validateComponentSchema(testHeader()), [], "native header should pass");
});

Deno.test("quality traversal counts modifier content once after normalization", () => {
    const tree: AnyComponent = { type: "VStack", properties: {}, children: [testHeader()], modifiers: [{ type: "Overlay", properties: {}, children: [{ type: "Text", properties: { text: "New" }, modifiers: [] }] }] };
    const normalized = postProcessComponents([tree])[0];
    let count = 0;
    walkComponentTree(normalized, (node) => { if (node.type === "Text") count++; });
    assertEqual(count, 3, "modifier bridge content must not inflate text counts");
    assertEqual(postProcessComponents([normalized]), [normalized], "normalization must be idempotent");
});

Deno.test("contrast follows inherited color and body text thresholds", () => {
    const tree: AnyComponent = { type: "VStack", properties: {}, modifiers: [{ type: "Foreground Color", properties: { color: "white:1.0" } }], children: [{ type: "Text", properties: { text: "Unreadable on white" } }] };
    assert(findAccessibilityViolations(tree, "light").some((i) => i.includes("4.5:1")), "inherited body color needs 4.5:1");
    assertEqual(findAccessibilityViolations(tree, "dark"), [], "fixed dark screens must not fail light-mode checks");
});

Deno.test("viewport uses canvas dimensions and rejects malformed values", () => {
    assertEqual(resolveViewport({ canvasWidth: 1024, canvasHeight: 1366 }), { width: 1024, height: 1366 }, "tablet dimensions lost");
    assertEqual(resolveViewport({ canvasWidth: -1, canvasHeight: Infinity }), { width: 390, height: 844 }, "invalid dimensions need safe defaults");
});

Deno.test("all six sections start together instead of starving later batches", async () => {
    const original = globalThis.fetch;
    let active = 0;
    let peak = 0;
    globalThis.fetch = async () => {
        active++;
        peak = Math.max(peak, active);
        await new Promise((resolve) => setTimeout(resolve, 5));
        active--;
        return Response.json({ status: "completed", output_text: JSON.stringify({ component: testHeader() }) });
    };
    try {
        const plan: ScreenPlan = { archetype: "reading", slots: Array.from({ length: 6 }, (_, i) => ({ slotType: "app_header", position: "top", intent: `Library section ${i}` })) };
        const theme = testTheme();
        const manifest = buildDesignManifest("Library");
        const { compilePromptDesignSpec } = await import("./manifest.ts");
        const results = await generateSlotsParallel({ supabase: null, prompt: "Library", theme, plan, plannedSlots: plan.slots, manifest, designSpec: compilePromptDesignSpec("Library", manifest), deadlineAt: Date.now() + 2000, withDeadline: (work) => work, surfaces: computeThemeSurfaces(theme) });
        assertEqual(peak, 6, "every section must receive the initial rendering window");
        assertEqual(results.length, 6, "each planned section must return a result");
        assert(results.every((r) => r.component.children?.[0].properties?.text === "Your library"), "every section should use generated content");
    } finally { globalThis.fetch = original; }
});
