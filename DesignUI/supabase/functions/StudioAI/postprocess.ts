import type { AnyComponent, PromptDesignSpec, PromptRequirement, RailVariant, SlotPlan, SlotType } from "./types.ts";
import { VALID_MODIFIER_TYPES } from "./schema.ts";
import type { SlotConstraint } from "./schema.ts";
import { containsInternalDiagnostic, detectRailVariantFromText, isObject, sanitizeInstructionalDisplayText, sanitizeInternalDisplayText } from "./utils.ts";
import { INSTRUCTIONAL_COPY_PATTERNS } from "./manifest.ts";

// ─── Post-processing (unchanged from v1) ─────────────────────────────────────

function adaptiveNeutralSurface(modifierType: string, color: unknown): string | null {
    if (typeof color !== "string" || !["Background Color", "Fill"].includes(modifierType)) return null;
    const match = color.trim().toLowerCase().match(/^(gray|grey|white|black):(0(?:\.\d+)?)$/);
    if (!match) return null;
    const opacity = Number(match[2]);
    if (!Number.isFinite(opacity) || opacity <= 0 || opacity >= 0.3) return null;
    if (modifierType === "Fill") {
        if (opacity <= 0.10) return "quaternarySystemFill:1.0";
        if (opacity <= 0.14) return "tertiarySystemFill:1.0";
        return "secondarySystemFill:1.0";
    }
    return opacity <= 0.10 ? "secondarySystemBackground:1.0" : "tertiarySystemBackground:1.0";
}

export function postProcessComponents(
    components: AnyComponent[],
    canvasColorScheme?: "light" | "dark",
): AnyComponent[] {
    const cloned = JSON.parse(JSON.stringify(components)) as AnyComponent[];
    const CONTAINER_PP = new Set(["Stack", "VStack", "HStack", "ZStack", "ScrollView", "Button"]);
    const LEAF_PP = new Set(["Text", "Image", "SF Symbol", "Shape", "Chart", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "Linear Gradient", "Text Field", "Switch", "Slider", "Progress View", "Status Bar", "Gauge", "Map"]);
    const SHAPE_PP = new Set(["Shape", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse"]);
    const ALL_VALID_PP = new Set([...CONTAINER_PP, ...LEAF_PP]);

    const coerceType = (type: unknown): string => {
        if (typeof type === "string" && ALL_VALID_PP.has(type)) return type;
        if (typeof type === "string") {
            const t = type.toLowerCase();
            if (t.includes("gradient")) return "Linear Gradient";
            if (t === "progress" || t === "progressview" || t === "progress view" || t === "progressbar" || t === "progress bar") return "Progress View";
        }
        return "Text";
    };

    const normalizeSFSymbolName = (raw: string): string => {
        let name = raw.trim().toLowerCase();
        if (!name) return "questionmark";
        const aliasMap: Record<string, string> = {
            "plane": "airplane", "airplane": "airplane", "paper plane": "paperplane", "paperplane": "paperplane",
            "send": "paperplane", "delete": "trash", "trash": "trash", "remove": "trash", "bin": "trash",
            "close": "xmark", "x": "xmark", "add": "plus", "plus": "plus", "edit": "pencil", "pencil": "pencil",
            "search": "magnifyingglass", "settings": "gearshape", "gear": "gearshape", "share": "square.and.arrow.up",
            "heart": "heart", "like": "heart", "star": "star", "user": "person", "profile": "person",
            "lock": "lock", "unlock": "lock.open", "camera": "camera", "photo": "photo", "image": "photo",
            "play": "play.fill", "pause": "pause.fill", "stop": "stop.fill", "menu": "line.3.horizontal",
            "more": "ellipsis", "info": "info.circle", "warning": "exclamationmark.triangle",
            "alert": "exclamationmark.triangle", "check": "checkmark", "success": "checkmark.circle",
            "error": "xmark.circle", "back": "chevron.left", "forward": "chevron.right",
            "up": "chevron.up", "down": "chevron.down",
        };
        if (aliasMap[name]) return aliasMap[name];
        name = name.replace(/\s+/g, ".").replace(/_+/g, ".");
        if (aliasMap[name]) return aliasMap[name];
        if (!/^[a-z0-9.]+$/.test(name)) return "questionmark";
        return name;
    };

    const normalizeModifierType = (rawType: unknown): string => {
        if (typeof rawType !== "string") return "Font";
        const key = rawType.toLowerCase().replace(/[^a-z]/g, "");
        const aliases: Record<string, string> = {
            frame: "Frame", padding: "Padding", backgroundcolor: "Background Color", bgcolor: "Background Color",
            background: "Background", foregroundcolor: "Foreground Color", textcolor: "Foreground Color",
            fontcolor: "Foreground Color", foreground: "Foreground Color", font: "Font",
            cornerradius: "Corner Radius", clipped: "Frame", shadow: "Shadow", opacity: "Opacity",
            rotation: "Rotation", rotate: "Rotation", scale: "Frame", offset: "Offset",
            clipshape: "Clip Shape", mask: "Mask", blur: "Blur", overlay: "Overlay",
            border: "Border", stroke: "Stroke", textalignment: "Text Alignment",
            fill: "Fill", aspectratio: "Frame", zindex: "Frame", tint: "Tint", glasseffect: "Glass Effect",
        };
        return aliases[key] ?? rawType;
    };

    const readFontValue = (props: Record<string, unknown>, keys: string[]): string | undefined => {
        for (const key of keys) { const v = props[key]; if (typeof v === "string" && v.length > 0) return v; }
        return undefined;
    };

    const hasMeaningfulModifier = (mod: Record<string, unknown>): boolean => {
        const type = String(mod.type ?? "");
        const props = isObject(mod.properties) ? mod.properties as Record<string, unknown> : {};
        if (type === "Font") {
            return typeof props.fontSize === "string" || typeof props.fontWeight === "string" || typeof props.fontDesign === "string";
        }
        if (type === "Frame") {
            return props.widthType !== undefined || props.heightType !== undefined || props.width !== undefined || props.height !== undefined;
        }
        if (type === "Padding") {
            return props.amount !== undefined || props.location !== undefined;
        }
        if (type === "Foreground Color" || type === "Background Color" || type === "Fill" || type === "Stroke" || type === "Tint") {
            return typeof props.color === "string" && props.color.trim().length > 0;
        }
        if (type === "Corner Radius") return props.radius !== undefined;
        if (type === "Opacity") return props.value !== undefined || props.opacity !== undefined;
        if (type === "Shadow") return props.radius !== undefined || props.x !== undefined || props.y !== undefined || props.color !== undefined;
        if (type === "Offset") return props.x !== undefined || props.y !== undefined;
        if (type === "Rotation") return props.degrees !== undefined || props.angle !== undefined;
        if (type === "Blur") return props.radius !== undefined;
        if (type === "Clip Shape") return typeof props.shape === "string";
        if (type === "Text Alignment") return typeof props.alignment === "string";
        if (type === "Border") return props.lineWidth !== undefined || props.color !== undefined;
        if (type === "Background" || type === "Overlay" || type === "Mask") return Array.isArray(mod.children) && mod.children.length > 0;
        return true;
    };

    const withoutNulls = (value: Record<string, unknown>): Record<string, unknown> =>
        Object.fromEntries(Object.entries(value).filter(([, entry]) => entry !== null));

    const visit = (node: AnyComponent): AnyComponent => {
        if (!node || typeof node !== "object") return { type: "Text", properties: { text: "" }, modifiers: [] };

        const inferredType = typeof node.type === "string" ? node.type
            : (Array.isArray(node.children) && node.children.length > 0 ? "VStack"
                : node.properties?.text != null ? "Text" : "Text");
        node.type = coerceType(inferredType);
        if (!isObject(node.properties)) node.properties = {};
        node.properties = withoutNulls(node.properties as Record<string, unknown>);
        if (!Array.isArray(node.modifiers)) node.modifiers = [];

        if (["Stack", "VStack", "HStack"].includes(node.type)) {
            const spacing = node.properties.spacing;
            if (typeof spacing === "number") node.properties.spacing = snapToSpacingScale(spacing);
        }

        if (CONTAINER_PP.has(node.type)) {
            node.children = Array.isArray(node.children) ? node.children.map(visit) : [];
        } else {
            delete node.children;
        }

        // Normalize button labels to editable child content instead of title-only payloads.
        if (node.type === "Button") {
            const props = node.properties as Record<string, unknown>;
            const rawTitle = typeof props.title === "string" ? props.title.trim() : "";
            const hasTextChild = Array.isArray(node.children)
                && node.children.some((child) => isObject(child) && child.type === "Text");
            if (!hasTextChild && rawTitle.length > 0) {
                node.children = [{
                    type: "Text",
                    properties: { text: rawTitle },
                    modifiers: [{ type: "Font", properties: { fontSize: "subheadline", fontWeight: "semibold" } }],
                }];
            }
            delete props.title;
        }

        if (node.type === "Text") {
            const props = node.properties as Record<string, unknown>;
            const tv = typeof props.text === "string" ? props.text.trim() : "";
            const safeText = tv.length > 0 ? sanitizeInternalDisplayText(tv) : "";
            const cleaned = safeText.length > 0 ? sanitizeInstructionalDisplayText(safeText) : "";
            props.text = cleaned.length > 0 ? cleaned : "Text";
        }
        if (node.type === "SF Symbol") {
            const props = node.properties as Record<string, unknown>;
            props.symbolName = typeof props.symbolName === "string" ? normalizeSFSymbolName(props.symbolName) : "questionmark";
        }
        if (node.type === "Gauge") {
            const props = node.properties as Record<string, unknown>;
            const gaugeColor = typeof props.color === "string" ? props.color.trim() : "";
            if (gaugeColor.length > 0) {
                const hasTint = node.modifiers.some((m) => isObject(m) && m.type === "Tint");
                if (!hasTint) {
                    node.modifiers.push({ type: "Tint", properties: { color: gaugeColor } });
                }
            }
        }

        node.modifiers = node.modifiers.map((mod) => {
            let modValue: unknown = mod;
            if (typeof modValue === "string") {
                const raw = modValue;
                modValue = { type: raw.includes(":") ? raw.split(":")[0].trim() : raw.trim(), properties: {} };
            } else if (!isObject(modValue)) {
                modValue = { type: "Font", properties: {} };
            }
            let modObj = modValue as Record<string, unknown>;
            if (!isObject(modObj.properties)) modObj.properties = {};
            modObj.properties = withoutNulls(modObj.properties as Record<string, unknown>);
            modObj.type = normalizeModifierType(modObj.type);

            if (modObj.type === "Padding") {
                const amount = modObj.properties.amount;
                if (typeof amount === "number") modObj.properties.amount = snapToSpacingScale(amount);
            }
            const semanticSurface = adaptiveNeutralSurface(String(modObj.type), modObj.properties.color);
            if (semanticSurface) modObj.properties.color = semanticSurface;

            if (modObj.type === "fontSize" || modObj.type === "fontWeight") {
                const fp = modObj.properties as Record<string, unknown>;
                const cf: Record<string, unknown> = { type: "Font", properties: {} };
                const cfp = cf.properties as Record<string, unknown>;
                if (modObj.type === "fontSize") { const sv = readFontValue(fp, ["value", "fontSize", "size"]); if (sv) cfp.fontSize = sv; }
                if (modObj.type === "fontWeight") { const wv = readFontValue(fp, ["value", "fontWeight", "weight"]); if (wv) cfp.fontWeight = wv; }
                modObj = cf;
            }

            if (modObj.type === "Font") {
                const props = modObj.properties as Record<string, unknown>;
                if (props.fontWeight === undefined) { const w = readFontValue(props, ["weight"]); if (w) props.fontWeight = w; }
                if (props.fontSize === undefined) { const s = readFontValue(props, ["size"]); if (s) props.fontSize = s; }
                if (props.fontDesign === undefined) { const d = readFontValue(props, ["design", "fontDesign"]); if (d) props.fontDesign = d; }
                const weightMap: Record<string, string> = { ultralight: "ultraLight", "ultra-light": "ultraLight", thin: "thin", light: "light", regular: "regular", normal: "regular", medium: "medium", semibold: "semibold", "semi-bold": "semibold", "semi bold": "semibold", bold: "bold", heavy: "heavy", black: "black" };
                const rw = typeof props.fontWeight === "string" ? props.fontWeight.toLowerCase() : "";
                if (rw) props.fontWeight = weightMap[rw] ?? props.fontWeight;
                const sizeMap: Record<string, string> = { largetitle: "largeTitle", "large title": "largeTitle", title: "title", title2: "title2", headline: "headline", body: "body", callout: "callout", subheadline: "subheadline", footnote: "footnote", caption: "caption" };
                const rs = typeof props.fontSize === "string" ? props.fontSize.toLowerCase() : "";
                if (rs) props.fontSize = sizeMap[rs] ?? props.fontSize;
                if (typeof props.fontSize === "string") { const n = Number.parseFloat(props.fontSize); if (Number.isFinite(n)) props.fontSize = String(Math.max(8, Math.min(72, n))); }
                const allowedDesigns = new Set(["default", "serif", "rounded", "monospaced"]);
                const rd = typeof props.fontDesign === "string" ? props.fontDesign.toLowerCase() : "";
                if (rd) { if (allowedDesigns.has(rd)) props.fontDesign = rd; else delete props.fontDesign; }
            }

            if (["Background", "Overlay", "Mask"].includes(modObj.type as string)) {
                if (Array.isArray(modObj.children) && modObj.children.length > 0) {
                    modObj.children = (modObj.children as AnyComponent[]).map(visit);
                } else {
                    // Don't auto-insert placeholder modifier children.
                    // Empty overlay/background/mask modifiers are dropped.
                    (modObj as Record<string, unknown>).__drop = true;
                }
            }

            if (["Foreground Color", "Background Color", "Fill", "Stroke"].includes(modObj.type as string)) {
                const props = modObj.properties as Record<string, unknown>;
                if (typeof props.color !== "string" || props.color.length === 0) {
                    const ac = (typeof props.value === "string" && props.value) || (typeof props.foregroundColor === "string" && props.foregroundColor) || (typeof props.backgroundColor === "string" && props.backgroundColor) || (typeof props.textColor === "string" && props.textColor) || (typeof props.fillColor === "string" && props.fillColor) || (typeof props.strokeColor === "string" && props.strokeColor) || (typeof props.tint === "string" && props.tint) || undefined;
                    if (ac) props.color = ac;
                }
                if (typeof props.color === "string" && props.color.length > 0 && !props.color.includes(":")) {
                    const ov = props.opacity;
                    if (typeof ov === "number" && Number.isFinite(ov)) props.color = `${props.color}:${Math.max(0, Math.min(1, ov))}`;
                }
            }
            return modObj;
        }).filter((mod) => {
            if (!VALID_MODIFIER_TYPES.has(mod.type as string)) return false;
            if ((mod as Record<string, unknown>).__drop === true) return false;
            return hasMeaningfulModifier(mod as Record<string, unknown>);
        });

        // Preserve intentional foreground color choices from generation.
        // Previously we stripped "primary" colors, which could flatten contrast
        // and remove deliberate styling decisions.
        if (node.type === "SF Symbol") {
            node.modifiers = node.modifiers.filter((mod) => {
                if ((mod.type as string) !== "Foreground Color") return true;
                const props = isObject(mod.properties) ? mod.properties : {};
                const color = typeof props.color === "string" ? props.color.toLowerCase() : "";
                return color !== "primary" && color !== "primary:1" && color !== "primary:1.0";
            });
        }

        if (SHAPE_PP.has(node.type)) {
            const hasFill = node.modifiers.some((mod) => (mod.type as string) === "Fill");
            node.modifiers = node.modifiers.flatMap((mod) => {
                if ((mod.type as string) !== "Background Color") return [mod];
                if (hasFill) return [];
                return [{ ...mod, type: "Fill" }];
            });
        }

        const hasCornerRadius = node.modifiers.some((mod) => (mod.type as string) === "Corner Radius");
        if (hasCornerRadius) {
            node.modifiers = node.modifiers.map((mod) => {
                if ((mod.type as string) !== "Border") return mod;
                return { ...mod, type: "Stroke" };
            });
        }

        // Preserve modifier order from generation to avoid unintentionally
        // changing visual semantics. We only normalize/validate modifier data.

        const modifierChildren: AnyComponent[] = [];
        node.modifiers.forEach((mod) => {
            const type = mod.type as string;
            if (!["Background", "Overlay", "Mask"].includes(type)) return;
            const children = Array.isArray(mod.children) ? (mod.children as AnyComponent[]) : [];
            if (children.length === 0) return;
            const rawId = (mod as Record<string, unknown>).id;
            const modId: string = typeof rawId === "string" ? rawId : crypto.randomUUID();
            if (typeof rawId !== "string") (mod as Record<string, unknown>).id = modId;
            modifierChildren.push({ type: "VStack", properties: {}, modifiers: [], children: children.map(visit), modifierId: modId, modifierType: type });
        });

        const existingChildren = Array.isArray(node.children) ? node.children : [];
        const nonModifierChildren = existingChildren.filter((child) => {
            if (!isObject(child)) return true;
            const c = child as Record<string, unknown>;
            return !(typeof c.modifierId === "string" && typeof c.modifierType === "string" && ["Background", "Overlay", "Mask"].includes(c.modifierType));
        });
        if (modifierChildren.length > 0) {
            node.children = [...nonModifierChildren, ...modifierChildren];
        } else if (nonModifierChildren.length !== existingChildren.length) {
            node.children = nonModifierChildren;
        }

        if (Array.isArray(node.children)) {
            node.children = node.children.filter((child) => {
                if (!isObject(child) || child.type !== "Text") return true;
                const props = isObject(child.properties) ? child.properties as Record<string, unknown> : {};
                const text = typeof props.text === "string" ? props.text.trim().toLowerCase() : "";
                const mods = Array.isArray(child.modifiers) ? child.modifiers as Array<Record<string, unknown>> : [];
                const hasMeaningfulMods = mods.some((m) => isObject(m) && hasMeaningfulModifier(m));
                return !(text === "text" && !hasMeaningfulMods);
            });
        }
        return node;
    };

    return cloned.map(visit);
}
// Validation gates run against the normalized component tree.
// Validation gates run against the normalized component tree.

const ALLOWED_SPACING_SCALE = new Set([0, 4, 8, 12, 16, 24, 32]);
const SPACING_SCALE = [...ALLOWED_SPACING_SCALE];

export function snapToSpacingScale(value: number): number {
    if (!Number.isFinite(value)) return 0;
    return SPACING_SCALE.reduce((best, candidate) =>
        Math.abs(candidate - value) <= Math.abs(best - value) ? candidate : best
    );
}

function getComponentDepth(component: AnyComponent): number {
    if (!Array.isArray(component.children) || component.children.length === 0) return 1;
    return 1 + Math.max(...component.children.map(getComponentDepth));
}

export function detectLowQualitySlotOutput(component: AnyComponent): string[] {
    let textNodeCount = 0;
    let placeholderTextCount = 0;
    let questionMarkSymbolCount = 0;
    let emptyFontModifierCount = 0;
    let duplicateFontChainCount = 0;
    let genericFallbackCopyCount = 0;
    const internalDiagnostics: string[] = [];
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
            if (containsInternalDiagnostic(text)) internalDiagnostics.push(text.trim().slice(0, 120));
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
    if (internalDiagnostics.length > 0) issues.push(`internal diagnostic text detected (${internalDiagnostics.length})`);
    issues.push(...findSpacingScaleViolations(component));
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
        if (n.modifiers.some((m) => isObject(m) && (m.type === "Blur" || m.type === "Glass Effect"))) found = true;
    });
    return found;
}

export function findInvalidGlassSurfaceUsage(component: AnyComponent): string[] {
    const issues: string[] = [];
    walkComponentTree(component, (n) => {
        if (!Array.isArray(n.modifiers) || n.modifiers.length === 0) return;
        const hasGlass = n.modifiers.some((m) => isObject(m) && m.type === "Glass Effect");
        if (!hasGlass) return;
        const hasFill = n.modifiers.some((m) => isObject(m) && m.type === "Fill");
        const hasBackground = n.modifiers.some((m) => isObject(m) && m.type === "Background Color");
        if (hasFill || hasBackground) {
            issues.push(`${n.type} uses Glass Effect together with ${[hasFill ? "Fill" : null, hasBackground ? "Background Color" : null].filter(Boolean).join(" + ")}`);
        }
    });
    return issues;
}

export function findSpacingScaleViolations(component: AnyComponent): string[] {
    let stackSpacingViolations = 0;
    let paddingViolations = 0;

    walkComponentTree(component, (n) => {
        if (
            (n.type === "Stack" || n.type === "VStack" || n.type === "HStack") &&
            isObject(n.properties) &&
            typeof n.properties.spacing === "number" &&
            !ALLOWED_SPACING_SCALE.has(n.properties.spacing)
        ) {
            stackSpacingViolations += 1;
        }

        if (!Array.isArray(n.modifiers)) return;
        for (const mod of n.modifiers) {
            if (!isObject(mod) || mod.type !== "Padding" || !isObject(mod.properties)) continue;
            const amount = mod.properties.amount;
            if (typeof amount === "number" && !ALLOWED_SPACING_SCALE.has(amount)) {
                paddingViolations += 1;
            }
        }
    });

    const issues: string[] = [];
    if (stackSpacingViolations > 0) issues.push(`off-scale stack spacing values detected (${stackSpacingViolations})`);
    if (paddingViolations > 0) issues.push(`off-scale padding values detected (${paddingViolations})`);
    return issues;
}

type RGBA = { r: number; g: number; b: number; a: number };

const NAMED_COLORS: Record<string, [number, number, number]> = {
    black: [0, 0, 0], white: [255, 255, 255], gray: [142, 142, 147],
    red: [255, 59, 48], orange: [255, 149, 0], yellow: [255, 204, 0],
    green: [52, 199, 89], mint: [0, 199, 190], teal: [48, 176, 199],
    cyan: [50, 173, 230], blue: [0, 122, 255], indigo: [88, 86, 214],
    purple: [175, 82, 222], pink: [255, 45, 85], brown: [162, 132, 94],
};

function semanticColor(key: string, colorScheme: "light" | "dark"): RGBA | null {
    const dark = colorScheme === "dark";
    const foreground = dark ? 255 : 0;
    const semantic: Record<string, RGBA> = {
        primary: { r: foreground, g: foreground, b: foreground, a: 1 },
        secondary: { r: foreground, g: foreground, b: foreground, a: 0.60 },
        tertiary: { r: foreground, g: foreground, b: foreground, a: 0.36 },
        quaternary: { r: foreground, g: foreground, b: foreground, a: 0.18 },
        systembackground: dark ? { r: 0, g: 0, b: 0, a: 1 } : { r: 255, g: 255, b: 255, a: 1 },
        secondarysystembackground: dark ? { r: 28, g: 28, b: 30, a: 1 } : { r: 242, g: 242, b: 247, a: 1 },
        tertiarysystembackground: dark ? { r: 44, g: 44, b: 46, a: 1 } : { r: 255, g: 255, b: 255, a: 1 },
        systemfill: { r: foreground, g: foreground, b: foreground, a: 0.20 },
        secondarysystemfill: { r: foreground, g: foreground, b: foreground, a: 0.16 },
        tertiarysystemfill: { r: foreground, g: foreground, b: foreground, a: 0.12 },
        quaternarysystemfill: { r: foreground, g: foreground, b: foreground, a: 0.08 },
    };
    return semantic[key] ?? null;
}

function parseSchemaColor(value: unknown, colorScheme: "light" | "dark"): RGBA | null {
    if (typeof value !== "string") return null;
    const [rawColor, rawOpacity] = value.trim().split(":");
    const key = rawColor.toLowerCase().replace(/^\./, "");
    const opacity = rawOpacity == null ? 1 : Number(rawOpacity);
    if (!Number.isFinite(opacity)) return null;

    const resolvedSemantic = semanticColor(key, colorScheme);
    if (resolvedSemantic) return { ...resolvedSemantic, a: resolvedSemantic.a * Math.min(1, Math.max(0, opacity)) };
    if (["accent", "surface", "onsurface", "border", "clear"].includes(key)) return null;

    let rgb = NAMED_COLORS[key];
    if (!rgb && /^#[0-9a-f]{6}$/i.test(rawColor)) {
        rgb = [
            Number.parseInt(rawColor.slice(1, 3), 16),
            Number.parseInt(rawColor.slice(3, 5), 16),
            Number.parseInt(rawColor.slice(5, 7), 16),
        ];
    }
    return rgb ? { r: rgb[0], g: rgb[1], b: rgb[2], a: Math.min(1, Math.max(0, opacity)) } : null;
}

function composite(foreground: RGBA, background: RGBA): RGBA {
    const alpha = foreground.a + background.a * (1 - foreground.a);
    if (alpha <= 0) return { r: 0, g: 0, b: 0, a: 0 };
    return {
        r: (foreground.r * foreground.a + background.r * background.a * (1 - foreground.a)) / alpha,
        g: (foreground.g * foreground.a + background.g * background.a * (1 - foreground.a)) / alpha,
        b: (foreground.b * foreground.a + background.b * background.a * (1 - foreground.a)) / alpha,
        a: alpha,
    };
}

function relativeLuminance(color: RGBA): number {
    const channel = (value: number) => {
        const normalized = value / 255;
        return normalized <= 0.04045 ? normalized / 12.92 : ((normalized + 0.055) / 1.055) ** 2.4;
    };
    return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b);
}

function contrastRatio(foreground: RGBA, background: RGBA): number {
    const light = Math.max(relativeLuminance(foreground), relativeLuminance(background));
    const dark = Math.min(relativeLuminance(foreground), relativeLuminance(background));
    return (light + 0.05) / (dark + 0.05);
}

function modifierColor(node: AnyComponent, type: string, colorScheme: "light" | "dark"): RGBA | null {
    if (!Array.isArray(node.modifiers)) return null;
    for (let index = node.modifiers.length - 1; index >= 0; index--) {
        const modifier = node.modifiers[index];
        if (!isObject(modifier) || modifier.type !== type || !isObject(modifier.properties)) continue;
        const parsed = parseSchemaColor(modifier.properties.color, colorScheme);
        if (parsed) return parsed;
    }
    return null;
}

export function findAccessibilityViolations(component: AnyComponent, colorScheme: "light" | "dark" | "both" = "both"): string[] {
    if (colorScheme === "both") {
        return [
            ...findAccessibilityViolations(component, "light").map((issue) => `Light mode: ${issue}`),
            ...findAccessibilityViolations(component, "dark").map((issue) => `Dark mode: ${issue}`),
        ];
    }
    const issues: string[] = [];
    const canvas: RGBA = colorScheme === "dark"
        ? { r: 0, g: 0, b: 0, a: 1 }
        : { r: 255, g: 255, b: 255, a: 1 };

    const visit = (node: AnyComponent, inheritedBackground: RGBA): void => {
        const ownBackground = modifierColor(node, "Background Color", colorScheme);
        const background = ownBackground ? composite(ownBackground, inheritedBackground) : inheritedBackground;
        if (node.type === "Text") {
            const foreground = modifierColor(node, "Foreground Color", colorScheme);
            if (foreground) {
                const renderedForeground = composite(foreground, background);
                const ratio = contrastRatio(renderedForeground, background);
                if (ratio < 3) issues.push(`Text contrast ${ratio.toFixed(2)}:1 is below 3:1`);
            }
        }
        if (node.type === "Button" && Array.isArray(node.modifiers)) {
            for (const modifier of node.modifiers) {
                if (!isObject(modifier) || modifier.type !== "Frame" || !isObject(modifier.properties)) continue;
                const width = modifier.properties.widthType === "Custom" ? modifier.properties.width : null;
                const height = modifier.properties.heightType === "Custom" ? modifier.properties.height : null;
                if ((typeof width === "number" && width < 44) || (typeof height === "number" && height < 44)) {
                    issues.push(`Button has an explicit tap target below 44pt`);
                }
            }
        }
        if (Array.isArray(node.children)) {
            for (const child of node.children) visit(child, background);
        }
        if (Array.isArray(node.modifiers)) {
            for (const modifier of node.modifiers) {
                if (!isObject(modifier) || !Array.isArray(modifier.children)) continue;
                for (const child of modifier.children) {
                    if (isObject(child) && typeof child.type === "string") visit(child as AnyComponent, background);
                }
            }
        }
    };
    visit(component, canvas);
    return [...new Set(issues)];
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
    const issues: string[] = [...findInvalidGlassSurfaceUsage(component), ...findSpacingScaleViolations(component)];
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
                issues.push("Timeline/feed requested translucent treatment but no Blur or Glass Effect modifier found.");
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
        if (slot.slotType === "settings_list") {
            issues.push(...validateExactCountForSlot(slot, component, req));
            if (must.includes("push notifications")) {
                const labels = new Set<string>();
                let switchCount = 0;
                walkComponentTree(component, (node) => {
                    if (node.type === "Switch") switchCount += 1;
                    if (node.type === "Text" && isObject(node.properties) && typeof node.properties.text === "string") {
                        labels.add(node.properties.text.trim().toLowerCase());
                    }
                });
                const requiredLabels = ["push notifications", "email updates", "sounds", "badges"];
                for (const label of requiredLabels) {
                    if (!labels.has(label)) issues.push(`Notification preferences are missing the \"${label}\" row.`);
                }
                if (!labels.has("notifications")) issues.push("Notification preferences require a visible Notifications section label.");
                if (must.includes("dark mode") && (!labels.has("appearance") || !labels.has("dark mode"))) {
                    issues.push("Dark Mode must appear under a visible Appearance section.");
                }
                const expectedSwitches = must.includes("dark mode") ? 5 : 4;
                if (switchCount < expectedSwitches) issues.push(`Notification preferences require at least ${expectedSwitches} distinct Switch controls.`);
            }
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
