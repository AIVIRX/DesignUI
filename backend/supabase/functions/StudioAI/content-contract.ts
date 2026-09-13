import type { AnyComponent } from "./types.ts";
import { walkComponentTree } from "./postprocess.ts";

// Check the section's assignment, rather than applying every chart request to every section.
export function validateChartAssignment(component: AnyComponent, intent: string): string[] {
    const charts: AnyComponent[] = [];
    walkComponentTree(component, (node) => { if (node.type === "Chart") charts.push(node); });
    const issues: string[] = [];
    for (const [pattern, styles, label] of [
        [/\b(?:donut|doughnut)\s+(?:chart|graph)\b/i, ["Donut"], "donut"],
        [/\bline\s+(?:chart|graph)\b/i, ["Line", "Line + Area"], "line"],
        [/\bstacked bar\s+(?:chart|graph)\b/i, ["Stacked Bar"], "stacked bar"],
    ] as const) {
        if (pattern.test(intent) && !charts.some((c) => styles.some((s) => s === c.properties?.chartStyle))) issues.push(`The assigned ${label} chart is missing or has the wrong chartStyle. Use a separate editable Chart for each requested chart.`);
    }
    for (const chart of charts) {
        if (chart.properties?.chartStyle !== "Donut") continue;
        try {
            const points = JSON.parse(String(chart.properties.dataPoints ?? "[]"));
            if (Array.isArray(points) && points.length > 1 && points.every((p) => /^(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|mon|tue|wed|thu|fri|sat|sun)/i.test(String(p.label))) && /\b(revenue|trend|monthly|weekly)\b/i.test(intent)) issues.push("A donut is using time-series labels. Put revenue trends in the requested line chart and spending categories in the donut.");
        } catch { /* Schema validation reports invalid data. */ }
    }
    return issues;
}
