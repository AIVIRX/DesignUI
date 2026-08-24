import type { ScreenArchetype, SlotType, SlotPosition } from "./types.ts";

export const SCHEMA_RULES = `
CONTAINERS (must have children[]): VStack, HStack, ZStack, ScrollView, Button
LEAVES (no children): Text, Image, SF Symbol, Shape, Chart, Spacer, Divider, Rectangle, Circle, RoundedRectangle, Capsule, Ellipse, Linear Gradient, Text Field, Switch, Slider, Progress View, Status Bar, Gauge, Map

PROPERTIES:
Text:{text:string} SF Symbol:{symbolName:string} — always add Font modifier
Text Field:{text?:string,placeholder?:string,semanticRole?:"input"|"search"|"email"|"password"}
VStack:{alignment:"leading"|"center"|"trailing",spacing:number}
HStack:{alignment:"top"|"center"|"bottom",spacing:number}
ZStack:{alignment:"center"|"topLeading"|"top"|"topTrailing"|"leading"|"trailing"|"bottomLeading"|"bottom"|"bottomTrailing"}
Button:{buttonStyle:"plain"|"bordered"|"borderedProminent",interactionRole?:"select_tab"|"select_filter"|"set_selection",interactionKey?:string,interactionValue?:string,interactionDefault?:boolean} — modifiers=[], all styling on label child
ScrollView:{axis:"vertical"|"horizontal",showsIndicators:boolean}
RoundedRectangle:{cornerRadius:number} Switch:{isOn:boolean} Slider:{value:number,min:number,max:number} Progress View:{value:number,total:number,color:string} Gauge:{value:number,min:number,max:number,gaugeType:"linear"|"circular"|"circular range",showValue:boolean,color:string} Map:{latitude:number,longitude:number,latitudeDelta?:number,longitudeDelta?:number,mapStyle?:"standard"|"imagery"|"hybrid",interactionModes?:"all"|"none"|"pan"|"zoom"|"rotate"|"pitch"|"pan+zoom"|"pan+zoom+rotate"|"pan+zoom+rotate+pitch",showsCompass?:boolean,showsScale?:boolean,showsPitchToggle?:boolean,showsUserLocation?:boolean,showsUserLocationButton?:boolean,showsTraffic?:boolean,locationName?:string,markers?:string}

MODIFIERS (exact strings only): Frame, Padding, Background Color, Foreground Color, Font, Corner Radius, Shadow, Opacity, Border, Stroke, Background, Overlay, Mask, Blur, Rotation, Offset, Fill, Clip Shape, Text Alignment, Tint, Glass Effect
Glass Effect:{shape?:"Rectangle"|"RoundedRectangle"|"Circle"|"Capsule"|"Ellipse",cornerRadius?:number,tint?:string}
Padding:{amount:number,location:"all"|"horizontal"|"vertical"}
Font:{fontSize:"largeTitle"|"title"|"title2"|"title3"|"headline"|"body"|"callout"|"subheadline"|"footnote"|"caption"|"caption2"|"<numeric-string>",fontWeight:"black"|"heavy"|"bold"|"semibold"|"medium"|"regular"|"light"|"thin"|"ultraLight"}
Font design: fontDesign:"default"|"serif"|"rounded"|"monospaced"
Frame:{widthType:"Custom"|"Default"|"Full",heightType:"Custom"|"Default"|"Full",width:number,height:number}
Corner Radius:{radius:number} Shadow:{radius:number,x:number,y:number,color:string,opacity:number}
Clip Shape:{shape:"Rectangle"|"Circle"|"Capsule"|"Ellipse"}
Background/Overlay/Mask:{children:[...UIComponent]}
Stroke:{color:string,lineWidth:number}
Border:{color:string,lineWidth:number}
BORDER vs STROKE RULE: Use "Stroke" when the element has a Corner Radius modifier OR is a shape (RoundedRectangle, Circle, Capsule, Ellipse). Use "Border" ONLY on elements with no Corner Radius (sharp-cornered rectangles). When in doubt, use "Stroke".
SHAPE COLOR RULE: For Shape/Rectangle/Circle/RoundedRectangle/Capsule/Ellipse, use "Fill" for shape color. Do NOT use "Background Color" directly on those shape components.
SF SYMBOL RULE: Use only official SF Symbols names for symbolName. Do NOT invent or paraphrase symbol names.
BUTTON RULE: If label child has Background Color modifier then buttonStyle MUST be "plain".
iOS COLORS: blue:#007AFF orange:#FF9500 green:#34C759 red:#FF3B30 lightblue:#32ADE6 purple:#AF52DE gray:#8E8E93
COLOR FORMAT: Always "colorname:opacity" e.g. "blue:1.0", "gray:0.12", "red:0.8"
SPACING SCALE: Prefer only 4, 8, 12, 16, 24, 32 for VStack/HStack spacing and Padding amounts. Use 0 only when elements must visually lock together. Avoid random values like 5, 7, 10, 14, 18, 20, or 22.
`;

export const CANVAS_SETTINGS_RULES = `
CANVAS SETTINGS (optional):
"canvas_settings": { "statusBarVisible": boolean, "statusBarTopSafeArea": boolean, "canvasColorScheme": "light" | "dark" }
Only include fields explicitly requested.
`;

export type SlotConstraint = {
    allowedRoots: string[];
    maxDepth: number;
    requiredTextCount?: number; // minimum # of Text nodes
    requiresSymbol?: boolean;
    maxChildren?: number; // at root level
    fullWidth?: boolean;
    description: string; // human-readable, included in the generation prompt
};

export const SLOT_CONSTRAINTS: Record<SlotType, SlotConstraint> = {
    app_header: {
        allowedRoots: ["HStack", "VStack", "ZStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "App title bar. Must contain app name. May include leading/trailing symbols, subtitle, avatar, or search icon. Keep it compact — no more than ~60pt tall.",
    },
    hero_banner: {
        allowedRoots: ["VStack", "ZStack", "HStack"],
        maxDepth: 6, requiredTextCount: 1, fullWidth: true,
        description: "Primary focal section. Can be editorial (large title + subtitle + CTA), stat-heavy (inline metrics + progress), immersive (poster background + overlaid text), or compact. Be creative with layout — overlap elements, use bold typography, asymmetric compositions. This is the visual anchor of the screen.",
    },
    stat_group: {
        allowedRoots: ["VStack", "HStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Group of 2-4 stat/metric displays. Can be a 2-col grid of cards, horizontal scrolling pills, a single row of inline stats, circular gauges, ring charts, progress bars — any layout that shows multiple data points at a glance. Each stat needs a label + value. Make each design UNIQUE to the app domain.",
    },
    content_list: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Vertical list of 3-5 content rows. Each row is a self-contained item (task, lesson, transaction, entry, etc). Rows should have a leading visual (symbol in colored circle, avatar shape, status dot, numbered badge), primary + secondary text, and optional trailing element (badge, chevron, time, price). Vary the row design per app — don't always use the same HStack pattern.",
    },
    content_grid: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "2-column grid of cards (4-6 items). Each card is a self-contained unit — could be square tiles, rounded cards with icons, image placeholders with labels, interactive toggle cards. Use creative card shapes and internal layouts.",
    },
    horizontal_rail: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 1, fullWidth: true,
        description: "Section title + horizontally scrolling content (ScrollView axis:horizontal). Items could be poster cards, square media-track cards (artwork with title + secondary subtitle below), circular avatars/artists, pill chips, small square tiles, or wide landscape cards. 4-6 items. The rail title sits above the scroller.",
    },
    action_bar: {
        allowedRoots: ["HStack", "VStack", "ZStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Primary action area — a big CTA button, or a row of action buttons, or a floating action button. The CTA text should match the app's voice tone. Can include secondary actions.",
    },
    nav_bar: {
        allowedRoots: ["VStack", "HStack"],
        maxDepth: 4, requiredTextCount: 2, fullWidth: true,
        description: "Bottom tab navigation. 3-5 tabs, each with an SF Symbol + label. Active tab should be visually distinct (accent color, filled icon, pill background). Variants: standard divider-top, floating rounded bar, minimal icon-only, pill-highlight on active.",
    },
    section_header: {
        allowedRoots: ["HStack", "VStack"],
        maxDepth: 3, requiredTextCount: 1, fullWidth: true,
        description: "Section divider with title and optional trailing action ('See All', count badge, filter icon). Simple and functional.",
    },
    media_player: {
        allowedRoots: ["HStack", "VStack", "ZStack"],
        maxDepth: 5, requiredTextCount: 1, fullWidth: true,
        description: "Mini media player bar (music, podcast, meditation). Shows current track/session name, play/pause controls, progress indicator. Compact — fits at bottom of screen above nav.",
    },
    profile_header: {
        allowedRoots: ["VStack", "HStack", "ZStack"],
        maxDepth: 5, requiredTextCount: 1, fullWidth: true,
        description: "User profile section with avatar area (Circle or RoundedRectangle placeholder), username, bio/subtitle, and optional stat row (followers, posts, streak). Can be centered or left-aligned.",
    },
    form_section: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Form inputs section — 2-4 labeled text fields, toggles, or sliders in a vertical stack. Each field has a label and the input component. Group with a subtle background card.",
    },
    empty_state: {
        allowedRoots: ["VStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Empty/zero state — centered illustration placeholder (large SF Symbol in a circle), title, subtitle explaining what to do, and a CTA button. Used when there's no content yet.",
    },
    banner_alert: {
        allowedRoots: ["HStack", "VStack", "ZStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Dismissible banner/alert card. Leading icon, message text, optional action button or trailing dismiss X. Colored background to stand out.",
    },
    segmented_tabs: {
        allowedRoots: ["HStack", "VStack", "ZStack"],
        maxDepth: 4, requiredTextCount: 2, fullWidth: true,
        description: "Segmented control / tab bar for switching between content sections. 2-4 segments with text labels. Active segment visually highlighted (accent background, bold text, underline).",
    },
    timeline_list: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Vertical timeline of 3-5 events. Each event has a time/date label, a connector visual (dot + vertical line), and event description. Use the connector pattern to create visual continuity.",
    },
    settings_list: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Settings/preferences list — 3-5 rows. Each row: leading symbol, label, trailing element (Switch, chevron, value text). Grouped with subtle card background and dividers.",
    },
    chart_section: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 1, fullWidth: true,
        description: "Data visualization section — a Chart component or a manually built bar/line chart using Rectangles + labels. Include a title and optional legend or summary stat. Use the app's accent color for the chart elements.",
    },
    social_feed_slot: {
        allowedRoots: ["VStack"],
        maxDepth: 6, requiredTextCount: 2, fullWidth: true,
        description: "Social feed cards — 2-3 post cards, each with avatar area + username + timestamp header, body text or image placeholder, and reaction/action bar (like, comment, share symbols). Dividers between posts.",
    },
    gallery_grid: {
        allowedRoots: ["VStack"],
        maxDepth: 4, requiredTextCount: 0, fullWidth: true,
        description: "Photo/media gallery grid — 6-9 square or rectangular placeholders (RoundedRectangle with subtle fill) arranged in a 3-col grid. Optional title above. Minimal text, focus on the visual grid pattern.",
    },
    onboarding_step: {
        allowedRoots: ["VStack", "ZStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Single onboarding step — centered large illustration area (big symbol or shape), headline, description text, primary CTA button, optional 'Skip' text. Generous spacing, clear visual hierarchy.",
    },
    search_bar: {
        allowedRoots: ["VStack", "HStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Search input area — magnifying glass icon + placeholder text inside a rounded/pill container. May include trailing filter icon. Optional recent searches or category chips below.",
    },
    fab_button: {
        allowedRoots: ["ZStack", "VStack", "Button"],
        maxDepth: 4, requiredTextCount: 0, fullWidth: false,
        description: "Floating action button — a single prominent circular or pill-shaped button with an SF Symbol (typically plus icon). Accent-colored background, shadow for elevation. Usually positioned bottom-right via offset.",
    },
    card_detail: {
        allowedRoots: ["VStack", "ZStack"],
        maxDepth: 6, requiredTextCount: 2, fullWidth: true,
        description: "Detailed content card — expanded view of a single item. Large image/poster placeholder at top, title + metadata below, description body text, action buttons at bottom. Like a detail/preview card.",
    },
    pricing_table: {
        allowedRoots: ["VStack", "HStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Pricing comparison — 2-3 plan cards side by side or stacked. Each shows plan name, price, feature bullets (using checkmark symbols), and CTA. Highlight the recommended plan with accent border/background.",
    },
    calendar_strip: {
        allowedRoots: ["VStack", "HStack", "ScrollView"],
        maxDepth: 4, requiredTextCount: 2, fullWidth: true,
        description: "Horizontal date/day strip — scrollable row of 5-7 day cells showing day name + date number. Today/selected date highlighted with accent color circle or pill. Compact.",
    },
    progress_section: {
        allowedRoots: ["VStack", "HStack", "ZStack"],
        maxDepth: 5, requiredTextCount: 1, fullWidth: true,
        description: "Progress display — for circular/ring progress use Gauge with gaugeType:'circular' or 'circular range' by default. Linear progress can use Gauge linear or Progress View. Shows completion state with label + percentage/fraction. Avoid fake full Circle stroke rings as the primary progress indicator.",
    },
    testimonial_rail: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Horizontally scrolling testimonial/review cards. Each card: quote text, author name, optional star rating (SF Symbols), avatar placeholder. 3-4 cards.",
    },
    feature_grid: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Feature showcase — 3-6 feature items in a 2-col grid or stacked list. Each: icon in colored circle, feature name, short description. Used for app features, benefits, capabilities.",
    },
    comparison_table: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Side-by-side comparison of 2-3 items. Header row with item names, then feature rows with checkmarks or values. Alternate row backgrounds for readability.",
    },
    countdown_timer: {
        allowedRoots: ["VStack", "HStack", "ZStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Countdown/timer display — large time numerals (HH:MM:SS or MM:SS), optional label, control buttons (start/pause/reset). Can be circular with ring progress or linear.",
    },
    weather_widget: {
        allowedRoots: ["VStack", "HStack", "ZStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Weather display — current temp (large text), condition icon (SF Symbol like cloud.sun.fill), location name, high/low temps. Optional hourly forecast rail below.",
    },
    map_preview: {
        allowedRoots: ["VStack", "ZStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Live map section — use a real Map component as the base, then customize it with camera span, interaction modes, markers, traffic, and lightweight overlays when the prompt calls for route, location, delivery, travel, or rideshare context.",
    },
    notification_list: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Notification/activity feed — 3-5 notification rows. Each: colored dot or app icon, notification text (bold sender + regular message), timestamp. Unread items have subtle highlight background.",
    },
    chat_bubble_list: {
        allowedRoots: ["VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Chat message bubbles — 3-5 alternating sent/received messages. Sent: trailing-aligned, accent-colored background. Received: leading-aligned, gray background. Each bubble: text + timestamp.",
    },
    story_rail: {
        allowedRoots: ["VStack"],
        maxDepth: 4, requiredTextCount: 1, fullWidth: true,
        description: "Stories/status rail — horizontal scroll of circular avatar placeholders with usernames below. First item can be 'Your Story' with a + icon. Active stories have accent ring border.",
    },
    avatar_group: {
        allowedRoots: ["HStack", "ZStack", "VStack"],
        maxDepth: 4, requiredTextCount: 0, fullWidth: false,
        description: "Overlapping avatar group — 3-5 small circles overlapping horizontally (use negative offset/spacing), with an optional '+N' counter. Shows group membership compactly.",
    },
    breadcrumb_nav: {
        allowedRoots: ["HStack", "ScrollView"],
        maxDepth: 3, requiredTextCount: 2, fullWidth: true,
        description: "Breadcrumb navigation — horizontal trail of clickable text labels separated by chevron.right symbols. Last item is active (bold, accent-colored).",
    },
    split_view: {
        allowedRoots: ["HStack", "VStack"],
        maxDepth: 5, requiredTextCount: 2, fullWidth: true,
        description: "Two-panel split layout — left panel (narrower, list/menu) and right panel (wider, content/detail). Separated by a divider or different background shades.",
    },
    floating_card: {
        allowedRoots: ["VStack", "ZStack", "HStack"],
        maxDepth: 5, requiredTextCount: 1, fullWidth: true,
        description: "Elevated floating card with shadow — a single prominent card that stands out. Contains mixed content (icon + title + description + action). Use Shadow modifier for elevation effect.",
    },
};

// ─── Archetype → Slot Templates ──────────────────────────────────────────────
// Default slot layouts per archetype. The planner can deviate but these provide
// strong defaults so even if the planner underperforms, screens are coherent.

export const ARCHETYPE_SLOT_TEMPLATES: Record<ScreenArchetype, Array<{ slotType: SlotType; position: SlotPosition; intentTemplate: string }>> = {
    dashboard: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + greeting or date" },
        { slotType: "stat_group", position: "body", intentTemplate: "key metrics overview" },
        { slotType: "content_list", position: "body", intentTemplate: "recent activity or tasks" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    feed: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + filter" },
        { slotType: "story_rail", position: "body", intentTemplate: "stories or status updates" },
        { slotType: "social_feed_slot", position: "body", intentTemplate: "feed posts" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    detail: [
        { slotType: "app_header", position: "top", intentTemplate: "back nav + title" },
        { slotType: "card_detail", position: "body", intentTemplate: "item details" },
        { slotType: "action_bar", position: "bottom", intentTemplate: "primary action" },
    ],
    onboarding: [
        { slotType: "onboarding_step", position: "body", intentTemplate: "welcome + value prop" },
        { slotType: "action_bar", position: "bottom", intentTemplate: "get started CTA" },
    ],
    settings: [
        { slotType: "app_header", position: "top", intentTemplate: "Settings title" },
        { slotType: "profile_header", position: "body", intentTemplate: "user profile summary" },
        { slotType: "settings_list", position: "body", intentTemplate: "preference toggles" },
        { slotType: "settings_list", position: "body", intentTemplate: "account & support links" },
    ],
    media_browse: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + search" },
        { slotType: "hero_banner", position: "body", intentTemplate: "featured content" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "category 1" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "category 2" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    social_profile: [
        { slotType: "app_header", position: "top", intentTemplate: "username + settings" },
        { slotType: "profile_header", position: "body", intentTemplate: "avatar + stats" },
        { slotType: "segmented_tabs", position: "body", intentTemplate: "posts/saved/tagged" },
        { slotType: "gallery_grid", position: "body", intentTemplate: "content grid" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    leaderboard: [
        { slotType: "app_header", position: "top", intentTemplate: "leaderboard title" },
        { slotType: "stat_group", position: "body", intentTemplate: "your rank + score" },
        { slotType: "content_list", position: "body", intentTemplate: "ranked players list" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    chat: [
        { slotType: "app_header", position: "top", intentTemplate: "contact name + status" },
        { slotType: "chat_bubble_list", position: "body", intentTemplate: "message history" },
        { slotType: "form_section", position: "bottom", intentTemplate: "message input + send" },
    ],
    marketplace: [
        { slotType: "search_bar", position: "top", intentTemplate: "search products" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "category chips" },
        { slotType: "content_grid", position: "body", intentTemplate: "product cards" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    tracker: [
        { slotType: "app_header", position: "top", intentTemplate: "tracker name" },
        { slotType: "hero_banner", position: "body", intentTemplate: "today's summary + CTA" },
        { slotType: "stat_group", position: "body", intentTemplate: "key metrics" },
        { slotType: "content_list", position: "body", intentTemplate: "logged entries" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    journal: [
        { slotType: "app_header", position: "top", intentTemplate: "journal title + date" },
        { slotType: "calendar_strip", position: "body", intentTemplate: "date selector" },
        { slotType: "content_list", position: "body", intentTemplate: "journal entries" },
        { slotType: "fab_button", position: "overlay", intentTemplate: "new entry" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    calendar: [
        { slotType: "app_header", position: "top", intentTemplate: "month + navigation" },
        { slotType: "calendar_strip", position: "body", intentTemplate: "week view" },
        { slotType: "content_list", position: "body", intentTemplate: "today's events" },
        { slotType: "fab_button", position: "overlay", intentTemplate: "add event" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    workout: [
        { slotType: "app_header", position: "top", intentTemplate: "app name" },
        { slotType: "hero_banner", position: "body", intentTemplate: "today's workout + start CTA" },
        { slotType: "stat_group", position: "body", intentTemplate: "weekly stats" },
        { slotType: "content_list", position: "body", intentTemplate: "workout history" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    recipe: [
        { slotType: "app_header", position: "top", intentTemplate: "recipe name" },
        { slotType: "card_detail", position: "body", intentTemplate: "recipe image + info" },
        { slotType: "stat_group", position: "body", intentTemplate: "prep/cook/servings" },
        { slotType: "content_list", position: "body", intentTemplate: "ingredients list" },
        { slotType: "action_bar", position: "bottom", intentTemplate: "start cooking" },
    ],
    music_player: [
        { slotType: "app_header", position: "top", intentTemplate: "app name" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "songs" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "artists" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "mixes" },
        { slotType: "media_player", position: "bottom", intentTemplate: "playback controls" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    news: [
        { slotType: "app_header", position: "top", intentTemplate: "news app title" },
        { slotType: "hero_banner", position: "body", intentTemplate: "breaking story" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "topic categories" },
        { slotType: "content_list", position: "body", intentTemplate: "latest articles" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    finance: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + notifications" },
        { slotType: "hero_banner", position: "body", intentTemplate: "total balance + chart" },
        { slotType: "stat_group", position: "body", intentTemplate: "account summaries" },
        { slotType: "content_list", position: "body", intentTemplate: "recent transactions" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    travel: [
        { slotType: "search_bar", position: "top", intentTemplate: "search destinations" },
        { slotType: "hero_banner", position: "body", intentTemplate: "featured destination" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "popular places" },
        { slotType: "content_list", position: "body", intentTemplate: "upcoming trips" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    education: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + streak" },
        { slotType: "hero_banner", position: "body", intentTemplate: "daily goal + progress" },
        { slotType: "content_list", position: "body", intentTemplate: "current lessons" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "course categories" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    health: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + date" },
        { slotType: "progress_section", position: "body", intentTemplate: "daily health ring" },
        { slotType: "stat_group", position: "body", intentTemplate: "vitals overview" },
        { slotType: "content_list", position: "body", intentTemplate: "health log" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    social_feed: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + messages" },
        { slotType: "story_rail", position: "body", intentTemplate: "stories" },
        { slotType: "social_feed_slot", position: "body", intentTemplate: "posts feed" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    portfolio: [
        { slotType: "app_header", position: "top", intentTemplate: "portfolio title" },
        { slotType: "hero_banner", position: "body", intentTemplate: "total value + change" },
        { slotType: "chart_section", position: "body", intentTemplate: "performance chart" },
        { slotType: "content_list", position: "body", intentTemplate: "holdings list" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    booking: [
        { slotType: "app_header", position: "top", intentTemplate: "service name" },
        { slotType: "card_detail", position: "body", intentTemplate: "booking details" },
        { slotType: "calendar_strip", position: "body", intentTemplate: "date selection" },
        { slotType: "content_list", position: "body", intentTemplate: "time slots" },
        { slotType: "action_bar", position: "bottom", intentTemplate: "confirm booking" },
    ],
    weather: [
        { slotType: "app_header", position: "top", intentTemplate: "location + settings" },
        { slotType: "weather_widget", position: "body", intentTemplate: "current conditions" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "hourly forecast" },
        { slotType: "content_list", position: "body", intentTemplate: "weekly forecast" },
    ],
    gaming: [
        { slotType: "app_header", position: "top", intentTemplate: "game name" },
        { slotType: "hero_banner", position: "body", intentTemplate: "current level/mission" },
        { slotType: "stat_group", position: "body", intentTemplate: "player stats" },
        { slotType: "content_list", position: "body", intentTemplate: "achievements/quests" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    photography: [
        { slotType: "app_header", position: "top", intentTemplate: "app name + camera" },
        { slotType: "gallery_grid", position: "body", intentTemplate: "photo grid" },
        { slotType: "fab_button", position: "overlay", intentTemplate: "new photo" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    meditation: [
        { slotType: "app_header", position: "top", intentTemplate: "app name" },
        { slotType: "hero_banner", position: "body", intentTemplate: "daily meditation + start" },
        { slotType: "stat_group", position: "body", intentTemplate: "mindfulness stats" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "session categories" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    reading: [
        { slotType: "app_header", position: "top", intentTemplate: "app name" },
        { slotType: "hero_banner", position: "body", intentTemplate: "currently reading" },
        { slotType: "horizontal_rail", position: "body", intentTemplate: "your library" },
        { slotType: "content_list", position: "body", intentTemplate: "reading list" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
    shopping_cart: [
        { slotType: "app_header", position: "top", intentTemplate: "cart title" },
        { slotType: "content_list", position: "body", intentTemplate: "cart items" },
        { slotType: "stat_group", position: "body", intentTemplate: "order summary totals" },
        { slotType: "action_bar", position: "bottom", intentTemplate: "checkout CTA" },
    ],
    order_tracking: [
        { slotType: "app_header", position: "top", intentTemplate: "order number" },
        { slotType: "timeline_list", position: "body", intentTemplate: "tracking steps" },
        { slotType: "map_preview", position: "body", intentTemplate: "delivery location" },
        { slotType: "action_bar", position: "bottom", intentTemplate: "contact support" },
    ],
    analytics: [
        { slotType: "app_header", position: "top", intentTemplate: "dashboard title" },
        { slotType: "segmented_tabs", position: "body", intentTemplate: "time range selector" },
        { slotType: "chart_section", position: "body", intentTemplate: "main chart" },
        { slotType: "stat_group", position: "body", intentTemplate: "summary metrics" },
        { slotType: "content_list", position: "body", intentTemplate: "top items table" },
    ],
    project_management: [
        { slotType: "app_header", position: "top", intentTemplate: "project name" },
        { slotType: "progress_section", position: "body", intentTemplate: "project progress" },
        { slotType: "stat_group", position: "body", intentTemplate: "task counts by status" },
        { slotType: "content_list", position: "body", intentTemplate: "current tasks" },
        { slotType: "nav_bar", position: "bottom", intentTemplate: "main navigation" },
    ],
};

export type CapabilityRule = {
    keywords: RegExp[];
    add: Array<{ slotType: SlotType; position: SlotPosition; intentTemplate: string; itemCount?: number; variant_hint?: string }>;
};

export const CAPABILITY_MATRIX: CapabilityRule[] = [
    {
        keywords: [/\bauth\b|\blogin\b|\bsign in\b|\bsignup\b|\bregister\b/i],
        add: [
            { slotType: "form_section", position: "body", intentTemplate: "credential fields and actions", itemCount: 3, variant_hint: "clean auth form with strong CTA hierarchy" },
            { slotType: "action_bar", position: "bottom", intentTemplate: "primary authentication action" },
        ],
    },
    {
        keywords: [/\bsearch\b|\bdiscover\b|\bresults?\b/i],
        add: [
            { slotType: "search_bar", position: "top", intentTemplate: "search query entry and quick filters" },
            { slotType: "content_list", position: "body", intentTemplate: "search results list", itemCount: 5, variant_hint: "readable result rows with secondary metadata" },
        ],
    },
    {
        keywords: [/\bcheckout\b|\bpayment\b|\bbilling\b|\bcart\b/i],
        add: [
            { slotType: "content_list", position: "body", intentTemplate: "cart line items and totals", itemCount: 4, variant_hint: "commerce rows with price emphasis" },
            { slotType: "action_bar", position: "bottom", intentTemplate: "complete purchase action" },
        ],
    },
    {
        keywords: [/\banalytics\b|\bmetrics?\b|\bkpi\b|\bdashboard\b/i],
        add: [
            { slotType: "stat_group", position: "body", intentTemplate: "key performance indicators", itemCount: 4, variant_hint: "high-contrast KPI cards with trends" },
            { slotType: "chart_section", position: "body", intentTemplate: "trend visualization and summary", variant_hint: "clear chart with labeled context" },
        ],
    },
    {
        keywords: [/\bprofile\b|\baccount\b|\buser\b/i],
        add: [
            { slotType: "profile_header", position: "body", intentTemplate: "identity overview with avatar and key stats" },
            { slotType: "settings_list", position: "body", intentTemplate: "account actions and preferences", itemCount: 4 },
        ],
    },
    {
        keywords: [/\bempty state\b|\bno data\b|\bnothing here\b/i],
        add: [
            { slotType: "empty_state", position: "body", intentTemplate: "empty state guidance and onboarding CTA" },
        ],
    },
    {
        keywords: [/\berror\b|\bfailed\b|\bwarning\b|\balert\b/i],
        add: [
            { slotType: "banner_alert", position: "body", intentTemplate: "error/warning summary with recovery action" },
        ],
    },
    {
        keywords: [/\bmap\b|\blocation\b|\bdirections\b/i],
        add: [
            { slotType: "map_preview", position: "body", intentTemplate: "location map context and route action" },
        ],
    },
    {
        keywords: [/\bcalendar\b|\bschedule\b|\bevents?\b/i],
        add: [
            { slotType: "calendar_strip", position: "body", intentTemplate: "date strip and schedule pivot" },
            { slotType: "content_list", position: "body", intentTemplate: "upcoming events and time slots", itemCount: 4 },
        ],
    },
    {
        keywords: [/\bchat\b|\bmessage\b|\binbox\b|\bconversation\b/i],
        add: [
            { slotType: "chat_bubble_list", position: "body", intentTemplate: "message timeline", itemCount: 4, variant_hint: "alternating conversational bubbles with timestamps" },
            { slotType: "form_section", position: "bottom", intentTemplate: "message composer" },
        ],
    },
];

export const VALID_MODIFIER_TYPES = new Set([
    "Frame", "Padding", "Background Color", "Foreground Color", "Font", "Corner Radius",
    "Shadow", "Opacity", "Border", "Stroke", "Background", "Overlay", "Mask", "Blur",
    "Rotation", "Offset", "Fill", "Clip Shape", "Text Alignment", "Tint", "Glass Effect",
]);
export const VALID_COMPONENT_TYPES = new Set([
    "Text", "Image", "SF Symbol", "Stack", "VStack", "HStack", "ZStack", "ScrollView", "Shape",
    "Button", "Chart", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle",
    "Capsule", "Ellipse", "Linear Gradient", "Text Field", "Switch", "Slider", "Progress View", "Status Bar", "Gauge", "Map",
]);
export const CONTAINER_TYPES = new Set(["Stack", "VStack", "HStack", "ZStack", "ScrollView", "Button"]);

export const SLOT_SCHEMA_COMPACT = `CONTAINERS(must have children[]): VStack HStack ZStack ScrollView Button
LEAVES(no children): Text Image "SF Symbol" Spacer Divider Rectangle Circle RoundedRectangle Capsule Ellipse "Linear Gradient" "Text Field" Switch Slider "Progress View" Gauge Chart Map
Text:{text:string} "SF Symbol":{symbolName:string} "Text Field":{text?:string,placeholder?:string,semanticRole?:"input"|"search"|"email"|"password"} VStack:{alignment:"leading"|"center"|"trailing",spacing:num} HStack:{alignment:"top"|"center"|"bottom",spacing:num} ZStack:{alignment:"center"|"topLeading"|"bottomTrailing"...} Button:{buttonStyle:"plain"|"bordered"|"borderedProminent"} ScrollView:{axis:"vertical"|"horizontal",showsIndicators:bool} RoundedRectangle:{cornerRadius:num} "Progress View":{value:num,total:num,color:string} Gauge:{value:num,min:num,max:num,gaugeType:"linear"|"circular"|"circular range",showValue:bool,color:string} Map:{latitude:num,longitude:num,latitudeDelta?:num,longitudeDelta?:num,mapStyle?:"standard"|"imagery"|"hybrid",interactionModes?:"all"|"none"|"pan"|"zoom"|"rotate"|"pitch"|"pan+zoom"|"pan+zoom+rotate"|"pan+zoom+rotate+pitch",showsCompass?:bool,showsScale?:bool,showsPitchToggle?:bool,showsUserLocation?:bool,showsUserLocationButton?:bool,showsTraffic?:bool,locationName?:string,markers?:string}
MODIFIERS: Frame Padding "Background Color" "Foreground Color" Font "Corner Radius" Shadow Opacity Stroke Fill "Clip Shape" "Text Alignment" Tint
Font:{fontSize:"largeTitle"|"title"|"title2"|"title3"|"headline"|"body"|"callout"|"subheadline"|"footnote"|"caption"|"caption2",fontWeight:"bold"|"semibold"|"medium"|"regular"|"light",fontDesign?:string}
Frame:{widthType:"Custom"|"Default"|"Full",heightType:"Custom"|"Default"|"Full",width?:num,height?:num}
Padding:{amount:num,location:"all"|"horizontal"|"vertical"}
Colors: "colorname:opacity" e.g. "blue:1.0" "gray:0.12"
RULES: Shapes use "Fill" not "Background Color". Corner Radius present → use "Stroke" not "Border". Button with bg-colored label → buttonStyle:"plain". SF Symbol names must be real. For circular progress/rings, prefer Gauge with gaugeType:"circular". SPACING SCALE: use only 4, 8, 12, 16, 24, 32 for VStack/HStack spacing and Padding amounts unless a special layout truly requires 0. Avoid random values like 5, 7, 10, 14, 18, 20, or 22.`;
