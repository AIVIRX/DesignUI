import type { AnyComponent, PromptDesignSpec, PromptRequirement, RailVariant, SlotPlan, SlotType } from "./types.ts";
import type { SlotConstraint } from "./schema.ts";
import { isObject } from "./utils.ts";
import { INSTRUCTIONAL_COPY_PATTERNS } from "./manifest.ts";

function getComponentDepth(component: AnyComponent): number {
    if (!Array.isArray(component.children) || component.children.length === 0) return 1;
    return 1 + Math.max(...component.children.map(getComponentDepth));
}

function detectRailVariantFromText(text: string): RailVariant | null {
    const t = text.toLowerCase();
    if (/\b(song|songs|track|tracks|artist|artists|now playing|playlist|playlists|music)\b/.test(t)) return "media_track";
    if (/\bsquare\b.*\b(art|artwork|cover|thumbnail)\b|\b(art|artwork|cover|thumbnail)\b.*\bsquare\b/.test(t)) return "media_track";
    if (/\b(poster|posters|album|albums|cover|covers|thumbnail|thumbnails)\b/.test(t)) return "poster";
    if (/\b(circular|avatar|profile|people|creators?)\b/.test(t)) return "circular_people";
    if (/\b(chip|chips|pill|pills|tags?)\b/.test(t)) return "chips";
    if (/\b(landscape|wide|banner)\b/.test(t)) return "landscape";
    return null;
}

export function detectLowQualitySlotOutput(component: AnyComponent): string[] {
    let textNodeCount = 0;
    let placeholderTextCount = 0;
    let questionMarkSymbolCount = 0;
    let emptyFontModifierCount = 0;
    let duplicateFontChainCount = 0;
    let genericFallbackCopyCount = 0;
    const genericFallbackPhrases = new Set([
        "priority item",
        "follow up",
        "keep momentum",
        "start here",
        "final check",
        "in progress",
        "pending",
        "items 1",
        "items 2",
    ]);

    walkComponentTree(component, (n) => {
        if (n.type === "Text") {
            textNodeCount += 1;
            const text = isObject(n.properties) ? String(n.properties.text ?? "") : "";
            const cleaned = text.trim().toLowerCase();
            if (!cleaned || cleaned === "text" || cleaned === "title" || cleaned === "subtitle" || cleaned === "item") {
                placeholderTextCount += 1;
            }
            if (genericFallbackPhrases.has(cleaned)) genericFallbackCopyCount += 1;
        }
        if (n.type === "SF Symbol") {
            const symbolName = isObject(n.properties) ? String(n.properties.symbolName ?? "").trim().toLowerCase() : "";
            if (symbolName === "questionmark" || symbolName === "questionmark.circle") {
                questionMarkSymbolCount += 1;
            }
        }

        if (!Array.isArray(n.modifiers)) return;
        let consecutiveFont = 0;
        for (const mod of n.modifiers) {
            if (!isObject(mod)) continue;
            if (mod.type === "Font") {
                consecutiveFont += 1;
                const props = isObject(mod.properties) ? mod.properties as Record<string, unknown> : {};
                const hasFontProps = typeof props.fontSize === "string" || typeof props.fontWeight === "string" || typeof props.fontDesign === "string";
                if (!hasFontProps) emptyFontModifierCount += 1;
            } else {
                if (consecutiveFont > 1) duplicateFontChainCount += 1;
                consecutiveFont = 0;
            }
        }
        if (consecutiveFont > 1) duplicateFontChainCount += 1;
    });

    const issues: string[] = [];
    if (emptyFontModifierCount >= 3) issues.push(`too many empty font modifiers (${emptyFontModifierCount})`);
    if (duplicateFontChainCount >= 2) issues.push(`repeated duplicate font modifier chains (${duplicateFontChainCount})`);
    if (textNodeCount > 0 && placeholderTextCount / textNodeCount >= 0.35 && placeholderTextCount >= 3) {
        issues.push(`placeholder text ratio too high (${placeholderTextCount}/${textNodeCount})`);
    }
    if (questionMarkSymbolCount >= 2) issues.push(`too many unknown symbols (${questionMarkSymbolCount})`);
    if (genericFallbackCopyCount >= 2) issues.push(`generic fallback copy detected (${genericFallbackCopyCount})`);
    return issues;
}

// ─── Slot Validation ─────────────────────────────────────────────────────────

export function validateSlotConstraints(component: AnyComponent, constraint: SlotConstraint): { valid: boolean; issues: string[] } {
    const issues: string[] = [];

    // Check root type
    if (!constraint.allowedRoots.includes(component.type)) {
        issues.push(`Root type "${component.type}" not in allowed: [${constraint.allowedRoots.join(", ")}]`);
    }

    // Check max depth — generous tolerance (+2) because post-processing can add wrappers
    const depth = getComponentDepth(component);
    if (depth > constraint.maxDepth + 2) {
        issues.push(`Tree depth ${depth} exceeds max ${constraint.maxDepth}`);
    }

    // Check required text count
    if (constraint.requiredTextCount && constraint.requiredTextCount > 0) {
        const textCount = countTextNodes(component);
        if (textCount < constraint.requiredTextCount) {
            issues.push(`Only ${textCount} Text nodes, need at least ${constraint.requiredTextCount}`);
        }
    }

    // Don't reject on empty text — post-processing + cheapRepair handle that.
    // Only reject on truly broken structure.

    return { valid: issues.length === 0, issues };
}

export function countTextNodes(node: AnyComponent): number {
    let count = node.type === "Text" ? 1 : 0;
    if (Array.isArray(node.children)) {
        for (const child of node.children) count += countTextNodes(child);
    }
    return count;
}

export function findEmptyTexts(node: AnyComponent): number {
    let count = 0;
    if (node.type === "Text") {
        const text = isObject(node.properties) ? String(node.properties.text ?? "") : "";
        if (text.trim() === "" || text === "Text") count++;
    }
    if (Array.isArray(node.children)) {
        for (const child of node.children) count += findEmptyTexts(child);
    }
    return count;
}

export function walkComponentTree(node: AnyComponent, visit: (n: AnyComponent) => void): void {
    visit(node);
    if (Array.isArray(node.children)) {
        for (const child of node.children) walkComponentTree(child, visit);
    }
    if (Array.isArray(node.modifiers)) {
        for (const mod of node.modifiers) {
            if (!isObject(mod)) continue;
            const modChildren = Array.isArray(mod.children) ? mod.children : [];
            for (const child of modChildren) {
                if (isObject(child) && typeof child.type === "string") {
                    walkComponentTree(child as AnyComponent, visit);
                }
            }
        }
    }
}

export function slotHasCircularGauge(component: AnyComponent): boolean {
    let found = false;
    walkComponentTree(component, (n) => {
        if (found || n.type !== "Gauge" || !isObject(n.properties)) return;
        const gt = typeof n.properties.gaugeType === "string" ? n.properties.gaugeType.toLowerCase() : "";
        if (gt === "circular" || gt === "circular range") found = true;
    });
    return found;
}

export function slotHasBlurTreatment(component: AnyComponent): boolean {
    let found = false;
    walkComponentTree(component, (n) => {
        if (found || !Array.isArray(n.modifiers)) return;
        if (n.modifiers.some((m) => isObject(m) && m.type === "Blur")) found = true;
    });
    return found;
}

export function estimateGridCardCount(component: AnyComponent): { rows: number; cards: number } {
    // Heuristic for 2x2-style grids: root VStack with HStack rows.
    if (component.type === "VStack" && Array.isArray(component.children)) {
        const rows = component.children.filter((c) => c.type === "HStack");
        const cards = rows.reduce((sum, row) => sum + (Array.isArray(row.children) ? row.children.length : 0), 0);
        if (rows.length > 0) return { rows: rows.length, cards };
    }
    let best = { rows: 0, cards: 0 };
    walkComponentTree(component, (n) => {
        if (n.type !== "VStack" || !Array.isArray(n.children)) return;
        const rows = n.children.filter((c) => c.type === "HStack");
        const cards = rows.reduce((sum, row) => sum + (Array.isArray(row.children) ? row.children.length : 0), 0);
        if (rows.length > best.rows || cards > best.cards) best = { rows: rows.length, cards };
    });
    return best;
}

export function normalizeIntentMatch(value: string): string {
    return value.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

export function selectPromptRequirementsForSlot(slot: SlotPlan, promptRequirements: PromptRequirement[]): PromptRequirement[] {
    const sameType = promptRequirements.filter((r) => r.slotType === slot.slotType);
    if (sameType.length <= 1) return sameType;

    const slotIntent = normalizeIntentMatch(slot.intent);
    const exactIntentMatches = sameType.filter((r) => normalizeIntentMatch(r.mustInclude) === slotIntent);
    if (exactIntentMatches.length > 0) return [exactIntentMatches[0]];

    const slotVariantHint = normalizeIntentMatch(slot.variant_hint ?? "");
    if (slotVariantHint) {
        const variantMatches = sameType.filter((r) => {
            const requirementHint = normalizeIntentMatch(r.variantHint ?? "");
            return Boolean(requirementHint) && (
                requirementHint.includes(slotVariantHint) || slotVariantHint.includes(requirementHint)
            );
        });
        if (variantMatches.length > 0) return [variantMatches[0]];
    }

    const intentContainmentMatches = sameType.filter((r) => {
        const must = normalizeIntentMatch(r.mustInclude);
        return Boolean(slotIntent) && Boolean(must) && (slotIntent.includes(must) || must.includes(slotIntent));
    });
    if (intentContainmentMatches.length > 0) return [intentContainmentMatches[0]];

    return [sameType[0]];
}

export function getCustomFrameSize(node: AnyComponent): { width: number; height: number } | null {
    if (!Array.isArray(node.modifiers)) return null;
    for (const mod of node.modifiers) {
        if (!isObject(mod) || mod.type !== "Frame" || !isObject(mod.properties)) continue;
        const p = mod.properties;
        const width = typeof p.width === "number" ? p.width : null;
        const height = typeof p.height === "number" ? p.height : null;
        const widthType = typeof p.widthType === "string" ? p.widthType : "";
        const heightType = typeof p.heightType === "string" ? p.heightType : "";
        if (width !== null && height !== null && widthType === "Custom" && heightType === "Custom") {
            return { width, height };
        }
    }
    return null;
}

export function findHorizontalRailItems(component: AnyComponent): AnyComponent[] {
    const search = (node: AnyComponent): AnyComponent[] | null => {
        if (node.type === "ScrollView" && isObject(node.properties)) {
            const axis = typeof node.properties.axis === "string" ? node.properties.axis : "vertical";
            if (axis === "horizontal" && Array.isArray(node.children)) {
                const hstack = node.children.find((c) => c.type === "HStack" && Array.isArray(c.children));
                if (hstack && Array.isArray(hstack.children)) {
                    return hstack.children.filter((c) => c.type !== "Spacer");
                }
            }
        }
        if (Array.isArray(node.children)) {
            for (const child of node.children) {
                const found = search(child);
                if (found) return found;
            }
        }
        if (Array.isArray(node.modifiers)) {
            for (const mod of node.modifiers) {
                if (!isObject(mod) || !Array.isArray(mod.children)) continue;
                for (const child of mod.children) {
                    if (!isObject(child) || typeof child.type !== "string") continue;
                    const found = search(child as AnyComponent);
                    if (found) return found;
                }
            }
        }
        return null;
    };
    return search(component) ?? [];
}

export type RailItemMetrics = {
    textCount: number;
    circles: number;
    capsules: number;
    pills: number;
    squareVisuals: number;
    portraitVisuals: number;
    landscapeVisuals: number;
};

export function analyzeRailItem(item: AnyComponent): RailItemMetrics {
    const visualTypes = new Set(["Image", "RoundedRectangle", "Rectangle", "Circle", "Capsule"]);
    const metrics: RailItemMetrics = {
        textCount: countTextNodes(item),
        circles: 0,
        capsules: 0,
        pills: 0,
        squareVisuals: 0,
        portraitVisuals: 0,
        landscapeVisuals: 0,
    };

    walkComponentTree(item, (n) => {
        if (n.type === "Circle") metrics.circles += 1;
        if (n.type === "Capsule") metrics.capsules += 1;
        if (!visualTypes.has(n.type)) return;

        const size = getCustomFrameSize(n);
        if (!size) return;
        const { width, height } = size;
        if (Math.abs(width - height) <= 14 && width >= 44 && height >= 44) metrics.squareVisuals += 1;
        if (height >= width + 18 && width >= 44) metrics.portraitVisuals += 1;
        if (width >= height + 24 && height >= 36) metrics.landscapeVisuals += 1;
        if ((n.type === "Capsule" || n.type === "RoundedRectangle") && width >= height * 1.8 && height <= 52) metrics.pills += 1;
    });

    return metrics;
}

export function scoreRailItemForVariant(item: RailItemMetrics, variant: RailVariant): number {
    if (variant === "media_track") return (item.squareVisuals > 0 ? 2 : 0) + (item.textCount >= 2 ? 2 : 0);
    if (variant === "poster") return ((item.portraitVisuals > 0 || item.squareVisuals > 0) ? 2 : 0) + (item.textCount >= 1 ? 1 : 0);
    if (variant === "circular_people") return (item.circles > 0 ? 2 : 0) + (item.textCount >= 1 ? 1 : 0);
    if (variant === "chips") return ((item.pills > 0 || item.capsules > 0) ? 2 : 0) + (item.textCount >= 1 ? 1 : 0);
    return (item.landscapeVisuals > 0 ? 2 : 0) + (item.textCount >= 1 ? 1 : 0);
}

export function detectRailVariantFromRequirement(req: PromptRequirement): RailVariant {
    if (req.railSpec?.variant) return req.railSpec.variant;
    const fromMust = detectRailVariantFromText(req.mustInclude);
    if (fromMust) return fromMust;
    const fromHint = detectRailVariantFromText(req.variantHint ?? "");
    if (fromHint) return fromHint;
    return "poster";
}

export function validateRailStructure(component: AnyComponent, req: PromptRequirement): string[] {
    const issues: string[] = [];
    const variant = detectRailVariantFromRequirement(req);
    const items = findHorizontalRailItems(component);
    const expectedItems = Math.max(3, Math.min(req.itemCount ?? 4, 6));
    if (items.length < expectedItems) {
        issues.push(`Rail expects ~${expectedItems} items but found ${items.length}.`);
    }

    const metrics = items.map(analyzeRailItem);
    const strongMatches = metrics.filter((m) => scoreRailItemForVariant(m, variant) >= 3).length;
    const requiredMatches = Math.max(2, Math.min(expectedItems, items.length));
    if (strongMatches < requiredMatches) {
        const label = variant === "media_track"
            ? "square artwork + title + secondary subtitle"
            : variant === "circular_people"
                ? "circular avatar/item + label"
                : variant === "chips"
                    ? "pill chip items"
                    : variant === "landscape"
                        ? "wide landscape cards"
                        : "poster-like cards";
        issues.push(`Rail variant "${variant}" not satisfied: need more items with ${label}.`);
    }
    if (variant === "media_track") {
        const subtitleReady = metrics.filter((m) => m.squareVisuals > 0 && m.textCount >= 2).length;
        if (subtitleReady < requiredMatches) {
            issues.push("Media-track rail requires square artwork with BOTH title and artist/subtitle rows for most items.");
        }
    }
    return issues;
}

export function inferRailVariantFromComponent(component: AnyComponent): RailVariant {
    const items = findHorizontalRailItems(component);
    if (items.length === 0) return "poster";
    const metrics = items.map(analyzeRailItem);
    const variants: RailVariant[] = ["media_track", "circular_people", "chips", "landscape", "poster"];
    let best: RailVariant = "poster";
    let bestScore = -1;
    for (const variant of variants) {
        const score = metrics.reduce((sum, m) => sum + scoreRailItemForVariant(m, variant), 0);
        if (score > bestScore) {
            bestScore = score;
            best = variant;
        }
    }
    return best;
}

export function containsInstructionalDisplayText(component: AnyComponent): boolean {
    let found = false;
    walkComponentTree(component, (n) => {
        if (found || n.type !== "Text" || !isObject(n.properties)) return;
        const text = typeof n.properties.text === "string" ? n.properties.text.trim() : "";
        if (!text) return;
        if (INSTRUCTIONAL_COPY_PATTERNS.some((re) => re.test(text))) found = true;
    });
    return found;
}

export function validateSlotAgainstPromptRequirements(slot: SlotPlan, component: AnyComponent, promptRequirements: PromptRequirement[]): string[] {
    const issues: string[] = [];
    if (containsInstructionalDisplayText(component)) {
        issues.push("Instruction/spec language leaked into visible text labels; use natural UI copy instead.");
    }
    if (promptRequirements.length === 0) return issues;

    for (const req of promptRequirements) {
        const must = req.mustInclude.toLowerCase();
        if (slot.slotType === "progress_section") {
            if (must.includes("gauge") && !slotHasCircularGauge(component)) {
                issues.push("Missing required circular Gauge progress element.");
            }
        }
        if (slot.slotType === "timeline_list") {
            if (must.includes("blur") && !slotHasBlurTreatment(component)) {
                issues.push("Timeline/feed requested blurred treatment but no Blur modifier found.");
            }
        }
        if (slot.slotType === "stat_group") {
            const grid = estimateGridCardCount(component);
            if (typeof req.itemCount === "number" && grid.cards < req.itemCount) {
                issues.push(`Stat group has ~${grid.cards} cards; requires at least ${req.itemCount}.`);
            }
            if (must.includes("2x2") && (grid.rows < 2 || grid.cards < 4)) {
                issues.push("Stat group must be arranged as a 2x2 grid (2 rows x 2 cards).");
            }
        }
        if (slot.slotType === "horizontal_rail") {
            issues.push(...validateRailStructure(component, req));
        }
    }

    return Array.from(new Set(issues));
}

export function countListLikeItems(slotType: SlotType, component: AnyComponent): number {
    if (slotType === "horizontal_rail") return findHorizontalRailItems(component).length;
    if (slotType === "stat_group" || slotType === "content_grid") return estimateGridCardCount(component).cards;
    if (!Array.isArray(component.children)) return 0;

    if (slotType === "content_list" || slotType === "settings_list" || slotType === "notification_list" || slotType === "timeline_list") {
        return component.children.filter((c) => c.type === "HStack" || c.type === "VStack").length;
    }
    if (slotType === "chat_bubble_list") {
        return component.children.filter((c) => c.type === "HStack").length;
    }
    return 0;
}

export function validateExactCountForSlot(slot: SlotPlan, component: AnyComponent, requirement: PromptRequirement): string[] {
    const issues: string[] = [];
    if (typeof requirement.itemCount !== "number") return issues;
    const expected = Math.max(1, Math.round(requirement.itemCount));
    const actual = countListLikeItems(slot.slotType, component);
    if (actual <= 0) return issues;

    const strictByText = /\b(exactly|only|just)\b/.test(requirement.mustInclude.toLowerCase());
    if (strictByText && actual !== expected) {
        issues.push(`Expected exactly ${expected} items for ${slot.slotType}, but found ${actual}.`);
    } else if (actual < expected) {
        issues.push(`Expected at least ${expected} items for ${slot.slotType}, but found ${actual}.`);
    }
    return issues;
}

export function collectComponentTypes(node: AnyComponent, out: string[] = []): string[] {
    out.push(node.type);
    if (Array.isArray(node.children)) {
        for (const child of node.children) collectComponentTypes(child, out);
    }
    return out;
}

export function computeMorphologySignature(component: AnyComponent): string {
    const types = collectComponentTypes(component, []);
    const counts = new Map<string, number>();
    for (const t of types) counts.set(t, (counts.get(t) ?? 0) + 1);
    return Array.from(counts.entries())
        .sort((a, b) => a[0].localeCompare(b[0]))
        .map(([k, v]) => `${k}:${v}`)
        .join("|");
}

export function validateStrictIntentLocksForSlot(
    slot: SlotPlan,
    component: AnyComponent,
    designSpec?: PromptDesignSpec,
): string[] {
    const issues: string[] = [];
    if (!designSpec?.strictOneToOne && !designSpec?.strict) return issues;
    const types = collectComponentTypes(component, []);

    if (designSpec.style.nativePattern === "appstore_search") {
        if (slot.slotType === "content_list") {
            if (types.includes("Capsule") || types.includes("RoundedRectangle")) {
                issues.push("App Store search list must use flat suggestion rows, not card/chip surfaces.");
            }
        }
        if (slot.slotType === "horizontal_rail") {
            issues.push("App Store search flow should not include horizontal rails unless explicitly requested.");
        }
    }

    if (designSpec.style.nativePattern === "mail_inbox" && slot.slotType === "content_list") {
        if (!types.includes("Divider")) {
            issues.push("Mail inbox list requires row dividers for native thread rhythm.");
        }
    }

    if (designSpec.style.nativePattern === "admob_dashboard" && slot.slotType === "stat_group") {
        if (!types.includes("RoundedRectangle")) {
            issues.push("AdMob dashboard metrics require chart/sparkline card visuals.");
        }
    }

    return issues;
}
