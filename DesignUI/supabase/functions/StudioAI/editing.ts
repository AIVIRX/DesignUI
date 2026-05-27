import type { AnyComponent, EditIntent } from "./types.ts";
import { SELECTION_MODEL, STYLE_PATCH_MAX_TOKENS, callOpenAI } from "./openai.ts";
import { CANVAS_SETTINGS_RULES, CONTAINER_TYPES, SCHEMA_RULES } from "./schema.ts";
import { isJsonParseError, isObject, parseJsonSafe } from "./utils.ts";

// ─── Selection editing (unchanged from v1) ───────────────────────────────────

export function getComponentDepth(component: AnyComponent): number {
    if (!Array.isArray(component.children) || component.children.length === 0) return 1;
    return 1 + Math.max(...component.children.map(getComponentDepth));
}

export function buildSelectionSystemPrompt(component: AnyComponent, intent: EditIntent): string {
    const isContainerNode = CONTAINER_TYPES.has(component.type);
    const isText = component.type === "Text";
    const isSymbol = component.type === "SF Symbol";
    const childCount = isContainerNode ? (component.children?.length ?? 0) : 0;

    const focusHints: Record<EditIntent, string> = {
        style: `Focus ONLY on modifiers. Preserve type, properties, and children EXACTLY. Do not rewrite copy.`,
        layout: `Focus ONLY on Frame, Padding, alignment properties. Preserve all other modifiers and all content.`,
        structure: isContainerNode
            ? `You may add or remove children. Preserve all modifiers and properties of the container itself.`
            : `This is a leaf node (${component.type}). It cannot have children. Suggest wrapping instead.`,
        content: isText ? `Update properties.text only. Preserve ALL modifiers exactly.`
            : isSymbol ? `Update properties.symbolName only. Use only valid SF Symbol names.`
                : `Update relevant data properties only. Do not change modifiers or children structure.`,
        wrap: `Return a new container that WRAPS the selected component as a child unchanged inside children[].`,
        canvas: `Return only canvas_settings changes. Output: { "canvas_settings": { ... } }`,
        unknown: `Apply the user's change. Preserve everything not mentioned. Err toward minimal changes.`,
    };

    return `You are a SwiftUI component editor. The user has a component selected.
Return the updated component as JSON. Output shape: {"component": UIComponent}

Infer intent: styling edits → modify modifiers only. Adding/removing children → keep all others.
Never change Text.properties.text unless the user explicitly asks to change the wording.
When changing font, use a single "Font" modifier with fontSize and/or fontWeight.
For color changes use "Foreground Color" with { "color": "colorname:opacity" }.
Clamp numeric fontSize to 8...72. Never return empty text for Text components.
If user gives an explicit numeric font size (e.g. 50), use that exact value (clamped 8...72), as a numeric string.
For style-only requests ("make red", "increase font"), do not alter structure, children, or text copy.

${SCHEMA_RULES}
${CANVAS_SETTINGS_RULES}

--- EDIT CONTEXT ---
SELECTED TYPE: ${component.type}
EDIT INTENT: ${intent}
CONSTRAINT: ${focusHints[intent]}
TREE DEPTH: ${getComponentDepth(component)} levels
CHILDREN COUNT: ${isContainerNode ? childCount : "N/A (leaf node)"}
--- END EDIT CONTEXT ---`;
}

export const STYLE_PATCH_SYSTEM_PROMPT = `You are a SwiftUI modifier patcher.
Given the CURRENT modifiers array and a user request, return ONLY the updated modifiers array.
Output shape: { "modifiers": [...] }
- Preserve modifiers not mentioned in the request.
- Use exact modifier type strings from the schema.
- Font: { "type": "Font", "properties": { "fontSize": string, "fontWeight": string } }
- Color: { "type": "Foreground Color", "properties": { "color": "colorname:opacity" } }
- Do NOT add children, change properties, or return the full component.`;

export function parseRequestedColor(prompt: string): string | null {
    const p = prompt.toLowerCase();
    const hexMatch = p.match(/#([0-9a-f]{6})\b/i);
    if (hexMatch) {
        return `#${hexMatch[1].toUpperCase()}:1.0`;
    }
    const colors = ["primary", "secondary", "tertiary", "quaternary", "red", "blue", "green", "orange", "purple", "yellow", "teal", "pink", "gray", "white", "black", "mint", "indigo", "cyan", "brown"];
    let match: string | null = null;
    for (const color of colors) {
        const re = new RegExp(`\\b${color}\\b`);
        if (re.test(p)) {
            match = color;
            break;
        }
    }
    if (!match) return null;
    const opacityMatch = p.match(/(?:opacity|alpha)\s*(?:to|=|:)?\s*(\d{1,3}(?:\.\d+)?)/);
    if (opacityMatch) {
        const raw = Number(opacityMatch[1]);
        const normalized = raw > 1 ? raw / 100 : raw;
        const opacity = Math.max(0, Math.min(1, normalized));
        return `${match}:${opacity.toFixed(2).replace(/\.?0+$/, "")}`;
    }
    return `${match}:1.0`;
}

export function semanticFontSizeToNumber(size: string): number | null {
    const key = size.trim();
    const map: Record<string, number> = {
        largeTitle: 34, title: 28, title2: 22, title3: 20, headline: 17, body: 17, callout: 16,
        subheadline: 15, footnote: 13, caption: 12, caption2: 11,
    };
    if (map[key]) return map[key];
    const n = Number(key);
    return Number.isFinite(n) ? n : null;
}

export function parseRequestedFontSize(prompt: string): { target: number; explicit: boolean } | null {
    const p = prompt.toLowerCase();
    const hasFontContext = /\bfont\b|\btext\b|\btitle\b|\blabel\b|\bheadline\b|\btypography\b/.test(p);
    const explicit = p.match(/(?:font(?:\s*size)?|text(?:\s*size)?|title(?:\s*size)?|label(?:\s*size)?)\s*(?:to|=|:)?\s*(\d{1,3})/);
    if (explicit) {
        return { target: Math.max(8, Math.min(72, Number(explicit[1]))), explicit: true };
    }
    const loose = p.match(/\b(\d{1,3})\s*(?:pt|px)?\b/);
    if (loose && hasFontContext) {
        return { target: Math.max(8, Math.min(72, Number(loose[1]))), explicit: true };
    }
    if (hasFontContext && /\bbigger\b|\blarger\b|\bincrease\b/.test(p)) {
        return { target: 0, explicit: false };
    }
    return null;
}

export function applyDeterministicModifierEdits(component: AnyComponent, prompt: string): AnyComponent | null {
    const p = prompt.toLowerCase();
    const cloned = JSON.parse(JSON.stringify(component)) as AnyComponent;
    if (!Array.isArray(cloned.modifiers)) cloned.modifiers = [];
    const modifiers = [...cloned.modifiers];
    let touched = false;

    const hasAny = (...patterns: string[]) => patterns.some((pattern) => new RegExp(pattern, "i").test(prompt));
    const extractNumber = (...patterns: RegExp[]): number | null => {
        for (const pattern of patterns) {
            const m = p.match(pattern);
            if (!m) continue;
            const v = Number(m[1]);
            if (Number.isFinite(v)) return v;
        }
        return null;
    };
    const parseAxisValue = (axis: "x" | "y"): number | null => {
        const m = p.match(new RegExp(`\\b${axis}\\b\\s*(?:to|=|:)?\\s*(-?\\d+(?:\\.\\d+)?)`));
        if (!m) return null;
        const v = Number(m[1]);
        return Number.isFinite(v) ? v : null;
    };
    const getCurrentModifierProp = (type: string, key: string, fallback = 0): number => {
        const mod = modifiers.find((m) => isObject(m) && m.type === type);
        if (!mod || !isObject(mod.properties)) return fallback;
        const raw = (mod.properties as Record<string, unknown>)[key];
        if (typeof raw === "number" && Number.isFinite(raw)) return raw;
        if (typeof raw === "string") {
            const v = Number(raw);
            if (Number.isFinite(v)) return v;
        }
        return fallback;
    };
    const hasIncreaseIntent = /\b(increase|raise|boost|more|larger|bigger|higher|up)\b/.test(p);
    const hasDecreaseIntent = /\b(decrease|lower|reduce|less|smaller|down)\b/.test(p);
    const defaultRelativeStep = (kind: "size" | "small" | "angle" | "opacity"): number => {
        if (kind === "size") return 8;
        if (kind === "small") return 2;
        if (kind === "angle") return 15;
        return 0.1;
    };
    const parseRelativeDelta = (anchor: RegExp, kind: "size" | "small" | "angle" | "opacity"): number | null => {
        if (!anchor.test(p)) return null;
        const byMatch = p.match(/\bby\s+(-?\d+(?:\.\d+)?)\b/);
        if (byMatch) {
            const raw = Number(byMatch[1]);
            if (Number.isFinite(raw)) {
                const mag = kind === "opacity" ? toOpacity(Math.abs(raw)) : Math.abs(raw);
                if (hasDecreaseIntent) return -mag;
                if (hasIncreaseIntent) return mag;
                return raw;
            }
        }
        if (!hasIncreaseIntent && !hasDecreaseIntent) return null;
        const magnitude = defaultRelativeStep(kind);
        return hasDecreaseIntent ? -magnitude : magnitude;
    };
    const toOpacity = (v: number) => {
        const normalized = v > 1 ? v / 100 : v;
        return Math.max(0, Math.min(1, normalized));
    };
    const parseDimensionType = (axis: "width" | "height"): "Custom" | "Default" | "Full" | null => {
        if (new RegExp(`\\b${axis}\\b.*\\b(full|fill|max)\\b`).test(p)) return "Full";
        if (new RegExp(`\\b${axis}\\b.*\\b(default|auto|intrinsic)\\b`).test(p)) return "Default";
        if (new RegExp(`\\b${axis}\\b.*\\b(custom|fixed)\\b`).test(p)) return "Custom";
        return null;
    };
    const parsePaddingLocation = (): string | null => {
        if (/\bhorizontal\b/.test(p)) return "horizontal";
        if (/\bvertical\b/.test(p)) return "vertical";
        if (/\bleading\b|\bleft\b/.test(p)) return "leading";
        if (/\btrailing\b|\bright\b/.test(p)) return "trailing";
        if (/\btop\b/.test(p)) return "top";
        if (/\bbottom\b/.test(p)) return "bottom";
        if (/\ball\b/.test(p)) return "all";
        return null;
    };
    const parseFontWeight = (): string | null => {
        const weights = ["ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"] as const;
        const aliases: Record<string, string> = {
            "ultralight": "ultraLight", "ultra light": "ultraLight",
            "semi bold": "semibold", "semi-bold": "semibold",
        };
        for (const w of weights) {
            if (new RegExp(`\\b${w}\\b`, "i").test(prompt)) return w;
        }
        for (const [k, v] of Object.entries(aliases)) {
            if (new RegExp(`\\b${k}\\b`).test(p)) return v;
        }
        if (/\bbolder\b|\bbolden\b/.test(p)) return "bold";
        if (/\blighter\b/.test(p)) return "light";
        return null;
    };
    const parseFontDesign = (): string | null => {
        if (/\bserif\b/.test(p)) return "serif";
        if (/\brounded\b/.test(p)) return "rounded";
        if (/\bmonospaced\b|\bmono\b/.test(p)) return "monospaced";
        if (/\bdefault\b/.test(p)) return "default";
        return null;
    };
    const parseClipShape = (): string | null => {
        if (/\bcircle\b/.test(p)) return "Circle";
        if (/\bcapsule\b|\bpill\b/.test(p)) return "Capsule";
        if (/\bellipse\b|\boval\b/.test(p)) return "Ellipse";
        if (/\brounded rectangle\b|\broundedrectangle\b/.test(p)) return "RoundedRectangle";
        if (/\brectangle\b/.test(p)) return "Rectangle";
        return null;
    };
    const parseTextAlignment = (): string | null => {
        if (/\bcenter(?:ed)?\b/.test(p)) return "center";
        if (/\btrailing\b|\bright\b/.test(p)) return "trailing";
        if (/\bleading\b|\bleft\b/.test(p)) return "leading";
        return null;
    };
    const makeDefaultModifierChild = (type: "Background" | "Overlay" | "Mask"): AnyComponent => {
        if (type === "Mask") return { type: "Circle", properties: {}, modifiers: [] };
        if (type === "Overlay") return { type: "Text", properties: { text: "Text" }, modifiers: [] };
        return { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [] };
    };
    const removeModifier = (type: string) => {
        const before = modifiers.length;
        for (let i = modifiers.length - 1; i >= 0; i--) {
            if (isObject(modifiers[i]) && modifiers[i].type === type) modifiers.splice(i, 1);
        }
        if (modifiers.length !== before) touched = true;
    };
    const upsertModifier = (type: string, nextProps: Record<string, unknown>, merge = true, children?: AnyComponent[]) => {
        const idx = modifiers.findIndex((m) => isObject(m) && m.type === type);
        const current = idx >= 0 && isObject(modifiers[idx].properties)
            ? modifiers[idx].properties as Record<string, unknown>
            : {};
        const updated = merge ? { ...current, ...nextProps } : { ...nextProps };
        const nextMod: Record<string, unknown> = { type, properties: updated };
        if (children) nextMod.children = children;
        if (idx >= 0) modifiers[idx] = nextMod;
        else modifiers.push(nextMod);
        touched = true;
    };
    const readCurrentFrameDimension = (axis: "width" | "height"): number => {
        const modValue = getCurrentModifierProp("Frame", axis, Number.NaN);
        if (Number.isFinite(modValue)) return Math.max(0, modValue);
        const componentRecord = component as Record<string, unknown>;
        const rawFrame = componentRecord.frame;
        if (isObject(rawFrame)) {
            const raw = (rawFrame as Record<string, unknown>)[axis];
            const n = typeof raw === "number" ? raw : Number(raw);
            if (Number.isFinite(n)) return Math.max(0, n);
        }
        if (Array.isArray(rawFrame) && rawFrame.length >= 2 && Array.isArray(rawFrame[1])) {
            const idx = axis === "width" ? 0 : 1;
            const raw = (rawFrame[1] as unknown[])[idx];
            const n = typeof raw === "number" ? raw : Number(raw);
            if (Number.isFinite(n)) return Math.max(0, n);
        }
        return 100;
    };
    const findPaddingModifierIndex = (location: string): number => modifiers.findIndex((m) =>
        isObject(m) &&
        m.type === "Padding" &&
        isObject(m.properties) &&
        String((m.properties as Record<string, unknown>).location ?? "all").toLowerCase() === location
    );
    const readPaddingAmount = (location: "horizontal" | "vertical"): number => {
        const exactIdx = findPaddingModifierIndex(location);
        if (exactIdx >= 0 && isObject(modifiers[exactIdx].properties)) {
            const raw = (modifiers[exactIdx].properties as Record<string, unknown>).amount;
            const n = typeof raw === "number" ? raw : Number(raw);
            if (Number.isFinite(n)) return Math.max(0, n);
        }
        const allIdx = findPaddingModifierIndex("all");
        if (allIdx >= 0 && isObject(modifiers[allIdx].properties)) {
            const raw = (modifiers[allIdx].properties as Record<string, unknown>).amount;
            const n = typeof raw === "number" ? raw : Number(raw);
            if (Number.isFinite(n)) return Math.max(0, n);
        }
        return 0;
    };
    const upsertPaddingAxis = (location: "horizontal" | "vertical", amount: number) => {
        const clamped = Math.max(0, amount);
        const idx = findPaddingModifierIndex(location);
        const nextProps: Record<string, unknown> = { amount: clamped, location };
        if (idx >= 0) {
            const nextMod: Record<string, unknown> = { ...(modifiers[idx] as Record<string, unknown>), properties: nextProps };
            modifiers[idx] = nextMod;
        } else {
            modifiers.push({ type: "Padding", properties: nextProps });
        }
        touched = true;
    };

    // Global add/remove modifier directives
    const removeRequested = /\b(remove|delete|clear|strip|disable|turn off|without|no)\b/.test(p);
    const resetRequested = /\b(reset|default)\b/.test(p);
    const resetAllRequested = /\b(?:reset|default)\s+(?:all|everything)\b/.test(p);
    const hasShapeLikeType = ["Shape", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse"].includes(component.type);
    const requestedNoFill = /\b(no fill|without fill|remove fill|clear fill)\b/.test(p);
    const requestedNoBorder = /\b(no border|without border|remove border|clear border)\b/.test(p);
    const requestedNoStroke = /\b(no stroke|without stroke|remove stroke|clear stroke|no outline|without outline)\b/.test(p);
    const hasCornerRadiusNow = modifiers.some((m) => isObject(m) && m.type === "Corner Radius");
    const preferStroke = hasShapeLikeType || hasCornerRadiusNow;
    const modifierPhraseMap: Array<{ type: string; re: RegExp }> = [
        { type: "Frame", re: /\bframe\b|\bwidth\b|\bheight\b|\bfull width\b|\bfull height\b/ },
        { type: "Padding", re: /\bpadding\b|\bpad\b|\binset\b/ },
        { type: "Background Color", re: /\bbackground color\b|\bbg color\b/ },
        { type: "Foreground Color", re: /\bforeground color\b|\btext color\b/ },
        { type: "Font", re: /\bfont\b|\bweight\b|\btext size\b/ },
        { type: "Corner Radius", re: /\bcorner radius\b|\brounded\b/ },
        { type: "Shadow", re: /\bshadow\b/ },
        { type: "Opacity", re: /\bopacity\b|\balpha\b|\btransparent\b/ },
        { type: "Border", re: /\bborder\b/ },
        { type: "Stroke", re: /\bstroke\b|\boutline\b/ },
        { type: "Background", re: /\bbackground layer\b|\bbackground element\b/ },
        { type: "Overlay", re: /\boverlay\b/ },
        { type: "Mask", re: /\bmask\b/ },
        { type: "Blur", re: /\bblur\b/ },
        { type: "Tint", re: /\btint\b/ },
        { type: "Rotation", re: /\brotate\b|\brotation\b|\bangle\b/ },
        { type: "Offset", re: /\boffset\b|\bmove\b|\bshift\b|\bnudge\b/ },
        { type: "Fill", re: /\bfill\b/ },
        { type: "Clip Shape", re: /\bclip shape\b/ },
        { type: "Text Alignment", re: /\balign(?:ment)?\b/ },
        { type: "Glass Effect", re: /\bglass\b|\bliquid\b|\bfrost(ed)?\b/ },
    ];
    if (removeRequested) {
        for (const item of modifierPhraseMap) {
            if (item.re.test(p)) removeModifier(item.type);
        }
    }
    if (requestedNoFill) removeModifier("Fill");
    if (requestedNoBorder) removeModifier("Border");
    if (requestedNoStroke) removeModifier("Stroke");

    const shouldReset = (re: RegExp) => resetAllRequested || (resetRequested && re.test(p));
    if (shouldReset(/\bframe\b|\bwidth\b|\bheight\b|\bsize\b/)) {
        upsertModifier("Frame", { widthType: "Default", heightType: "Default", width: 100, height: 100 }, false);
    }
    if (shouldReset(/\bpadding\b|\bpad\b|\binset\b/)) {
        upsertPaddingAxis("horizontal", 0);
        upsertPaddingAxis("vertical", 0);
    }
    if (shouldReset(/\boffset\b|\bposition\b|\bmove\b|\bshift\b|\bnudge\b/)) {
        upsertModifier("Offset", { x: 0, y: 0 }, false);
    }
    if (shouldReset(/\brotation\b|\brotate\b|\bangle\b/)) {
        upsertModifier("Rotation", { angle: 0 }, false);
    }
    if (shouldReset(/\bblur\b/)) {
        upsertModifier("Blur", { radius: 0 }, false);
    }
    if (shouldReset(/\bopacity\b|\balpha\b|\btransparent\b/)) {
        upsertModifier("Opacity", { opacity: 1 }, false);
    }
    if (shouldReset(/\bcorner radius\b|\bradius\b|\brounded\b/)) {
        upsertModifier("Corner Radius", { radius: 0 }, false);
    }
    if (shouldReset(/\bshadow\b/)) {
        upsertModifier("Shadow", { radius: 0, x: 0, y: 0, color: "black", opacity: 0.3 }, false);
    }
    if (shouldReset(/\bborder\b/)) {
        upsertModifier("Border", { width: 1, color: "primary:1.0" }, false);
    }
    if (shouldReset(/\bstroke\b|\boutline\b/)) {
        upsertModifier("Stroke", { lineWidth: 1, color: "color:gray" }, false);
    }
    if (shouldReset(/\bfill\b/)) {
        upsertModifier("Fill", { color: "primary:1.0" }, false);
    }
    if (shouldReset(/\btint\b/)) {
        upsertModifier("Tint", { color: "blue:1.0" }, false);
    }
    if (shouldReset(/\bglass\b|\bliquid\b|\bfrost(ed)?\b/)) {
        upsertModifier("Glass Effect", { shape: "RoundedRectangle", cornerRadius: 10 }, false);
    }
    if (shouldReset(/\bfont\b|\btext size\b|\bweight\b|\btypography\b/)) {
        upsertModifier("Font", { fontSize: "body", fontWeight: "regular" }, false);
    }

    // Color + font edits
    const requestedColor = parseRequestedColor(prompt);
    if (requestedColor && hasAny("\\btint\\b")) {
        upsertModifier("Tint", { color: requestedColor });
    }
    if (requestedColor && (hasAny("\\bcolor\\b", "\\bforeground\\b", "\\btext color\\b") || component.type === "Text" || component.type === "SF Symbol")) {
        upsertModifier("Foreground Color", { color: requestedColor });
    }
    if (requestedColor && hasAny("\\bbackground\\b", "\\bbg\\b")) {
        upsertModifier("Background Color", { color: requestedColor });
    }
    if (requestedColor && hasAny("\\bfill\\b") && !requestedNoFill) {
        upsertModifier("Fill", { color: requestedColor });
    }

    const supportsFont = component.type === "Text" || component.type === "SF Symbol";
    const layoutPriorityRequest = /\bpadding\b|\bpad\b|\binset\b|\bframe\b|\bwidth\b|\bheight\b|\boffset\b|\bmove\b|\bshift\b|\bnudge\b/.test(p);
    const explicitFontContext = /\bfont\b|\btext\b|\btitle\b|\blabel\b|\bheadline\b|\btypography\b/.test(p);
    const fontRequest = parseRequestedFontSize(prompt);
    const fontWeight = parseFontWeight();
    const fontDesign = parseFontDesign();
    if (supportsFont && (!layoutPriorityRequest || explicitFontContext) && (fontRequest || fontWeight || fontDesign)) {
        const fontIndex = modifiers.findIndex((m) => isObject(m) && m.type === "Font");
        const currentProps = fontIndex >= 0 && isObject(modifiers[fontIndex].properties)
            ? modifiers[fontIndex].properties as Record<string, unknown>
            : {};
        const currentNumeric = typeof currentProps.fontSize === "string"
            ? semanticFontSizeToNumber(currentProps.fontSize)
            : null;
        const computedSize = fontRequest
            ? (fontRequest.explicit ? fontRequest.target : Math.max(12, Math.min(72, (currentNumeric ?? 17) + 8)))
            : undefined;
        const updatedFont: Record<string, unknown> = {
            ...currentProps,
            ...(computedSize !== undefined ? { fontSize: String(computedSize) } : {}),
            ...(fontWeight ? { fontWeight } : {}),
            ...(fontDesign ? { fontDesign } : {}),
        };
        if (!updatedFont.fontWeight) updatedFont.fontWeight = "regular";
        upsertModifier("Font", updatedFont, false);
    }

    // Frame
    const width = extractNumber(/\bwidth\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bw\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const height = extractNumber(/\bheight\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bh\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const widthDelta = parseRelativeDelta(/\bwidth\b|\bframe\b/, "size");
    const heightDelta = parseRelativeDelta(/\bheight\b|\bframe\b/, "size");
    const frameAmount = extractNumber(
        /\b(?:add|increase|decrease|reduce)\s*(\d+(?:\.\d+)?)\s*(?:px|pt)?\s*(?:to\s*)?(?:frame|size)\b/,
        /\b(?:add|increase|decrease|reduce)\s*(\d+(?:\.\d+)?)\s*(?:px|pt)?\s*(?:to\s*)?(?:width|height)\b/
    );
    const explicitFrameAdd = /\b(?:add|increase)\s*\d+(?:\.\d+)?\s*(?:px|pt)?\s*(?:to\s*)?(?:frame|size|width|height)\b/.test(p);
    const explicitFrameReduce = /\b(?:decrease|reduce)\s*\d+(?:\.\d+)?\s*(?:px|pt)?\s*(?:to\s*)?(?:frame|size|width|height)\b/.test(p);
    const widthType = parseDimensionType("width");
    const heightType = parseDimensionType("height");
    if (width !== null || height !== null || widthType || heightType || widthDelta !== null || heightDelta !== null || frameAmount !== null) {
        const frameProps: Record<string, unknown> = {};
        const widthRequested = /\bwidth\b/.test(p);
        const heightRequested = /\bheight\b/.test(p);
        const axisRequested = widthRequested || heightRequested;
        const applyFrameDelta = (current: number) => {
            if (frameAmount !== null && (explicitFrameAdd || explicitFrameReduce)) {
                const sign = explicitFrameReduce ? -1 : 1;
                return current + (sign * frameAmount);
            }
            return current;
        };

        if (width !== null) {
            frameProps.widthType = "Custom";
            frameProps.width = Math.max(0, width);
        } else if (widthDelta !== null) {
            frameProps.widthType = "Custom";
            frameProps.width = Math.max(0, readCurrentFrameDimension("width") + widthDelta);
        } else if (frameAmount !== null && !axisRequested) {
            frameProps.widthType = "Custom";
            frameProps.width = Math.max(0, applyFrameDelta(readCurrentFrameDimension("width")));
        } else if (frameAmount !== null && widthRequested) {
            frameProps.widthType = "Custom";
            frameProps.width = Math.max(0, applyFrameDelta(readCurrentFrameDimension("width")));
        }
        if (height !== null) {
            frameProps.heightType = "Custom";
            frameProps.height = Math.max(0, height);
        } else if (heightDelta !== null) {
            frameProps.heightType = "Custom";
            frameProps.height = Math.max(0, readCurrentFrameDimension("height") + heightDelta);
        } else if (frameAmount !== null && !axisRequested) {
            frameProps.heightType = "Custom";
            frameProps.height = Math.max(0, applyFrameDelta(readCurrentFrameDimension("height")));
        } else if (frameAmount !== null && heightRequested) {
            frameProps.heightType = "Custom";
            frameProps.height = Math.max(0, applyFrameDelta(readCurrentFrameDimension("height")));
        }
        if (widthType) frameProps.widthType = widthType;
        if (heightType) frameProps.heightType = heightType;
        upsertModifier("Frame", frameProps);
    }

    // Padding
    const padAmount = extractNumber(
        /\bpadding\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/,
        /\bpad\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/,
        /\binset\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/,
        /\b(?:add|increase|decrease|reduce)\s*(\d+(?:\.\d+)?)\s*(?:px|pt)?\s*(?:horizontal|vertical|leading|trailing|top|bottom)?\s*padding\b/,
        /\b(\d+(?:\.\d+)?)\s*(?:px|pt)?\s*(?:horizontal|vertical|leading|trailing|top|bottom)\s*padding\b/
    );
    const padDelta = parseRelativeDelta(/\bpadding\b|\bpad\b|\binset\b/, "size");
    const padLocation = parsePaddingLocation();
    const explicitPaddingAdd = /\b(?:add|increase)\s*\d+(?:\.\d+)?\s*(?:px|pt)?\s*(?:horizontal|vertical|leading|trailing|top|bottom)?\s*padding\b/.test(p);
    const explicitPaddingReduce = /\b(?:decrease|reduce)\s*\d+(?:\.\d+)?\s*(?:px|pt)?\s*(?:horizontal|vertical|leading|trailing|top|bottom)?\s*padding\b/.test(p);
    if (padAmount !== null || padDelta !== null || /\bpadding\b|\bpad\b|\binset\b/.test(p)) {
        // Axis-specific phrases should affect only that axis; otherwise update both H+V.
        const axisRequested = padLocation === "horizontal" || padLocation === "vertical";
        const applyDelta = (current: number) => {
            if (padAmount !== null && (explicitPaddingAdd || explicitPaddingReduce)) {
                const sign = explicitPaddingReduce ? -1 : 1;
                return current + (sign * padAmount);
            }
            if (padAmount !== null) return padAmount;
            if (padDelta !== null) return current + padDelta;
            return current;
        };

        if (axisRequested) {
            const axis = padLocation as "horizontal" | "vertical";
            const next = Math.max(0, applyDelta(readPaddingAmount(axis)));
            upsertPaddingAxis(axis, next);
        } else {
            const nextHorizontal = Math.max(0, applyDelta(readPaddingAmount("horizontal")));
            const nextVertical = Math.max(0, applyDelta(readPaddingAmount("vertical")));
            upsertPaddingAxis("horizontal", nextHorizontal);
            upsertPaddingAxis("vertical", nextVertical);
        }
    }

    // Corner radius
    const radius = extractNumber(/\bcorner radius\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bradius\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bround(?:ed)?\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const radiusDelta = parseRelativeDelta(/\bcorner radius\b|\bradius\b|\brounded\b/, "size");
    if (radius !== null || radiusDelta !== null) {
        const nextRadius = radius !== null ? radius : getCurrentModifierProp("Corner Radius", "radius", 8) + (radiusDelta ?? 0);
        upsertModifier("Corner Radius", { radius: Math.max(0, Math.min(100, nextRadius)) });
    }

    // Shadow
    if (/\bshadow\b/.test(p)) {
        const shadowRadius = extractNumber(/\bshadow(?:\s+radius)?\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bradius\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
        const shadowRadiusDelta = parseRelativeDelta(/\bshadow\b.*\bradius\b|\bshadow\b/, "small");
        const shadowX = parseAxisValue("x");
        const shadowY = parseAxisValue("y");
        const shadowColor = parseRequestedColor(prompt);
        const shadowOpacityRaw = extractNumber(/(?:shadow\s+)?(?:opacity|alpha)\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
        upsertModifier("Shadow", {
            ...(shadowRadius !== null
                ? { radius: Math.max(0, shadowRadius) }
                : (shadowRadiusDelta !== null ? { radius: Math.max(0, getCurrentModifierProp("Shadow", "radius", 2) + shadowRadiusDelta) } : {})),
            ...(shadowX !== null ? { x: shadowX } : {}),
            ...(shadowY !== null ? { y: shadowY } : {}),
            ...(shadowColor ? { color: shadowColor } : {}),
            ...(shadowOpacityRaw !== null ? { opacity: toOpacity(shadowOpacityRaw) } : {}),
        });
    }

    // Opacity
    const opacityRaw = extractNumber(/\bopacity\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\balpha\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\b(\d{1,3})%\s*opaque\b/);
    const opacityDelta = parseRelativeDelta(/\bopacity\b|\balpha\b|\btransparent\b/, "opacity");
    let inferredOpacity: number | null = null;
    if (/\bfully transparent\b|\binvisible\b/.test(p)) inferredOpacity = 0;
    else if (/\bsemi transparent\b|\bsemi-transparent\b/.test(p)) inferredOpacity = 0.5;
    else if (/\bslightly transparent\b/.test(p)) inferredOpacity = 0.8;
    else if (/\bopaque\b/.test(p)) inferredOpacity = 1;
    if (opacityRaw !== null || inferredOpacity !== null || opacityDelta !== null) {
        const nextOpacity = opacityRaw !== null
            ? toOpacity(opacityRaw)
            : (inferredOpacity !== null
                ? inferredOpacity
                : Math.max(0, Math.min(1, getCurrentModifierProp("Opacity", "opacity", 1) + (opacityDelta ?? 0))));
        upsertModifier("Opacity", { opacity: nextOpacity });
    }

    // Border / Stroke
    const lineWidth = extractNumber(/\bline\s*width\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bborder\s*width\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bstroke\s*width\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const borderColor = parseRequestedColor(prompt);
    if (/\bborder\b/.test(p) && !requestedNoBorder) {
        if (preferStroke) {
            upsertModifier("Stroke", {
                ...(lineWidth !== null ? { lineWidth: Math.max(0, lineWidth) } : {}),
                ...(borderColor ? { color: borderColor } : {}),
            });
            removeModifier("Border");
        } else {
            upsertModifier("Border", {
                ...(lineWidth !== null ? { width: Math.max(0, lineWidth) } : {}),
                ...(borderColor ? { color: borderColor } : {}),
            });
        }
    }
    if (/\bstroke\b|\boutline\b/.test(p) && !requestedNoStroke) {
        upsertModifier("Stroke", {
            ...(lineWidth !== null ? { lineWidth: Math.max(0, lineWidth) } : {}),
            ...(borderColor ? { color: borderColor } : {}),
        });
        removeModifier("Border");
    }

    // Blur
    const blur = extractNumber(/\bblur(?:\s+radius)?\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const blurDelta = parseRelativeDelta(/\bblur\b/, "small");
    if (blur !== null || blurDelta !== null || /\bblur\b/.test(p)) {
        const nextBlur = blur !== null ? blur : Math.max(0, getCurrentModifierProp("Blur", "radius", 0) + (blurDelta ?? 8));
        upsertModifier("Blur", { radius: Math.max(0, nextBlur) });
    }

    // Rotation
    const angle = extractNumber(/\b(?:rotate|rotation|angle)\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/);
    const angleDelta = parseRelativeDelta(/\brotate\b|\brotation\b|\bangle\b/, "angle");
    if (angle !== null || angleDelta !== null || /\brotate\b/.test(p)) {
        const nextAngle = angle !== null ? angle : getCurrentModifierProp("Rotation", "angle", 0) + (angleDelta ?? 15);
        upsertModifier("Rotation", { angle: nextAngle });
    }

    // Offset
    const offsetX = parseAxisValue("x");
    const offsetY = parseAxisValue("y");
    const offsetAmount = extractNumber(
        /\b(?:move|shift|nudge|offset)\s+(?:left|right|up|down)\s*(?:by)?\s*(\d+(?:\.\d+)?)/,
        /\b(?:increase|decrease|reduce)\s+(?:x|y)\s+offset\s*(?:by)?\s*(\d+(?:\.\d+)?)/
    );
    const leftRequested = /\b(?:move|shift|nudge|offset)\s+left\b/.test(p);
    const rightRequested = /\b(?:move|shift|nudge|offset)\s+right\b/.test(p);
    const upRequested = /\b(?:move|shift|nudge|offset)\s+up\b/.test(p);
    const downRequested = /\b(?:move|shift|nudge|offset)\s+down\b/.test(p);
    const xOffsetIncreaseRequested = /\b(?:increase|raise|boost)\s+x\s+offset\b/.test(p);
    const xOffsetDecreaseRequested = /\b(?:decrease|reduce|lower)\s+x\s+offset\b/.test(p);
    const yOffsetIncreaseRequested = /\b(?:increase|raise|boost)\s+y\s+offset\b/.test(p);
    const yOffsetDecreaseRequested = /\b(?:decrease|reduce|lower)\s+y\s+offset\b/.test(p);
    const directionalStep =
        /\b(a bit|slightly|little)\b/.test(p) ? 6 :
            (/\bfar|a lot|significantly\b/.test(p) ? 24 : 12);
    const inferredOffsetX =
        leftRequested ? -directionalStep :
            (rightRequested ? directionalStep : null);
    const inferredOffsetY =
        upRequested ? -directionalStep :
            (downRequested ? directionalStep : null);
    const directionalAmount = offsetAmount ?? directionalStep;
    const exactDirectionalOffsetX =
        leftRequested ? -directionalAmount :
            (rightRequested ? directionalAmount : null);
    const exactDirectionalOffsetY =
        upRequested ? -directionalAmount :
            (downRequested ? directionalAmount : null);
    if (/\boffset\b|\bmove\b|\bshift\b|\bnudge\b/.test(p) || offsetX !== null || offsetY !== null || inferredOffsetX !== null || inferredOffsetY !== null || exactDirectionalOffsetX !== null || exactDirectionalOffsetY !== null || xOffsetIncreaseRequested || xOffsetDecreaseRequested || yOffsetIncreaseRequested || yOffsetDecreaseRequested) {
        const xRelativeDelta = xOffsetIncreaseRequested ? directionalAmount : (xOffsetDecreaseRequested ? -directionalAmount : null);
        const yRelativeDelta = yOffsetIncreaseRequested ? directionalAmount : (yOffsetDecreaseRequested ? -directionalAmount : null);
        upsertModifier("Offset", {
            ...((offsetX !== null || exactDirectionalOffsetX !== null || inferredOffsetX !== null || xRelativeDelta !== null)
                ? { x: offsetX !== null ? offsetX : (exactDirectionalOffsetX !== null ? getCurrentModifierProp("Offset", "x", 0) + exactDirectionalOffsetX : getCurrentModifierProp("Offset", "x", 0) + ((xRelativeDelta ?? inferredOffsetX) ?? 0)) }
                : {}),
            ...((offsetY !== null || exactDirectionalOffsetY !== null || inferredOffsetY !== null || yRelativeDelta !== null)
                ? { y: offsetY !== null ? offsetY : (exactDirectionalOffsetY !== null ? getCurrentModifierProp("Offset", "y", 0) + exactDirectionalOffsetY : getCurrentModifierProp("Offset", "y", 0) + ((yRelativeDelta ?? inferredOffsetY) ?? 0)) }
                : {}),
        });
    }

    // Clip shape
    const clipShape = parseClipShape();
    if (/\bclip shape\b|\bmask shape\b/.test(p) || clipShape) {
        if (removeRequested && (/\bclip shape\b|\bmask shape\b/.test(p))) {
            removeModifier("Clip Shape");
        } else {
            upsertModifier("Clip Shape", { shape: clipShape ?? "Rectangle" });
        }
    }

    // Text alignment
    const textAlignment = parseTextAlignment();
    if (textAlignment && (/\balign(?:ment)?\b/.test(p) || /\btext\b/.test(p))) {
        upsertModifier("Text Alignment", { alignment: textAlignment });
    }

    // Background / Overlay / Mask structural modifiers
    if (/\boverlay\b/.test(p) && !removeRequested) upsertModifier("Overlay", {}, true, [makeDefaultModifierChild("Overlay")]);
    if (/\bbackground\b/.test(p) && /\blayer\b|\belement\b/.test(p) && !removeRequested) {
        upsertModifier("Background", {}, true, [makeDefaultModifierChild("Background")]);
    }
    if (/\bmask\b/.test(p) && !removeRequested) upsertModifier("Mask", {}, true, [makeDefaultModifierChild("Mask")]);

    // Glass effect
    if (/\bglass\b|\bliquid\b|\bfrost(ed)?\b/.test(p)) {
        if (removeRequested) removeModifier("Glass Effect");
        else upsertModifier("Glass Effect", { shape: "RoundedRectangle", cornerRadius: 10 });
    }

    if (!touched) return null;
    cloned.modifiers = modifiers;
    return cloned;
}

export async function applyStylePatch(component: AnyComponent, prompt: string): Promise<AnyComponent | null> {
    const response = await callOpenAI({
        model: SELECTION_MODEL,
        messages: [
            { role: "system", content: STYLE_PATCH_SYSTEM_PROMPT },
            { role: "system", content: `CURRENT MODIFIERS:\n${JSON.stringify(component.modifiers ?? [])}` },
            { role: "user", content: prompt },
        ],
        temperature: 0, maxTokens: STYLE_PATCH_MAX_TOKENS, responseFormat: { type: "json_object" },
    });
    if (!response.ok) return null;
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) return null;
    const result = parsed.value as Record<string, unknown>;
    if (!Array.isArray(result.modifiers)) return null;
    return { ...component, modifiers: result.modifiers as Array<Record<string, unknown>> };
}
