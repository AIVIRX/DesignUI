import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { AnyComponent, DesignManifest, Exemplar, GenerationMode, LayoutSketch, LayoutSketchNode, PromptDesignSpec, PromptRequirement, RailVariant, ScreenPlan, SketchPrimitive, SlotMemory, SlotPlan, SlotPosition, SlotType, ThemeSurfaces, ThemeTokens, VoiceTone } from "./types.ts";
import { EMBEDDING_MODEL, EMBEDDING_TIMEOUT_MS, FULL_CANVAS_SLOT_BATCH_SIZE, FULL_CANVAS_SLOT_DESIGN_PASSES, FULL_CANVAS_SLOT_GENERATION_MAX_ATTEMPTS, FULL_CANVAS_SLOT_GENERATOR_MAX_TOKENS, GEN_V3_SKETCH_RENDER, MAX_GENERATION_SLOTS, REPAIR_MAX_TOKENS, REPAIR_MODEL, SELECTION_MAX_TOKENS, SELECTION_MODEL, SLOT_BATCH_GRACE_MS, SLOT_BATCH_SIZE, SLOT_DESIGN_PASSES, SLOT_GENERATION_MAX_ATTEMPTS, SLOT_GENERATOR_MAX_TOKENS, SLOT_GENERATOR_MODEL, callOpenAI, openaiApiKey } from "./openai.ts";
import type { OpenAIResponseMeta } from "./openai.ts";
import { SLOT_COMPONENT_RESPONSE_FORMAT, SLOT_CONSTRAINTS, VALID_COMPONENT_TYPES } from "./schema.ts";
import { buildDesignManifest, compilePromptDesignSpec, formatPromptDesignSpec } from "./manifest.ts";
import { detectRailVariantFromText, isJsonParseError, isObject, parseJsonSafe, sanitizeInternalDisplayText } from "./utils.ts";
import { analyzeRailItem, computeMorphologySignature, countListLikeItems, detectLowQualitySlotOutput, estimateGridCardCount, findAccessibilityViolations, findHorizontalRailItems, detectRailVariantFromRequirement, inferRailVariantFromComponent, postProcessComponents, scoreRailItemForVariant, selectPromptRequirementsForSlot, slotHasBlurTreatment, slotHasCircularGauge, validateExactCountForSlot, validateRailStructure, validateSlotAgainstPromptRequirements, validateSlotConstraints, validateStrictIntentLocksForSlot, walkComponentTree } from "./postprocess.ts";

// ─── Slot Generator ──────────────────────────────────────────────────────────

// Condensed schema for slot generation — much shorter than full SCHEMA_RULES.
// Only includes the rules the generator actually needs (full rules are for editing).
export const SLOT_SCHEMA_COMPACT = `CONTAINERS(must have children[]): VStack HStack ZStack ScrollView Button
LEAVES(no children): Text Image "SF Symbol" Spacer Divider Rectangle Circle RoundedRectangle Capsule Ellipse "Linear Gradient" "Text Field" Switch Slider "Progress View" Gauge Chart Map
Text:{text:string} "SF Symbol":{symbolName:string} "Text Field":{text?:string,placeholder?:string} VStack:{alignment:"leading"|"center"|"trailing",spacing:num} HStack:{alignment:"top"|"center"|"bottom",spacing:num} ZStack:{alignment:"center"|"topLeading"|"bottomTrailing"...} Button:{buttonStyle:"plain"|"bordered"|"borderedProminent"} ScrollView:{axis:"vertical"|"horizontal",showsIndicators:bool} RoundedRectangle:{cornerRadius:num} "Progress View":{value:num,total:num,color:string} Gauge:{value:num,min:num,max:num,gaugeType:"linear"|"circular"|"circular range",showValue:bool,color:string} Map:{latitude:num,longitude:num,latitudeDelta?:num,longitudeDelta?:num,mapStyle?:"standard"|"imagery"|"hybrid",interactionModes?:"all"|"none"|"pan"|"zoom"|"rotate"|"pitch"|"pan+zoom"|"pan+zoom+rotate"|"pan+zoom+rotate+pitch",showsCompass?:bool,showsScale?:bool,showsPitchToggle?:bool,showsUserLocation?:bool,showsUserLocationButton?:bool,showsTraffic?:bool,locationName?:string,markers?:string}
MODIFIERS: Frame Padding "Background Color" "Foreground Color" Font "Corner Radius" Shadow Opacity Stroke Fill "Clip Shape" "Text Alignment" Tint "Glass Effect"
Font:{fontSize:"largeTitle"|"title"|"title2"|"title3"|"headline"|"body"|"callout"|"subheadline"|"footnote"|"caption"|"caption2",fontWeight:"bold"|"semibold"|"medium"|"regular"|"light",fontDesign?:string}
Frame:{widthType:"Custom"|"Default"|"Full",heightType:"Custom"|"Default"|"Full",width?:num,height?:num}
Padding:{amount:num,location:"all"|"horizontal"|"vertical"}
Colors: use adaptive semantic tokens for neutral UI: primary secondary tertiary quaternary systemBackground secondarySystemBackground tertiarySystemBackground systemFill secondarySystemFill tertiarySystemFill quaternarySystemFill. Reserve "colorname:opacity" literals for accents only.
RULES: Cards/rows must use semantic background/fill tokens, never low-opacity gray/white/black literals. Shapes use "Fill" not "Background Color". Corner Radius present → use "Stroke" not "Border". Button with bg-colored label → buttonStyle:"plain". SF Symbol names must be real. For circular progress/rings, prefer Gauge with gaugeType:"circular". Use "Glass Effect" for translucent overlay chips/cards/controls when the screen sits on top of imagery, maps, or immersive surfaces. Glass Effect supports optional tint via properties like { tint:"blue:0.18" }. IMPORTANT: when using "Glass Effect", do NOT also add "Fill" or "Background Color" on that same glass surface. For maps, prefer a real Map component with tuned camera span, markers, interaction modes, and controls instead of faking a map with plain shapes. SPACING SCALE: use only 4, 8, 12, 16, 24, 32 for VStack/HStack spacing and Padding amounts unless a very special layout truly requires 0. Avoid random values like 5, 7, 10, 14, 18, 20, 22.`;

export function chooseRailVariant(slot: SlotPlan, slotPromptRequirements: PromptRequirement[]): RailVariant {
    for (const req of slotPromptRequirements) {
        if (req.railSpec?.variant) return req.railSpec.variant;
        const fromMust = detectRailVariantFromText(req.mustInclude);
        if (fromMust) return fromMust;
        const fromHint = detectRailVariantFromText(req.variantHint ?? "");
        if (fromHint) return fromHint;
    }

    const fromIntent = detectRailVariantFromText(slot.intent);
    if (fromIntent) return fromIntent;
    const fromSlotHint = detectRailVariantFromText(slot.variant_hint ?? "");
    if (fromSlotHint) return fromSlotHint;
    return "poster";
}

export function promptLikelyDetailScreen(prompt: string): boolean {
    const p = prompt.toLowerCase();
    return /\bdetail\b|\bdrill\b|\binner\b|\bsubpage\b|\bthread\b|\bconversation\b|\bprofile detail\b|\bbooking detail\b/.test(p);
}

export function promptLikelyRootScreen(prompt: string): boolean {
    const p = prompt.toLowerCase();
    return /\bhome\b|\bmain\b|\bdashboard\b|\bfeed\b|\blanding\b|\bstart\b|\broot\b/.test(p);
}

export function buildRailVariantGuide(slot: SlotPlan, slotPromptRequirements: PromptRequirement[]): string {
    if (slot.slotType !== "horizontal_rail") return "";
    const selected = chooseRailVariant(slot, slotPromptRequirements);
    const selectedSpec = slotPromptRequirements.find((r) => r.railSpec)?.railSpec;
    const byVariant: Record<RailVariant, string> = {
        poster: `RAIL VARIANT: poster cards
- Item structure: poster/cover visual on top, title text below.
- Typical morphology: RoundedRectangle thumbnail + short title.
- Focus: bold visual-first rail.`,
        media_track: `RAIL VARIANT: media track cards
- Item structure: square artwork at top, .primary title directly under, .secondary artist/subtitle under that.
- Typical morphology: RoundedRectangle (square artwork) + 2 text rows below.
- Keep subtitle lighter using secondary color or lower opacity.`,
        circular_people: `RAIL VARIANT: circular people/artists
- Item structure: circular avatar/art visual, label below.
- Typical morphology: Circle image/avatar + centered text below.
- Keep cards compact and repetitive rhythm clean.
- If this is an Instagram-style home screen, label the section as Stories and use cafe/shop names, not Artists.`,
        chips: `RAIL VARIANT: pill chips
- Item structure: compact pill/capsule item, short label, optional icon.
- Typical morphology: Capsule or rounded chip surfaces with tight spacing.`,
        landscape: `RAIL VARIANT: wide landscape cards
- Item structure: wide thumbnail with text overlay or text below.
- Typical morphology: wide RoundedRectangle cards, lower height, more cinematic feel.`,
    };
    const specLine = selectedSpec
        ? `\nRAIL SPEC: variant=${selectedSpec.variant} shape=${selectedSpec.itemShape} textRows=${selectedSpec.textRows}`
        : "";
    return `${byVariant[selected]}${specLine}`;
}

export function buildSlotGeneratorSystemPrompt(
    theme: ThemeTokens,
    slot: SlotPlan,
    allSlots: SlotPlan[],
    slotPromptRequirements: PromptRequirement[],
    designSpec?: PromptDesignSpec,
    rawPrompt?: string,
    memory?: SlotMemory,
): string {
    const constraint = SLOT_CONSTRAINTS[slot.slotType];
    const accentBase = theme.accentColor.split(":")[0];

    const radiusMap = { pill: "cards:22 rows:18 icons:999 cta:999", sharp: "cards:12 rows:12 icons:6 cta:12", medium: "cards:16 rows:12 icons:10 cta:10" };
    const spacingMap = { compact: "4/8/12/16", regular: "4/8/12/16/24/32", airy: "4/8/12/16/24/32" };
    const paletteMap: Record<string, string> = {
        immersive: `card:"secondarySystemFill:1.0" row:"tertiarySystemFill:1.0" text2:"secondary:1.0"`,
        calm: `card:"secondarySystemBackground:1.0" row:"tertiarySystemBackground:1.0" text2:"secondary:1.0"`,
        minimal: `card:"secondarySystemBackground:1.0" row:"tertiarySystemBackground:1.0" text2:"secondary:1.0"`,
        editorial: `card:"secondarySystemBackground:1.0" row:"tertiarySystemBackground:1.0" text2:"secondary:1.0"`,
        utility: `card:"secondarySystemBackground:1.0" row:"tertiarySystemBackground:1.0" text2:"secondary:1.0"`,
    };

    const contextSlots = allSlots.filter((s) => s !== slot).map((s) => s.slotType).join(", ");
    const railVariantGuide = buildRailVariantGuide(slot, slotPromptRequirements);
    const selectedRailVariant = slot.slotType === "horizontal_rail" ? chooseRailVariant(slot, slotPromptRequirements) : null;
    const likelyDetail = promptLikelyDetailScreen(slot.intent);
    const likelyRoot = promptLikelyRootScreen(slot.intent);
    const promptLower = (rawPrompt || "").toLowerCase();
    const slotIntentLower = (slot.intent || "").toLowerCase();
    const shouldPreferGlassOverlay = designSpec?.style.preferGlass
        || theme.surfaceStyle === "immersive"
        || slot.position === "overlay"
        || slot.slotType === "floating_card"
        || slot.slotType === "fab_button"
        || slot.slotType === "map_preview"
        || /\b(map|route|rideshare|ride share|transport|driver|pickup|destination|immersive|glass|overlay)\b/.test(`${promptLower} ${slotIntentLower}`);
    const searchBarPlacementRule = slot.slotType === "search_bar"
        ? "Search bars are standalone top-of-content slots. Render them inline at the top of the scrolling content as a single full-width row. Do not make them floating overlays, detached map chrome, or separate utility bubbles."
        : "";
    const promptContext = rawPrompt ? `
USER'S ORIGINAL REQUEST: "${rawPrompt}"
Your component must feel like a direct response to these specific words.
If the user used unusual or specific language, reflect it in content choices and visual design.
` : "";
    const memoryContext = formatSlotMemory(memory);

    const locksText = slotPromptRequirements.length > 0
        ? slotPromptRequirements.map((r) => `${r.slotType}:${r.mustInclude}${r.variantHint ? ` [${r.variantHint}]` : ""}`).join(" | ")
        : "none";

    return `Return JSON only: {"component":<UIComponent>}. No markdown.

LAYER 1 — IDENTITY
${promptContext}
${memoryContext}
You are designing the "${slot.slotType}" section for "${theme.appName}".
Section role: ${constraint.description}
Intent: ${slot.intent}
${slot.itemCount ? `Items target: ${slot.itemCount}` : ""}
${slot.variant_hint ? `Creative hint: ${slot.variant_hint}` : ""}

LAYER 2 — VISUAL BRIEF
Theme: tone=${theme.voiceTone} surface=${theme.surfaceStyle} density=${theme.density} accent=${theme.accentColor} radius=${theme.cornerRadiusScale}(${radiusMap[theme.cornerRadiusScale]}) spacing=${spacingMap[theme.density]} font=${theme.fontDesign}
Palette hints: ${paletteMap[theme.surfaceStyle] || paletteMap.utility}
${theme.mascotSymbol ? `Mascot symbol: ${theme.mascotSymbol}` : ""}
Other slots in screen: ${contextSlots || "none"} (avoid repetition)
${railVariantGuide ? `\n${railVariantGuide}` : ""}

Design principles (priority order):
1) Clear visual hierarchy with one focal element.
2) Real content from provided data; never placeholder copy.
3) Use a disciplined spacing scale. Preferred values are 4/8/12/16/24/32. You may use 0 only when layers must visually lock together.
4) Component variety; avoid repeated identical row/card structures.
5) Prefer a single strong visual idea over multiple weak filler sections.

Spacing rules:
- VStack/HStack spacing and Padding amounts should come from this scale: 4, 8, 12, 16, 24, 32.
- Match density by choosing fewer/lower steps for compact screens and more breathing room for airy screens.
- Do not invent in-between values like 6, 10, 14, 18, 20, or 22 unless a hard visual reason truly demands it.
- Keep sibling surfaces on the same cadence so the screen feels intentional and uniform.

LAYER 3 — CONTENT DATA
FACTS: greeting="${theme.sharedFacts.greeting}" user="${theme.sharedFacts.userName}" metric1="${theme.sharedFacts.primaryMetricValue}" metric2="${theme.sharedFacts.secondaryMetricValue}" streak="${theme.sharedFacts.streakValue}" progress=${theme.sharedFacts.progressPercent}% date="${theme.sharedFacts.todayDate}"
ITEMS: ${JSON.stringify(theme.sampleItems)}
METRICS: ${JSON.stringify(theme.sampleMetrics)}
RAIL: ${JSON.stringify(theme.sampleRailItems)}
CTA: "${theme.ctaText}" NOUN: "${theme.itemNoun}"

LAYER 4 — HARD CONSTRAINTS
Root type must be one of: [${constraint.allowedRoots.join("|")}]
Max depth: ${constraint.maxDepth}
${constraint.fullWidth ? 'Root frame requirement: {widthType:"Full",heightType:"Default"}' : ""}
${constraint.requiredTextCount ? `Minimum text nodes: ${constraint.requiredTextCount}` : ""}
Prompt locks for this section: ${locksText}
${designSpec ? `Prompt DSL spec: ${formatPromptDesignSpec(designSpec)}` : ""}

Critical rules:
- Never render planning/spec language as UI text.
- Use real SF Symbol names only.
- Use Gauge for circular progress/rings; do not fake rings with layered full-stroke circles.
- ${selectedRailVariant === "media_track"
            ? "Media-track rail is mandatory: each rail item must be square artwork + primary title + secondary artist/subtitle."
            : "If a rail variant is specified, honor its morphology exactly."}
- App header rule: back chevron only for detail/drill-in screens (likelyDetail=${likelyDetail}, likelyRoot=${likelyRoot}).
- Do not invent toolbar buttons or utility chrome. No top-right ellipsis/profile/menu buttons and no extra mic/filter/clear controls in search bars unless the user explicitly asks for them.
- ${shouldPreferGlassOverlay
            ? "This section should prefer Glass Effect on compact overlay surfaces like floating chips, map controls, top utility buttons, and translucent CTA trays instead of defaulting to flat gray pills. If colored glass helps, use Glass Effect tint instead of Fill or Background Color. Glass surfaces must not also have Fill or Background Color on the same node."
            : "Use Glass Effect only when it helps an overlay/surface feel intentionally translucent; do not add it to every card by default. If you want colored glass, use the Glass Effect tint property, and never combine Glass Effect with Fill or Background Color on the same node."}
- ${searchBarPlacementRule || "Keep the section in normal content flow unless the slot itself is explicitly an overlay control."}

LAYER 5 — OUTPUT SCHEMA
${SLOT_SCHEMA_COMPACT}`;
}

export function buildExemplarsBlock(exemplars: Exemplar[]): string {
    if (exemplars.length === 0) return "";
    const shown = exemplars.map((e) => ({
        description: e.description,
        slot_type: e.slot_type,
        component_tree: e.component_tree,
    }));
    return `EXEMPLARS (reference for quality and tone — do NOT copy layout. Create something NEW):
${JSON.stringify(shown, null, 1)}`;
}

export async function generateSlot(params: {
    supabase: SupabaseClient | null;
    prompt: string;
    theme: ThemeTokens;
    plan: ScreenPlan;
    slot: SlotPlan;
    manifest?: DesignManifest;
    designSpec?: PromptDesignSpec;
    memory?: SlotMemory;
    blockers?: string[];
    generationMode?: GenerationMode;
}): Promise<{ component: AnyComponent; exemplarIds: string[] }> {
    const { prompt, theme, plan, slot } = params;
    const manifest = params.manifest ?? buildDesignManifest(prompt);
    const designSpec = params.designSpec ?? compilePromptDesignSpec(prompt, manifest);
    const slotPromptRequirements = selectPromptRequirementsForSlot(slot, manifest.requirements);
    const hardRulesBlock = manifest.hardRules.length > 0 ? manifest.hardRules.join(" | ") : "none";

    const requirementText = slotPromptRequirements.map((r) => `${r.mustInclude} ${r.variantHint ?? ""}`.trim()).join(" | ");
    const nativePatternHint = designSpec?.style.nativePattern ?? "none";
    const queryText = `${prompt} | pattern:${nativePatternHint} | ${theme.voiceTone} ${theme.surfaceStyle} ${theme.domainTags.join(" ")} | slot:${slot.slotType} intent:${slot.intent} | req:${requirementText} | rules:${hardRulesBlock}`;

    // Only attempt retrieval if we have a DB connection — skip the embedding
    // call entirely on cold starts to save ~400ms per slot.
    const exemplars: Exemplar[] = await retrieveSlotExemplars({
        supabase: params.supabase,
        slotType: slot.slotType,
        voiceTone: theme.voiceTone,
        domainTags: theme.domainTags,
        queryText,
        k: designSpec?.strictOneToOne ? 3 : 2,
    });

    const systemPrompt = buildSlotGeneratorSystemPrompt(theme, slot, plan.slots, slotPromptRequirements, designSpec, prompt, params.memory);
    let critiqueGuidance = "";
    let lastHardIssues: string[] = [];
    const isFullCanvas = params.generationMode === "full_canvas";
    const designPasses = isFullCanvas ? FULL_CANVAS_SLOT_DESIGN_PASSES : SLOT_DESIGN_PASSES;
    const firstPassTemperature = isFullCanvas ? 0.58 : 0.5;
    const firstPassMaxTokens = isFullCanvas ? FULL_CANVAS_SLOT_GENERATOR_MAX_TOKENS : SLOT_GENERATOR_MAX_TOKENS;
    const generationMaxAttempts = isFullCanvas ? FULL_CANVAS_SLOT_GENERATION_MAX_ATTEMPTS : SLOT_GENERATION_MAX_ATTEMPTS;

    for (let designPass = 0; designPass < designPasses; designPass++) {
        const messages: Array<Record<string, unknown>> = [
            { role: "system", content: systemPrompt },
            ...(exemplars.length > 0 ? [{ role: "system", content: buildExemplarsBlock(exemplars) }] : []),
            { role: "system", content: `DESIGN MANIFEST HARD RULES: ${hardRulesBlock}` },
            ...(critiqueGuidance
                ? [{
                    role: "system",
                    content: `REVISION FEEDBACK (must honor while preserving schema validity):
${critiqueGuidance}
Keep the same slot intent, but improve visual hierarchy/composition/contrast/spacing.`,
                }]
                : []),
            ...((params.blockers && params.blockers.length > 0) ? [{ role: "system", content: `STRICT FIX REQUIRED BEFORE ACCEPTANCE:
- ${params.blockers.join("\n- ")}` }] : []),
            { role: "user", content: `Generate the ${slot.slotType} component for: ${prompt}` },
        ];

        const result = await compileSlotWithRepair({
            messages,
            slot,
            maxAttempts: generationMaxAttempts,
            firstPassTemperature,
            firstPassMaxTokens,
        });
        if (result.ok === false) continue;

        const hardIssues = validateSlotAgainstPromptRequirements(slot, result.component, slotPromptRequirements);
        if (hardIssues.length > 0) {
            lastHardIssues = hardIssues;
            critiqueGuidance = `HARD CONSTRAINT VIOLATIONS:\n- ${hardIssues.join("\n- ")}\nYou must satisfy every hard requirement from the prompt exactly.`;
            continue;
        }

        return { component: result.component, exemplarIds: exemplars.map((e) => e.id) };
    }

    // Ultimate fallback: minimal placeholder
    if (lastHardIssues.length > 0) {
        console.warn(`Falling back ${slot.slotType} due to unresolved hard issues: ${lastHardIssues.join(" | ")}`);
    }
    return {
        component: buildFallbackSlot(slot, theme, params.designSpec),
        exemplarIds: [],
    };
}

export async function compileSlotWithRepair(params: {
    messages: Array<Record<string, unknown>>;
    slot: SlotPlan;
    maxAttempts: number;
    firstPassTemperature?: number;
    firstPassMaxTokens?: number;
    repairMaxTokens?: number;
}): Promise<{ ok: true; component: AnyComponent } | { ok: false; error: string }> {
    const constraint = SLOT_CONSTRAINTS[params.slot.slotType];
    let lastError = "";
    let lastContent = "";
    let repairError = "";
    let repairAttempts = 0;

    for (let attempt = 0; attempt < params.maxAttempts; attempt++) {
        // A transport failure has no JSON to repair. Retry the original request
        // instead of exposing its diagnostic string to the model as UI context.
        const isRepair = lastContent.trim().length > 0;
        if (isRepair) repairAttempts += 1;
        const messages = !isRepair ? params.messages : [
            { role: "system", content: buildRepairPrompt(params.slot, repairError ? repairError.split("\n").filter(Boolean) : ["Fix schema and slot validation errors"]) },
            { role: "user", content: `Previous JSON:\n${lastContent}\n\nValidation errors:\n${repairError}\n\nFix ALL errors and return corrected JSON: { "component": <UIComponent> }` },
        ];

        const response = await callOpenAI({
            model: isRepair ? REPAIR_MODEL : SLOT_GENERATOR_MODEL,
            messages,
            temperature: isRepair ? 0 : (params.firstPassTemperature ?? 0.5),
            maxTokens: isRepair ? (params.repairMaxTokens ?? REPAIR_MAX_TOKENS) : (params.firstPassMaxTokens ?? SLOT_GENERATOR_MAX_TOKENS),
            responseFormat: SLOT_COMPONENT_RESPONSE_FORMAT,
        });

        if (!response.ok) {
            lastError = response.error;
            const meta = "meta" in response ? response.meta as OpenAIResponseMeta : null;
            console.warn(JSON.stringify({
                event: "slot_attempt_failed",
                slot_type: params.slot.slotType,
                attempt: attempt + 1,
                is_repair: isRepair,
                error: response.error.slice(0, 500),
                response_id: meta?.responseId ?? null,
                response_status: meta?.status ?? null,
                incomplete_reason: meta?.incompleteReason ?? null,
                refused: Boolean(meta?.refusal),
                output_tokens: meta?.outputTokens ?? null,
            }));
            continue;
        }
        lastContent = response.content;

        const parsed = parseJsonSafe(response.content);
        if (isJsonParseError(parsed)) { lastError = parsed.error; repairError = parsed.error; continue; }
        if (!isObject(parsed.value)) { lastError = "Response is not an object"; repairError = lastError; continue; }

        const result = parsed.value as Record<string, unknown>;
        const raw = result.component ?? (Array.isArray(result.components) ? result.components[0] : null);
        if (!isObject(raw)) { lastError = "Missing 'component' key in response"; repairError = lastError; continue; }

        // Run cheap repair + post-processing
        const { component: cheapFixed, issues } = cheapRepair(raw as AnyComponent);
        const diagnosticIssues = detectLowQualitySlotOutput(cheapFixed).filter((issue) => issue.includes("internal diagnostic"));
        if (diagnosticIssues.length > 0) {
            lastError = `Internal diagnostics rejected:\n${diagnosticIssues.join("\n")}`;
            repairError = "Replace backend diagnostics with real, user-facing product copy that satisfies the original slot intent.";
            continue;
        }
        const fixed = postProcessComponents([cheapFixed])[0];

        // Validate against slot constraints
        const validation = validateSlotConstraints(fixed, constraint);
        if (!validation.valid) {
            lastError = `Slot constraint violations:\n${validation.issues.join("\n")}`;
            repairError = lastError;
            continue;
        }

        const qualityIssues = detectLowQualitySlotOutput(fixed);
        if (qualityIssues.length > 0) {
            lastError = `Low-quality output rejected:\n${qualityIssues.join("\n")}`;
            repairError = lastError;
            continue;
        }

        const accessibilityIssues = findAccessibilityViolations(fixed);
        if (accessibilityIssues.length > 0) {
            lastError = `Accessibility violations:\n${accessibilityIssues.join("\n")}`;
            repairError = lastError;
            continue;
        }

        console.info(JSON.stringify({
            event: "slot_compile",
            slot_type: params.slot.slotType,
            outcome: "accepted",
            attempts: attempt + 1,
            repair_attempts: repairAttempts,
            first_pass_accepted: attempt === 0 && !isRepair,
            response_id: response.meta.responseId,
            response_status: response.meta.status,
            input_tokens: response.meta.inputTokens,
            output_tokens: response.meta.outputTokens,
        }));
        return { ok: true, component: fixed };
    }

    console.warn(JSON.stringify({
        event: "slot_compile",
        slot_type: params.slot.slotType,
        outcome: "rejected",
        attempts: params.maxAttempts,
        repair_attempts: repairAttempts,
        first_pass_accepted: false,
        error: lastError.slice(0, 500),
    }));
    return { ok: false, error: `Failed after ${params.maxAttempts} attempts: ${lastError}` };
}


// ─── Fallback slot builder (for when generation totally fails) ───────────────
// These produce REAL UI — they're the floor, not a placeholder.
// They use theme tokens to stay consistent with the generated slots.

export function buildFallbackSlot(slot: SlotPlan, theme: ThemeTokens, designSpec?: PromptDesignSpec): AnyComponent {
    slot = {
        ...slot,
        intent: sanitizeInternalDisplayText(slot.intent || "", `Show relevant ${theme.itemNoun} content`),
    };
    const ab = theme.accentColor.split(":")[0];
    const sb = theme.secondaryColor.split(":")[0];
    const r = theme.cornerRadiusScale === "pill" ? 22 : theme.cornerRadiusScale === "sharp" ? 12 : 16;
    const rSmall = theme.cornerRadiusScale === "pill" ? 18 : theme.cornerRadiusScale === "sharp" ? 12 : 12;
    const rIcon = theme.cornerRadiusScale === "pill" ? 999 : theme.cornerRadiusScale === "sharp" ? 6 : 10;
    const pad = theme.density === "compact" ? 12 : theme.density === "airy" ? 20 : 16;
    const sp = theme.density === "compact" ? 8 : theme.density === "airy" ? 16 : 12;
    const cardBg = theme.surfaceStyle === "immersive" ? "secondarySystemFill:1.0" : "secondarySystemBackground:1.0";
    const rowBg = theme.surfaceStyle === "immersive" ? "tertiarySystemFill:1.0" : "tertiarySystemBackground:1.0";

    const mkText = (text: string, size: string, weight: string, color?: string): AnyComponent => {
        const m: Array<Record<string, unknown>> = [{ type: "Font", properties: { fontSize: size, fontWeight: weight } }];
        if (color) m.push({ type: "Foreground Color", properties: { color } });
        return { type: "Text", properties: { text }, modifiers: m };
    };
    const mkSym = (name: string, color?: string, size = "body", weight = "semibold"): AnyComponent => {
        const m: Array<Record<string, unknown>> = [{ type: "Font", properties: { fontSize: size, fontWeight: weight } }];
        if (color) m.push({ type: "Foreground Color", properties: { color } });
        return { type: "SF Symbol", properties: { symbolName: name }, modifiers: m };
    };
    const mkIconCircle = (sym: string, bg: string, fg: string, size = 38): AnyComponent => ({
        type: "ZStack", children: [
            {
                type: "Circle", properties: {}, modifiers: [
                    { type: "Frame", properties: { widthType: "Custom", width: size, heightType: "Custom", height: size } },
                    { type: "Fill", properties: { color: bg } },
                ]
            },
            mkSym(sym, fg, size > 36 ? "caption" : "caption2", "semibold"),
        ],
    });
    const fullW = { type: "Frame", properties: { widthType: "Full", heightType: "Default" } };
    const padAll = { type: "Padding", properties: { amount: pad, location: "all" } };

    // Parse theme seeds into structured data
    const metrics = theme.sampleMetrics.map(s => { const [l, v, t] = s.split(":").map(x => (x || "").trim()); return { label: l || "Metric", value: v || "0", trend: t || "" }; });
    const items = theme.sampleItems.map(s => { const [t, sub, trail] = s.split(":").map(x => (x || "").trim()); return { title: t || "Item", subtitle: sub || "", trailing: trail || "" }; });
    const loweredIntent = (slot.intent || "").toLowerCase();
    const isSearchResultsIntent = /\bsearch\b|\bresults?\b/.test(loweredIntent);
    const isSearchSuggestionIntent = isSearchResultsIntent && /\bsuggest|autocomplete|query\b/.test(loweredIntent);
    const nativePattern = designSpec?.style.nativePattern;
    const fingerprint = `${theme.appName}|${theme.itemNoun}|${slot.slotType}|${slot.intent || ""}`;
    const hash = Array.from(fingerprint).reduce((acc, ch) => ((acc * 31) + ch.charCodeAt(0)) >>> 0, 7);
    const pick = (count: number) => hash % Math.max(1, count);
    const transportContext = `${theme.appName} ${theme.itemNoun} ${theme.domainTags.join(" ")} ${slot.intent || ""} ${theme.sampleItems.join(" ")}`.toLowerCase();
    const isTransportLike = /\b(uber|lyft|rideshare|ride share|pickup|dropoff|drop-off|destination|driver|eta|fare|route|trip|vehicle|cab|taxi)\b/.test(transportContext)
        || theme.domainTags.includes("transport");
    const isTransportOptionIntent = isTransportLike && /\b(ride|fare|eta|vehicle|trip|option|pickup|reserve)\b/.test(loweredIntent);
    const transportAccent = theme.accentColor || "blue:1.0";
    const transportSheetFill = "systemBackground:1.0";
    const transportInsetFill = "secondarySystemBackground:1.0";
    const transportSecondaryButtonFill = "tertiarySystemBackground:1.0";
    const transportSecondary = "secondary:1.0";
    const transportReserveMode = /\breserve\b|\bschedule\b|\blater\b|\bdeparture\b|\bleave at\b/.test(transportContext);
    const transportCompareMode = /\bcompare\b|\boptions?\b|\bfares?\b|\btiers?\b|\bprice\b|\bpricing\b/.test(transportContext);
    const transportMapMode = /\bmap\b|\broute\b|\bnearby\b|\bdriver\b|\blive\b/.test(transportContext);
    const fallbackTransportRows = [
        { title: "Go", subtitle: "Fast pickup", trailing: "$14.90" },
        { title: "Priority", subtitle: "Shorter wait", trailing: "$18.40" },
        { title: "Comfort", subtitle: "More space", trailing: "$24.20" },
        { title: transportReserveMode ? "Reserve" : "Shared", subtitle: transportReserveMode ? "Leave later" : "Lower fare", trailing: transportReserveMode ? "Schedule" : "$11.60" },
    ];
    const fallbackTransportBadges = transportReserveMode
        ? ["Soonest", "Flexible", "Premium", "Scheduled"]
        : transportCompareMode
        ? ["Best value", "Fastest", "Extra room", "Lowest fare"]
        : ["Nearby", "Popular", "Comfort", "Flexible"];
    const transportPrimaryOption = items[0]?.title || fallbackTransportRows[0].title;
    const transportPrimaryPrice = items.find((item) => item.trailing)?.trailing || fallbackTransportRows[0].trailing;
    const transportPrimaryStatus = items[0]?.subtitle || (transportReserveMode ? "Pickup window ready" : transportMapMode ? "Driver arrives in 4 min" : "Trip ready");
    const transportPrimaryCTA = transportReserveMode ? "Reserve Ride" : `Choose ${transportPrimaryOption}`;
    const transportSecondaryCTA = transportReserveMode ? "Ride Now" : "Reserve";
    const transportPickupLabel = items[0]?.title || "Pickup";
    const transportPickupDetail = items[0]?.subtitle || "Apple Park Visitor Center";
    const transportDestinationLabel = items[1]?.title || "Destination";
    const transportDestinationDetail = items[1]?.subtitle || "Infinite Loop";

    const buildTransportMapPreview = (): AnyComponent => ({
        type: "ZStack",
        properties: { alignment: "topLeading" },
        modifiers: [fullW],
        children: [
            {
                type: "Map",
                properties: {
                    latitude: 37.3346,
                    longitude: -122.0090,
                    latitudeDelta: 0.018,
                    longitudeDelta: 0.018,
                    mapStyle: "standard",
                    interactionModes: "all",
                    showsCompass: true,
                    showsScale: false,
                    showsUserLocation: false,
                    showsTraffic: true,
                    locationName: "Apple Park, Cupertino",
                    markers: "[{\"latitude\":37.3329,\"longitude\":-122.0054,\"title\":\"Pickup\",\"tint\":\"green:1.0\"},{\"latitude\":37.3388,\"longitude\":-122.0112,\"title\":\"Destination\",\"tint\":\"blue:1.0\"}]",
                },
                modifiers: [
                    { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 318 } },
                    { type: "Corner Radius", properties: { radius: r + 8 } },
                    { type: "Clip Shape", properties: { shape: "Rectangle" } },
                ],
            },
            {
                type: "VStack",
                properties: { alignment: "leading", spacing: 18 },
                modifiers: [
                    { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 318 } },
                    { type: "Padding", properties: { amount: 18, location: "all" } },
                ],
                children: [
                    {
                        type: "HStack",
                        properties: { spacing: 10, alignment: "center" },
                        modifiers: [fullW],
                        children: [
                            {
                                type: "HStack",
                                properties: { spacing: 8, alignment: "center" },
                                modifiers: [
                                    { type: "Padding", properties: { amount: 10, location: "all" } },
                                    { type: "Corner Radius", properties: { radius: 999 } },
                                    { type: "Glass Effect", properties: { shape: "Capsule" } },
                                ],
                                children: [
                                    mkSym("clock.fill", transportAccent, "caption", "semibold"),
                                    mkText(items[0]?.subtitle || "Pickup in 4 min", "caption", "semibold", transportAccent),
                                ],
                            },
                            { type: "Spacer" },
                            mkIconCircle("location.north.line.fill", transportInsetFill, transportAccent, 40),
                        ],
                    },
                    { type: "Spacer" },
                    {
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 10 },
                        modifiers: [
                            fullW,
                            { type: "Padding", properties: { amount: 16, location: "all" } },
                            { type: "Corner Radius", properties: { radius: 22 } },
                            { type: "Glass Effect", properties: { shape: "RoundedRectangle" } },
                        ],
                        children: [
                            {
                                type: "HStack",
                                properties: { spacing: 10, alignment: "center" },
                                modifiers: [fullW],
                                children: [
                                    mkIconCircle("circle.fill", "green:0.18", "green:0.95", 28),
                                    {
                                        type: "VStack",
                                        properties: { alignment: "leading", spacing: 2 },
                                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                                        children: [
                                            mkText(transportPickupLabel, "subheadline", "bold"),
                                            mkText(transportPickupDetail, "caption", "regular", transportSecondary),
                                        ],
                                    },
                                ],
                            },
                            {
                                type: "HStack",
                                properties: { spacing: 10, alignment: "center" },
                                modifiers: [fullW],
                                children: [
                                    mkIconCircle("mappin.circle.fill", `${ab}:0.14`, transportAccent, 28),
                                    {
                                        type: "VStack",
                                        properties: { alignment: "leading", spacing: 2 },
                                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                                        children: [
                                            mkText(transportDestinationLabel, "subheadline", "bold"),
                                            mkText(transportDestinationDetail, "caption", "regular", transportSecondary),
                                        ],
                                    },
                                ],
                            },
                        ],
                    },
                ],
            },
        ],
    });

    const buildTransportRideOptions = (): AnyComponent => {
        const rowCount = Math.max(1, Math.min(12, slot.itemCount ?? 4));
        const rideRows = [...items.slice(0, rowCount), ...fallbackTransportRows].slice(0, rowCount);
        const badges = fallbackTransportBadges;

        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            children: rideRows.map((item, index) => ({
                type: "HStack",
                properties: { spacing: 12, alignment: "center" },
                modifiers: [
                    fullW,
                    { type: "Padding", properties: { amount: 14, location: "all" } },
                    { type: "Background Color", properties: { color: index === 0 ? transportSheetFill : transportInsetFill } },
                    { type: "Corner Radius", properties: { radius: 22 } },
                ],
                children: [
                    mkIconCircle(index === 0 ? "car.fill" : index === 1 ? "figure.seated.side.air.upper" : index === 2 ? "sparkles" : "calendar.badge.clock", `${ab}:0.12`, transportAccent, 44),
                    {
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 3 },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [
                            {
                                type: "HStack",
                                properties: { spacing: 8, alignment: "center" },
                                modifiers: [fullW],
                                children: [
                                    mkText(item.title, "headline", "bold"),
                                    {
                                        type: "Text",
                                        properties: { text: badges[index] || "Fastest" },
                                        modifiers: [
                                            { type: "Padding", properties: { amount: 8, location: "horizontal" } },
                                            { type: "Padding", properties: { amount: 4, location: "vertical" } },
                                            { type: "Corner Radius", properties: { radius: 999 } },
                                            { type: "Glass Effect", properties: { shape: "Capsule" } },
                                            { type: "Font", properties: { fontSize: "caption2", fontWeight: "semibold" } },
                                            { type: "Foreground Color", properties: { color: transportAccent } },
                                        ],
                                    },
                                    { type: "Spacer" },
                                    mkText(item.trailing || "$18.00", "headline", "bold", transportAccent),
                                ],
                            },
                            {
                                type: "HStack",
                                properties: { spacing: 8, alignment: "center" },
                                children: [
                                    mkText(item.subtitle || "4 min away", "subheadline", "regular", transportSecondary),
                                    mkText("•", "subheadline", "regular", transportSecondary),
                                    mkText(index === 0 ? "4 seats" : index === 1 ? "Quiet cabin" : index === 2 ? "Top-rated" : "Plan ahead", "caption", "semibold", transportSecondary),
                                ],
                            },
                        ],
                    },
                ],
            }) as AnyComponent),
        };
    };

    const buildTransportActionBar = (): AnyComponent => ({
        type: "VStack",
        properties: { alignment: "leading", spacing: 12 },
        modifiers: [
            fullW,
            { type: "Padding", properties: { amount: 14, location: "all" } },
            { type: "Glass Effect", properties: { shape: "RoundedRectangle" } },
        ],
        children: [
            {
                type: "HStack",
                properties: { spacing: 10, alignment: "center" },
                modifiers: [fullW],
                children: [
                    {
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 2 },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [
                            mkText("Pickup now", "subheadline", "bold"),
                            mkText(transportPrimaryStatus, "caption", "regular", transportSecondary),
                        ],
                    },
                    mkText(transportPrimaryPrice, "title3", "bold", transportAccent),
                ],
            },
            {
                type: "HStack",
                properties: { spacing: 10, alignment: "center" },
                modifiers: [fullW],
                children: [
                    {
                        type: "Button",
                        properties: { buttonStyle: "plain" },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [{
                            type: "Text",
                            properties: { text: transportSecondaryCTA },
                            modifiers: [
                                fullW,
                                { type: "Padding", properties: { amount: 16, location: "all" } },
                                { type: "Background Color", properties: { color: transportSecondaryButtonFill } },
                                { type: "Foreground Color", properties: { color: "primary:1.0" } },
                                { type: "Font", properties: { fontSize: "headline", fontWeight: "semibold" } },
                                { type: "Corner Radius", properties: { radius: 18 } },
                            ],
                        }],
                    },
                    {
                        type: "Button",
                        properties: { buttonStyle: "plain" },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [{
                            type: "Text",
                            properties: { text: transportPrimaryCTA },
                            modifiers: [
                                fullW,
                                { type: "Padding", properties: { amount: 16, location: "all" } },
                                { type: "Background Color", properties: { color: transportAccent } },
                                { type: "Foreground Color", properties: { color: "white:1.0" } },
                                { type: "Font", properties: { fontSize: "headline", fontWeight: "bold" } },
                                { type: "Corner Radius", properties: { radius: 18 } },
                            ],
                        }],
                    },
                ],
            },
        ],
    });

    switch (slot.slotType) {
        case "app_header":
            if (isTransportLike) {
                return {
                    type: "HStack",
                    properties: { spacing: 12, alignment: "center" },
                    modifiers: [
                        fullW,
                        { type: "Padding", properties: { amount: 8, location: "horizontal" } },
                        { type: "Padding", properties: { amount: 10, location: "vertical" } },
                    ],
                    children: [
                        {
                            type: "VStack",
                            properties: { alignment: "leading", spacing: 2 },
                            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                            children: [
                                mkText(transportPickupLabel, "caption", "semibold", transportSecondary),
                                mkText(transportPickupDetail, "headline", "bold"),
                            ],
                        },
                    ],
                };
            }
            if (nativePattern === "apple_store") {
                return {
                    type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "vertical" } }],
                    children: [
                        mkText("Products", "largeTitle", "bold"),
                    ],
                };
            }
            if (nativePattern === "admob_dashboard") {
                return {
                    type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW],
                    children: [
                        mkText("Dashboard", "title2", "bold"),
                    ],
                };
            }
            const headerIntent = (slot.intent || "").toLowerCase();
            const isDetailHeader = /\bback\b|\bdetail\b|\bdrill\b|\binner\b|\bthread\b/.test(headerIntent);
            return {
                type: "HStack", properties: { spacing: 10, alignment: "center" },
                modifiers: [
                    fullW,
                    { type: "Padding", properties: { amount: 10, location: "horizontal" } },
                    { type: "Padding", properties: { amount: 10, location: "vertical" } },
                ],
                children: [
                    ...(isDetailHeader ? [mkSym("chevron.left", undefined, "subheadline", "semibold")] : []),
                    {
                        type: "Text",
                        properties: { text: theme.appName },
                        modifiers: [
                            { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                            { type: "Font", properties: { fontSize: "headline", fontWeight: "bold" } },
                            { type: "Text Alignment", properties: { alignment: "center" } },
                        ],
                    },
                ],
            };

        case "hero_banner": {
            const pct = theme.sharedFacts.progressPercent;
            return {
                type: "VStack", properties: { alignment: "leading", spacing: sp },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: r } }],
                children: [
                    mkText(theme.sharedFacts.greeting, "title2", "bold"),
                    mkText(`${theme.sharedFacts.primaryMetricValue} ${theme.primaryMetricLabel.toLowerCase()}`, "body", "regular", "secondary:1.0"),
                    {
                        type: "VStack", properties: { alignment: "leading", spacing: 4 }, children: [
                            {
                                type: "HStack", properties: { spacing: 0, alignment: "center" }, children: [
                                    mkText(theme.primaryMetricLabel, "caption", "semibold", theme.accentColor),
                                    { type: "Spacer" },
                                    mkText(`${pct}%`, "caption", "regular", "secondary:1.0"),
                                ]
                            },
                            {
                                type: "Progress View", properties: { value: pct / 100, total: 1.0, color: theme.accentColor },
                                modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }]
                            },
                        ]
                    },
                    {
                        type: "Button", properties: { buttonStyle: "plain" }, children: [
                            {
                                type: "Text", properties: { text: theme.ctaText }, modifiers: [
                                    { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                                    { type: "Padding", properties: { amount: 14, location: "all" } },
                                    { type: "Background Color", properties: { color: theme.accentColor } },
                                    { type: "Foreground Color", properties: { color: "white:1.0" } },
                                    { type: "Font", properties: { fontSize: "subheadline", fontWeight: "bold" } },
                                    { type: "Corner Radius", properties: { radius: theme.cornerRadiusScale === "pill" ? 999 : theme.cornerRadiusScale === "sharp" ? 6 : 10 } },
                                ]
                            },
                        ]
                    },
                ],
            };
        }

        case "stat_group": {
            if (nativePattern === "admob_dashboard") {
                const adMobCards = metrics.slice(0, 5).map((m, idx) => {
                    const palette = [
                        { tint: "green:1.0", fill: "green:0.18" },
                        { tint: "lightblue:1.0", fill: "lightblue:0.18" },
                        { tint: "orange:1.0", fill: "orange:0.18" },
                    ][idx % 3];
                    return {
                        type: "HStack",
                        properties: { spacing: 14, alignment: "center" },
                        modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.10" } }, { type: "Corner Radius", properties: { radius: 18 } }],
                        children: [
                            {
                                type: "VStack",
                                properties: { alignment: "leading", spacing: 5 },
                                modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                                children: [
                                    mkText(m.label, "headline", "semibold", palette.tint),
                                    mkText(m.value, "title2", "bold"),
                                    ...(m.trend ? [mkText(m.trend, "body", "semibold", m.trend.startsWith("-") ? "purple:1.0" : "green:1.0")] : []),
                                ],
                            },
                            {
                                type: "RoundedRectangle",
                                properties: { cornerRadius: 10 },
                                modifiers: [
                                    { type: "Frame", properties: { widthType: "Custom", width: 140, heightType: "Custom", height: 70 } },
                                    { type: "Fill", properties: { color: palette.fill } },
                                ],
                            },
                        ],
                    } as AnyComponent;
                });
                return { type: "VStack", properties: { alignment: "leading", spacing: 10 }, children: adMobCards };
            }
            const statCards = metrics.slice(0, 4).map(m => ({
                type: "VStack", properties: { alignment: "leading", spacing: 4 },
                modifiers: [
                    { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                    { type: "Padding", properties: { amount: pad, location: "all" } },
                    { type: "Background Color", properties: { color: cardBg } },
                    { type: "Corner Radius", properties: { radius: rSmall } },
                ],
                children: [
                    mkText(m.label, "caption", "regular", "secondary:1.0"),
                    mkText(m.value, "title3", "bold", theme.accentColor),
                    ...(m.trend ? [mkText(m.trend, "caption", "semibold", m.trend.startsWith("-") ? "red:1.0" : "green:1.0")] : []),
                ],
            } as AnyComponent));
            const rows: AnyComponent[] = [];
            for (let i = 0; i < statCards.length; i += 2) {
                rows.push({
                    type: "HStack", properties: { spacing: sp, alignment: "top" }, children: statCards.slice(i, i + 2),
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }]
                });
            }
            return { type: "VStack", properties: { alignment: "leading", spacing: sp }, children: rows };
        }

        case "content_list": {
            if (isTransportOptionIntent) {
                return buildTransportRideOptions();
            }
            const rowCount = Math.max(1, Math.min(12, slot.itemCount ?? 4));
            const fallbackRows = Array.from({ length: rowCount }, (_, i) => ({
                title: `${theme.itemNoun.charAt(0).toUpperCase() + theme.itemNoun.slice(1)} ${i + 1}`,
                subtitle: i % 2 === 0 ? "Primary detail • Updated recently" : "Secondary detail • Relevant now",
                trailing: i % 3 === 0 ? "Open" : "",
            }));
            const sourceItems = isSearchResultsIntent
                ? Array.from({ length: rowCount }, (_, i) => ({
                    title: `Result ${i + 1}`,
                    subtitle: i % 2 === 0 ? "Matched in title • Updated today" : "Secondary metadata • Relevant match",
                    trailing: i % 3 === 0 ? "Open" : "",
                }))
                : [...items.slice(0, rowCount), ...fallbackRows].slice(0, rowCount);
            const searchLeadingSymbols = [
                "magnifyingglass",
                "magnifyingglass",
                "magnifyingglass",
                "magnifyingglass",
                "apple.logo",
                "person.crop.square",
                "arcade.stick",
                "applewatch",
                "magnifyingglass",
            ];
            const listRows = sourceItems.map((item, i) => {
                if (isSearchSuggestionIntent || nativePattern === "appstore_search") {
                    return {
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 0 },
                        modifiers: [fullW],
                        children: [
                            {
                                type: "HStack",
                                properties: { spacing: 12, alignment: "center" },
                                modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
                                children: [
                                    mkSym(searchLeadingSymbols[i % searchLeadingSymbols.length], "gray:0.60", "title3", "regular"),
                                    {
                                        type: "VStack", properties: { alignment: "leading", spacing: 1 },
                                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                                        children: [
                                            mkText(item.title, "title3", "regular"),
                                            ...(item.subtitle ? [mkText(item.subtitle, "body", "regular", "gray:0.65")] : []),
                                        ],
                                    },
                                ],
                            },
                            { type: "Divider" },
                        ],
                    } as AnyComponent;
                }
                if (nativePattern === "mail_inbox") {
                    const denseVariant = pick(2) === 0;
                    return {
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 0 },
                        modifiers: [fullW],
                        children: [
                            {
                                type: "HStack", properties: { spacing: 10, alignment: "top" },
                                modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
                                children: [
                                    mkIconCircle(denseVariant ? "person.fill" : "envelope.fill", "gray:0.20", "gray:0.85", denseVariant ? 44 : 40),
                                    {
                                        type: "VStack", properties: { alignment: "leading", spacing: denseVariant ? 2 : 3 },
                                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                                        children: [
                                            mkText(item.title, denseVariant ? "title3" : "headline", "bold"),
                                            ...(item.subtitle ? [mkText(item.subtitle, denseVariant ? "body" : "subheadline", "regular", "gray:0.70")] : []),
                                        ],
                                    },
                                    mkText(item.trailing || "Today", "body", "regular", "gray:0.70"),
                                ],
                            },
                            { type: "Divider" },
                        ],
                    } as AnyComponent;
                }
                return {
                    type: "HStack", properties: { spacing: 12, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: rowBg } }, { type: "Corner Radius", properties: { radius: rSmall } }],
                    children: [
                        mkIconCircle(isSearchResultsIntent ? "magnifyingglass" : (theme.mascotSymbol || "circle.fill"), `${ab}:0.15`, theme.accentColor),
                        {
                            type: "VStack", properties: { alignment: "leading", spacing: 2 },
                            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                            children: [mkText(item.title, "body", "semibold"), ...(item.subtitle ? [mkText(item.subtitle, "caption", "regular", "secondary:1.0")] : [])]
                        },
                        ...(item.trailing ? [mkText(item.trailing, "caption", "bold", theme.accentColor)] : []),
                    ],
                } as AnyComponent;
            });
            return {
                type: "VStack", properties: { alignment: "leading", spacing: sp },
                children: (isSearchSuggestionIntent || nativePattern === "appstore_search" || nativePattern === "mail_inbox")
                    ? listRows
                    : listRows,
            };
        }

        case "content_grid": {
            const gridItems = items.slice(0, 4).map(item => ({
                type: "VStack", properties: { alignment: "leading", spacing: 8 },
                modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: pad, location: "all" } }, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: rSmall } }],
                children: [
                    mkSym(theme.mascotSymbol || "star.fill", theme.accentColor, "title3", "semibold"),
                    mkText(item.title, "subheadline", "bold"),
                    ...(item.subtitle ? [mkText(item.subtitle, "caption", "regular", "secondary:1.0")] : []),
                ],
            } as AnyComponent));
            const gridRows: AnyComponent[] = [];
            for (let i = 0; i < gridItems.length; i += 2) {
                gridRows.push({ type: "HStack", properties: { spacing: sp, alignment: "top" }, children: gridItems.slice(i, i + 2), modifiers: [fullW] });
            }
            return { type: "VStack", properties: { alignment: "leading", spacing: sp }, children: gridRows };
        }

        case "horizontal_rail": {
            if (nativePattern === "spotify_browse") {
                const variant = pick(3);
                const chipLabels = ["All", "Music", "Podcasts", "Audiobooks"];
                const chips = chipLabels.map((label, idx) => ({
                    type: "Capsule",
                    properties: {},
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Custom", width: label.length > 8 ? 120 : 86, heightType: "Custom", height: 42 } },
                        { type: "Fill", properties: { color: idx === 0 ? "green:1.0" : "gray:0.20" } },
                        { type: "Overlay", children: [{ type: "Text", properties: { text: label }, modifiers: [{ type: "Font", properties: { fontSize: "body", fontWeight: "medium" } }, { type: "Foreground Color", properties: { color: idx === 0 ? "black:1.0" : "white:1.0" } }] }] },
                    ],
                } as AnyComponent));
                return {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 14 },
                    children: [
                        {
                            type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false },
                            children: [{ type: "HStack", properties: { spacing: 10, alignment: "center" }, children: chips }],
                        },
                        {
                            type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false },
                            children: [{
                                type: "HStack", properties: { spacing: 14, alignment: "top" }, children: theme.sampleRailItems.slice(0, 5).map((title, idx) => ({
                                    type: "VStack",
                                    properties: { alignment: "leading", spacing: 8 },
                                    modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: variant === 2 ? 150 : 190, heightType: "Default" } }],
                                    children: [
                                        variant === 1
                                            ? ({
                                                type: "Circle",
                                                properties: {},
                                                modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 136, heightType: "Custom", height: 136 } }, { type: "Fill", properties: { color: "gray:0.18" } }],
                                            } as AnyComponent)
                                            : ({ type: "RoundedRectangle", properties: { cornerRadius: 10 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 160 } }, { type: "Fill", properties: { color: "gray:0.18" } }] } as AnyComponent),
                                        mkText(title, variant === 2 ? "subheadline" : "headline", "semibold"),
                                        mkText(variant === 1 ? "Artist radio" : "For fans of this artist", "body", "regular", "gray:0.70"),
                                        ...(variant === 2 && idx % 2 === 0 ? [mkText("NEW", "caption", "bold", "green:1.0")] : []),
                                    ],
                                } as AnyComponent)),
                            }],
                        },
                    ],
                };
            }
            const railVariant = chooseRailVariant(slot, []);
            const railTitle = (() => {
                const raw = (slot.intent || "").trim();
                if (!raw) return "Highlights";
                const cleaned = raw
                    .replace(/^a\s+horizontal\s+rail\s+of\s+/i, "")
                    .replace(/^horizontal\s+rail\s+of\s+/i, "")
                    .replace(/^show\s+/i, "")
                    .replace(/^with\s+/i, "")
                    .trim();
                return cleaned ? cleaned.charAt(0).toUpperCase() + cleaned.slice(1) : "Highlights";
            })();
            const shouldHideRailTitle = /^(chips?|results?|highlights?|places?|items?)$/i.test(railTitle.trim());
            const railCards = theme.sampleRailItems.slice(0, 5).map((title, idx) => {
                if (railVariant === "circular_people") {
                    return {
                        type: "VStack",
                        properties: { alignment: "center", spacing: 8 },
                        modifiers: [
                            { type: "Frame", properties: { widthType: "Custom", width: 104, heightType: "Custom", height: 132 } },
                            { type: "Padding", properties: { amount: 8, location: "all" } },
                        ],
                        children: [
                            {
                                type: "Circle", properties: {}, modifiers: [
                                    { type: "Frame", properties: { widthType: "Custom", width: 72, heightType: "Custom", height: 72 } },
                                    { type: "Fill", properties: { color: `${ab}:0.20` } },
                                ]
                            },
                            mkText(title, "caption", "semibold"),
                        ],
                    } as AnyComponent;
                }

                if (railVariant === "chips") {
                    return {
                        type: "Capsule",
                        properties: {},
                        modifiers: [
                            { type: "Padding", properties: { amount: 6, location: "all" } },
                            { type: "Frame", properties: { widthType: "Custom", width: 120, heightType: "Custom", height: 36 } },
                            { type: "Fill", properties: { color: `${ab}:0.16` } },
                            {
                                type: "Overlay", children: [
                                    { type: "Text", properties: { text: title }, modifiers: [{ type: "Font", properties: { fontSize: "caption", fontWeight: "semibold" } }, { type: "Foreground Color", properties: { color: theme.accentColor } }] },
                                ]
                            },
                        ],
                    } as AnyComponent;
                }

                if (railVariant === "landscape") {
                    return {
                        type: "VStack", properties: { alignment: "leading", spacing: 8 },
                        modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 220, heightType: "Custom", height: 132 } }],
                        children: [
                            {
                                type: "RoundedRectangle",
                                properties: { cornerRadius: rSmall },
                                modifiers: [
                                    { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 96 } },
                                    { type: "Fill", properties: { color: `${ab}:0.20` } },
                                ],
                            },
                            mkText(title, "subheadline", "bold"),
                        ],
                    } as AnyComponent;
                }

                const titleText = theme.sampleItems[idx]?.split(":")[0] ?? title;
                const subtitleText = theme.sampleItems[idx]?.split(":")[1] ?? theme.sharedFacts.userName;
                return {
                    type: "VStack", properties: { alignment: "leading", spacing: 8 },
                    modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 140, heightType: "Custom", height: 180 } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: r } }],
                    children: [
                        { type: "RoundedRectangle", properties: { cornerRadius: rSmall }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 104 } }, { type: "Fill", properties: { color: `${ab}:0.20` } }] },
                        mkText(titleText, "subheadline", "semibold"),
                        ...(railVariant === "media_track"
                            ? [mkText(subtitleText, "caption", "regular", "secondary:1.0")]
                            : []),
                    ],
                } as AnyComponent;
            });
            return {
                type: "VStack", properties: { alignment: "leading", spacing: sp },
                children: [
                    ...(shouldHideRailTitle ? [] : [mkText(railTitle, "headline", "bold")]),
                    {
                        type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false }, children: [
                            { type: "HStack", properties: { spacing: sp, alignment: "top" }, children: railCards },
                        ]
                    },
                ],
            };
        }

        case "nav_bar": {
            if (nativePattern === "spotify_browse") {
                const tabs = [
                    { label: "Home", sym: "house.fill", active: true },
                    { label: "Search", sym: "magnifyingglass", active: false },
                    { label: "Your Library", sym: "books.vertical", active: false },
                    { label: "Create", sym: "plus", active: false },
                ];
                return {
                    type: "HStack",
                    properties: { spacing: 8, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.08" } }, { type: "Corner Radius", properties: { radius: 18 } }],
                    children: tabs.map((tab) => ({
                        type: "VStack",
                        properties: { spacing: 4, alignment: "center" },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [
                            mkSym(tab.sym, tab.active ? "white:1.0" : "gray:0.65"),
                            mkText(tab.label, "caption", "regular", tab.active ? "white:1.0" : "gray:0.65"),
                        ],
                    }) as AnyComponent),
                };
            }
            if (nativePattern === "admob_dashboard") {
                return {
                    type: "HStack",
                    properties: { spacing: 12, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.10" } }, { type: "Corner Radius", properties: { radius: 20 } }],
                    children: [
                        {
                            type: "Capsule",
                            properties: {},
                            modifiers: [
                                { type: "Frame", properties: { widthType: "Custom", width: 150, heightType: "Custom", height: 42 } },
                                { type: "Fill", properties: { color: "gray:0.20" } },
                                { type: "Overlay", children: [{ type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [mkSym("dollarsign.circle.fill", "lightblue:1.0"), mkText("Dashboard", "body", "semibold", "lightblue:1.0")] }] },
                            ],
                        },
                        {
                            type: "VStack",
                            properties: { spacing: 4, alignment: "center" },
                            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                            children: [mkSym("chart.bar.fill", "white:1.0"), mkText("Chart", "body", "regular", "white:1.0")],
                        },
                    ],
                };
            }
            if (nativePattern === "apple_store") {
                const tabs = [
                    { label: "For You", sym: "sparkles", active: false },
                    { label: "Products", sym: "iphone.gen3", active: true },
                    { label: "Go Further", sym: "safari", active: false },
                    { label: "Bag", sym: "bag", active: false },
                ];
                return {
                    type: "HStack",
                    properties: { spacing: 8, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.08" } }, { type: "Corner Radius", properties: { radius: 22 } }],
                    children: tabs.map((tab) => ({
                        type: "VStack",
                        properties: { spacing: 4, alignment: "center" },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [
                            mkSym(tab.sym, tab.active ? "blue:1.0" : "white:0.9", "body", tab.active ? "semibold" : "regular"),
                            mkText(tab.label, "caption", tab.active ? "semibold" : "regular", tab.active ? "blue:1.0" : "white:0.85"),
                        ],
                    }) as AnyComponent),
                };
            }
            const navItems = [
                { label: "Home", sym: "house.fill", symOff: "house" },
                { label: "Explore", sym: "safari.fill", symOff: "safari" },
                { label: "Saved", sym: "bookmark.fill", symOff: "bookmark" },
                { label: "Profile", sym: "person.fill", symOff: "person" },
            ];
            const tabs = navItems.flatMap((item, i) => {
                const active = i === 0;
                return [
                    { type: "Spacer" } as AnyComponent,
                    {
                        type: "VStack", properties: { spacing: 3, alignment: "center" },
                        children: [
                            mkSym(active ? item.sym : item.symOff, active ? theme.accentColor : "gray:0.50", "body", active ? "bold" : "regular"),
                            mkText(item.label, "caption2", active ? "bold" : "regular", active ? theme.accentColor : "gray:0.50"),
                        ],
                    } as AnyComponent,
                ];
            });
            tabs.push({ type: "Spacer" } as AnyComponent);
            return {
                type: "VStack", properties: { alignment: "leading", spacing: 0 },
                modifiers: [fullW],
                children: [
                    { type: "Divider" },
                    {
                        type: "HStack", properties: { spacing: 0, alignment: "center" },
                        modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.03" } }],
                        children: tabs
                    },
                ],
            };
        }

        case "action_bar":
            if (isTransportLike) {
                return buildTransportActionBar();
            }
            return {
                type: "VStack", properties: { alignment: "center", spacing: 0 },
                modifiers: [fullW, { type: "Padding", properties: { amount: pad, location: "all" } }],
                children: [{
                    type: "Button", properties: { buttonStyle: "plain" }, children: [
                        {
                            type: "Text", properties: { text: theme.ctaText }, modifiers: [
                                fullW, { type: "Padding", properties: { amount: 16, location: "all" } },
                                { type: "Background Color", properties: { color: theme.accentColor } },
                                { type: "Foreground Color", properties: { color: "white:1.0" } },
                                { type: "Font", properties: { fontSize: "headline", fontWeight: "bold" } },
                                { type: "Corner Radius", properties: { radius: theme.cornerRadiusScale === "pill" ? 999 : rSmall } },
                            ]
                        },
                    ]
                }],
            };

        case "map_preview":
            if (isTransportLike) {
                return buildTransportMapPreview();
            }
            return {
                type: "VStack",
                properties: { alignment: "leading", spacing: 12 },
                modifiers: [fullW],
                children: [
                    {
                        type: "ZStack",
                        properties: { alignment: "center" },
                        children: [
                            {
                                type: "Map",
                                properties: {
                                    latitude: 37.3346,
                                    longitude: -122.0090,
                                    latitudeDelta: 0.024,
                                    longitudeDelta: 0.024,
                                    mapStyle: "standard",
                                    interactionModes: "all",
                                    showsCompass: true,
                                    showsScale: false,
                                    showsUserLocation: false,
                                    showsTraffic: false,
                                    locationName: "Apple Park, Cupertino",
                                    markers: "[{\"latitude\":37.3346,\"longitude\":-122.0090,\"title\":\"Apple Park\",\"tint\":\"red:1.0\"}]",
                                },
                                modifiers: [
                                    { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 248 } },
                                    { type: "Corner Radius", properties: { radius: r + 6 } },
                                    { type: "Clip Shape", properties: { shape: "Rectangle" } },
                                ],
                            },
                        ],
                    },
                    {
                        type: "HStack",
                        properties: { spacing: 10, alignment: "center" },
                        modifiers: [
                            fullW,
                            { type: "Padding", properties: { amount: 14, location: "all" } },
                            { type: "Background Color", properties: { color: cardBg } },
                            { type: "Corner Radius", properties: { radius: rSmall } },
                        ],
                        children: [
                            {
                                type: "VStack",
                                properties: { alignment: "leading", spacing: 2 },
                                modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                                children: [
                                    mkText(items[0]?.title || "Location", "subheadline", "bold"),
                                    mkText(items[0]?.subtitle || "Map context preview", "caption", "regular", "secondary:1.0"),
                                ],
                            },
                            mkText("Directions", "subheadline", "semibold", theme.accentColor),
                        ],
                    },
                ],
            };

        case "section_header":
            return {
                type: "HStack", properties: { spacing: 0, alignment: "center" },
                modifiers: [fullW],
                children: [
                    mkText(slot.intent || theme.itemNoun, "headline", "bold"),
                    { type: "Spacer" },
                    mkText("See All", "subheadline", "semibold", theme.accentColor),
                ],
            };

        case "search_bar":
            if (nativePattern === "mail_inbox") {
                return {
                    type: "HStack", properties: { spacing: 10, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.10" } }, { type: "Corner Radius", properties: { radius: 18 } }],
                    children: [
                        mkSym("magnifyingglass", "gray:0.62", "title3", "regular"),
                        { type: "Text Field", properties: { placeholder: "Search", text: "" }, modifiers: [fullW] },
                    ],
                };
            }
            return {
                type: "HStack",
                properties: { spacing: 0, alignment: "center" },
                modifiers: [fullW],
                children: [
                    {
                        type: "HStack",
                        properties: { spacing: 10, alignment: "center" },
                        modifiers: [
                            { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                            { type: "Padding", properties: { amount: 12, location: "all" } },
                            { type: "Background Color", properties: { color: "gray:0.10" } },
                            { type: "Corner Radius", properties: { radius: 18 } },
                        ],
                        children: [
                            mkSym("magnifyingglass", "gray:0.60", "body", "regular"),
                            { type: "Text Field", properties: { placeholder: `Search ${theme.itemNoun}`, text: "" }, modifiers: [fullW] },
                        ],
                    },
                ],
            };

        case "progress_section": {
            const pct = theme.sharedFacts.progressPercent;
            return {
                type: "VStack", properties: { alignment: "center", spacing: sp },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: r } }],
                children: [
                    {
                        type: "Gauge", properties: { value: pct, min: 0, max: 100, gaugeType: "circular", showValue: true, color: theme.accentColor }, modifiers: [
                            { type: "Frame", properties: { widthType: "Custom", width: 124, heightType: "Custom", height: 124 } },
                        ]
                    },
                    mkText(theme.primaryMetricLabel, "subheadline", "semibold"),
                    mkText(theme.sharedFacts.primaryMetricValue, "caption", "regular", "secondary:1.0"),
                ],
            };
        }

        case "profile_header":
            return {
                type: "VStack", properties: { alignment: "center", spacing: sp },
                modifiers: [fullW, padAll],
                children: [
                    { type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 72, heightType: "Custom", height: 72 } }, { type: "Fill", properties: { color: `${ab}:0.20` } }] },
                    mkText(theme.sharedFacts.userName, "title3", "bold"),
                    {
                        type: "HStack", properties: { spacing: 24, alignment: "center" }, children: metrics.slice(0, 3).map(m => ({
                            type: "VStack", properties: { alignment: "center", spacing: 2 },
                            children: [mkText(m.value, "headline", "bold"), mkText(m.label, "caption", "regular", "secondary:1.0")],
                        } as AnyComponent))
                    },
                ],
            };

        case "segmented_tabs":
            return {
                type: "HStack", properties: { spacing: 0, alignment: "center" },
                modifiers: [fullW, { type: "Padding", properties: { amount: 4, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.08" } }, { type: "Corner Radius", properties: { radius: rSmall } }],
                children: ["All", "Active", "Done"].map((label, i) => ({
                    type: "Button",
                    properties: { buttonStyle: "plain" },
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                    children: [{
                        type: "Text", properties: { text: label },
                        modifiers: [
                            { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                            { type: "Padding", properties: { amount: 10, location: "all" } },
                            ...(i === 0 ? [{ type: "Background Color", properties: { color: "white:1.0" } }, { type: "Corner Radius", properties: { radius: rSmall - 2 } }] : []),
                            { type: "Font", properties: { fontSize: "subheadline", fontWeight: i === 0 ? "bold" : "regular" } },
                            { type: "Foreground Color", properties: { color: i === 0 ? theme.accentColor : "secondary:1.0" } },
                            { type: "Text Alignment", properties: { alignment: "center" } },
                        ],
                    }],
                } as AnyComponent)),
            };

        case "calendar_strip": {
            const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
            const nums = ["12", "13", "14", "15", "16", "17", "18"];
            return {
                type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false },
                children: [{
                    type: "HStack", properties: { spacing: 8, alignment: "center" },
                    children: days.map((d, i) => ({
                        type: "VStack", properties: { alignment: "center", spacing: 6 },
                        modifiers: [
                            { type: "Padding", properties: { amount: 10, location: "all" } },
                            ...(i === 2 ? [{ type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: rSmall } }] : []),
                        ],
                        children: [
                            mkText(d, "caption2", "regular", i === 2 ? "white:1.0" : "secondary:1.0"),
                            mkText(nums[i], "body", i === 2 ? "bold" : "regular", i === 2 ? "white:1.0" : undefined),
                        ],
                    } as AnyComponent)),
                }],
            };
        }

        case "timeline_list": {
            const events = items.slice(0, 3).map((item, i) => ({
                type: "HStack", properties: { spacing: 12, alignment: "top" },
                modifiers: [fullW],
                children: [
                    {
                        type: "VStack", properties: { alignment: "center", spacing: 0 }, children: [
                            { type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 12, heightType: "Custom", height: 12 } }, { type: "Fill", properties: { color: i === 0 ? theme.accentColor : `${ab}:0.30` } }] },
                            ...(i < 2 ? [{ type: "Rectangle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 2, heightType: "Custom", height: 40 } }, { type: "Fill", properties: { color: `${ab}:0.15` } }] } as AnyComponent] : []),
                        ]
                    },
                    {
                        type: "VStack", properties: { alignment: "leading", spacing: 2 }, children: [
                            mkText(item.title, "body", "semibold"),
                            ...(item.subtitle ? [mkText(item.subtitle, "caption", "regular", "secondary:1.0")] : []),
                        ]
                    },
                ],
            } as AnyComponent));
            return { type: "VStack", properties: { alignment: "leading", spacing: 4 }, children: events };
        }

        case "settings_list": {
            if (designSpec?.content.wantsSettingsToggles) {
                const makeToggleRow = (row: { label: string; sym: string; on: boolean }): AnyComponent => ({
                    type: "HStack",
                    properties: { spacing: 12, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: rowBg } }, { type: "Corner Radius", properties: { radius: rSmall } }],
                    children: [
                        mkIconCircle(row.sym, `${ab}:0.15`, theme.accentColor, 32),
                        mkText(row.label, "body", "regular"),
                        { type: "Spacer" },
                        { type: "Switch", properties: { isOn: row.on } },
                    ],
                });
                if (designSpec.content.wantsNotificationPreferences) {
                    const notificationRows = [
                        { label: "Push Notifications", sym: "bell.badge.fill", on: true },
                        { label: "Email Updates", sym: "envelope.fill", on: true },
                        { label: "Sounds", sym: "speaker.wave.2.fill", on: true },
                        { label: "Badges", sym: "app.badge.fill", on: true },
                    ].map(makeToggleRow);
                    const children: AnyComponent[] = [];
                    if (designSpec.content.wantsDarkMode) {
                        children.push(mkText("Appearance", "caption", "semibold", "secondary:1.0"));
                        children.push(makeToggleRow({ label: "Dark Mode", sym: "moon.fill", on: false }));
                    }
                    children.push(mkText("Notifications", "caption", "semibold", "secondary:1.0"));
                    children.push(...notificationRows);
                    return { type: "VStack", properties: { alignment: "leading", spacing: 12 }, children };
                }
                const toggleRows = [
                    { label: "Notifications", sym: "bell.fill", on: true },
                    { label: "Dark Mode", sym: "moon.fill", on: false },
                    { label: "Sound", sym: "speaker.wave.2.fill", on: true },
                ].map(makeToggleRow);
                return { type: "VStack", properties: { alignment: "leading", spacing: 8 }, children: toggleRows };
            }
            const settingsRows = [
                { label: "Notifications", sym: "bell.fill", trailing: "chevron.right" },
                { label: "Appearance", sym: "paintbrush.fill", trailing: "chevron.right" },
                { label: "Privacy", sym: "lock.fill", trailing: "chevron.right" },
            ].map(row => ({
                type: "HStack", properties: { spacing: 12, alignment: "center" },
                modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: rowBg } }, { type: "Corner Radius", properties: { radius: rSmall } }],
                children: [
                    mkIconCircle(row.sym, `${ab}:0.15`, theme.accentColor, 32),
                    mkText(row.label, "body", "regular"),
                    { type: "Spacer" },
                    mkSym(row.trailing, "gray:0.40", "caption", "regular"),
                ],
            } as AnyComponent));
            return { type: "VStack", properties: { alignment: "leading", spacing: 8 }, children: settingsRows };
        }

        case "empty_state":
            return {
                type: "VStack", properties: { alignment: "center", spacing: sp },
                modifiers: [fullW, padAll],
                children: [
                    { type: "Spacer" },
                    mkIconCircle(theme.mascotSymbol || "plus.circle.fill", `${ab}:0.12`, theme.accentColor, 64),
                    mkText(`No ${theme.itemNoun} yet`, "title3", "bold"),
                    mkText(`Add your first ${theme.itemNoun.replace(/s$/, "")} to get started`, "body", "regular", "secondary:1.0"),
                    { type: "Spacer" },
                ],
            };

        case "banner_alert":
            return {
                type: "HStack", properties: { spacing: 12, alignment: "center" },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: `${ab}:0.10` } }, { type: "Corner Radius", properties: { radius: rSmall } }],
                children: [
                    mkSym("info.circle.fill", theme.accentColor, "title3", "semibold"),
                    {
                        type: "VStack", properties: { alignment: "leading", spacing: 2 },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [mkText(`${theme.sharedFacts.streakValue} streak!`, "subheadline", "bold"), mkText("Keep it up to reach your goal", "caption", "regular", "secondary:1.0")]
                    },
                    mkSym("xmark", "gray:0.40", "caption", "regular"),
                ],
            };

        case "fab_button":
            return {
                type: "Button", properties: { buttonStyle: "plain" },
                modifiers: [{ type: "Padding", properties: { amount: 16, location: "all" } }],
                children: [{
                    type: "ZStack", properties: { alignment: "center" },
                    children: [
                        { type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 56, heightType: "Custom", height: 56 } }, { type: "Fill", properties: { color: theme.accentColor } }, { type: "Shadow", properties: { radius: 8, x: 0, y: 4, color: `${ab}:0.30` } }] },
                        mkSym("plus", "white:1.0", "title3", "bold"),
                    ],
                }],
            };

        case "media_player":
            return {
                type: "HStack", properties: { spacing: 12, alignment: "center" },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: cardBg } }],
                children: [
                    { type: "RoundedRectangle", properties: { cornerRadius: 6 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 44, heightType: "Custom", height: 44 } }, { type: "Fill", properties: { color: `${ab}:0.20` } }] },
                    {
                        type: "VStack", properties: { alignment: "leading", spacing: 2 },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                        children: [mkText(theme.sampleRailItems[0] || "Now Playing", "subheadline", "semibold"), mkText(theme.appName, "caption", "regular", "secondary:1.0")]
                    },
                    mkSym("play.fill", theme.accentColor, "title3", "semibold"),
                ],
            };

        case "chart_section":
            return {
                type: "VStack", properties: { alignment: "leading", spacing: sp },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: r } }],
                children: [
                    mkText("Overview", "headline", "bold"),
                    {
                        type: "HStack", properties: { spacing: 4, alignment: "bottom" },
                        modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 120 } }],
                        children: [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.3].map((h, i) => ({
                            type: "RoundedRectangle", properties: { cornerRadius: 4 },
                            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: Math.round(h * 100) } }, { type: "Fill", properties: { color: i === 3 ? theme.accentColor : `${ab}:0.20` } }],
                        } as AnyComponent)),
                    },
                ],
            };

        case "gallery_grid": {
            const tiles = Array.from({ length: 6 }, (_, i) => ({
                type: "RoundedRectangle", properties: { cornerRadius: rSmall },
                modifiers: [{ type: "Frame", properties: { widthType: "Custom", heightType: "Custom", width: 68, height: 68 } }, { type: "Fill", properties: { color: `${ab}:${0.08 + (i % 3) * 0.06}` } }],
            } as AnyComponent));
            const gridRows: AnyComponent[] = [];
            for (let i = 0; i < tiles.length; i += 3) {
                gridRows.push({ type: "HStack", properties: { spacing: 4, alignment: "top" }, children: tiles.slice(i, i + 3), modifiers: [fullW] });
            }
            return { type: "VStack", properties: { alignment: "leading", spacing: 4 }, children: gridRows };
        }

        case "story_rail": {
            const themeWords = `${theme.appName} ${theme.itemNoun} ${theme.sampleRailItems.join(" ")} ${theme.domainTags.join(" ")}`;
            const isCoffee = /\b(coffee|cafe|cafes|brew|latte|espresso|roaster|roasters)\b/i.test(themeWords);
            const storyNames = isCoffee
                ? ["Your Story", "Morning", "Latte Lab", "Roasters", "Cozy Nook", "Pour Over"]
                : ["Your Story", ...theme.sampleRailItems.slice(0, 5)];
            const stories = storyNames.slice(0, 6).map((name, i) => ({
                type: "VStack", properties: { alignment: "center", spacing: 4 },
                children: [
                    {
                        type: "ZStack", properties: { alignment: "center" }, children: [
                            { type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 56, heightType: "Custom", height: 56 } }, ...(i > 0 ? [{ type: "Stroke", properties: { color: theme.accentColor, lineWidth: 2 } }] : [{ type: "Fill", properties: { color: `${ab}:0.12` } }])] },
                            ...(i === 0 ? [mkSym("plus", theme.accentColor, "body", "bold")] : [{ type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 48, heightType: "Custom", height: 48 } }, { type: "Fill", properties: { color: `${ab}:0.15` } }] } as AnyComponent]),
                        ]
                    },
                    mkText(name.length > 8 ? name.slice(0, 7) + "…" : name, "caption2", "regular", "secondary:1.0"),
                ],
            } as AnyComponent));
            return {
                type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false },
                children: [{ type: "HStack", properties: { spacing: 12, alignment: "top" }, children: stories }],
            };
        }

        case "social_feed_slot": {
            const posts = items.slice(0, 2).map(item => ({
                type: "VStack", properties: { alignment: "leading", spacing: 10 },
                modifiers: [
                    fullW,
                    { type: "Padding", properties: { amount: 12, location: "all" } },
                    { type: "Background Color", properties: { color: cardBg } },
                    { type: "Corner Radius", properties: { radius: r } },
                ],
                children: [
                    {
                        type: "HStack", properties: { spacing: 10, alignment: "center" }, children: [
                            { type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 36, heightType: "Custom", height: 36 } }, { type: "Fill", properties: { color: `${ab}:0.15` } }] },
                            { type: "VStack", properties: { alignment: "leading", spacing: 1 }, children: [mkText(item.title, "subheadline", "bold"), mkText("2h ago", "caption2", "regular", "secondary:1.0")] },
                            { type: "Spacer" },
                            mkSym("ellipsis", "gray:0.40", "caption", "regular"),
                        ]
                    },
                    {
                        type: "RoundedRectangle",
                        properties: { cornerRadius: rSmall },
                        modifiers: [
                            { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 180 } },
                            { type: "Fill", properties: { color: `${ab}:0.10` } },
                            { type: "Stroke", properties: { color: `${ab}:0.18`, lineWidth: 1 } },
                        ],
                    },
                    ...(item.subtitle ? [mkText(item.subtitle, "body", "regular")] : []),
                    {
                        type: "HStack", properties: { spacing: 16, alignment: "center" }, children: [
                            mkSym("heart", "gray:0.50", "body", "regular"),
                            mkSym("bubble.left", "gray:0.50", "body", "regular"),
                            mkSym("paperplane", "gray:0.50", "body", "regular"),
                            { type: "Spacer" },
                            mkSym("bookmark", "gray:0.50", "body", "regular"),
                        ]
                    },
                ],
            } as AnyComponent));
            return { type: "VStack", properties: { alignment: "leading", spacing: 12 }, children: posts };
        }

        case "chat_bubble_list": {
            const msgs = [
                { text: "Hey! How's the project going?", sent: false },
                { text: "Going great, almost done with the design phase", sent: true },
                { text: "That's awesome! Can you share a preview?", sent: false },
            ];
            return {
                type: "VStack", properties: { alignment: "leading", spacing: 8 },
                modifiers: [fullW],
                children: msgs.map(m => ({
                    type: "HStack", properties: { spacing: 0, alignment: "bottom" },
                    modifiers: [fullW],
                    children: [
                        ...(m.sent ? [{ type: "Spacer" } as AnyComponent] : []),
                        {
                            type: "Text", properties: { text: m.text }, modifiers: [
                                { type: "Padding", properties: { amount: 12, location: "all" } },
                                { type: "Background Color", properties: { color: m.sent ? theme.accentColor : "gray:0.10" } },
                                { type: "Foreground Color", properties: { color: m.sent ? "white:1.0" : "primary:1.0" } },
                                { type: "Font", properties: { fontSize: "body", fontWeight: "regular" } },
                                { type: "Corner Radius", properties: { radius: 18 } },
                            ]
                        },
                        ...(!m.sent ? [{ type: "Spacer" } as AnyComponent] : []),
                    ],
                } as AnyComponent)),
            };
        }

        case "countdown_timer":
            return {
                type: "VStack", properties: { alignment: "center", spacing: sp },
                modifiers: [fullW, padAll],
                children: [
                    mkText("25:00", "largeTitle", "bold", theme.accentColor),
                    mkText("Focus Session", "body", "regular", "secondary:1.0"),
                    {
                        type: "HStack", properties: { spacing: 16, alignment: "center" }, children: [
                            mkSym("stop.fill", "gray:0.50", "title3", "regular"),
                            mkIconCircle("play.fill", theme.accentColor, "white:1.0", 56),
                            mkSym("forward.fill", "gray:0.50", "title3", "regular"),
                        ]
                    },
                ],
            };

        case "weather_widget":
            return {
                type: "VStack", properties: { alignment: "center", spacing: sp },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: r } }],
                children: [
                    mkSym("cloud.sun.fill", theme.accentColor, "largeTitle", "regular"),
                    mkText("72°F", "largeTitle", "bold"),
                    mkText("Partly Cloudy", "body", "regular", "secondary:1.0"),
                    {
                        type: "HStack", properties: { spacing: 16, alignment: "center" }, children: [
                            mkText("H: 78°", "caption", "semibold"),
                            mkText("L: 64°", "caption", "semibold", "secondary:1.0"),
                        ]
                    },
                ],
            };

        // For all remaining slot types, use a themed card with relevant icon + text
        default: {
            const intentLabel = (slot.intent || theme.itemNoun).replace(/^[a-z]/, (c) => c.toUpperCase());
            return {
                type: "VStack", properties: { alignment: "leading", spacing: sp },
                modifiers: [fullW, padAll, { type: "Background Color", properties: { color: cardBg } }, { type: "Corner Radius", properties: { radius: r } }],
                children: [
                    {
                        type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [
                            mkIconCircle(theme.mascotSymbol || "star.fill", `${ab}:0.15`, theme.accentColor),
                            mkText(intentLabel.length > 30 ? theme.appName : intentLabel, "headline", "bold"),
                        ]
                    },
                    mkText(theme.sharedFacts.primaryMetricValue, "title2", "bold", theme.accentColor),
                    mkText(theme.sharedFacts.secondaryMetricValue, "body", "regular", "secondary:1.0"),
                ],
            };
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN ASSEMBLY
// ═════════════════════════════════════════════════════════════════════════════

const ALL_RAIL_VARIANTS: RailVariant[] = ["media_track", "circular_people", "poster", "landscape", "chips"];

export function pickDistinctRailVariant(used: Set<RailVariant>, preferred: RailVariant[]): RailVariant {
    for (const p of preferred) {
        if (!used.has(p)) return p;
    }
    for (const candidate of ALL_RAIL_VARIANTS) {
        if (!used.has(candidate)) return candidate;
    }
    return preferred[0] ?? "poster";
}

export async function enforceRailDiversityAcrossSlots(params: {
    supabase: SupabaseClient | null;
    prompt: string;
    theme: ThemeTokens;
    plan: ScreenPlan;
    plannedSlots: SlotPlan[];
    slotResults: Array<{ component: AnyComponent; exemplarIds: string[] }>;
    deadlineAt: number;
    manifest?: DesignManifest;
    designSpec?: PromptDesignSpec;
}): Promise<Array<{ component: AnyComponent; exemplarIds: string[] }>> {
    const railIndices = params.plannedSlots
        .map((slot, i) => ({ slot, i }))
        .filter(({ slot }) => slot.slotType === "horizontal_rail")
        .map(({ i }) => i);
    if (railIndices.length <= 1) return params.slotResults;

    const manifest = params.manifest ?? buildDesignManifest(params.prompt);
    const usedVariants = new Set<RailVariant>();
    const nextResults = [...params.slotResults];

    for (const idx of railIndices) {
        const slot = params.plannedSlots[idx];
        const reqs = selectPromptRequirementsForSlot(slot, manifest.requirements);
        const preferred = reqs.map((r) => detectRailVariantFromRequirement(r));
        const actual = inferRailVariantFromComponent(nextResults[idx].component);

        if (!usedVariants.has(actual)) {
            usedVariants.add(actual);
            continue;
        }

        const forced = pickDistinctRailVariant(usedVariants, preferred);
        const forcedSlot: SlotPlan = {
            ...slot,
            variant_hint: `${slot.variant_hint ?? ""} | force distinct rail morphology: ${forced}`,
        };

        const remaining = params.deadlineAt - Date.now();
        if (remaining > 3800) {
            try {
                const forcedPlan: ScreenPlan = {
                    ...params.plan,
                    slots: params.plannedSlots.map((s, i) => (i === idx ? forcedSlot : s)),
                };
                const regenerated = await generateSlot({
                    supabase: params.supabase,
                    prompt: params.prompt,
                    theme: params.theme,
                    plan: forcedPlan,
                    slot: forcedSlot,
                    manifest,
                    designSpec: params.designSpec,
                });
                nextResults[idx] = regenerated;
                usedVariants.add(inferRailVariantFromComponent(regenerated.component));
                continue;
            } catch {
                // fall through to deterministic fallback
            }
        }

        nextResults[idx] = { component: buildFallbackSlot(forcedSlot, params.theme, params.designSpec), exemplarIds: [] };
        usedVariants.add(forced);
    }

    return nextResults;
}

export async function enforceSlotVarietyAcrossSlots(params: {
    supabase: SupabaseClient | null;
    prompt: string;
    theme: ThemeTokens;
    plan: ScreenPlan;
    plannedSlots: SlotPlan[];
    slotResults: Array<{ component: AnyComponent; exemplarIds: string[] }>;
    deadlineAt: number;
    manifest?: DesignManifest;
    designSpec?: PromptDesignSpec;
}): Promise<Array<{ component: AnyComponent; exemplarIds: string[] }>> {
    const nextResults = [...params.slotResults];
    const seenBySlotType = new Map<SlotType, Set<string>>();
    const manifest = params.manifest ?? buildDesignManifest(params.prompt);

    for (let i = 0; i < params.plannedSlots.length; i++) {
        const slot = params.plannedSlots[i];
        if (!nextResults[i]) continue;
        if (slot.slotType === "horizontal_rail") continue; // handled by dedicated rail diversity

        const signature = computeMorphologySignature(nextResults[i].component);
        const seen = seenBySlotType.get(slot.slotType) ?? new Set<string>();

        if (!seen.has(signature)) {
            seen.add(signature);
            seenBySlotType.set(slot.slotType, seen);
            continue;
        }

        if ((params.deadlineAt - Date.now()) <= 3800) continue;

        const diversifiedSlot: SlotPlan = {
            ...slot,
            variant_hint: `${slot.variant_hint ?? ""} | force morphology variation: change composition, spacing cadence, and visual anchor`,
        };
        try {
            const diversifiedPlan: ScreenPlan = {
                ...params.plan,
                slots: params.plannedSlots.map((s, idx) => (idx === i ? diversifiedSlot : s)),
            };
            const regenerated = await generateSlot({
                supabase: params.supabase,
                prompt: params.prompt,
                theme: params.theme,
                plan: diversifiedPlan,
                slot: diversifiedSlot,
                manifest,
                designSpec: params.designSpec,
            });
            nextResults[i] = regenerated;
            seen.add(computeMorphologySignature(regenerated.component));
            seenBySlotType.set(slot.slotType, seen);
        } catch {
            // keep original if diversification fails
        }
    }

    return nextResults;
}

export function inferSketchPrimitive(slot: SlotPlan, designSpec?: PromptDesignSpec): SketchPrimitive {
    const intent = (slot.intent || "").toLowerCase();
    const transportLike = /\b(uber|lyft|rideshare|pickup|dropoff|drop-off|destination|driver|eta|fare|route|trip|vehicle|cab|taxi)\b/.test(intent);
    const optionCompareLike = /\b(option|options|compare|fare|eta|tier|tiers|vehicle|ride)\b/.test(intent);
    const mapLike = /\b(map|route|pickup|destination|drivers?)\b/.test(intent);
    const actionLike = /\b(confirm|book|reserve|pickup|ride)\b/.test(intent);

    if (slot.slotType === "app_header" && transportLike) return "ContextHeader";
    if (slot.slotType === "app_header") return "SectionHeader";
    if (slot.slotType === "search_bar") return "SearchBarNative";
    if (slot.slotType === "stat_group") return "MetricCard";
    if (slot.slotType === "chart_section") return "SparklinePanel";
    if (slot.slotType === "timeline_list") return "TimelineSteps";
    if (slot.slotType === "story_rail") return "StoryRail";
    if (slot.slotType === "social_feed_slot") return "PostCardFeed";
    if (slot.slotType === "content_grid") return "ProductTileGrid";
    if (slot.slotType === "form_section") return "CredentialForm";
    if (slot.slotType === "map_preview" && mapLike) return "MapRouteStage";
    if (slot.slotType === "content_list" && optionCompareLike) return "OptionCompareStack";
    if (slot.slotType === "action_bar" && actionLike) return "StickyActionSplit";
    if (slot.slotType === "action_bar" && designSpec?.content.conceptTag === "modern_login") return "SocialSignInRow";
    if (slot.slotType === "hero_banner" && designSpec?.content.conceptTag === "modern_login") return "AuthHero";
    if (slot.slotType === "settings_list" && designSpec?.content.wantsSettingsToggles) return "ToggleRow";
    if (designSpec?.style.nativePattern === "appstore_search" && slot.slotType === "content_list") return "SuggestionRow";
    if (slot.slotType === "settings_list" || slot.slotType === "content_list") return "IconRow";
    if (slot.slotType === "horizontal_rail") return "RailItem";
    if (slot.slotType === "section_header") return "SectionHeader";
    if (slot.slotType === "hero_banner" || slot.slotType === "card_detail") return "HeroPanel";
    return "IconRow";
}

export function buildLayoutSketch(plan: ScreenPlan, designSpec?: PromptDesignSpec): LayoutSketch {
    return {
        mode: "sketch_v1",
        nodes: plan.slots.slice(0, MAX_GENERATION_SLOTS).map((slot, idx) => ({
            slotType: slot.slotType,
            position: slot.position,
            intent: slot.intent,
            itemCount: slot.itemCount,
            primitive: inferSketchPrimitive(slot, designSpec),
            emphasis: slot.slotType === "hero_banner" || slot.slotType === "card_detail"
                ? "high"
                : idx <= 2
                ? "medium"
                : "low",
        })),
    };
}

export function materializeSlotFromSketchNode(node: LayoutSketchNode): SlotPlan {
    const primitiveHint: Record<SketchPrimitive, string> = {
        MetricCard: "metric cards with strong value hierarchy",
        IconRow: "icon-led informative rows with trailing affordance",
        ToggleRow: "settings toggle rows with native switch controls",
        SuggestionRow: "flat suggestion rows with divider rhythm",
        RailItem: "rail items with distinct morphology and readable labels",
        SectionHeader: "section hierarchy title row",
        HeroPanel: "focal hero panel with clear visual anchor",
        AuthHero: "auth brand hero with modern hierarchy",
        CredentialForm: "credential form block with passkey affordances",
        SocialSignInRow: "social sign in action stack",
        StoryRail: "stories rail with circular avatars",
        PostCardFeed: "social post cards with media and actions",
        SearchBarNative: "native search bar chrome",
        SparklinePanel: "sparkline/chart panel with summary labels",
        TimelineSteps: "timeline progression steps with connector rhythm",
        ProductTileGrid: "product tile grid with media and price metadata",
        ContextHeader: "context-aware header with location and identity metadata",
        MapRouteStage: "map-first live route stage with pickup and destination layers",
        OptionCompareStack: "comparative option cards with price eta and service badges",
        StickyActionSplit: "dual-action booking bar with secondary reserve and primary confirm",
    };
    return {
        slotType: node.slotType,
        position: node.position,
        intent: node.intent,
        itemCount: node.itemCount,
        variant_hint: primitiveHint[node.primitive],
    };
}

export function renderPrimitiveDeterministically(
    node: LayoutSketchNode,
    theme: ThemeTokens,
    surfaces: ThemeSurfaces,
    designSpec?: PromptDesignSpec,
): AnyComponent {
    const mkText = (text: string, size: string, weight: string, color?: string): AnyComponent => {
        const mods: Array<Record<string, unknown>> = [{ type: "Font", properties: { fontSize: size, fontWeight: weight } }];
        if (color) mods.push({ type: "Foreground Color", properties: { color } });
        return { type: "Text", properties: { text }, modifiers: mods };
    };
    const mkSym = (symbolName: string, color: string, size = "body"): AnyComponent => ({
        type: "SF Symbol",
        properties: { symbolName },
        modifiers: [
            { type: "Foreground Color", properties: { color } },
            { type: "Font", properties: { fontSize: size, fontWeight: "regular" } },
        ],
    });
    const fullW = { type: "Frame", properties: { widthType: "Full", heightType: "Default" } };

    if (node.primitive === "SearchBarNative" || node.slotType === "search_bar") {
        return {
            type: "HStack",
            properties: { spacing: 10, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.subtleFill } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow + 6 } }],
            children: [mkSym("magnifyingglass", surfaces.iconTint, "title3"), { type: "Text Field", properties: { placeholder: "Search", text: "" }, modifiers: [fullW] }],
        };
    }

    if (node.primitive === "ContextHeader") {
        return {
            type: "HStack",
            properties: { spacing: 12, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 8, location: "horizontal" } }, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 2 },
                    modifiers: [fullW],
                    children: [
                        mkText("Pickup", "caption", "semibold", surfaces.secondaryText),
                        mkText("Apple Park Visitor Center", "headline", "bold"),
                    ],
                },
            ],
        };
    }

    if (node.primitive === "AuthHero") {
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
            children: [
                mkText(`Welcome to ${theme.appName}`, "title", "bold"),
                mkText("Sign in to continue with secure passkeys and seamless sync.", "body", "regular", surfaces.secondaryText),
            ],
        };
    }

    if (node.primitive === "CredentialForm") {
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: surfaces.cornerCard } }],
            children: [
                mkText("Email", "caption", "semibold", surfaces.secondaryText),
                { type: "Text Field", properties: { placeholder: "you@example.com", text: "" }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.12" } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow } }] },
                mkText("Password", "caption", "semibold", surfaces.secondaryText),
                { type: "Text Field", properties: { placeholder: "Password", text: "" }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.12" } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow } }] },
                {
                    type: "HStack",
                    properties: { spacing: 8, alignment: "center" },
                    children: [mkSym("faceid", surfaces.iconTint), mkText("Use Passkey", "subheadline", "semibold", theme.accentColor), { type: "Spacer" }, mkText("Forgot?", "subheadline", "semibold", theme.accentColor)],
                },
            ],
        };
    }

    if (node.primitive === "SocialSignInRow") {
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            modifiers: [fullW],
            children: [
                {
                    type: "Button",
                    properties: { buttonStyle: "plain" },
                    children: [{
                        type: "HStack",
                        properties: { spacing: 8, alignment: "center" },
                        modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: "white:1.0" } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow } }],
                        children: [mkSym("apple.logo", "black:1.0"), mkText("Continue with Apple", "body", "semibold", "black:1.0"), { type: "Spacer" }],
                    }],
                },
                {
                    type: "Button",
                    properties: { buttonStyle: "plain" },
                    children: [{
                        type: "Text",
                        properties: { text: "Sign In" },
                        modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Foreground Color", properties: { color: "white:1.0" } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow } }, { type: "Font", properties: { fontSize: "headline", fontWeight: "bold" } }],
                    }],
                },
            ],
        };
    }

    if (node.primitive === "MapRouteStage") {
        return {
            type: "ZStack",
            properties: { alignment: "topLeading" },
            modifiers: [fullW],
            children: [
                {
                    type: "Map",
                    properties: {
                        latitude: 37.3346,
                        longitude: -122.0090,
                        latitudeDelta: 0.018,
                        longitudeDelta: 0.018,
                        mapStyle: "standard",
                        interactionModes: "all",
                        showsCompass: true,
                        showsScale: false,
                        showsUserLocation: false,
                        showsTraffic: true,
                        locationName: "Apple Park, Cupertino",
                        markers: "[{\"latitude\":37.3329,\"longitude\":-122.0054,\"title\":\"Pickup\",\"tint\":\"green:1.0\"},{\"latitude\":37.3388,\"longitude\":-122.0112,\"title\":\"Destination\",\"tint\":\"blue:1.0\"}]",
                    },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 306 } },
                        { type: "Corner Radius", properties: { radius: surfaces.cornerCard + 8 } },
                        { type: "Clip Shape", properties: { shape: "Rectangle" } },
                    ],
                },
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 16 },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 306 } },
                        { type: "Padding", properties: { amount: 18, location: "all" } },
                    ],
                    children: [
                        {
                            type: "HStack",
                            properties: { spacing: 8, alignment: "center" },
                            children: [
                                mkText("Pickup in 4 min", "caption", "semibold", theme.accentColor),
                                { type: "Spacer" },
                                mkSym("location.north.line.fill", theme.accentColor, "body"),
                            ],
                        },
                        { type: "Spacer" },
                        {
                            type: "VStack",
                            properties: { alignment: "leading", spacing: 10 },
                            modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: "white:0.92" } }, { type: "Corner Radius", properties: { radius: 22 } }],
                            children: [
                                { type: "HStack", properties: { spacing: 10, alignment: "center" }, children: [mkSym("circle.fill", "green:0.95", "caption"), { type: "VStack", properties: { alignment: "leading", spacing: 2 }, modifiers: [fullW], children: [mkText("Pickup", "subheadline", "bold"), mkText("Apple Park Visitor Center", "caption", "regular", surfaces.secondaryText)] }] },
                                { type: "HStack", properties: { spacing: 10, alignment: "center" }, children: [mkSym("mappin.circle.fill", theme.accentColor, "body"), { type: "VStack", properties: { alignment: "leading", spacing: 2 }, modifiers: [fullW], children: [mkText("Destination", "subheadline", "bold"), mkText("Infinite Loop", "caption", "regular", surfaces.secondaryText)] }] },
                            ],
                        },
                    ],
                },
            ],
        };
    }

    if (node.primitive === "StoryRail") {
        const users = ["You", "Alex", "Mia", "Noah", "Sara", "Kai", "Luna", "Leo"];
        return {
            type: "ScrollView",
            properties: { axis: "horizontal", showsIndicators: false },
            children: [{
                type: "HStack",
                properties: { spacing: 12, alignment: "top" },
                children: users.map((u, i) => ({
                    type: "VStack",
                    properties: { alignment: "center", spacing: 4 },
                    children: [
                        { type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 58, heightType: "Custom", height: 58 } }, { type: i === 0 ? "Fill" : "Stroke", properties: i === 0 ? { color: "gray:0.18" } : { color: theme.accentColor, lineWidth: 2 } }] },
                        mkText(u, "caption2", "regular", surfaces.secondaryText),
                    ],
                } as AnyComponent)),
            }],
        };
    }

    if (node.primitive === "PostCardFeed") {
        const posts = ["sunset vibes", "new drop", "city run"];
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 16 },
            children: posts.map((p) => ({
                type: "VStack",
                properties: { alignment: "leading", spacing: 10 },
                modifiers: [fullW],
                children: [
                    { type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 30, heightType: "Custom", height: 30 } }, { type: "Fill", properties: { color: "gray:0.22" } }] }, mkText("username", "subheadline", "semibold"), { type: "Spacer" }, mkSym("ellipsis", surfaces.iconTint)] },
                    { type: "RoundedRectangle", properties: { cornerRadius: 12 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 280 } }, { type: "Fill", properties: { color: "gray:0.16" } }] },
                    { type: "HStack", properties: { spacing: 14, alignment: "center" }, children: [mkSym("heart", surfaces.primaryText), mkSym("bubble.right", surfaces.primaryText), mkSym("paperplane", surfaces.primaryText), { type: "Spacer" }, mkSym("bookmark", surfaces.primaryText)] },
                    mkText("1,024 likes", "caption", "semibold"),
                    mkText(`username ${p}`, "subheadline", "regular"),
                    mkText("2h", "caption2", "regular", surfaces.secondaryText),
                    { type: "Divider" },
                ],
            } as AnyComponent)),
        };
    }

    if (node.primitive === "MetricCard") {
        const rows = theme.sampleMetrics.slice(0, Math.max(3, Math.min(5, node.itemCount ?? 4)));
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            children: rows.map((m, idx) => {
                const [label, value, trend] = m.split(":");
                return {
                    type: "HStack",
                    properties: { spacing: 12, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: surfaces.cornerCard } }],
                    children: [
                        { type: "VStack", properties: { alignment: "leading", spacing: 3 }, modifiers: [fullW], children: [mkText(label || "Metric", "headline", "semibold"), mkText(value || "0", "title2", "bold"), mkText(trend || "", "body", "semibold", idx % 2 === 0 ? "green:1.0" : "purple:1.0")] },
                        { type: "RoundedRectangle", properties: { cornerRadius: 10 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 138, heightType: "Custom", height: 70 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] },
                    ],
                } as AnyComponent;
            }),
        };
    }

    if (node.primitive === "OptionCompareStack") {
        const optionRows = [
            { title: "Go", subtitle: "Fast pickup", trailing: "$14.90", badge: "Best value" },
            { title: "Priority", subtitle: "Shorter wait", trailing: "$18.40", badge: "Fastest" },
            { title: "Comfort", subtitle: "More space", trailing: "$24.20", badge: "Premium" },
            { title: "Reserve", subtitle: "Leave later", trailing: "Schedule", badge: "Planned" },
        ];
        const options = optionRows.slice(0, Math.max(3, Math.min(4, node.itemCount ?? 4)));
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            children: options.map((option, idx) => ({
                type: "HStack",
                properties: { spacing: 12, alignment: "center" },
                modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: idx === 0 ? surfaces.cardFill : surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 22 } }],
                children: [
                    {
                        type: "ZStack",
                        children: [
                            { type: "Circle", properties: {}, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 44, heightType: "Custom", height: 44 } }, { type: "Fill", properties: { color: `${theme.accentColor.split(":")[0]}:0.12` } }] },
                            mkSym(idx === 0 ? "car.fill" : idx === 1 ? "figure.seated.side.air.upper" : idx === 2 ? "sparkles" : "calendar.badge.clock", theme.accentColor, "body"),
                        ],
                    },
                    {
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 3 },
                        modifiers: [fullW],
                        children: [
                            {
                                type: "HStack",
                                properties: { spacing: 8, alignment: "center" },
                                modifiers: [fullW],
                                children: [
                                    mkText(option.title, "headline", "bold"),
                                    {
                                        type: "Text",
                                        properties: { text: option.badge },
                                        modifiers: [
                                            { type: "Padding", properties: { amount: 8, location: "horizontal" } },
                                            { type: "Padding", properties: { amount: 4, location: "vertical" } },
                                            { type: "Background Color", properties: { color: `${theme.accentColor.split(":")[0]}:0.10` } },
                                            { type: "Corner Radius", properties: { radius: 999 } },
                                            { type: "Font", properties: { fontSize: "caption2", fontWeight: "semibold" } },
                                            { type: "Foreground Color", properties: { color: theme.accentColor } },
                                        ],
                                    },
                                    { type: "Spacer" },
                                    mkText(option.trailing, "headline", "bold", theme.accentColor),
                                ],
                            },
                            mkText(option.subtitle, "subheadline", "regular", surfaces.secondaryText),
                        ],
                    },
                ],
            }) as AnyComponent),
        };
    }

    if (node.primitive === "SparklinePanel") {
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: surfaces.cornerCard } }],
            children: [
                mkText("Trend", "headline", "bold"),
                { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 120 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] },
                mkText("Updated just now", "caption", "regular", surfaces.secondaryText),
            ],
        };
    }

    if (node.primitive === "TimelineSteps") {
        const steps = ["Start", "Checkpoint", "Review", "Complete"];
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 6 },
            children: steps.map((s, i) => ({
                type: "HStack",
                properties: { spacing: 10, alignment: "top" },
                children: [
                    { type: "VStack", properties: { alignment: "center", spacing: 0 }, children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 12, heightType: "Custom", height: 12 } }, { type: "Fill", properties: { color: i === 0 ? theme.accentColor : "gray:0.28" } }] }, ...(i < steps.length - 1 ? [{ type: "Rectangle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 2, heightType: "Custom", height: 30 } }, { type: "Fill", properties: { color: "gray:0.20" } }] } as AnyComponent] : [])] },
                    { type: "VStack", properties: { alignment: "leading", spacing: 2 }, children: [mkText(s, "body", "semibold"), mkText("Status update", "caption", "regular", surfaces.secondaryText)] },
                ],
            } as AnyComponent)),
        };
    }

    if (node.primitive === "ProductTileGrid") {
        const items = theme.sampleRailItems.slice(0, 6);
        const tiles = items.map((t) => ({
            type: "VStack",
            properties: { alignment: "leading", spacing: 8 },
            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow } }],
            children: [{ type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 90 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }, mkText(t, "subheadline", "semibold"), mkText("$99", "caption", "regular", surfaces.secondaryText)],
        } as AnyComponent));
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            children: [0, 1, 2].map((r) => ({ type: "HStack", properties: { spacing: 10, alignment: "top" }, modifiers: [fullW], children: tiles.slice(r * 2, r * 2 + 2) } as AnyComponent)),
        };
    }

    if (node.primitive === "SuggestionRow") {
        const n = Math.max(4, Math.min(12, node.itemCount ?? 8));
        const symbols = ["magnifyingglass", "magnifyingglass", "apple.logo", "person.crop.square", "arcade.stick", "applewatch"];
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 0 },
            children: Array.from({ length: n }).flatMap((_, i) => ([
                {
                    type: "HStack",
                    properties: { spacing: 12, alignment: "center" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
                    children: [mkSym(symbols[i % symbols.length], surfaces.iconTint, "title3"), { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [fullW], children: [mkText(`Result ${i + 1}`, "title3", "regular"), mkText(i % 2 === 0 ? "Matched in title • Updated today" : "Secondary metadata • Relevant match", "body", "regular", "gray:0.65")] }],
                } as AnyComponent,
                { type: "Divider" } as AnyComponent,
            ])),
        };
    }

    if (node.primitive === "ToggleRow") {
        const rows = [
            { label: "Notifications", sym: "bell.fill", on: true },
            { label: "Dark Mode", sym: "moon.fill", on: false },
            { label: "Sound", sym: "speaker.wave.2.fill", on: true },
        ];
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: surfaces.spacing },
            children: rows.map((r) => ({
                type: "HStack",
                properties: { spacing: 12, alignment: "center" },
                modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: surfaces.cornerRow } }],
                children: [mkSym(r.sym, theme.accentColor, "body"), mkText(r.label, "body", "regular"), { type: "Spacer" }, { type: "Switch", properties: { isOn: r.on } }],
            } as AnyComponent)),
        };
    }

    if (node.primitive === "StickyActionSplit") {
        const primaryPrice = theme.sampleItems.find((item) => item.includes("$"))?.split(":")[2]?.trim() || "$14.90";
        return {
            type: "VStack",
            properties: { alignment: "leading", spacing: 12 },
            modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: "white:0.94" } }],
            children: [
                { type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 2 }, modifiers: [fullW], children: [mkText("Pickup now", "subheadline", "bold"), mkText("Trip ready to confirm", "caption", "regular", surfaces.secondaryText)] }, mkText(primaryPrice, "title3", "bold", theme.accentColor)] },
                {
                    type: "HStack",
                    properties: { spacing: 10, alignment: "center" },
                    modifiers: [fullW],
                    children: [
                        { type: "Text", properties: { text: "Reserve" }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: theme.surfaceStyle === "immersive" ? "white:0.16" : "gray:0.14" } }, { type: "Corner Radius", properties: { radius: 18 } }, { type: "Font", properties: { fontSize: "headline", fontWeight: "semibold" } }, { type: "Text Alignment", properties: { alignment: "center" } }] },
                        { type: "Text", properties: { text: "Choose Ride" }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Foreground Color", properties: { color: "white:1.0" } }, { type: "Corner Radius", properties: { radius: 18 } }, { type: "Font", properties: { fontSize: "headline", fontWeight: "bold" } }, { type: "Text Alignment", properties: { alignment: "center" } }] },
                    ],
                },
            ],
        };
    }

    if (node.primitive === "SectionHeader") {
        return {
            type: "HStack",
            properties: { spacing: 0, alignment: "center" },
            modifiers: [fullW],
            children: [mkText(theme.appName, "headline", "bold")],
        };
    }

    const fallbackSlot = materializeSlotFromSketchNode(node);
    return buildFallbackSlot(fallbackSlot, theme, designSpec);
}

export function shouldRenderSlotDeterministically(
    node: LayoutSketchNode,
    designSpec?: PromptDesignSpec,
): boolean {
    if (GEN_V3_SKETCH_RENDER) return true;

    const nativePattern = designSpec?.style.nativePattern;
    const conceptTag = designSpec?.content.conceptTag;

    if (node.primitive === "SearchBarNative" || node.primitive === "SuggestionRow") {
        return nativePattern === "appstore_search";
    }

    if (node.primitive === "AuthHero" || node.primitive === "CredentialForm" || node.primitive === "SocialSignInRow") {
        return conceptTag === "modern_login";
    }

    if (node.primitive === "ToggleRow") {
        return Boolean(designSpec?.content.wantsSettingsToggles);
    }

    if (node.primitive === "StoryRail") {
        return conceptTag === "instagram_home";
    }

    return false;
}


export function emptySlotMemory(): SlotMemory {
    return { colorsUsed: [], symbolsUsed: [], layoutPatterns: [], dataPointsShown: [], sectionCount: 0 };
}

export function uniquePush(target: string[], values: string[], limit = 24): void {
    for (const value of values) {
        const trimmed = value.trim();
        if (!trimmed || target.includes(trimmed)) continue;
        target.push(trimmed);
        if (target.length >= limit) return;
    }
}

export function extractSlotMemory(component: AnyComponent): Partial<SlotMemory> {
    const colors: string[] = [];
    const symbols: string[] = [];
    const data: string[] = [];
    walkComponentTree(component, (node) => {
        if (Array.isArray(node.modifiers)) {
            for (const mod of node.modifiers) {
                if (!isObject(mod) || !isObject(mod.properties)) continue;
                const color = (mod.properties as Record<string, unknown>).color;
                if (typeof color === "string" && color.trim()) colors.push(color.trim());
            }
        }
        if (node.type === "SF Symbol" && isObject(node.properties)) {
            const symbol = node.properties.symbolName;
            if (typeof symbol === "string" && symbol.trim()) symbols.push(symbol.trim());
        }
        if (node.type === "Text" && isObject(node.properties)) {
            const text = node.properties.text;
            if (typeof text === "string" && /\d|%|\$|day|streak|Alex|Maya|today/i.test(text)) data.push(text.trim());
        }
    });
    return {
        colorsUsed: Array.from(new Set(colors)).slice(0, 8),
        symbolsUsed: Array.from(new Set(symbols)).slice(0, 8),
        layoutPatterns: [computeMorphologySignature(component)].filter(Boolean),
        dataPointsShown: Array.from(new Set(data)).slice(0, 8),
        sectionCount: 1,
    };
}

export function mergeSlotMemory(memory: SlotMemory, partial: Partial<SlotMemory>): SlotMemory {
    const next: SlotMemory = { ...memory, colorsUsed: [...memory.colorsUsed], symbolsUsed: [...memory.symbolsUsed], layoutPatterns: [...memory.layoutPatterns], dataPointsShown: [...memory.dataPointsShown], sectionCount: memory.sectionCount + (partial.sectionCount ?? 0) };
    uniquePush(next.colorsUsed, partial.colorsUsed ?? []);
    uniquePush(next.symbolsUsed, partial.symbolsUsed ?? []);
    uniquePush(next.layoutPatterns, partial.layoutPatterns ?? []);
    uniquePush(next.dataPointsShown, partial.dataPointsShown ?? []);
    return next;
}

export function formatSlotMemory(memory?: SlotMemory): string {
    if (!memory || memory.sectionCount === 0) return "";
    return `ALREADY GENERATED IN THIS SCREEN:\nColors used: ${memory.colorsUsed.join(", ") || "none"}\nSymbols used: ${memory.symbolsUsed.join(", ") || "none"}\nLayout patterns used: ${memory.layoutPatterns.join(" | ") || "none"}\nData shown: ${memory.dataPointsShown.map((v) => `"${v}"`).join(", ") || "none"}\n→ Use different symbols, avoid repeating the same layout pattern, don't repeat data values already shown.`;
}

export function checkMorphologyDuplicate(slot: SlotPlan, component: AnyComponent, usedMorphologies: Map<SlotType, Set<string>>): string[] {
    const signature = computeMorphologySignature(component);
    if (!signature) return [];
    const usedForType = usedMorphologies.get(slot.slotType);
    if (usedForType?.has(signature)) return [`Duplicate morphology for ${slot.slotType}: ${signature}`];
    return [];
}

export function checkRailVariantDuplicate(slot: SlotPlan, component: AnyComponent, usedRailVariants: Set<RailVariant>): string[] {
    if (slot.slotType !== "horizontal_rail") return [];
    const variant = inferRailVariantFromComponent(component);
    if (usedRailVariants.has(variant)) return [`Duplicate horizontal rail variant: ${variant}`];
    return [];
}

export function scoreSlotOutput(
    slot: SlotPlan,
    component: AnyComponent,
    requirements: PromptRequirement[],
    usedMorphologies: Map<SlotType, Set<string>>,
    usedRailVariants: Set<RailVariant>,
    designSpec?: PromptDesignSpec,
): { pass: boolean; blockers: string[] } {
    const blockers = Array.from(new Set([
        ...validateSlotAgainstPromptRequirements(slot, component, requirements),
        ...validateStrictIntentLocksForSlot(slot, component, designSpec),
        ...checkMorphologyDuplicate(slot, component, usedMorphologies),
        ...checkRailVariantDuplicate(slot, component, usedRailVariants),
    ]));
    return { pass: blockers.length === 0, blockers };
}

export function rememberAcceptedSlot(slot: SlotPlan, component: AnyComponent, usedMorphologies: Map<SlotType, Set<string>>, usedRailVariants: Set<RailVariant>): void {
    const signature = computeMorphologySignature(component);
    if (signature) {
        const set = usedMorphologies.get(slot.slotType) ?? new Set<string>();
        set.add(signature);
        usedMorphologies.set(slot.slotType, set);
    }
    if (slot.slotType === "horizontal_rail") usedRailVariants.add(inferRailVariantFromComponent(component));
}

export async function generateSlotsParallel(params: {
    supabase: SupabaseClient | null;
    prompt: string;
    theme: ThemeTokens;
    plan: ScreenPlan;
    plannedSlots: SlotPlan[];
    manifest: DesignManifest;
    designSpec: PromptDesignSpec;
    deadlineAt: number;
    withDeadline: <T>(work: Promise<T>, stage: string) => Promise<T>;
    surfaces: ThemeSurfaces;
    generationMode?: GenerationMode;
}): Promise<Array<{ component: AnyComponent; exemplarIds: string[] }>> {
    const isFullCanvas = params.generationMode === "full_canvas";
    const batchSize = isFullCanvas ? FULL_CANVAS_SLOT_BATCH_SIZE : SLOT_BATCH_SIZE;

    if ((params.deadlineAt - Date.now()) <= SLOT_BATCH_GRACE_MS) {
        return params.plannedSlots.map((slot) => ({ component: buildFallbackSlot(slot, params.theme, params.designSpec), exemplarIds: [] }));
    }

    const results: Array<{ component: AnyComponent; exemplarIds: string[] }> = [];
    let memory = emptySlotMemory();
    const usedMorphologies = new Map<SlotType, Set<string>>();
    const usedRailVariants = new Set<RailVariant>();

    for (let start = 0; start < params.plannedSlots.length; start += batchSize) {
        const batch = params.plannedSlots.slice(start, start + batchSize);
        const tasks = batch.map((slot) => params.withDeadline((async () => {
            const sketchNode: LayoutSketchNode = {
                slotType: slot.slotType,
                position: slot.position,
                intent: slot.intent,
                itemCount: slot.itemCount,
                primitive: inferSketchPrimitive(slot, params.designSpec),
                emphasis: slot.slotType === "hero_banner" ? "high" : "medium",
            };

            if (shouldRenderSlotDeterministically(sketchNode, params.designSpec)) {
                return {
                    slot,
                    result: {
                        component: renderPrimitiveDeterministically(sketchNode, params.theme, params.surfaces, params.designSpec),
                        exemplarIds: [],
                    },
                };
            }

            const requirements = selectPromptRequirementsForSlot(slot, params.manifest.requirements);
            let result = await generateSlot({
                supabase: params.supabase,
                prompt: params.prompt,
                theme: params.theme,
                plan: params.plan,
                slot,
                manifest: params.manifest,
                designSpec: params.designSpec,
                memory,
                generationMode: params.generationMode,
            });
            const score = scoreSlotOutput(slot, result.component, requirements, usedMorphologies, usedRailVariants, params.designSpec);
            if (!score.pass && (params.deadlineAt - Date.now()) > 3500) {
                const fixedSlot: SlotPlan = { ...slot, variant_hint: `${slot.variant_hint ?? ""} STRICT FIX REQUIRED: ${score.blockers.join(" | ")}`.trim() };
                result = await generateSlot({
                    supabase: params.supabase,
                    prompt: params.prompt,
                    theme: params.theme,
                    plan: params.plan,
                    slot: fixedSlot,
                    manifest: params.manifest,
                    designSpec: params.designSpec,
                    memory,
                    blockers: score.blockers,
                    generationMode: params.generationMode,
                });
            }
            return { slot, result };
        })(), `slot:${slot.slotType}`));
        const settled = await Promise.allSettled(tasks);
        for (let i = 0; i < settled.length; i++) {
            const slot = batch[i];
            const settledResult = settled[i];
            const value = settledResult.status === "fulfilled" ? settledResult.value.result : { component: buildFallbackSlot(slot, params.theme, params.designSpec), exemplarIds: [] };
            results.push(value);
            rememberAcceptedSlot(slot, value.component, usedMorphologies, usedRailVariants);
            memory = mergeSlotMemory(memory, extractSlotMemory(value.component));
        }
    }
    return results;
}


// Repair and exemplar retrieval are implementation stages of slot generation.
// ─── Repair ──────────────────────────────────────────────────────────────────

export function cheapRepair(component: AnyComponent): { component: AnyComponent; issues: string[] } {
    const issues: string[] = [];
    const visit = (node: AnyComponent): AnyComponent => {
        if (node.type === "Button" && (!Array.isArray(node.children) || node.children.length === 0)) {
            node.children = [{ type: "Text", properties: { text: "Button" }, modifiers: [{ type: "Font", properties: { fontSize: "body", fontWeight: "semibold" } }] }];
            issues.push("Added missing Button child");
        }
        if (node.type === "ScrollView") {
            if (!Array.isArray(node.children) || node.children.length === 0) {
                node.children = [{ type: "VStack", properties: { alignment: "leading", spacing: 16 }, modifiers: [], children: [] }];
                issues.push("Added missing ScrollView child");
            } else if (node.children.length > 1) {
                node.children = [{ type: "VStack", properties: { alignment: "leading", spacing: 16 }, modifiers: [], children: node.children }];
                issues.push("Wrapped multiple ScrollView children");
            }
        }
        if (node.type === "Text") {
            const props = isObject(node.properties) ? node.properties : {};
            if (typeof props.text !== "string" || props.text.trim() === "") {
                props.text = "Text";
                node.properties = props;
                issues.push("Fixed empty Text");
            }
        }
        if (Array.isArray(node.modifiers)) {
            const hasCornerRadius = node.modifiers.some((m) => (m as Record<string, unknown>).type === "Corner Radius");
            if (hasCornerRadius) {
                node.modifiers = node.modifiers.map((m) => {
                    const mod = m as Record<string, unknown>;
                    return mod.type === "Border" ? { ...mod, type: "Stroke" } : mod;
                });
            }
        }
        if (Array.isArray(node.children)) node.children = node.children.map(visit);
        return node;
    };
    return { component: visit(component), issues };
}

export const REPAIR_SYSTEM_PROMPT = `Fix schema errors in the SwiftUI JSON. Output ONLY the corrected JSON: { "component": <UIComponent> }
CONTAINERS (must have children[]): VStack, HStack, ZStack, ScrollView, Button
LEAVES (delete children if present): Text, Image, SF Symbol, Shape, Chart, Spacer, Divider, Rectangle, Circle, RoundedRectangle, Capsule, Ellipse, Linear Gradient, Text Field, Switch, Slider, Progress View, Status Bar, Gauge, Map
Invalid type: row/cell->HStack | card/stat->VStack | label/title->Text | icon->SF Symbol | graph->Chart | progress/progressbar->Progress View
Invalid modifier: remove it. Button with Background Color on label: buttonStyle="plain"
Shape color rule: Background Color on shape -> convert to Fill. Text.properties.text must be non-empty. Fix ALL errors.
Border vs Stroke rule: if a node has a Corner Radius modifier, convert any "Border" modifier to "Stroke" (keep same properties).
Color format: always "colorname:opacity" e.g. "blue:1.0", "gray:0.12"`;

export function buildRepairPrompt(slot: SlotPlan, issues: string[]): string {
    const constraint = SLOT_CONSTRAINTS[slot.slotType];
    return `${REPAIR_SYSTEM_PROMPT}

TARGET SLOT: ${slot.slotType}
SLOT ROLE: ${constraint.description}
ALLOWED ROOT TYPES: ${constraint.allowedRoots.join(", ")}
MAX DEPTH: ${constraint.maxDepth}

SPECIFIC VIOLATIONS TO FIX:
${issues.map((i) => `- ${i}`).join("\n")}

Fix ONLY these violations. Preserve all other structure, content, and styling exactly.`;
}

export async function compileWithRepairMessages(params: {
    messages: Array<Record<string, unknown>>;
    maxAttempts: number;
    model?: string;
    maxTokens?: number;
    repairModel?: string;
    repairMaxTokens?: number;
}) {
    let lastError = "";
    let lastContent = "";
    let attempt = 0;

    while (attempt < params.maxAttempts) {
        const isFirst = attempt === 0;
        const messages = isFirst ? params.messages : [
            { role: "system", content: REPAIR_SYSTEM_PROMPT },
            { role: "user", content: `Previous JSON:\n${lastContent}\n\nErrors:\n${lastError}` },
        ];

        const response = await callOpenAI({
            model: isFirst ? (params.model ?? SELECTION_MODEL) : (params.repairModel ?? REPAIR_MODEL),
            messages, temperature: 0,
            maxTokens: isFirst ? (params.maxTokens ?? SELECTION_MAX_TOKENS) : (params.repairMaxTokens ?? REPAIR_MAX_TOKENS),
            responseFormat: { type: "json_object" },
        });

        if (!response.ok) return { ok: false as const, error: response.error };
        lastContent = response.content;
        const parsed = parseJsonSafe(response.content);
        if (isJsonParseError(parsed)) { lastError = parsed.error; attempt++; continue; }
        if (!isObject(parsed.value)) { lastError = "Response is not an object"; attempt++; continue; }

        const result = parsed.value as Record<string, unknown>;
        const raw = result.component ?? (Array.isArray(result.components) ? result.components[0] : null);

        if (!raw && isObject(result.canvas_settings)) {
            return { ok: true as const, parsed: { mode: "canvas", canvas_settings: result.canvas_settings } };
        }
        if (!isObject(raw)) { lastError = "Missing component in response"; attempt++; continue; }

        const { component: cheapFixed } = cheapRepair(raw as AnyComponent);
        const fixed = postProcessComponents([cheapFixed])[0];
        if (!VALID_COMPONENT_TYPES.has(fixed.type)) { lastError = `Invalid component type: ${fixed.type}`; attempt++; continue; }
        return { ok: true as const, parsed: { mode: "component", component: fixed, canvas_settings: result.canvas_settings } };
    }
    return { ok: false as const, error: `Failed after ${params.maxAttempts} attempts: ${lastError}` };
}

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
    supabase: SupabaseClient | null;
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
