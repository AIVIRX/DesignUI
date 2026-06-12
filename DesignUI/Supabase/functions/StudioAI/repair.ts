import type { AnyComponent, SlotPlan } from "./types.ts";
import { callOpenAI, REPAIR_MAX_TOKENS, REPAIR_MODEL, SELECTION_MAX_TOKENS, SELECTION_MODEL } from "./openai.ts";
import { VALID_COMPONENT_TYPES, SLOT_CONSTRAINTS } from "./schema.ts";
import { isJsonParseError, isObject, parseJsonSafe } from "./utils.ts";
import { postProcessComponents } from "./postprocess.ts";

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
LEAVES (delete children if present): Text, Image, SF Symbol, Shape, Chart, Spacer, Divider, Rectangle, Circle, RoundedRectangle, Capsule, Ellipse, Linear Gradient, Text Field, Switch, Slider, Progress View, Status Bar, Gauge
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
