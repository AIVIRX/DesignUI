import type { AnyComponent, DesignManifest, ScreenPlan, SlotPlan, ThemeTokens } from "./types.ts";
import { selectPromptRequirementsForSlot, validateSlotAgainstPromptRequirements, walkComponentTree } from "./postprocess.ts";
import { validateComponentSchema } from "./validation.ts";
import { validateChartAssignment } from "./content-contract.ts";

export type ScreenSection = { slot: SlotPlan; component: AnyComponent; exemplarIds: string[] };
export type ScreenIssue = { section: number; code: string; message: string; severity: "error" | "warning" };
const textValues = (component: AnyComponent): string[] => {
    const result: string[] = [];
    walkComponentTree(component, (node) => { if (node.type === "Text" && typeof node.properties?.text === "string") result.push(node.properties.text.trim().toLowerCase().replace(/\s+/g, " ")); });
    return result;
};

// Conservative planning estimate, not a substitute for native measured bounds.
export function estimatedHeight(node: AnyComponent, width = 358): number {
    const props = node.properties ?? {};
    const font = node.modifiers?.find((m) => m.type === "Font")?.properties as Record<string, unknown> | undefined;
    const sizes: Record<string, number> = { largeTitle: 34, title: 28, title2: 22, title3: 20, headline: 17, body: 17, callout: 16, subheadline: 15, footnote: 13, caption: 12, caption2: 11 };
    const size = sizes[String(font?.fontSize)] ?? 17;
    const children = node.children ?? [];
    const horizontal = node.type === "HStack" || (node.type === "Stack" && props.stackType === "horizontal");
    const overlay = node.type === "ZStack" || (node.type === "Stack" && props.stackType === "z");
    const gap = typeof props.spacing === "number" ? props.spacing : 8;
    const widths = horizontal ? Math.max(32, (width - gap * (children.length - 1)) / Math.max(1, children.length)) : width;
    let height = children.length ? (horizontal || overlay ? Math.max(...children.map((c) => estimatedHeight(c, widths))) : children.reduce((sum, c) => sum + estimatedHeight(c, widths), 0) + gap * (children.length - 1)) : 24;
    if (node.type === "Text") height = Math.max(1, Math.ceil(String(props.text ?? "").length * size * 0.52 / Math.max(32, width))) * size * 1.25;
    if (node.type === "Chart" || node.type === "Map") height = 180;
    if (node.type === "Spacer") height = 0;
    if (node.type === "Button" || node.type === "Text Field" || node.type === "Switch") height = Math.max(44, height);
    for (const mod of node.modifiers ?? []) {
        const p = (mod.properties ?? {}) as Record<string, unknown>;
        if (mod.type === "Frame" && p.heightType === "Custom" && typeof p.height === "number") height = p.height;
        if (mod.type === "Padding" && ["all", "vertical"].includes(String(p.location))) height += 2 * Number(p.amount ?? 0);
    }
    return Math.max(0, height);
}

export function unifyScreenStyle(component: AnyComponent, theme: ThemeTokens): AnyComponent {
    const root = structuredClone(component);
    const radius = theme.cornerRadiusScale === "sharp" ? 12 : theme.cornerRadiusScale === "pill" ? 22 : 16;
    walkComponentTree(root, (node) => {
        for (const mod of node.modifiers ?? []) {
            const props = (mod.properties ?? {}) as Record<string, unknown>;
            if (mod.type === "Font" && props.fontDesign !== "monospaced") props.fontDesign = theme.fontDesign;
            // Align ordinary card corners, preserving circular artwork, pills and small controls.
            if (mod.type === "Corner Radius" && ["VStack", "HStack", "Stack"].includes(node.type) && typeof props.radius === "number" && props.radius >= 12 && props.radius < 40) props.radius = radius;
        }
    });
    return root;
}

export function auditScreen(sections: ScreenSection[], plan: ScreenPlan, manifest: DesignManifest): ScreenIssue[] {
    const issues: ScreenIssue[] = [];
    const add = (section: number, code: string, message: string, severity: ScreenIssue["severity"] = "error") => issues.push({ section, code, message, severity });
    const previous = new Map<string, number>();
    const chartOwners = sections.map((s, i) => s.slot.slotType === "chart_section" ? i : -1).filter((i) => i >= 0);
    const metricOwner = sections.findIndex((s) => s.slot.slotType === "stat_group");
    const metricTexts = metricOwner >= 0 ? new Set(textValues(sections[metricOwner].component).filter((s) => /\d/.test(s))) : new Set<string>();
    const fontDesigns = new Map<string, number[]>();
    sections.forEach((section, index) => {
        const requirements = selectPromptRequirementsForSlot(section.slot, manifest.requirements);
        for (const message of validateComponentSchema(section.component)) add(index, "schema", message);
        for (const message of validateSlotAgainstPromptRequirements(section.slot, section.component, requirements)) add(index, "requirement", message);
        const texts = textValues(section.component);
        if (section.slot.slotType === "horizontal_rail" && /\b(?:filter|chip|mood)\b/i.test(section.slot.intent)) {
            const navigation = sections.find((candidate) => candidate.slot.slotType === "nav_bar");
            const navLabels = navigation ? new Set(textValues(navigation.component)) : new Set<string>();
            if ([...new Set(texts)].filter((text) => navLabels.has(text)).length >= 2) add(index, "filter_navigation_collision", "Use filter labels distinct from the bottom navigation labels; the navigation section owns those tabs.");
        }
        if ((plan.chartSchemaVersion ?? 1) >= 2) for (const message of validateChartAssignment(section.component, section.slot.intent)) add(index, "chart_assignment", message);
        for (const text of texts) if (/\brequired:\s|\b(?:offer|include|render|display)\s+\d+\s+selectable\b/i.test(text)) add(index, "instruction_copy", "Replace planner instructions with concise product copy.");
        // Whole-section duplication is stronger evidence than a common label such as "See all".
        const signature = texts.filter((s) => s.length > 2).sort().join("|");
        if (texts.length >= 3 && previous.has(signature)) add(index, "duplicate_section", `This section duplicates section ${previous.get(signature)! + 1}; replace it with its own assigned content: ${section.slot.intent}.`);
        else previous.set(signature, index);
        if (index !== metricOwner && section.slot.position === "body" && texts.filter((s) => metricTexts.has(s)).length >= 2) add(index, "duplicate_metrics", "Two or more metrics repeat the dedicated stat section. Remove that summary while preserving this section's assigned content.");
        walkComponentTree(section.component, (node) => {
            if (node.type === "Chart" && chartOwners.length && !chartOwners.includes(index)) add(index, "duplicate_chart", "The screen has a dedicated chart section. Remove the extra chart from this section.");
            for (const m of node.modifiers ?? []) {
                const p = (m.properties ?? {}) as Record<string, unknown>;
                if (m.type === "Frame" && p.widthType === "Custom" && Number(p.width) > (plan.viewport?.width ?? 390) - 32) add(index, "overflow", "A fixed-width element exceeds the available canvas width. Use a flexible width or smaller artwork.");
                if (m.type === "Font" && typeof p.fontDesign === "string" && p.fontDesign !== "monospaced") fontDesigns.set(p.fontDesign, [...(fontDesigns.get(p.fontDesign) ?? []), index]);
            }
        });
    });
    const allText = sections.flatMap((s) => textValues(s.component)).join(" ");
    for (const match of manifest.rawPrompt.matchAll(/\b(?:titled|called|named|labeled|labelled)\s+[“"]([^”"]+)[”"]/gi)) {
        const label = match[1].toLowerCase();
        if (!allText.includes(label)) {
            const owner = sections.findIndex((s) => s.slot.intent.toLowerCase().includes(label));
            add(owner >= 0 ? owner : 0, "missing_copy", `Include the explicitly requested label “${match[1]}”.`);
        }
    }
    if (fontDesigns.size > 1) {
        const dominant = [...fontDesigns.entries()].sort((a, b) => b[1].length - a[1].length)[0][0];
        for (const [design, indices] of fontDesigns) if (design !== dominant) for (const i of new Set(indices)) add(i, "typography", `Use the shared ${dominant} font design for ordinary text.`, "warning");
    }
    if (/\b(above the fold|without scrolling|action visible|action.*visible)\b/i.test(manifest.rawPrompt)) {
        const bottomHeight = sections.filter((s) => s.slot.position === "bottom").reduce((n, s) => n + estimatedHeight(s.component, (plan.viewport?.width ?? 390) - 32), 0);
        let offset = 76;
        sections.forEach((section, index) => {
            if (section.slot.position !== "body" && section.slot.position !== "top") return;
            const height = estimatedHeight(section.component, (plan.viewport?.width ?? 390) - 32);
            let action = false;
            walkComponentTree(section.component, (node) => { if (node.type === "Button") action = true; });
            const isPrimary = /\b(primary|start|continue|buy|book|checkout|workout|subscribe)\b/i.test(section.slot.intent);
            if (action && isPrimary && offset + height > (plan.viewport?.height ?? 844) - bottomHeight - 34) add(index, "action_below_fold", "The primary action is likely below the visible screen. Compact this section or move it earlier. Native visual tests must confirm the final bounds.", "warning");
            offset += height + 16;
        });
    }
    for (const req of manifest.requirements) if (!sections.some((s) => s.slot.slotType === req.slotType)) add(-1, "missing_section", `Missing requested ${req.slotType}: ${req.mustInclude}`);
    return issues;
}

export async function reviewScreen(params: {
    sections: ScreenSection[]; plan: ScreenPlan; manifest: DesignManifest; theme: ThemeTokens; deadlineAt: number;
    repair: (section: ScreenSection, issues: string[]) => Promise<ScreenSection>;
}): Promise<{ sections: ScreenSection[]; issues: ScreenIssue[] }> {
    let sections = params.sections.map((s) => ({ ...s, component: unifyScreenStyle(s.component, params.theme) }));
    // Preserve the first instance of an identical rail/section. This catches
    // model retries that return the same filter group twice.
    const seenSections = new Set<string>();
    let filterRailSeen = false;
    sections = sections.filter((section) => {
        if (section.slot.slotType !== "horizontal_rail" || !/\b(?:filter|chip|mood)\b/i.test(section.slot.intent)) return true;
        if (filterRailSeen) return false;
        filterRailSeen = true;
        const signature = `${section.slot.slotType}|${textValues(section.component).join("|")}`;
        if (signature.length < 12 || !seenSections.has(signature)) { seenSections.add(signature); return true; }
        return false;
    });
    // A dedicated navigation section owns its labels. Remove only complete duplicate
    // label groups elsewhere; preserve individual shared words and unrelated content.
    const nav = sections.find((s) => s.slot.slotType === "nav_bar");
    const labels = nav ? new Set(textValues(nav.component)) : new Set<string>();
    if (labels.size >= 3) {
        const prune = (node: AnyComponent): AnyComponent | null => {
            const texts = textValues(node);
            if (texts.length >= labels.size && new Set(texts).size === labels.size && texts.every((t) => labels.has(t))) return null;
            if (node.children) node.children = node.children.map(prune).filter((n): n is AnyComponent => n !== null);
            return node;
        };
        sections = sections.flatMap((s) => {
            if (s === nav) return [s];
            const component = prune(s.component);
            return component ? [{ ...s, component }] : [];
        });
    }
    const initial = auditScreen(sections, params.plan, params.manifest);
    const targets = [...new Set(initial.filter((i) => i.section >= 0 && i.severity === "error").map((i) => i.section))].slice(0, 2);
    if (params.deadlineAt - Date.now() > 8000) {
        const repaired = await Promise.allSettled(targets.map(async (index) => {
            const result = await params.repair(sections[index], initial.filter((i) => i.section === index).map((i) => i.message));
            return { index, result: { ...result, component: unifyScreenStyle(result.component, params.theme) } };
        }));
        for (const result of repaired) if (result.status === "fulfilled") {
            const { index, result: candidate } = result.value;
            const trial = sections.map((s, i) => i === index ? candidate : s);
            const errors = (list: ScreenIssue[]) => list.filter((i) => i.severity === "error" && i.section === index).length;
            if (errors(auditScreen(trial, params.plan, params.manifest)) < errors(auditScreen(sections, params.plan, params.manifest))) sections = trial;
        }
    }
    // Moving an intact section is safe and avoids another model call for fold placement.
    const fold = auditScreen(sections, params.plan, params.manifest).find((i) => i.code === "action_below_fold");
    if (fold && !/\b(after|below|before|order)\b/i.test(params.manifest.rawPrompt)) {
        const firstBody = sections.findIndex((s) => s.slot.position === "body");
        if (firstBody >= 0 && fold.section > firstBody) {
            const [action] = sections.splice(fold.section, 1);
            sections.splice(firstBody, 0, action);
        }
    }
    return { sections, issues: auditScreen(sections, params.plan, params.manifest) };
}
