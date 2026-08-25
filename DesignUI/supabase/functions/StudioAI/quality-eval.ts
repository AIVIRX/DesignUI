import type { AnyComponent, SlotType } from "./types.ts";
import { VALID_COMPONENT_TYPES, VALID_MODIFIER_TYPES } from "./schema.ts";
import { detectLowQualitySlotOutput, findAccessibilityViolations, findInvalidGlassSurfaceUsage, walkComponentTree } from "./postprocess.ts";
import { isObject } from "./utils.ts";

export type ComponentQualityReport = {
    passed: boolean;
    score: number;
    nodeCount: number;
    textCount: number;
    issues: string[];
};

export type PipelineEvalCase = {
    id: string;
    prompt: string;
    expectedSlots: SlotType[];
    forbiddenSlots: SlotType[];
    requiredCopy?: string[];
};

export const PIPELINE_EVAL_CASES: PipelineEvalCase[] = [
    {
        id: "rideshare-map-first",
        prompt: "Design a premium rideshare iPhone home screen with a live route map, pickup and destination, nearby drivers, fare options with ETA, and a bottom confirm ride bar.",
        expectedSlots: ["map_preview", "form_section", "content_list", "action_bar"],
        forbiddenSlots: ["stat_group", "chart_section"],
        requiredCopy: ["pickup", "destination"],
    },
    {
        id: "city-guide-map-first",
        prompt: "Create a calm luxury city guide with a map, native search, compact filter chips, curated places, and a bottom action tray.",
        expectedSlots: ["search_bar", "map_preview", "content_list", "action_bar"],
        forbiddenSlots: ["stat_group", "progress_section"],
    },
    {
        id: "mail-inbox",
        prompt: "Design a native iPhone mail inbox with search, mailbox rows, unread states, timestamps, and a compose action.",
        expectedSlots: ["search_bar", "content_list", "fab_button"],
        forbiddenSlots: ["hero_banner", "stat_group"],
    },
    {
        id: "music-browse",
        prompt: "Design an editorial music browse screen with category chips, new releases, artist radios, a mini player, and bottom navigation.",
        expectedSlots: ["horizontal_rail", "media_player", "nav_bar"],
        forbiddenSlots: ["stat_group", "settings_list"],
    },
    {
        id: "settings-native",
        prompt: "Design a native settings screen with account, appearance, notifications, privacy, and destructive sign-out actions.",
        expectedSlots: ["app_header", "settings_list"],
        forbiddenSlots: ["hero_banner", "stat_group", "chart_section"],
    },
    {
        id: "commerce-search",
        prompt: "Design a clean product search screen with a native search field, category filters, two-column products, prices, and cart navigation.",
        expectedSlots: ["search_bar", "content_grid", "nav_bar"],
        forbiddenSlots: ["stat_group", "progress_section"],
    },
];

export function evaluateComponentQuality(component: AnyComponent): ComponentQualityReport {
    const issues = new Set<string>();
    let nodeCount = 0;
    let textCount = 0;

    walkComponentTree(component, (node) => {
        nodeCount += 1;
        if (!VALID_COMPONENT_TYPES.has(node.type)) issues.add(`invalid component type: ${node.type}`);
        if (node.type === "Text") textCount += 1;

        if (!Array.isArray(node.modifiers)) return;
        for (const modifier of node.modifiers) {
            if (!isObject(modifier) || typeof modifier.type !== "string") {
                issues.add("invalid modifier object");
                continue;
            }
            if (!VALID_MODIFIER_TYPES.has(modifier.type)) issues.add(`invalid modifier type: ${modifier.type}`);
        }
    });

    detectLowQualitySlotOutput(component).forEach((issue) => issues.add(issue));
    findInvalidGlassSurfaceUsage(component).forEach((issue) => issues.add(issue));
    findAccessibilityViolations(component).forEach((issue) => issues.add(issue));

    const issueList = [...issues];
    const score = Math.max(0, 100 - issueList.length * 12);
    return {
        passed: issueList.length === 0,
        score,
        nodeCount,
        textCount,
        issues: issueList,
    };
}

export function evaluateSlotPlan(
    slots: Array<{ slotType: SlotType }>,
    testCase: PipelineEvalCase,
): string[] {
    const actual = new Set(slots.map((slot) => slot.slotType));
    const issues: string[] = [];
    for (const expected of testCase.expectedSlots) {
        if (!actual.has(expected)) issues.push(`missing expected slot: ${expected}`);
    }
    for (const forbidden of testCase.forbiddenSlots) {
        if (actual.has(forbidden)) issues.push(`included forbidden slot: ${forbidden}`);
    }
    return issues;
}
