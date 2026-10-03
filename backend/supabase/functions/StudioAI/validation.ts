import type { AnyComponent } from "./types.ts";
import { UI_COMPONENT_SCHEMA_DEFS } from "./schema.ts";
import { isObject } from "./utils.ts";

// Validate against the same property vocabulary sent to Structured Outputs.
// Optional editor defaults may be omitted; present values must match the schema.
export function validateComponentSchema(component: AnyComponent): string[] {
    const issues: string[] = [];
    let count = 0;
    const visit = (value: unknown, kind: "component" | "modifier", path: string, depth: number): void => {
        if (++count > 500 || depth > 24) { issues.push(`${path}: tree exceeds rendering limits`); return; }
        if (!isObject(value)) { issues.push(`${path}: expected an object`); return; }
        const variants = UI_COMPONENT_SCHEMA_DEFS[kind].anyOf as Array<Record<string, any>>;
        const variant = variants.find((v) => v.properties.type.enum[0] === value.type);
        if (!variant) { issues.push(`${path}: unsupported ${kind} ${value.type}`); return; }
        const properties = value.properties ?? {};
        if (!isObject(properties)) { issues.push(`${path}.properties: expected an object`); return; }
        const definitions = variant.properties.properties.properties;
        for (const [key, entry] of Object.entries(properties)) {
            const def = definitions[key];
            if (!def) { issues.push(`${path}.${key}: unsupported property`); continue; }
            const types = Array.isArray(def.type) ? def.type : [def.type];
            const type = entry === null ? "null" : Array.isArray(entry) ? "array" : typeof entry;
            if (!types.includes(type) || (type === "number" && !Number.isFinite(entry))) {
                issues.push(`${path}.${key}: invalid value type`);
            } else if (def.enum && !def.enum.includes(entry)) {
                issues.push(`${path}.${key}: unsupported value ${entry}`);
            }
        }
        if (value.type === "Text" && (typeof properties.text !== "string" || !properties.text.trim())) issues.push(`${path}: empty text`);
        if (value.type === "Chart") {
            for (const [key, min, max] of [["pointCount", 1, 60], ["lineWidth", 1, 8], ["barWidthRatio", 0.2, 0.95], ["areaOpacity", 0, 1]] as const) {
                const number = properties[key];
                if (typeof number === "number" && (number < min || number > max || (key === "pointCount" && !Number.isInteger(number)))) issues.push(`${path}.${key}: outside supported range`);
            }
            if (typeof properties.dataPoints === "string" && properties.dataPoints.trim()) {
                try {
                    const data = JSON.parse(properties.dataPoints);
                    if (!Array.isArray(data) || data.length < 1 || data.length > 60 || data.some((p) => !isObject(p) || typeof p.label !== "string" || !p.label.trim() || typeof p.value !== "number" || !Number.isFinite(p.value) || Math.abs(p.value) > 1e12 || (p.series !== undefined && typeof p.series !== "string") || (p.highlighted !== undefined && typeof p.highlighted !== "boolean")) || new Set(data.map((p) => JSON.stringify([p.series ?? "", p.label]))).size !== data.length) throw new Error("invalid data");
                    if (properties.chartStyle === "Donut" && (data.some((p) => p.value < 0) || !data.some((p) => p.value > 0) || new Set(data.map((p) => p.label)).size !== data.length)) throw new Error("invalid donut");
                } catch { issues.push(`${path}.dataPoints: use 1–60 unique labeled numeric data points`); }
            }
        }
        if (value.type === "Frame") {
            for (const axis of ["width", "height"]) {
                if (properties[`${axis}Type`] === "Custom" && !(typeof properties[axis] === "number" && properties[axis] >= 0)) issues.push(`${path}: custom ${axis} needs a nonnegative dimension`);
            }
        }
        if (["Gauge", "Slider"].includes(String(value.type)) && typeof properties.min === "number" && typeof properties.max === "number") {
            if (properties.max <= properties.min || typeof properties.value !== "number" || properties.value < properties.min || properties.value > properties.max) issues.push(`${path}: invalid control range`);
        }
        if (variant.properties.children) {
            if (!Array.isArray(value.children) || value.children.length === 0) issues.push(`${path}: missing child content`);
        }
        if (Array.isArray(value.children)) value.children.forEach((child, i) => {
            if (isObject(child) && typeof child.modifierId === "string") return;
            visit(child, "component", `${path}.children[${i}]`, depth + 1);
        });
        if (Array.isArray(value.modifiers)) value.modifiers.forEach((child, i) => visit(child, "modifier", `${path}.modifiers[${i}]`, depth + 1));
    };
    visit(component, "component", "component", 0);
    return issues.slice(0, 30);
}
