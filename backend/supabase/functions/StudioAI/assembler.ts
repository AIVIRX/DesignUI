import type { SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { AnyComponent, CanvasSettings, GenerationMode, ScreenArchetype, ScreenPlan, SlotPosition, ThemeTokens } from "./types.ts";
import { FULL_CANVAS_SLOT_PLANNER_MAX_TOKENS, GENERATION_DEADLINE_MS, GEN_V3_SKETCH_RENDER, MAX_GENERATION_SLOTS } from "./openai.ts";
import { buildDesignManifest, compilePromptDesignSpec, enforcePlanRequirements } from "./manifest.ts";
import { classifyArchetype, compileScreenIRToPlan, defaultPlanFromArchetype, extractScreenIR, extractSemanticIntent, planSlots, refineScreenPlan, resolveScreenContract } from "./planner.ts";
import { buildFallbackSlot, buildLayoutSketch, generateSlotsParallel, materializeSlotFromSketchNode } from "./slot-generator.ts";
import { buildBaselineTheme, computeThemeSurfaces, extractThemeTokens } from "./theme.ts";
import { reviewScreen } from "./screen-quality.ts";
import type { ScreenIssue } from "./screen-quality.ts";
import { generateSlot } from "./slot-generator.ts";
import { postProcessComponents } from "./postprocess.ts";

export async function buildGeneratedScreen(
    supabase: SupabaseClient | null,
    prompt: string,
    context: unknown,
    mode: GenerationMode,
): Promise<{
    components: AnyComponent[];
    canvas_settings: CanvasSettings;
    theme?: ThemeTokens;
    exemplarsUsed?: string[];
    quality?: ScreenIssue[];
}> {
    const deadlineAt = Date.now() + GENERATION_DEADLINE_MS;
    const withDeadline = async <T>(work: Promise<T>, stage: string): Promise<T> => {
        const startedAt = Date.now();
        const remaining = deadlineAt - Date.now();
        if (remaining <= 0) throw new Error(`Generation deadline exceeded before ${stage}`);
        let timer: ReturnType<typeof setTimeout> | undefined;
        const timeout = new Promise<T>((_, reject) => {
            timer = setTimeout(() => reject(new Error(`Generation timed out during ${stage}`)), remaining);
        });
        try {
            return await Promise.race([work, timeout]);
        } finally {
            if (timer !== undefined) clearTimeout(timer);
            console.info(JSON.stringify({ event: "generation_stage", stage, elapsed_ms: Date.now() - startedAt, remaining_ms: Math.max(0, deadlineAt - Date.now()) }));
        }
    };

    if (mode === "full_canvas") {
        const manifest = buildDesignManifest(prompt);
        const designSpec = compilePromptDesignSpec(prompt, manifest);
        // Step 1: Archetype + Theme in parallel
        const [theme, archetype, semanticIntent] = await withDeadline(
            Promise.all([extractThemeTokens(prompt), classifyArchetype(prompt), extractSemanticIntent(prompt)]),
            "theme/archetype/semantic-intent",
        );
        const surfaces = computeThemeSurfaces(theme);
        const contract = resolveScreenContract(prompt, designSpec, semanticIntent);
        // Step 2: Plan slots (informed by archetype + theme)
        const rawPlan = await withDeadline(
            planSlots(prompt, archetype, theme, context, semanticIntent, manifest, designSpec, contract ?? undefined, {
                maxTokens: FULL_CANVAS_SLOT_PLANNER_MAX_TOKENS,
                temperature: 0.52,
                deadlineAt: deadlineAt - 24000,
            }),
            "slot planning",
        );
        const refinedPlan = refineScreenPlan(rawPlan, manifest, designSpec, semanticIntent);
        const screenIR = await withDeadline(
            extractScreenIR({ prompt, theme, plan: refinedPlan, semanticIntent, designSpec }),
            "screen ir",
        );
        const plan = enforcePlanRequirements(compileScreenIRToPlan(screenIR, refinedPlan), manifest.requirements);
        const sketch = GEN_V3_SKETCH_RENDER ? buildLayoutSketch(plan, designSpec) : null;
        const plannedSlots = (sketch ? sketch.nodes.map(materializeSlotFromSketchNode) : plan.slots).slice(0, MAX_GENERATION_SLOTS);
        const renderPlan: ScreenPlan = { ...plan, slots: plannedSlots, viewport: resolveViewport(context), chartSchemaVersion: context && typeof context === "object" && (context as Record<string, unknown>).chartSchemaVersion === 2 ? 2 : 1 };

        // Step 3: Generate all slots in parallel (Sketch -> Render path).
        const slotResults = await generateSlotsParallel({
            supabase,
            prompt,
            theme,
            plan: renderPlan,
            plannedSlots,
            manifest,
            designSpec,
            deadlineAt: deadlineAt - 8500,
            withDeadline,
            surfaces,
            generationMode: "full_canvas",
        });
        const reviewed = await reviewScreen({
            sections: slotResults.map((r, i) => ({ slot: plannedSlots[i], ...r })),
            plan: renderPlan, manifest, theme, deadlineAt,
            repair: async (section, issues) => ({
                slot: section.slot,
                ...await generateSlot({ supabase, prompt, theme, plan: renderPlan, slot: section.slot,
                    manifest, designSpec, deadlineAt, generationMode: mode, blockers: issues, repairComponent: section.component }),
            }),
        });
        console.info(JSON.stringify({ event: "screen_quality", issues: reviewed.issues, section_count: reviewed.sections.length }));
        const slotComponents = reviewed.sections.map((r) => ({
            position: r.slot.position,
            slotType: r.slot.slotType,
            component: r.component,
        }));

        const screen = assembleScreen(slotComponents, {
            stickyTop: manifest.stickyTopRequested,
            allowOverlay: manifest.overlayRequested,
        });
        return {
            components: screen.components,
            canvas_settings: plan.canvas_settings ?? { statusBarVisible: true, statusBarTopSafeArea: true },
            theme,
            exemplarsUsed: reviewed.sections.flatMap((r) => r.exemplarIds),
            quality: reviewed.issues,
        };
    }

    // Standard mode — still use full prompt-aware theme extraction
    // to avoid generic "Workspace"/default content outputs.
    const [theme, archetype, semanticIntent] = await withDeadline(Promise.all([
        extractThemeTokens(prompt),
        classifyArchetype(prompt),
        extractSemanticIntent(prompt),
    ]), "theme/archetype/semantic-intent");
    const surfaces = computeThemeSurfaces(theme);
    const manifest = buildDesignManifest(prompt);
    const designSpec = compilePromptDesignSpec(prompt, manifest);
    const contract = resolveScreenContract(prompt, designSpec, semanticIntent);
    const rawPlan = await withDeadline(
        planSlots(prompt, archetype, theme, context, semanticIntent, manifest, designSpec, contract ?? undefined, { deadlineAt: deadlineAt - 24000 }),
        "slot planning",
    );
    const refinedPlan = refineScreenPlan(rawPlan, manifest, designSpec, semanticIntent);
    const screenIR = await withDeadline(
        extractScreenIR({ prompt, theme, plan: refinedPlan, semanticIntent, designSpec }),
        "screen ir",
    );
    const plan = enforcePlanRequirements(compileScreenIRToPlan(screenIR, refinedPlan), manifest.requirements);
    const sketch = GEN_V3_SKETCH_RENDER ? buildLayoutSketch(plan, designSpec) : null;
    const plannedSlots = (sketch ? sketch.nodes.map(materializeSlotFromSketchNode) : plan.slots).slice(0, MAX_GENERATION_SLOTS);
    const renderPlan: ScreenPlan = { ...plan, slots: plannedSlots, viewport: resolveViewport(context), chartSchemaVersion: context && typeof context === "object" && (context as Record<string, unknown>).chartSchemaVersion === 2 ? 2 : 1 };

    const slotResults = await generateSlotsParallel({
        supabase,
        prompt,
        theme,
        plan: renderPlan,
        plannedSlots,
        manifest,
        designSpec,
        deadlineAt: deadlineAt - 8500,
        withDeadline,
        surfaces,
        generationMode: "standard",
    });
    const reviewed = await reviewScreen({
            sections: slotResults.map((r, i) => ({ slot: plannedSlots[i], ...r })),
            plan: renderPlan, manifest, theme, deadlineAt,
            repair: async (section, issues) => ({
                slot: section.slot,
                ...await generateSlot({ supabase, prompt, theme, plan: renderPlan, slot: section.slot,
                    manifest, designSpec, deadlineAt, generationMode: mode, blockers: issues, repairComponent: section.component }),
            }),
        });
        console.info(JSON.stringify({ event: "screen_quality", issues: reviewed.issues, section_count: reviewed.sections.length }));
        const slotComponents = reviewed.sections.map((r) => ({
        position: r.slot.position,
        slotType: r.slot.slotType,
        component: r.component,
    }));

    const screen = assembleScreen(slotComponents, {
        stickyTop: manifest.stickyTopRequested,
        allowOverlay: manifest.overlayRequested,
    });
    return {
        components: screen.components,
        canvas_settings: renderPlan.canvas_settings ?? { statusBarVisible: true, statusBarTopSafeArea: true },
        theme,
        exemplarsUsed: reviewed.sections.flatMap((r) => r.exemplarIds),
        quality: reviewed.issues,
    };
}

export function inferFallbackArchetype(prompt: string): ScreenArchetype {
    const p = prompt.toLowerCase();
    if (/\btracker\b|\bcalorie\b|\bhabit\b|\bfitness\b|\bsleep\b/.test(p)) return "tracker";
    if (/\bshop\b|\bstore\b|\bcart\b|\bcheckout\b/.test(p)) return "marketplace";
    if (/\bchat\b|\bmessage\b|\binbox\b/.test(p)) return "chat";
    return "dashboard";
}

export function resolveViewport(context: unknown): { width: number; height: number } {
    const ctx = context && typeof context === "object" ? context as Record<string, unknown> : {};
    const dimension = (value: unknown, fallback: number) => typeof value === "number" && Number.isFinite(value) && value >= 240 && value <= 4096 ? value : fallback;
    return { width: dimension(ctx.canvasWidth, 390), height: dimension(ctx.canvasHeight, 844) };
}

export function buildEmergencyGeneratedScreen(prompt: string): {
    components: AnyComponent[];
    canvas_settings: CanvasSettings;
    theme: ThemeTokens;
    exemplarsUsed: string[];
} {
    const theme = buildBaselineTheme({ accentColor: "blue:1.0", surfaceStyle: "utility", density: "regular", fontDesign: "default" });
    const archetype = inferFallbackArchetype(prompt);
    const plan = defaultPlanFromArchetype(archetype, theme, prompt);
    const manifest = buildDesignManifest(prompt);
    const designSpec = compilePromptDesignSpec(prompt, manifest);
    const fallbackSlots = plan.slots.slice(0, 4);
    const slotComponents = fallbackSlots.map((slot) => ({
        position: slot.position,
        slotType: slot.slotType,
        component: buildFallbackSlot(slot, theme, designSpec),
    }));
    const screen = assembleScreen(slotComponents, {
        stickyTop: manifest.stickyTopRequested,
        allowOverlay: manifest.overlayRequested,
    });
    return {
        components: screen.components,
        canvas_settings: plan.canvas_settings ?? { statusBarVisible: true, statusBarTopSafeArea: true },
        theme,
        exemplarsUsed: [],
    };
}

export type ScreenAssemblyOptions = {
    stickyTop?: boolean;
    allowOverlay?: boolean;
};

export function removeRepeatedCrossSlotGreetings(
    slots: Array<{ position: SlotPosition; slotType?: string; component: AnyComponent }>,
): Array<{ position: SlotPosition; slotType?: string; component: AnyComponent }> {
    const seen = new Set<string>();
    const isGreeting = (text: string): boolean => /^(welcome(?: back)?|hello|good (morning|afternoon|evening)|signed in as)\b/i.test(text.trim());
    const prune = (component: AnyComponent): AnyComponent | null => {
        if (component.type === "Text" && typeof component.properties?.text === "string" && isGreeting(component.properties.text)) {
            const key = component.properties.text.trim().toLowerCase().replace(/\s+/g, " ");
            if (seen.has(key)) return null;
            seen.add(key);
        }
        if (!Array.isArray(component.children)) return component;
        return { ...component, children: component.children.map(prune).filter((child): child is AnyComponent => child !== null) };
    };
    return slots.map((slot) => ({ ...slot, component: prune(slot.component) ?? { type: "Spacer", properties: {} } }));
}

export function assembleScreen(
    slotComponents: Array<{ position: SlotPosition; slotType?: string; component: AnyComponent }>,
    options: ScreenAssemblyOptions = {},
): { components: AnyComponent[] } {
    const normalizedSlots = removeRepeatedCrossSlotGreetings(slotComponents);
    const topSlots = normalizedSlots.filter((s) => s.position === "top");
    const stickyTop = options.stickyTop
        ? topSlots.filter((s) => s.slotType === "app_header").map((s) => s.component)
        : [];
    const inlineTop = topSlots
        .filter((s) => !options.stickyTop || s.slotType !== "app_header")
        .map((s) => s.component);
    const bottomCandidates = normalizedSlots.filter((s) => s.position === "bottom");
    const fixedBottomTypes = new Set(["action_bar", "nav_bar", "media_player"]);
    const bottom = bottomCandidates.filter((s) => fixedBottomTypes.has(s.slotType ?? "")).map((s) => s.component);
    const misplacedBottom = bottomCandidates.filter((s) => !fixedBottomTypes.has(s.slotType ?? "")).map((s) => s.component);
    const overlayCandidates = normalizedSlots.filter((s) => s.position === "overlay");
    const overlay = options.allowOverlay ? overlayCandidates.map((s) => s.component) : [];
    const misplacedOverlay = options.allowOverlay ? [] : overlayCandidates.map((s) => s.component);
    const body = [
        ...normalizedSlots.filter((s) => s.position === "body").map((s) => s.component),
        ...misplacedBottom,
        ...misplacedOverlay,
    ];
    const hasStickyTop = stickyTop.length > 0;
    const estimateStickyTopInset = (components: AnyComponent[]): number => {
        if (components.length === 0) return 0;
        const first = components[0];
        const isSearchLike = first.type === "HStack" || first.type === "VStack" || first.type === "Stack";
        const base = isSearchLike ? 56 : 48;
        const stackedCount = Math.max(1, Math.min(components.length, 2));
        return base * stackedCount;
    };
    const topOverlayHeight = hasStickyTop ? estimateStickyTopInset(stickyTop) : 0;
    const bottomSafeInset = bottom.length > 0 ? 14 : 34;
    const liftedOverlay = bottom.length > 0
        ? overlay.map((component) => ({
            ...component,
            modifiers: [...(Array.isArray(component.modifiers) ? component.modifiers : []), { type: "Offset", properties: { x: 0, y: -64 } }],
        }))
        : overlay;

    const topInsetSpacer: AnyComponent = {
        type: "Spacer",
        properties: {},
        modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: topOverlayHeight } }],
    };

    const safeAreaSpacer: AnyComponent = {
        type: "Spacer",
        properties: {},
        modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: bottomSafeInset } }],
    };

    const scrollContent: AnyComponent = {
        type: "VStack",
        properties: { alignment: "leading", spacing: 16 },
        modifiers: [
            { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
            { type: "Padding", properties: { amount: 16, location: "all" } },
        ],
        children: [...(hasStickyTop ? [topInsetSpacer] : []), ...inlineTop, ...body, safeAreaSpacer],
    };

    const stickyTopBar: AnyComponent | null = hasStickyTop
        ? {
            type: "VStack",
            properties: { alignment: "leading", spacing: 0 },
            modifiers: [
                { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                { type: "Padding", properties: { amount: 10, location: "horizontal" } },
                { type: "Padding", properties: { amount: 4, location: "vertical" } },
            ],
            children: stickyTop,
        }
        : null;

    const mainColumn: AnyComponent[] = [
        {
            type: "ScrollView",
            properties: { axis: "vertical", showsIndicators: false },
            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }],
            children: [scrollContent],
        },
        ...bottom,
    ];

    let root: AnyComponent;
    if (overlay.length > 0 || stickyTopBar !== null) {
        root = {
            type: "ZStack",
            properties: { alignment: "topLeading" },
            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }],
            children: [
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 0 },
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }],
                    children: mainColumn,
                },
                ...(stickyTopBar ? [stickyTopBar] : []),
                ...liftedOverlay.map((component) => ({
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 0 },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Full" } },
                    ],
                    children: [
                        { type: "Spacer" },
                        {
                            type: "HStack",
                            properties: { spacing: 0, alignment: "bottom" },
                            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }],
                            children: [{ type: "Spacer" }, component],
                        },
                    ],
                })),
            ],
        };
    } else {
        root = {
            type: "VStack",
            properties: { alignment: "leading", spacing: 0 },
            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }],
            children: mainColumn,
        };
    }

    return { components: postProcessComponents([root]) };
}

export { postProcessComponents } from "./postprocess.ts";
