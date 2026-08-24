export type EditIntent = "style" | "layout" | "structure" | "content" | "wrap" | "canvas" | "unknown";
export type SurfaceStyle = "minimal" | "editorial" | "utility" | "immersive" | "calm";
export type Density = "compact" | "regular" | "airy";
export type CornerRadiusScale = "sharp" | "medium" | "pill";
export type VoiceTone = "playful" | "calm" | "professional" | "urgent";
export type GenerationMode = "standard" | "full_canvas";

// ─── Screen Archetypes ───────────────────────────────────────────────────────
export const SCREEN_ARCHETYPES = [
    "dashboard", "feed", "detail", "onboarding", "settings", "media_browse",
    "social_profile", "leaderboard", "chat", "marketplace", "tracker",
    "journal", "calendar", "workout", "recipe", "music_player", "news",
    "finance", "travel", "education", "health", "social_feed", "portfolio",
    "booking", "weather", "gaming", "photography", "meditation", "reading",
    "shopping_cart", "order_tracking", "analytics", "project_management",
] as const;
export type ScreenArchetype = typeof SCREEN_ARCHETYPES[number];

// ─── Slot System ─────────────────────────────────────────────────────────────
export const SLOT_TYPES = [
    "app_header", "hero_banner", "stat_group", "content_list", "content_grid",
    "horizontal_rail", "action_bar", "nav_bar", "section_header", "media_player",
    "profile_header", "form_section", "empty_state", "banner_alert", "segmented_tabs",
    "timeline_list", "settings_list", "chart_section", "social_feed_slot", "gallery_grid",
    "onboarding_step", "search_bar", "fab_button", "card_detail", "pricing_table",
    "calendar_strip", "progress_section", "testimonial_rail", "feature_grid",
    "comparison_table", "countdown_timer", "weather_widget", "map_preview",
    "notification_list", "chat_bubble_list", "story_rail", "avatar_group",
    "breadcrumb_nav", "split_view", "floating_card",
] as const;
export type SlotType = typeof SLOT_TYPES[number];
export const VALID_SLOT_TYPES = new Set<string>(SLOT_TYPES);

export type SlotPosition = "top" | "body" | "bottom" | "overlay";

export type SlotPlan = {
    slotType: SlotType;
    position: SlotPosition;
    intent: string;
    itemCount?: number; // how many rows/cards/items for list-like slots
    variant_hint?: string; // free-text hint the planner gives to the generator: "circular gauges", "card-style rows", etc.
};

export type PromptRequirement = {
    requirementKey?: string;
    slotType: SlotType;
    position: SlotPosition;
    mustInclude: string;
    variantHint?: string;
    railSpec?: {
        variant: RailVariant;
        itemShape: "square" | "portrait" | "circle" | "pill" | "landscape";
        textRows: number;
    };
    itemCount?: number;
    sourceIndex: number;
};

export type DesignManifest = {
    rawPrompt: string;
    requirements: PromptRequirement[];
    hardRules: string[];
    strictMode: boolean;
    forbiddenSlotTypes: SlotType[];
};

export type PromptDesignSpec = {
    strict: boolean;
    strictOneToOne: boolean;
    isSearchResultsMode: boolean;
    layout: {
        targetSectionCount?: number;
        targetRailCount?: number;
        targetCardCount?: number;
        requireScrollableBody: boolean;
        forbidBottomControls: boolean;
        allowBottomControls: boolean;
    };
    style: {
        density?: Density;
        cornerRadiusScale?: CornerRadiusScale;
        preferredSurface?: SurfaceStyle;
        preferGlass: boolean;
        preferGradient: boolean;
        nativePattern?: "appstore_search" | "mail_inbox" | "spotify_browse" | "apple_store" | "admob_dashboard";
    };
    content: {
        emphasizedNouns: string[];
        statePack: boolean;
        wantsSettingsToggles: boolean;
        conceptVariant?: "clean" | "dense" | "cinematic";
        conceptTag?:
            | "instagram_home"
            | "modern_login"
            | "post_apoc_barter"
            | "lux_fragrance"
            | "deep_sea_research"
            | "moon_transit"
            | "gothic_reading"
            | "streetwear_drop"
            | "wildlife_field_log"
            | "mise_en_place"
            | "legal_case_strategy"
            | "vinyl_collector"
            | "film_prepro"
            | "cyberpunk_bounty"
            | "altitude_climb"
            | "perfume_layering"
            | "tattoo_studio";
    };
    forbiddenSlotTypes: SlotType[];
    hardRules: string[];
};

export type ScreenPlan = {
    archetype: ScreenArchetype;
    slots: SlotPlan[];
    canvas_settings?: CanvasSettings;
};

export type SketchPrimitive =
    | "MetricCard"
    | "IconRow"
    | "ToggleRow"
    | "SuggestionRow"
    | "RailItem"
    | "SectionHeader"
    | "HeroPanel"
    | "AuthHero"
    | "CredentialForm"
    | "SocialSignInRow"
    | "StoryRail"
    | "PostCardFeed"
    | "SearchBarNative"
    | "SparklinePanel"
    | "TimelineSteps"
    | "ProductTileGrid"
    | "ContextHeader"
    | "MapRouteStage"
    | "OptionCompareStack"
    | "StickyActionSplit";

export type LayoutSketchNode = {
    slotType: SlotType;
    position: SlotPosition;
    intent: string;
    itemCount?: number;
    primitive: SketchPrimitive;
    emphasis?: "low" | "medium" | "high";
};

export type LayoutSketch = {
    mode: "sketch_v1";
    nodes: LayoutSketchNode[];
};

export type RailVariant = "poster" | "media_track" | "circular_people" | "chips" | "landscape";

export type CanvasSettings = {
    statusBarVisible?: boolean;
    statusBarTopSafeArea?: boolean;
    canvasColorScheme?: "light" | "dark";
};

export type ThemeTokens = {
    accentColor: string;
    secondaryColor: string;
    surfaceStyle: SurfaceStyle;
    density: Density;
    fontDesign: string;
    cornerRadiusScale: CornerRadiusScale;
    usesGradient: boolean;
    appName: string;
    voiceTone: VoiceTone;
    mascotSymbol: string;
    itemNoun: string;
    ctaVerb: string;
    primaryMetricLabel: string;
    primaryMetricUnit: string;
    sampleItems: string[];
    sampleMetrics: string[];
    sampleRailItems: string[];
    ctaText: string;
    domainTags: string[];
    // v2: shared facts for cross-slot consistency
    sharedFacts: {
        greeting: string;
        userName: string;
        primaryMetricValue: string;
        secondaryMetricValue: string;
        streakValue: string;
        progressPercent: number;
        todayDate: string;
    };
};

export type ThemeSurfaces = {
    cardFill: string;
    rowFill: string;
    subtleFill: string;
    primaryText: string;
    secondaryText: string;
    iconTint: string;
    dividerTint: string;
    cornerCard: number;
    cornerRow: number;
    spacing: number;
};

export type ScreenTokens = {
    accentColor: string;
    surfaceStyle: SurfaceStyle;
    density: Density;
    fontDesign: string;
};

export type SemanticDomain =
    | "productivity"
    | "social"
    | "media"
    | "commerce"
    | "finance"
    | "transport"
    | "travel"
    | "health"
    | "education"
    | "utility"
    | "lifestyle"
    | "creative"
    | "general";

export type InteractionModel =
    | "dashboard"
    | "list_first"
    | "map_first"
    | "form_flow"
    | "feed"
    | "comparison"
    | "detail"
    | "media_browse"
    | "search_results";

export type UICapability =
    | "live_context_surface"
    | "map_surface"
    | "location_flow"
    | "compare_options"
    | "status_tracking"
    | "identity_header"
    | "content_feed"
    | "settings_controls"
    | "media_playback"
    | "data_summary"
    | "search_refinement"
    | "commerce_listing"
    | "timeline_flow";

export type SemanticIntent = {
    domain: SemanticDomain;
    interactionModel: InteractionModel;
    primaryGoal: string;
    entities: string[];
    capabilities: UICapability[];
    preferredFocalSlot?: SlotType;
    preferredSupportSlots: SlotType[];
    avoidSlots: SlotType[];
};

export type ScreenIRSectionKind =
    | "header"
    | "search"
    | "hero"
    | "map_surface"
    | "input_group"
    | "option_list"
    | "content_list"
    | "content_grid"
    | "rail"
    | "chart"
    | "progress"
    | "settings_group"
    | "feed"
    | "timeline"
    | "profile_summary"
    | "action_strip"
    | "media_controls"
    | "empty_state";

export type ScreenIRSection = {
    kind: ScreenIRSectionKind;
    slotType: SlotType;
    position: SlotPosition;
    goal: string;
    entities: string[];
    emphasis: "low" | "medium" | "high";
    itemCount?: number;
    variant?: string;
};

export type ScreenIR = {
    version: "screen_ir_v1";
    layoutMode: InteractionModel;
    primaryGoal: string;
    sections: ScreenIRSection[];
};

export type AnyComponent = {
    type: string;
    properties?: Record<string, unknown>;
    modifiers?: Array<Record<string, unknown>>;
    children?: AnyComponent[];
    modifierId?: string;
    modifierType?: string;
};

export type Exemplar = {
    id: string;
    slot_type: string;
    voice_tone: string;
    surface_style: string;
    domain_tags: string[];
    description: string;
    component_tree: AnyComponent;
    similarity?: number;
};

export type ScreenContract =
    | "instagram_feed_v1"
    | "modern_login_v1"
    | "search_results_native_v1"
    | "music_discovery_v1"
    | "creator_dashboard_v1"
    | "ecommerce_home_v1"
    | "travel_planner_v1"
    | "finance_portfolio_v1"
    | "learning_path_v1"
    | "chat_inbox_v1"
    | "chat_thread_v1"
    | "maps_explore_v1"
    | "rideshare_home_v1"
    | "rideshare_map_sheet_v1"
    | "rideshare_fare_compare_v1"
    | "rideshare_trip_planner_v1"
    | "rideshare_reserve_v1"
    | "video_feed_v1"
    | "checkout_flow_v1"
    | "settings_account_v1"
    | "auth_2fa_v1"
    | "state_pack_v1"
    | "restaurant_delivery_v1"
    | "calendar_week_v1"
    | "kanban_board_v1"
    | "onboarding_flow_v1"
    | "notification_center_v1"
    | "profile_social_v1"
    | "health_activity_v1"
    | "news_reader_v1"
    | "booking_hotel_v1"
    | "customer_support_v1"
    | "admin_table_v1"
    | "camera_capture_v1";


export type SlotMemory = {
    colorsUsed: string[];
    symbolsUsed: string[];
    layoutPatterns: string[];
    dataPointsShown: string[];
    sectionCount: number;
};
