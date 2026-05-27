import type { AnyComponent } from "./types.ts";
import { VALID_MODIFIER_TYPES } from "./schema.ts";
import { isObject, sanitizeInstructionalDisplayText } from "./utils.ts";

// ─── Post-processing (unchanged from v1) ─────────────────────────────────────

export function postProcessComponents(
    components: AnyComponent[],
    canvasColorScheme?: "light" | "dark",
): AnyComponent[] {
    const cloned = JSON.parse(JSON.stringify(components)) as AnyComponent[];
    const CONTAINER_PP = new Set(["VStack", "HStack", "ZStack", "ScrollView", "Button"]);
    const LEAF_PP = new Set(["Text", "Image", "SF Symbol", "Shape", "Chart", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "Linear Gradient", "Text Field", "Switch", "Slider", "Progress View", "Status Bar", "Gauge"]);
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

    const visit = (node: AnyComponent): AnyComponent => {
        if (!node || typeof node !== "object") return { type: "Text", properties: { text: "" }, modifiers: [] };

        const inferredType = typeof node.type === "string" ? node.type
            : (Array.isArray(node.children) && node.children.length > 0 ? "VStack"
                : node.properties?.text != null ? "Text" : "Text");
        node.type = coerceType(inferredType);
        if (!isObject(node.properties)) node.properties = {};
        if (!Array.isArray(node.modifiers)) node.modifiers = [];

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
            const cleaned = tv.length > 0 ? sanitizeInstructionalDisplayText(tv) : "";
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
            modObj.type = normalizeModifierType(modObj.type);

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
