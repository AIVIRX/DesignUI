import type { AnyComponent, SlotType, ThemeTokens } from "./types.ts";

export type DesignPattern = { id: string; name: string; slotTypes: SlotType[]; guidance: string; component: AnyComponent };
const text = (value: string, size = "body", weight = "regular"): AnyComponent => ({ type: "Text", properties: { text: value }, modifiers: [{ type: "Font", properties: { fontSize: size, fontWeight: weight, fontDesign: "default" } }, { type: "Foreground Color", properties: { color: ["caption", "caption2", "subheadline"].includes(size) ? "secondary" : "primary" } }] });
const icon = (name: string, color = "blue"): AnyComponent => ({ type: "SF Symbol", properties: { symbolName: name }, modifiers: [{ type: "Foreground Color", properties: { color } }] });
const stack = (children: AnyComponent[], horizontal = false): AnyComponent => ({ type: horizontal ? "HStack" : "VStack", properties: { alignment: horizontal ? "center" : "leading", spacing: 12 }, children });
const button = (title: string): AnyComponent => ({ type: "Button", properties: { buttonStyle: "plain" }, children: [text(title, "body", "semibold")], modifiers: [{ type: "Padding", properties: { location: "all", amount: 12 } }, { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 48 } }, { type: "Background Color", properties: { color: "blue:0.16" } }, { type: "Corner Radius", properties: { radius: 12 } }] });
const card = (children: AnyComponent[]): AnyComponent => ({ ...stack(children), modifiers: [{ type: "Padding", properties: { amount: 16, location: "all" } }, { type: "Background Color", properties: { color: "secondarySystemBackground" } }, { type: "Corner Radius", properties: { radius: 16 } }, { type: "Frame", properties: { widthType: "Full", heightType: "Default" } }] });
const row = (symbol: string, title: string, subtitle: string) => stack([icon(symbol), stack([text(title, "body", "medium"), text(subtitle, "caption")]), { type: "Spacer" }], true);


const flexible = (component: AnyComponent): AnyComponent => ({ ...component, modifiers: [...(component.modifiers ?? []), { type: "Frame", properties: { widthType: "Full", heightType: "Default" } }] });
const artwork = (symbol: string): AnyComponent => ({ type: "ZStack", properties: { alignment: "center" }, children: [
    { type: "RoundedRectangle", properties: { cornerRadius: 16 }, modifiers: [{ type: "Fill", properties: { color: "blue:0.10" } }] },
    { ...icon(symbol), modifiers: [{ type: "Font", properties: { fontSize: "largeTitle", fontWeight: "regular", fontDesign: "default" } }, { type: "Foreground Color", properties: { color: "blue" } }] },
], modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 120 } }] });
const filterChip = (label: string, selected: boolean): AnyComponent => {
    const chip = button(label);
    (chip.modifiers!.find((m) => m.type === "Background Color")!.properties as Record<string, unknown>).color = selected ? "blue:0.16" : "systemFill";
    return chip;
};

// Recipes expand to ordinary editable schema nodes. No opaque screenshot components.
export const DESIGN_PATTERNS: DesignPattern[] = [
    { id: "navigation", name: "Bottom navigation", slotTypes: ["nav_bar"], guidance: "3–5 equal-width labeled destinations, one selected accent; pin outside scrolling content. Use the exact requested labels.", component: card([stack([flexible(stack([icon("house.fill"), text("Today", "caption")])), flexible(stack([icon("square.grid.2x2", "secondary"), text("Explore", "caption")])), flexible(stack([icon("person", "secondary"), text("Profile", "caption")]))], true)]) },
    { id: "search_filters", name: "Search and filters", slotTypes: ["search_bar", "segmented_tabs"], guidance: "A real Text Field, compact filters with one selected state; no invented toolbar controls. Keep results in a separate section.", component: stack([stack([icon("magnifyingglass"), { type: "Text Field", properties: { placeholder: "Search", text: "" } }], true), stack([filterChip("All", true), filterChip("Favorites", false)], true)]) },
    { id: "product", name: "Product card", slotTypes: ["gallery_grid", "horizontal_rail", "hero_banner"], guidance: "Artwork or intentional symbol illustration, product name, concise descriptor, price and one purchase action. Keep metadata subordinate.", component: card([artwork("headphones"), text("Studio headphones", "title3", "semibold"), text("Wireless · Midnight", "subheadline"), text("$129", "title2", "bold"), button("Add to bag")]) },
    { id: "settings", name: "Settings group", slotTypes: ["settings_list"], guidance: "Grouped headings and distinct native Switch rows for boolean preferences; use chevrons only for drill-in navigation.", component: card([text("Notifications", "headline", "semibold"), stack([text("Push notifications"), { type: "Spacer" }, { type: "Switch", properties: { isOn: true } }], true), stack([text("Email updates"), { type: "Spacer" }, { type: "Switch", properties: { isOn: false } }], true)]) },
    { id: "calendar", name: "Week and agenda", slotTypes: ["calendar_strip", "timeline_list"], guidance: "Seven evenly spaced dates with one selected day and chronological agenda rows. Preserve weekday order and avoid cramped month grids on phones.", component: card([text("This week", "headline", "semibold"), stack(["M 12", "T 13", "W 14", "T 15", "F 16", "S 17", "S 18"].map((day) => text(day, "caption")), true), row("clock", "Design review", "10:00–10:45"), row("calendar", "Team check-in", "14:00–14:30")]) },
    { id: "chat", name: "Conversation", slotTypes: ["chat_bubble_list"], guidance: "Alternate incoming and outgoing alignment, distinguish bubbles with semantic surfaces and one accent, include discreet timestamps. Composer belongs at the bottom.", component: stack([stack([card([text("Are we still on for tomorrow?")]), { type: "Spacer" }], true), stack([{ type: "Spacer" }, { ...stack([text("Absolutely! See you at 10.")]), modifiers: [{ type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "blue:0.12" } }, { type: "Corner Radius", properties: { radius: 16 } }] }], true), text("Delivered · 9:41", "caption2")]) },
    { id: "pricing", name: "Pricing plan", slotTypes: ["pricing_table", "comparison_table"], guidance: "Clear plan name, price and billing interval, 3 concise benefits, one primary subscription action; avoid invented discounts.", component: card([text("Pro", "headline", "semibold"), text("$12 / month", "title", "bold"), row("checkmark", "Unlimited projects", "Room for every idea"), row("checkmark", "Export SwiftUI", "Editable native code"), button("Choose Pro")]) },
    { id: "checkout", name: "Checkout summary", slotTypes: ["form_section", "action_bar"], guidance: "Item summary, subtotal, delivery and total that add up. Show payment choice and one clear purchase action; never fake card details.", component: card([text("Order summary", "headline", "semibold"), row("shippingbox", "Studio headphones", "$129.00"), stack([text("Delivery"), { type: "Spacer" }, text("$0.00")], true), stack([text("Total", "headline", "bold"), { type: "Spacer" }, text("$129.00", "headline", "bold")], true), button("Place order")]) },
    { id: "empty", name: "Empty state", slotTypes: ["empty_state"], guidance: "One relevant symbol, a specific reason the view is empty and a useful action. Do not fabricate populated rows.", component: card([icon("tray"), text("No projects yet", "title3", "semibold"), text("Create your first project to get started."), button("Create project")]) },
    { id: "loading", name: "Loading state", slotTypes: ["empty_state", "progress_section"], guidance: "Subtle placeholders and honest indeterminate loading copy; no fake percentage. Keep the future content structure stable.", component: card([text("Loading your content", "headline", "semibold"), { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Fill", properties: { color: "systemFill" } }, { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 16 } }] }, text("This may take a moment.", "subheadline")]) },
    { id: "error", name: "Error and retry", slotTypes: ["empty_state"], guidance: "Explain the recoverable problem in plain language, preserve user work, and show a retry action. Never show backend diagnostics.", component: card([icon("wifi.exclamationmark"), text("Couldn’t load your content", "title3", "semibold"), text("Check your connection and try again."), button("Try again")]) },
    { id: "onboarding", name: "Onboarding step", slotTypes: ["hero_banner", "feature_grid"], guidance: "One benefit per step, intentional illustration, concise supporting text, step count and clear Continue action.", component: card([artwork("sparkles"), text("Make room for your ideas", "title", "bold"), text("Turn a quick thought into something you can build."), text("1 of 3", "caption"), button("Continue")]) },
];

export function patternGuidance(slotType: SlotType, intent: string): string {
    const choices = DESIGN_PATTERNS.filter((p) => p.slotTypes.includes(slotType));
    if (!choices.length) return "Use a clear heading, focused content and natural-height layout.";
    const selected = choices.find((p) => intent.toLowerCase().includes(p.id)) ?? choices[0];
    return `${selected.name}: ${selected.guidance} Adapt the content and visual treatment to the user's brief; this is a composition recipe, not mandatory extra content.`;
}

export function themedPattern(id: string, theme: ThemeTokens): AnyComponent {
    const pattern = DESIGN_PATTERNS.find((p) => p.id === id) ?? DESIGN_PATTERNS[0];
    const component = structuredClone(pattern.component);
    const visit = (node: AnyComponent) => {
        for (const modifier of node.modifiers ?? []) {
            const properties = (modifier.properties ?? {}) as Record<string, unknown>;
            modifier.properties = properties;
            if (modifier.type === "Font") modifier.properties = { ...properties, fontDesign: theme.fontDesign };
            const color = properties.color;
            if (typeof color === "string" && color.startsWith("blue")) properties.color = color.includes(":") ? `${theme.accentColor.split(":")[0]}:${color.split(":")[1]}` : theme.accentColor;
        }
        node.children?.forEach(visit);
    };
    visit(component);
    return component;
}
