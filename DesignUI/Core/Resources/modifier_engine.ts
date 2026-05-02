export type ModifierEditComponent = {
    type: string;
    properties?: Record<string, unknown>;
    modifiers?: Array<Record<string, unknown>>;
    children?: ModifierEditComponent[];
};

type ModifierEditOpModifier = {
    type: string;
    properties?: Record<string, unknown>;
};

type ModifierEditOperation = {
    op: "update_modifiers";
    nodeId: "root";
    mode: "replace";
    modifiers: ModifierEditOpModifier[];
};

const VALID_OP_MODIFIER_TYPES = new Set([
    "Frame", "Padding", "Background Color", "Foreground Color", "Font", "Corner Radius",
    "Shadow", "Opacity", "Border", "Stroke", "Blur",
    "Scale", "Rotation", "Offset", "Fill", "Clipped", "Clip Shape", "Text Alignment", "Aspect Ratio", "Z Index", "Glass Effect",
]);

function isObject(v: unknown): v is Record<string, unknown> {
    return Boolean(v) && typeof v === "object" && !Array.isArray(v);
}

function parseRequestedColor(prompt: string): string | null {
    const p = prompt.toLowerCase();
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

function semanticFontSizeToNumber(size: string): number | null {
    const key = size.trim();
    const map: Record<string, number> = {
        largeTitle: 34, title: 28, title2: 22, title3: 20, headline: 17, body: 17, callout: 16,
        subheadline: 15, footnote: 13, caption: 12, caption2: 11,
    };
    if (map[key]) return map[key];
    const n = Number(key);
    return Number.isFinite(n) ? n : null;
}

function parseRequestedFontSize(prompt: string): { target: number; explicit: boolean } | null {
    const p = prompt.toLowerCase();
    const explicit = p.match(/(?:font(?:\s*size)?|text(?:\s*size)?|size)\s*(?:to|=|:)?\s*(\d{1,3})/);
    if (explicit) {
        return { target: Math.max(8, Math.min(72, Number(explicit[1]))), explicit: true };
    }
    const loose = p.match(/\b(\d{1,3})\s*(?:pt|px)?\b/);
    if (loose && /(?:\bfont\b|\bsize\b|\btext\b)/.test(p)) {
        return { target: Math.max(8, Math.min(72, Number(loose[1]))), explicit: true };
    }
    if (/\bbigger\b|\blarger\b|\bincrease\b/.test(p)) {
        return { target: 0, explicit: false };
    }
    return null;
}

export function applyDeterministicModifierEdits(component: ModifierEditComponent, prompt: string): ModifierEditComponent | null {
    const p = prompt.toLowerCase();
    const cloned = JSON.parse(JSON.stringify(component)) as ModifierEditComponent;
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
        const m = p.match(new RegExp(`${axis}\\s*(?:to|=|:)?\\s*(-?\\d+(?:\\.\\d+)?)`));
        if (!m) return null;
        const v = Number(m[1]);
        return Number.isFinite(v) ? v : null;
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
    const parseAspectMode = (): string | null => {
        if (/\bfill\b/.test(p)) return "fill";
        if (/\bfit\b/.test(p)) return "fit";
        return null;
    };
    const makeDefaultModifierChild = (type: "Background" | "Overlay" | "Mask"): ModifierEditComponent => {
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
    const upsertModifier = (type: string, nextProps: Record<string, unknown>, merge = true, children?: ModifierEditComponent[]) => {
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

    const removeRequested = /\b(remove|delete|clear|strip|disable|turn off|without|no)\b/.test(p);
    const isRemoveOnly = (re: RegExp) => removeRequested && re.test(p);
    const modifierPhraseMap: Array<{ type: string; re: RegExp }> = [
        { type: "Frame", re: /\bframe\b|\bwidth\b|\bheight\b|\bfull width\b|\bfull height\b/ },
        { type: "Padding", re: /\bpadding\b|\bpad\b|\binset\b/ },
        { type: "Background Color", re: /\bbackground color\b|\bbg color\b/ },
        { type: "Foreground Color", re: /\bforeground color\b|\btext color\b|\btint\b/ },
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
        { type: "Scale", re: /\bscale\b|\bsize up\b|\bsize down\b/ },
        { type: "Rotation", re: /\brotate\b|\brotation\b|\bangle\b/ },
        { type: "Offset", re: /\boffset\b|\bmove\b|\bshift\b|\bnudge\b/ },
        { type: "Fill", re: /\bfill\b/ },
        { type: "Clipped", re: /\bclip(ped)?\b/ },
        { type: "Clip Shape", re: /\bclip shape\b/ },
        { type: "Text Alignment", re: /\balign(?:ment)?\b/ },
        { type: "Aspect Ratio", re: /\baspect\b/ },
        { type: "Z Index", re: /\bz[- ]?index\b|\blayer\b/ },
        { type: "Glass Effect", re: /\bglass\b|\bliquid\b|\bfrost(ed)?\b/ },
    ];
    if (removeRequested) {
        for (const item of modifierPhraseMap) {
            if (item.re.test(p)) removeModifier(item.type);
        }
    }

    const requestedColor = parseRequestedColor(prompt);
    if (requestedColor && !isRemoveOnly(/\bcolor\b|\bforeground\b|\btint\b|\btext color\b/) && (hasAny("\\bcolor\\b", "\\bforeground\\b", "\\btint\\b", "\\btext color\\b") || component.type === "Text" || component.type === "SF Symbol")) {
        upsertModifier("Foreground Color", { color: requestedColor });
    }
    if (requestedColor && !isRemoveOnly(/\bbackground\b|\bbg\b/) && hasAny("\\bbackground\\b", "\\bbg\\b")) {
        upsertModifier("Background Color", { color: requestedColor });
    }
    if (requestedColor && !isRemoveOnly(/\bfill\b/) && hasAny("\\bfill\\b")) {
        upsertModifier("Fill", { color: requestedColor });
    }

    const supportsFont = component.type === "Text" || component.type === "SF Symbol";
    const fontRequest = parseRequestedFontSize(prompt);
    const fontWeight = parseFontWeight();
    const fontDesign = parseFontDesign();
    if (!isRemoveOnly(/\bfont\b|\bweight\b|\bsize\b/) && supportsFont && (fontRequest || fontWeight || fontDesign)) {
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

    const width = extractNumber(/\bwidth\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bw\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const height = extractNumber(/\bheight\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bh\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const widthType = parseDimensionType("width");
    const heightType = parseDimensionType("height");
    if (!isRemoveOnly(/\bframe\b|\bwidth\b|\bheight\b|\bfull width\b|\bfull height\b/) && (width !== null || height !== null || widthType || heightType)) {
        const frameProps: Record<string, unknown> = {};
        if (width !== null) {
            frameProps.widthType = "Custom";
            frameProps.width = Math.max(0, width);
        }
        if (height !== null) {
            frameProps.heightType = "Custom";
            frameProps.height = Math.max(0, height);
        }
        if (widthType) frameProps.widthType = widthType;
        if (heightType) frameProps.heightType = heightType;
        upsertModifier("Frame", frameProps);
    }

    const padAmount = extractNumber(/\bpadding\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bpad\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\binset\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const padLocation = parsePaddingLocation();
    if (!isRemoveOnly(/\bpadding\b|\bpad\b|\binset\b/) && (padAmount !== null || /\bpadding\b|\bpad\b|\binset\b/.test(p))) {
        upsertModifier("Padding", {
            ...(padAmount !== null ? { amount: Math.max(0, padAmount) } : {}),
            ...(padLocation ? { location: padLocation } : {}),
        });
    }

    const radius = extractNumber(/\bcorner radius\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bradius\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bround(?:ed)?\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    if (!isRemoveOnly(/\bcorner radius\b|\bradius\b|\brounded\b/) && radius !== null) upsertModifier("Corner Radius", { radius: Math.max(0, radius) });

    if (/\bshadow\b/.test(p) && !isRemoveOnly(/\bshadow\b/)) {
        const shadowRadius = extractNumber(/\bshadow(?:\s+radius)?\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bradius\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
        const shadowX = parseAxisValue("x");
        const shadowY = parseAxisValue("y");
        const shadowColor = parseRequestedColor(prompt);
        const shadowOpacityRaw = extractNumber(/(?:shadow\s+)?(?:opacity|alpha)\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
        upsertModifier("Shadow", {
            ...(shadowRadius !== null ? { radius: Math.max(0, shadowRadius) } : {}),
            ...(shadowX !== null ? { x: shadowX } : {}),
            ...(shadowY !== null ? { y: shadowY } : {}),
            ...(shadowColor ? { color: shadowColor } : {}),
            ...(shadowOpacityRaw !== null ? { opacity: toOpacity(shadowOpacityRaw) } : {}),
        });
    }

    const opacityRaw = extractNumber(/\bopacity\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\balpha\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\b(\d{1,3})%\s*opaque\b/);
    if (!isRemoveOnly(/\bopacity\b|\balpha\b|\btransparent\b/) && opacityRaw !== null) upsertModifier("Opacity", { opacity: toOpacity(opacityRaw) });

    const lineWidth = extractNumber(/\bline\s*width\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bborder\s*width\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/, /\bstroke\s*width\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const borderColor = parseRequestedColor(prompt);
    if (/\bborder\b/.test(p) && !isRemoveOnly(/\bborder\b/)) {
        upsertModifier("Border", {
            ...(lineWidth !== null ? { width: Math.max(0, lineWidth) } : {}),
            ...(borderColor ? { color: borderColor } : {}),
        });
    }
    if ((/\bstroke\b|\boutline\b/.test(p)) && !isRemoveOnly(/\bstroke\b|\boutline\b/)) {
        upsertModifier("Stroke", {
            ...(lineWidth !== null ? { lineWidth: Math.max(0, lineWidth) } : {}),
            ...(borderColor ? { color: borderColor } : {}),
        });
    }

    const blur = extractNumber(/\bblur(?:\s+radius)?\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    if (!isRemoveOnly(/\bblur\b/) && (blur !== null || /\bblur\b/.test(p))) upsertModifier("Blur", { radius: Math.max(0, blur ?? 8) });

    const scaleUniform = extractNumber(/\bscale\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/, /\bzoom\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/);
    const scaleX = extractNumber(/\bscale\s*x\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/, /\bx\s*scale\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/);
    const scaleY = extractNumber(/\bscale\s*y\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/, /\by\s*scale\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/);
    if (!isRemoveOnly(/\bscale\b|\bzoom\b/) && (scaleUniform !== null || scaleX !== null || scaleY !== null)) {
        upsertModifier("Scale", {
            ...(scaleUniform !== null ? { x: scaleUniform, y: scaleUniform } : {}),
            ...(scaleX !== null ? { x: scaleX } : {}),
            ...(scaleY !== null ? { y: scaleY } : {}),
        });
    }

    const angle = extractNumber(/\b(?:rotate|rotation|angle)\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/);
    if (!isRemoveOnly(/\brotate\b|\brotation\b|\bangle\b/) && (angle !== null || /\brotate\b/.test(p))) upsertModifier("Rotation", { angle: angle ?? 15 });

    const offsetX = parseAxisValue("x");
    const offsetY = parseAxisValue("y");
    if (!isRemoveOnly(/\boffset\b|\bmove\b|\bshift\b|\bnudge\b/) && (/\boffset\b|\bmove\b|\bshift\b|\bnudge\b/.test(p) || offsetX !== null || offsetY !== null)) {
        upsertModifier("Offset", {
            ...(offsetX !== null ? { x: offsetX } : {}),
            ...(offsetY !== null ? { y: offsetY } : {}),
        });
    }

    if (/\bclip(ped)?\b/.test(p) && !/\bclip shape\b/.test(p)) {
        if (removeRequested) removeModifier("Clipped");
        else upsertModifier("Clipped", {});
    }
    const clipShape = parseClipShape();
    if (/\bclip shape\b|\bmask shape\b/.test(p) || clipShape) {
        if (removeRequested && (/\bclip shape\b|\bmask shape\b/.test(p))) {
            removeModifier("Clip Shape");
        } else {
            upsertModifier("Clip Shape", { shape: clipShape ?? "Rectangle" });
        }
    }

    const textAlignment = parseTextAlignment();
    if (!isRemoveOnly(/\balign(?:ment)?\b/) && textAlignment && (/\balign(?:ment)?\b/.test(p) || /\btext\b/.test(p))) {
        upsertModifier("Text Alignment", { alignment: textAlignment });
    }

    const ratio = extractNumber(/\bratio\s*(?:to|=|:)?\s*(\d+(?:\.\d+)?)/);
    const aspectMode = parseAspectMode();
    if (!isRemoveOnly(/\baspect\b|\bratio\b/) && (/\baspect\b/.test(p) || ratio !== null || aspectMode)) {
        upsertModifier("Aspect Ratio", {
            ...(ratio !== null ? { ratio } : {}),
            ...(aspectMode ? { aspectRatio: aspectMode, contentMode: aspectMode } : {}),
        });
    }

    const zIndex = extractNumber(/\bz[- ]?index\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/, /\blayer\s*(?:to|=|:)?\s*(-?\d+(?:\.\d+)?)/);
    if (!isRemoveOnly(/\bz[- ]?index\b|\blayer\b/) && zIndex !== null) upsertModifier("Z Index", { index: zIndex });

    if (/\boverlay\b/.test(p) && !removeRequested) upsertModifier("Overlay", {}, true, [makeDefaultModifierChild("Overlay")]);
    if (/\bbackground\b/.test(p) && /\blayer\b|\belement\b/.test(p) && !removeRequested) {
        upsertModifier("Background", {}, true, [makeDefaultModifierChild("Background")]);
    }
    if (/\bmask\b/.test(p) && !removeRequested) upsertModifier("Mask", {}, true, [makeDefaultModifierChild("Mask")]);

    if (/\bglass\b|\bliquid\b|\bfrost(ed)?\b/.test(p)) {
        if (removeRequested) removeModifier("Glass Effect");
        else upsertModifier("Glass Effect", {});
    }

    if (!touched) return null;
    cloned.modifiers = modifiers;
    return cloned;
}

function normalizeModifierForOp(mod: Record<string, unknown>): ModifierEditOpModifier | null {
    const type = typeof mod.type === "string" ? mod.type : "";
    if (!VALID_OP_MODIFIER_TYPES.has(type)) return null;
    const props = isObject(mod.properties) ? mod.properties : {};
    return { type, properties: props };
}

export function buildNormalizedModifierOps(component: ModifierEditComponent): ModifierEditOperation[] | null {
    const source = Array.isArray(component.modifiers) ? component.modifiers : [];
    const modifiers = source
        .map((mod) => (isObject(mod) ? normalizeModifierForOp(mod) : null))
        .filter((mod): mod is ModifierEditOpModifier => mod !== null);
    if (modifiers.length !== source.length) return null;
    return [{ op: "update_modifiers", nodeId: "root", mode: "replace", modifiers }];
}
