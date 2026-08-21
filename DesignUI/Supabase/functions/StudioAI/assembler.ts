import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import type { AnyComponent, CanvasSettings, GenerationMode, ScreenArchetype, ScreenPlan, SlotPosition, ThemeTokens } from "./types.ts";
import { FULL_CANVAS_SLOT_PLANNER_MAX_TOKENS, GENERATION_DEADLINE_MS, GEN_V3_SKETCH_RENDER, MAX_GENERATION_SLOTS } from "./openai.ts";
import { buildDesignManifest, compilePromptDesignSpec } from "./manifest.ts";
import { classifyArchetype, defaultPlanFromArchetype, planSlots, refineScreenPlan, resolveScreenContract } from "./planner.ts";
import { extractSemanticIntent } from "./semantic-intent.ts";
import { compileScreenIRToPlan, extractScreenIR } from "./screen-ir.ts";
import { buildFallbackSlot, buildLayoutSketch, generateSlotsParallel, materializeSlotFromSketchNode } from "./slot-generator.ts";
import { buildBaselineTheme, computeThemeSurfaces, extractThemeTokens } from "./theme.ts";
import { postProcessComponents } from "./postprocess.ts";

export async function buildGeneratedScreen(
    supabase: ReturnType<typeof createClient> | null,
    prompt: string,
    context: unknown,
    mode: GenerationMode,
): Promise<{
    components: AnyComponent[];
    canvas_settings: CanvasSettings;
    theme?: ThemeTokens;
    exemplarsUsed?: string[];
}> {
    const deadlineAt = Date.now() + GENERATION_DEADLINE_MS;
    const withDeadline = async <T>(work: Promise<T>, stage: string): Promise<T> => {
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
            }),
            "slot planning",
        );
        const refinedPlan = refineScreenPlan(rawPlan, manifest, designSpec, semanticIntent);
        const screenIR = await withDeadline(
            extractScreenIR({ prompt, theme, plan: refinedPlan, semanticIntent, designSpec }),
            "screen ir",
        );
        const plan = compileScreenIRToPlan(screenIR, refinedPlan);
        const sketch = GEN_V3_SKETCH_RENDER ? buildLayoutSketch(plan, designSpec) : null;
        const plannedSlots = (sketch ? sketch.nodes.map(materializeSlotFromSketchNode) : plan.slots).slice(0, MAX_GENERATION_SLOTS);
        const renderPlan: ScreenPlan = { ...plan, slots: plannedSlots };

        // Step 3: Generate all slots in parallel (Sketch -> Render path).
        const slotResults = await generateSlotsParallel({
            supabase,
            prompt,
            theme,
            plan: renderPlan,
            plannedSlots,
            manifest,
            designSpec,
            deadlineAt,
            withDeadline,
            surfaces,
            generationMode: "full_canvas",
        });
        const slotComponents = slotResults.map((r, i) => ({
            position: plannedSlots[i].position,
            component: r.component,
        }));

        const screen = assembleScreen(slotComponents);
        return {
            components: screen.components,
            canvas_settings: plan.canvas_settings ?? { statusBarVisible: true, statusBarTopSafeArea: true },
            theme,
            exemplarsUsed: slotResults.flatMap((r) => r.exemplarIds),
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
        planSlots(prompt, archetype, theme, context, semanticIntent, manifest, designSpec, contract ?? undefined),
        "slot planning",
    );
    const refinedPlan = refineScreenPlan(rawPlan, manifest, designSpec, semanticIntent);
    const screenIR = await withDeadline(
        extractScreenIR({ prompt, theme, plan: refinedPlan, semanticIntent, designSpec }),
        "screen ir",
    );
    const plan = compileScreenIRToPlan(screenIR, refinedPlan);
    const sketch = GEN_V3_SKETCH_RENDER ? buildLayoutSketch(plan, designSpec) : null;
    const plannedSlots = (sketch ? sketch.nodes.map(materializeSlotFromSketchNode) : plan.slots).slice(0, MAX_GENERATION_SLOTS);
    const renderPlan: ScreenPlan = { ...plan, slots: plannedSlots };

    const slotResults = await generateSlotsParallel({
        supabase,
        prompt,
        theme,
        plan: renderPlan,
        plannedSlots,
        manifest,
        designSpec,
        deadlineAt,
        withDeadline,
        surfaces,
        generationMode: "standard",
    });
    const slotComponents = slotResults.map((r, i) => ({
        position: plannedSlots[i].position,
        component: r.component,
    }));

    const screen = assembleScreen(slotComponents);
    return {
        components: screen.components,
        canvas_settings: renderPlan.canvas_settings ?? { statusBarVisible: true, statusBarTopSafeArea: true },
    };
}

export function inferFallbackArchetype(prompt: string): ScreenArchetype {
    const p = prompt.toLowerCase();
    if (/\btracker\b|\bcalorie\b|\bhabit\b|\bfitness\b|\bsleep\b/.test(p)) return "tracker";
    if (/\bshop\b|\bstore\b|\bcart\b|\bcheckout\b/.test(p)) return "marketplace";
    if (/\bchat\b|\bmessage\b|\binbox\b/.test(p)) return "chat";
    return "dashboard";
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
        component: buildFallbackSlot(slot, theme, designSpec),
    }));
    const screen = assembleScreen(slotComponents);
    return {
        components: screen.components,
        canvas_settings: plan.canvas_settings ?? { statusBarVisible: true, statusBarTopSafeArea: true },
        theme,
        exemplarsUsed: [],
    };
}

export function assembleScreen(slotComponents: Array<{ position: SlotPosition; component: AnyComponent }>): { components: AnyComponent[] } {
    const top = slotComponents.filter((s) => s.position === "top").map((s) => s.component);
    const body = slotComponents.filter((s) => s.position === "body").map((s) => s.component);
    const bottom = slotComponents.filter((s) => s.position === "bottom").map((s) => s.component);
    const overlay = slotComponents.filter((s) => s.position === "overlay").map((s) => s.component);
    const hasStickyTop = top.length > 0;
    const estimateStickyTopInset = (components: AnyComponent[]): number => {
        if (components.length === 0) return 0;
        const first = components[0];
        const isSearchLike = first.type === "HStack" || first.type === "VStack" || first.type === "Stack";
        const base = isSearchLike ? 56 : 48;
        const stackedCount = Math.max(1, Math.min(components.length, 2));
        return base * stackedCount;
    };
    const topOverlayHeight = hasStickyTop ? estimateStickyTopInset(top) : 0;
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
        children: [...(hasStickyTop ? [topInsetSpacer] : []), ...body, safeAreaSpacer],
    };

    const stickyTopBar: AnyComponent | null = hasStickyTop
        ? {
            type: "ZStack",
            properties: { alignment: "topLeading" },
            modifiers: [
                { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
            ],
            children: [
                {
                    type: "Linear Gradient",
                    properties: {
                        colors: ["gray:0.14", "gray:0.06", "gray:0.00"],
                        startPoint: "top",
                        endPoint: "bottom",
                    },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: Math.max(72, topOverlayHeight + 20) } },
                        { type: "Opacity", properties: { value: 0.92 } },
                        { type: "Blur", properties: { radius: 0.25 } },
                    ],
                },
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 0 },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Default" } },
                        { type: "Padding", properties: { amount: 10, location: "horizontal" } },
                        { type: "Padding", properties: { amount: 4, location: "vertical" } },
                    ],
                    children: top,
                },
            ],
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
