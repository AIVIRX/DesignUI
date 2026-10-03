import type { EditIntent, DesignManifest, PromptDesignSpec, PromptRequirement, RailVariant, ScreenPlan, SlotType } from "./types.ts";
import { MAX_GENERATION_SLOTS } from "./openai.ts";
import { detectRailVariantFromText } from "./utils.ts";

function detectRailVariantFromRequirement(req: PromptRequirement): RailVariant {
    if (req.railSpec?.variant) return req.railSpec.variant;
    return detectRailVariantFromText(req.mustInclude) ?? detectRailVariantFromText(req.variantHint ?? "") ?? "poster";
}

// ─── Prompt detection ────────────────────────────────────────────────────────

export function classifyIntent(prompt: string): EditIntent {
    const p = prompt.toLowerCase();
    if (/status bar|dark mode|light mode|color scheme|safe area/.test(p)) return "canvas";
    const requestsVisualStyle = /\b(color|fill|tint|shadow|opacity|blur|gradient|border|stroke|font|size|weight|bold|red|blue|green|orange|purple|yellow|teal|pink|gray|grey|white|black|mint|indigo|cyan|brown)\b/.test(p);
    const modifierOperation = /\b(add|remove|delete|reset|clear|change|set|make)\s+(?:the\s+)?(?:background\s+)?(color|fill|tint|shadow|opacity|blur|gradient|border|stroke|font|weight)\b/.test(p);
    if (modifierOperation) return "style";
    if (/\badd\b|\binsert\b|\bappend\b|\bremove\b|\bdelete\b|\bwrap\b|\bunwrap\b|\bnest\b/.test(p)) return "structure";
    if (requestsVisualStyle) return "style";
    if (/\bsay\b|\btext\b|\blabel\b|\btitle\b|\brename\b|\bwrite\b|\bchange.*(what|wording|copy)\b|\bset.*(text|label)\b/.test(p)) return "content";
    if (/\bwrap\b|\bcard\b|\bcontainer\b|\bsurface\b/.test(p)) return "wrap";
    if (/\bpad\b|\bspac\b|\bframe\b|\bwidth\b|\bheight\b|\balign\b|\boffset\b|\binset\b/.test(p)) return "layout";
    return "unknown";
}

export function isFullCanvasPrompt(prompt: string): boolean {
    const p = prompt.toLowerCase().trim();
    const hasCreationVerb = /^(make|create|build|design|generate|give me|show me|i want|can you make|can you create|build me|design me|generate a)/.test(p);
    const hasBrandRef = /duolingo|spotify|apple fitness|apple health|nike|strava|headspace|calm|notion|linear|figma|robinhood|coinbase|airbnb|uber|instagram|snapchat|twitter|tiktok|netflix|hulu|youtube|todoist|things3?|bereal|pinterest|reddit|discord|slack|stripe|monzo|revolut|wealthfront/.test(p);
    const hasThemeRef = /\bthemed?\b|\bstyle[d]?\b|\blike\s+\w|\binspired\b|\bsimilar to\b|\bvibe\b|\baesthetic\b|\bfeel\b|\blook and feel\b|\bui like\b/.test(p);
    const hasAppScope = /\bapp\b|\bscreen\b|\bdashboard\b|\bdesign\b|\bui\b|\binterface\b|\bwhole\b|\bfull\b|\bentire\b|\bpage\b|\bhome screen\b|\bmain screen\b/.test(p);
    const hasProductCategory = /\btodo\b|\btask\b|\bhabit\b|\bfitness\b|\bworkout\b|\bfinance\b|\bbudget\b|\bexpense\b|\bmusic\b|\bpodcast\b|\bmeditation\b|\bjournal\b|\bnote\b|\brecipe\b|\btravel\b|\bsocial\b|\bnews\b|\bweather\b|\bcrypto\b|\blearning\b|\beducation\b|\bhealth\b|\bcalendar\b|\bsleep\b|\brun\b|\btracker\b|\bplanner\b|\bdiary\b|\breadings?\b|\bflashcard\b|\blanguage\b|\bshopping\b|\bfood\b|\bcooking\b|\bgaming\b|\bphoto\b|\bchat\b|\bmessag\b|\bproject\b|\banalytics\b|\bportfolio\b|\bbooking\b|\border\b|\bmarket\b|\bleaderboard\b/.test(p);
    if (!hasCreationVerb) return false;
    return hasBrandRef || hasThemeRef || (hasAppScope && hasProductCategory) || hasProductCategory;
}

export function promptExplicitlyChangesText(prompt: string): boolean {
    return [
        /\bchange (?:the )?text\b/, /\bchange what (?:it|this) says\b/, /\bmake (?:the )?text say\b/,
        /\bset (?:the )?text to\b/, /\brename\b/, /\bretitle\b/,
        /\bupdate (?:the )?(?:title|label|copy|wording)\b/, /\breplace (?:the )?text\b/,
        /\btext should be\b/, /\blabel should be\b/, /\btitle should be\b/, /\bsay[s]?\b/, /\bwrite\b/,
    ].some((p) => p.test(prompt.toLowerCase()));
}

export function buildDesignManifest(prompt: string): DesignManifest {
    const p = prompt.toLowerCase();
    const requirements: PromptRequirement[] = [];
    const hardRules: string[] = [];
    const forbiddenSlotTypes = new Set<SlotType>();
    const strictMode = /\b(exactly|must|only|strict|do not|don't|without|no)\b/.test(p);
    const stickyTopRequested = /\b(sticky|pinned)\s+(header|top|nav(?:igation)?(?:\s+bar)?)\b|\bfixed\s+(header|top|top\s+bar|nav(?:igation)?(?:\s+bar)?)\b|\b(header|top\s+bar)\s+(always\s+visible|stays?\s+visible)\b/.test(p);
    const overlayRequested = /\b(floating|overlay|overlaid)\b|\bfab\b|\bfloating action button\b|\bon top of (?:the )?(map|image|photo|video)\b/.test(p);

    // Reserve common explicit content before optional archetype sections consume the budget.
    const metrics = prompt.replace(/\bthree\b/gi, "3").match(/\b(?:exactly\s+)?(\d+)\s+(?:compact\s+)?(?:metrics|metric cards|stats|kpis)\b(?:\s*\([^)]*\)|\s+for\s+[^.!;]+)?/i);
    if (metrics) requirements.push({ requirementKey: "explicit_metrics", slotType: "stat_group", position: "body", itemCount: Math.max(1, Math.min(12, Number(metrics[1]))), mustInclude: metrics[0], sourceIndex: metrics.index ?? 0 });
    const navigation = prompt.match(/\bbottom\s+(?:tabs|tab bar|navigation|nav(?:igation)?\s+bar)\b[^.!;]*/i);
    if (navigation && !/\b(no|without|hide)\s*$/i.test(prompt.slice(0, navigation.index))) {
        requirements.push({ requirementKey: "explicit_navigation", slotType: "nav_bar", position: "bottom", mustInclude: navigation[0], sourceIndex: navigation.index ?? 0 });
    }
    const featured = prompt.match(/(?:\b(?:a\s+)?featured\s+[^.!;]*?\bcard\b|[“"][^”"]+[”"]\s+card\b)[^.!;]*/i);
    if (featured) requirements.push({ requirementKey: "explicit_feature", slotType: "hero_banner", position: "body", mustInclude: featured[0], sourceIndex: featured.index ?? 0 });
    const chart = prompt.match(/\b(?:(?:weekly|monthly|daily|activity|spending|revenue)\s+){0,2}(?:chart|graph)\b/i);
    const typedCharts = [...prompt.matchAll(/\b(?:(?:weekly|monthly|daily|activity|spending|revenue)\s+)*(?:donut|doughnut|line|stacked bar|bar|area)\s+(?:chart|graph)\b/gi)];
    if (typedCharts.length > 1) requirements.push({ requirementKey: "explicit_charts", slotType: "chart_section", position: "body", mustInclude: `Separate editable charts: ${typedCharts.map((m) => m[0]).join(" and ")}. Preserve each chart's data purpose; goal lines belong to trend charts.`, sourceIndex: typedCharts[0].index ?? 0 });
    const transactions = prompt.match(/\b(?:recent\s+)?transactions(?:\s+list)?\b/i);
    if (transactions) requirements.push({ requirementKey: "explicit_transactions", slotType: "content_list", position: "body", mustInclude: "Recent transactions with merchant names, dates and currency amounts", sourceIndex: transactions.index ?? 0 });
    if (chart && [...prompt.matchAll(/\b(?:chart|graph)s?\b/gi)].length === 1 && !/\b(no|without|hide|\d+)\s*$/i.test(prompt.slice(0, chart.index))) requirements.push({ requirementKey: "explicit_chart", slotType: "chart_section", position: "body", mustInclude: `one ${chart[0]}, without repeating metrics assigned to another section`, sourceIndex: chart.index ?? 0 });

    if (/\bno\b.*\bnav\s*bar\b|\bwithout\b.*\bnav\s*bar\b|\bhide\b.*\bnav\s*bar\b/.test(p)) {
        forbiddenSlotTypes.add("nav_bar");
        hardRules.push("Do not include a bottom nav bar.");
    }
    if (/\bno\b.*\bmedia\s*player\b|\bwithout\b.*\bmedia\s*player\b/.test(p)) {
        forbiddenSlotTypes.add("media_player");
        hardRules.push("Do not include a media player section.");
    }
    if (/\bno\b.*\bfab\b|\bwithout\b.*\bfab\b|\bno\b.*\bfloating action\b/.test(p)) {
        forbiddenSlotTypes.add("fab_button");
        hardRules.push("Do not include a floating action button.");
    }
    if (/\bno\b.*\bhero\b|\bwithout\b.*\bhero\b|\bno\b.*\bbanner\b/.test(p)) {
        forbiddenSlotTypes.add("hero_banner");
        hardRules.push("Do not include a hero/banner section.");
    }

    const ringIndex = p.search(/moon[\s-]*phase|progress[\s-]*ring|circular[\s-]*ring|\bring\b/);
    if (ringIndex >= 0) {
        requirements.push({
            requirementKey: "progress_circular_gauge",
            slotType: "progress_section",
            position: "body",
            mustInclude: "a centered circular Gauge progress ring as a primary focal element",
            sourceIndex: ringIndex,
        });
        hardRules.push("Include a circular Gauge as a primary focal progress element.");
    }

    const cardsMatch = p.match(/\b(\d+)\s+(?:stat\s+)?cards?\b/);
    const cardsIndex = cardsMatch ? p.indexOf(cardsMatch[0]) : p.search(/\bcards?\b/);
    if (cardsIndex >= 0 && /\bgrid\b|\b2x2\b|\b2 by 2\b/.test(p)) {
        const count = cardsMatch ? Math.max(2, Math.min(8, Number(cardsMatch[1]) || 4)) : 4;
        const hasTwoByTwo = /\b2x2\b|\b2 by 2\b/.test(p);
        requirements.push({
            requirementKey: hasTwoByTwo ? "stat_grid_2x2" : "stat_grid",
            slotType: "stat_group",
            position: "body",
            mustInclude: hasTwoByTwo
                ? `${count} stat cards arranged in a 2x2 grid below the focal section`
                : `${count} stat cards arranged in a grid below the focal section`,
            itemCount: count,
            sourceIndex: cardsIndex,
        });
        if (hasTwoByTwo) hardRules.push(`Use a 2x2 card grid with ${count} cards.`);
    }

    const chipsMatch = p.match(/\b(\d+)\s+(?:mood\s+)?chips?\b/);
    const chipsIndex = chipsMatch ? p.indexOf(chipsMatch[0]) : p.search(/\bchips?\b/);
    if (chipsIndex >= 0) {
        const count = chipsMatch ? Math.max(2, Math.min(8, Number(chipsMatch[1]) || 3)) : 3;
        requirements.push({
            requirementKey: "rail_chips_count",
            slotType: "horizontal_rail",
            position: "body",
            mustInclude: `${count} selectable ${/\bmood\b/.test(p) ? "mood " : "filter "}chips`,
            railSpec: { variant: "chips", itemShape: "pill", textRows: 1 },
            itemCount: count,
            sourceIndex: chipsIndex,
        });
    }

    const timelineIndex = p.search(/\btimeline\b|\bfeed\b/);
    if (timelineIndex >= 0) {
        const blurred = /\bblurred\b|\bblur\b/.test(p);
        requirements.push({
            requirementKey: blurred ? "timeline_blurred" : "timeline_standard",
            slotType: "timeline_list",
            position: "body",
            mustInclude: blurred
                ? "a blurred timeline feed with stacked chronological entries"
                : "a timeline feed with stacked chronological entries",
            sourceIndex: timelineIndex,
        });
        if (blurred) hardRules.push("Timeline/feed section should include a blurred surface treatment.");
    }

    const searchMode = /\bresults?\b|\bdiscover\b|\bsearch\s+(?:screen|page|interface)\b/.test(p)
        || (/\bsearch\b/.test(p) && !/\b(dashboard|transactions|spending|revenue)\b/.test(p));
    if (searchMode) {
        const exactResultsMatch = p.match(/\b(?:exactly|only|just)\s*(\d+)\s*(?:results?|items?)\b/);
        const listCount = exactResultsMatch ? Math.max(1, Math.min(12, Number(exactResultsMatch[1]) || 6)) : undefined;
        requirements.push({
            requirementKey: "search_results_list",
            slotType: "content_list",
            position: "body",
            mustInclude: listCount
                ? `exactly ${listCount} search result rows with title and secondary metadata`
                : "search result rows with title and secondary metadata",
            itemCount: listCount ?? 6,
            sourceIndex: exactResultsMatch?.index ?? p.search(/\bresults?\b|\bitems?\b/),
        });
        hardRules.push("Search/results screens should prioritize query + filters + results list, and avoid unrelated dashboard hero/stat sections unless explicitly requested.");
    }

    const notificationPreferenceMode = /\bnotification preferences?\b|\bnotifications?.{0,24}\b(preferences?|settings?|list)\b/.test(p);
    const settingsToggleMode = notificationPreferenceMode || /\bdark mode\b/.test(p) || (/\bsettings?\b/.test(p) && /\btoggle|switch|notifications?|sound\b/.test(p));
    if (settingsToggleMode) {
        const wantsNotificationPreferences = notificationPreferenceMode;
        const wantsDarkMode = /\bdark mode\b/.test(p);
        requirements.push({
            requirementKey: "settings_toggles",
            slotType: "settings_list",
            position: "body",
            mustInclude: wantsNotificationPreferences
                ? `grouped settings list with ${wantsDarkMode ? "an Appearance section containing Dark Mode and " : ""}a Notifications section containing Push Notifications, Email Updates, Sounds, and Badges, each as Switch rows`
                : "settings rows with Switch toggles for notifications, dark mode, and sound",
            itemCount: wantsNotificationPreferences ? (wantsDarkMode ? 5 : 4) : 3,
            sourceIndex: Math.max(0, p.search(/\bsettings?\b|\bnotification|\bdark mode\b/)),
        });
        hardRules.push(wantsNotificationPreferences
            ? "Notification preference requests must show separate notification controls grouped under a Notifications section; do not collapse them into one generic Notifications toggle."
            : "Settings prompts with toggles must use settings list rows with Switch controls; do not use hero banners.");
    }

    const rideshareMode = /\buber\b|\blyft\b|\brideshare\b|\bride share\b|\bbook a ride\b|\brequest a ride\b|\bpickup\b|\bdrop[\s-]*off\b|\bdestination\b|\bdriver\b|\beta\b/.test(p);
    if (rideshareMode) {
        const compareMode = /\bcompare\b|\boptions?\b|\bfares?\b|\btiers?\b|\bprice\b|\bpricing\b/.test(p);
        const plannerMode = /\bpickup\b|\bdestination\b|\bwhere to\b|\broute\b|\btrip plan\b/.test(p);
        const reserveMode = /\breserve\b|\bschedule\b|\blater\b|\btomorrow\b|\bdeparture\b|\bleave at\b/.test(p);
        const mapMode = /\bmap\b|\broute\b|\bnearby\b|\bdrivers?\b|\blive\b/.test(p);
        requirements.push({
            requirementKey: "rideshare_map",
            slotType: "map_preview",
            position: "body",
            mustInclude: "a large live ride map area as the primary focal section",
            variantHint: "map-first composition with route context and nearby cars",
            sourceIndex: p.search(/\buber\b|\blyft\b|\brideshare\b|\bmap\b|\bpickup\b|\bdestination\b/),
        });
        if (plannerMode) {
            requirements.push({
                requirementKey: "rideshare_trip_inputs",
                slotType: "form_section",
                position: "body",
                mustInclude: "pickup and destination planning with clear origin and destination hierarchy",
                variantHint: "trip planning inputs may appear as fields, floating cards, or a compact route planner surface",
                itemCount: 2,
                sourceIndex: p.search(/\bpickup\b|\bdestination\b|\bdrop[\s-]*off\b|\bwhere to\b/),
            });
        }
        if (compareMode) {
            requirements.push({
                requirementKey: "rideshare_tiers",
                slotType: "content_list",
                position: "body",
                mustInclude: "ride options with ETA and price comparison",
                variantHint: "vehicle choices should reflect the user's requested tone rather than fixed brand tier names",
                itemCount: 4,
                sourceIndex: p.search(/\bride\b|\bcar\b|\btiers?\b|\boptions?\b|\bfares?\b|\bprice\b|\beta\b/),
            });
        }
        if (reserveMode) {
            requirements.push({
                requirementKey: "rideshare_reserve_action",
                slotType: "action_bar",
                position: "bottom",
                mustInclude: "reserve or schedule ride controls with clear primary and secondary actions",
                variantHint: "time-aware booking controls for later departures",
                sourceIndex: p.search(/\breserve\b|\bschedule\b|\blater\b|\bdeparture\b|\bleave at\b/),
            });
        }
        hardRules.push("Rideshare screens should stay grounded in live location context, trip planning, or option comparison instead of generic dashboard cards.");
        if (mapMode) hardRules.push("If the prompt emphasizes live map context, keep the map as the dominant focal surface.");
        hardRules.push("Do not use dashboard hero banners, KPI stat groups, streak cards, or generic productivity sections for rideshare screens.");
    }

    // Generic rail style extraction (not domain-specific):
    // supports prompts like "varied rails (posters then circular artists)".
    type RailStyleHit = {
        key: string;
        mustInclude: string;
        variantHint: string;
        railSpec: PromptRequirement["railSpec"];
        sourceIndex: number;
    };
    const railHits: RailStyleHit[] = [];
    const pushRailHit = (
        key: string,
        mustInclude: string,
        variantHint: string,
        railSpec: PromptRequirement["railSpec"],
        match: RegExpMatchArray | null,
    ) => {
        if (!match || typeof match.index !== "number") return;
        railHits.push({ key, mustInclude, variantHint, railSpec, sourceIndex: match.index });
    };

    pushRailHit(
        "rail_posters",
        "a horizontal rail of poster-style cards",
        "poster cards with strong visual thumbnails and title overlays",
        { variant: "poster", itemShape: "portrait", textRows: 1 },
        p.match(/\bposters?\b/),
    );
    pushRailHit(
        "rail_media_track",
        "a horizontal rail of song cards with square artwork, primary title, and secondary artist subtitle",
        "square artwork with two text rows below (title then artist/subtitle)",
        { variant: "media_track", itemShape: "square", textRows: 2 },
        p.match(/\b(songs?|tracks?)\b|\bsquare\b.*\bart(work)?\b|\bart(work)?\b.*\bsquare\b/),
    );
    pushRailHit(
        "rail_circular_profiles",
        "a horizontal rail of circular profile/avatar items",
        "circular items with label below; avatar/artist/profile style",
        { variant: "circular_people", itemShape: "circle", textRows: 1 },
        p.match(/\bcircular\b.*\b(artists?|profiles?|avatars?)\b|\b(artists?|profiles?|avatars?)\b.*\bcircular\b/),
    );
    pushRailHit(
        "rail_chips",
        "a horizontal rail of compact pill chips",
        "compact pill chips with subtle state contrast",
        { variant: "chips", itemShape: "pill", textRows: 1 },
        p.match(/\bchips?\b|\bpills?\b/),
    );
    pushRailHit(
        "rail_landscape",
        "a horizontal rail of wide landscape cards",
        "wide cards with cinematic landscape proportions",
        { variant: "landscape", itemShape: "landscape", textRows: 1 },
        p.match(/\bwide\b|\blandscape\b|\bbanner\b/),
    );

    if (railHits.length > 0) {
        railHits.sort((a, b) => a.sourceIndex - b.sourceIndex);
        const uniqueRailHits = railHits.filter((hit, i, arr) => arr.findIndex((h) => h.key === hit.key) === i);
        uniqueRailHits.forEach((hit, idx) => {
            requirements.push({
                requirementKey: `${hit.key}_${idx + 1}`,
                slotType: "horizontal_rail",
                position: "body",
                mustInclude: hit.mustInclude,
                variantHint: hit.variantHint,
                railSpec: hit.railSpec,
                itemCount: 5,
                sourceIndex: hit.sourceIndex,
            });
        });
        hardRules.push("When multiple rail styles are requested, each rail must have distinct morphology and not repeat the same card pattern.");
        if (uniqueRailHits.some((h) => h.railSpec?.variant === "media_track")) {
            hardRules.push("For media-track rails, each item must use square artwork plus two text rows: primary title then secondary artist/subtitle.");
        }
    }

    if (ringIndex >= 0 && cardsIndex >= 0 && /\bbelow\b/.test(p)) {
        hardRules.push("Place the card grid visually below the primary circular progress focus.");
    }

    const deduped = requirements
        .sort((a, b) => a.sourceIndex - b.sourceIndex)
        .filter((req, i, arr) => arr.findIndex((x) => `${x.slotType}::${x.mustInclude}` === `${req.slotType}::${req.mustInclude}`) === i);

    return {
        rawPrompt: prompt,
        requirements: deduped,
        hardRules: Array.from(new Set(hardRules)),
        strictMode,
        forbiddenSlotTypes: Array.from(forbiddenSlotTypes),
        stickyTopRequested,
        overlayRequested,
    };
}

export function compilePromptDesignSpec(prompt: string, manifest: DesignManifest): PromptDesignSpec {
    const p = prompt.toLowerCase();
    const sectionMatch = p.match(/\b(?:exactly|only|just)?\s*(\d+)\s+(?:sections?|blocks?|areas?)\b/);
    const railMatch = p.match(/\b(?:exactly|only|just)?\s*(\d+)\s+(?:rails?|carousels?)\b/);
    const cardMatch = p.match(/\b(?:exactly|only|just)?\s*(\d+)\s+(?:cards?)\b/);

    const emphasizedNouns = ["dashboard", "feed", "stats", "cards", "rail", "timeline", "chat", "profile", "weather", "music"]
        .filter((token) => new RegExp(`\\b${token}\\b`, "i").test(prompt));

    const layout = {
        targetSectionCount: sectionMatch ? Math.max(2, Math.min(8, Number(sectionMatch[1]) || 0)) : undefined,
        targetRailCount: railMatch ? Math.max(0, Math.min(4, Number(railMatch[1]) || 0)) : undefined,
        targetCardCount: (() => {
            const explicitResultCount = p.match(/\b(?:exactly|only|just)?\s*(\d+)\s+(?:results?|items?|rows?)\b/);
            const value = explicitResultCount ? Number(explicitResultCount[1]) : (cardMatch ? Number(cardMatch[1]) : undefined);
            return typeof value === "number" && Number.isFinite(value)
                ? Math.max(1, Math.min(12, value))
                : undefined;
        })(),
        requireScrollableBody: !/\bnon-?scroll|no scroll|without scroll\b/.test(p),
        forbidBottomControls: /\bno bottom controls\b|\bwithout bottom controls\b/.test(p),
        allowBottomControls: /\b(bottom nav|tab bar|bottom tabs|bottom toolbar|bottom bar)\b/.test(p),
    };

    const style: PromptDesignSpec["style"] = {
        density: /\bcompact\b/.test(p) ? "compact" : /\bairy\b/.test(p) ? "airy" : undefined,
        cornerRadiusScale: /\bsharp\b/.test(p) ? "sharp" : /\bpill\b/.test(p) ? "pill" : undefined,
        preferredSurface: /\bimmersive\b/.test(p)
            ? "immersive"
            : /\bminimal\b/.test(p)
                ? "minimal"
                : /\beditorial\b/.test(p)
                    ? "editorial"
                    : /\bcalm\b/.test(p)
                        ? "calm"
                        : undefined,
        preferGlass: /\bglass\b|\bliquid\b/.test(p),
        preferGradient: /\bgradient\b/.test(p),
        nativePattern: /\bapp\s*store\b.*\bsearch\b|\bautocomplete\b/.test(p)
            ? "appstore_search"
            : /\bmail\b|\binbox\b|\bemail\b/.test(p)
                ? "mail_inbox"
                : /\bspotify\b|\bmusic\b.*\bbrowse\b|\bplaylist\b/.test(p)
                    ? "spotify_browse"
                    : /\bapple\s*store\b|\bproducts?\b.*\baccessories\b/.test(p)
                        ? "apple_store"
                        : /\badmob\b|\bimpressions\b|\becpm\b|\brevenue dashboard\b/.test(p)
                            ? "admob_dashboard"
                            : undefined,
    };

    const conceptTag: PromptDesignSpec["content"]["conceptTag"] =
        /\binstagram\b.*\bhome\b|\binstagram-style\b|\binstagram style\b|\bhome feed\b/.test(p) ? "instagram_home"
            : /\blogin\b|\bsign in\b|\bauth\b|\bpasskey\b|\bcontinue with apple\b|\boauth\b/.test(p) ? "modern_login"
            : /\bpost-apocalyptic\b|\bbarter market\b|\bbattery %\b|\bwater liters?\b|\bammo\b/.test(p) ? "post_apoc_barter"
            : /\bluxury fragrance\b|\bscent-note\b|\bmidnight velvet\b|\bsunlit citrus\b/.test(p) ? "lux_fragrance"
                : /\bdeep-sea\b|\bsubmersible\b|\bsonar\b|\bpressure alerts?\b/.test(p) ? "deep_sea_research"
                    : /\bmoon colony\b|\bcrater routes?\b|\boxygen-safe\b|\bdocking gate\b/.test(p) ? "moon_transit"
                        : /\bgothic reading\b|\bcandlelight\b|\bquote vault\b|\breading streak\b/.test(p) ? "gothic_reading"
                            : /\bstreetwear drop\b|\braffle status\b|\bcop probability\b/.test(p) ? "streetwear_drop"
                                : /\bwildlife field log\b|\brainforest\b|\bspecies sighting\b|\bgeotag\b/.test(p) ? "wildlife_field_log"
                                    : /\bmise-en-place\b|\bprep lanes?\b|\bplating sequence\b/.test(p) ? "mise_en_place"
                                        : /\blegal case\b|\bargument trees?\b|\bevidence confidence\b|\bwitness reliability\b/.test(p) ? "legal_case_strategy"
                                            : /\bvinyl collector\b|\bpressing metadata\b|\bcondition grading\b/.test(p) ? "vinyl_collector"
                                                : /\bfilm pre-production\b|\bscene breakdown\b|\bshot-list\b|\bcontinuity\b/.test(p) ? "film_prepro"
                                                    : /\bcyberpunk bounty\b|\btarget threat\b|\bdistrict heatmap\b|\bgear loadout\b/.test(p) ? "cyberpunk_bounty"
                                                        : /\bhigh-altitude climbing\b|\bacclimatization\b|\boxygen reserve\b|\bstorm-window\b/.test(p) ? "altitude_climb"
                                                            : /\bperfume layering\b|\btop\/mid\/base accords?\b|\blongevity predictions?\b/.test(p) ? "perfume_layering"
                                                                : /\btattoo concept studio\b|\bpain-zone\b|\bink-tone\b|\bplacement silhouettes?\b/.test(p) ? "tattoo_studio"
                                                                    : undefined;
    const conceptVariant: PromptDesignSpec["content"]["conceptVariant"] =
        /\bclean\b|\bminimal\b|\bairy\b/.test(p) ? "clean"
            : /\bdense\b|\bcompact\b|\binformation-dense\b/.test(p) ? "dense"
                : /\bcinematic\b|\beditorial\b|\bimmersive\b/.test(p) ? "cinematic"
                    : undefined;

    return {
        strict: manifest.strictMode || /\bexactly\b|\bmust\b|\bonly\b/.test(p),
        strictOneToOne: /\bstrict\s*1:1\b|\b1:1\b|\bexact match\b|\bexactly like\b|\bpixel\b/.test(p),
        isSearchResultsMode: (() => {
            const hasSearchWord = /\bsearch\b/.test(p);
            const hasSearchContext = /\bresults?\b|\bautocomplete\b|\bquery\b|\bsearch screen\b|\bapp\s*store\b/.test(p);
            const looksLikeInstagramHome = /\binstagram\b|\bhome feed\b/.test(p);
            return (hasSearchWord && hasSearchContext) && !looksLikeInstagramHome;
        })(),
        layout,
        style,
        content: {
            emphasizedNouns,
            statePack: /\bstate pack\b|\bdefault loading empty error\b|\ball states\b|\bloading state\b|\bempty state\b|\berror state\b/.test(p),
            wantsSettingsToggles: /\bnotification preferences?\b|\bnotifications?.{0,24}\b(preferences?|settings?|list)\b|\bdark mode\b/.test(p) || (/\bsettings?\b/.test(p) && /\btoggle|switch|notifications?|sound\b/.test(p)),
            wantsNotificationPreferences: /\bnotification preferences?\b|\bnotifications?.{0,24}\b(preferences?|settings?|list)\b/.test(p),
            wantsDarkMode: /\bdark mode\b/.test(p),
            conceptVariant,
            conceptTag,
        },
        forbiddenSlotTypes: manifest.forbiddenSlotTypes,
        hardRules: manifest.hardRules,
    };
}

export function formatPromptDesignSpec(spec: PromptDesignSpec): string {
    return JSON.stringify(spec);
}

export function detectPromptRequirements(prompt: string): PromptRequirement[] {
    return buildDesignManifest(prompt).requirements;
}

export const INSTRUCTIONAL_COPY_PATTERNS: RegExp[] = [
    /\ba horizontal rail of\b/i,
    /\bsong cards with square artwork\b/i,
    /\bcircular profile\/?avatar items\b/i,
    /\bdisplay curated mixes for the day\b/i,
    /\bmust include\b/i,
    /\bprompt-locks?\b/i,
    /\brail spec\b/i,
    /\bschema\/spec instructions?\b/i,
];

export function sanitizeInstructionalDisplayText(text: string): string {
    const raw = text.trim();
    if (!raw) return raw;

    if (/^song cards with square artwork/i.test(raw)) return "Songs";
    if (/^circular profile\/?avatar items/i.test(raw)) return "Artists";
    if (/^display curated mixes for the day/i.test(raw)) return "Mixes";

    const railMatch = raw.match(/^a horizontal rail of (.+)$/i);
    if (railMatch?.[1]) return cleanIntentLabel(railMatch[1]);

    if (/\bprompt-locks?\b|\brail spec\b|\bmust include\b|\bschema\/spec/i.test(raw)) {
        return "Section";
    }
    return raw;
}

export function cleanIntentLabel(text: string): string {
    const cleaned = text
        .replace(/^a\s+horizontal\s+rail\s+of\s+/i, "")
        .replace(/^horizontal\s+rail\s+of\s+/i, "")
        .replace(/^a\s+/i, "")
        .replace(/^an\s+/i, "")
        .replace(/^the\s+/i, "")
        .replace(/^with\s+/i, "")
        .replace(/^for\s+/i, "")
        .replace(/\s+/g, " ")
        .trim();
    if (!cleaned) return "Section";
    return cleaned.charAt(0).toUpperCase() + cleaned.slice(1);
}

export function intentLabelFromRequirement(req: PromptRequirement): string {
    if (req.slotType === "horizontal_rail") {
        const variant = req.railSpec?.variant ?? detectRailVariantFromRequirement(req);
        if (variant === "media_track") return "Songs";
        if (variant === "circular_people") return "Artists";
        if (variant === "landscape") return "Mixes";
        if (variant === "chips") return "Chips";
        return "Featured";
    }
    if (req.slotType === "timeline_list") return "Timeline";
    if (req.slotType === "progress_section") return "Progress";
    if (req.slotType === "stat_group") return "Stats";
    return cleanIntentLabel(req.mustInclude);
}

export function enforcePlanRequirements(plan: ScreenPlan, promptRequirements: PromptRequirement[]): ScreenPlan {
    if (promptRequirements.length === 0) return plan;

    const slots = [...plan.slots];
    const requiredSlots = new Set<number>();
    const sortedRequirements = [...promptRequirements].sort((a, b) => a.sourceIndex - b.sourceIndex);

    const availableByType = new Map<SlotType, number[]>();
    slots.forEach((slot, index) => {
        const queue = availableByType.get(slot.slotType) ?? [];
        queue.push(index);
        availableByType.set(slot.slotType, queue);
    });

    for (const req of sortedRequirements) {
        const queue = availableByType.get(req.slotType) ?? [];
        const existingIndex = queue.length > 0 ? queue.shift()! : -1;
        availableByType.set(req.slotType, queue);

        if (existingIndex >= 0) {
            requiredSlots.add(existingIndex);
            const existing = slots[existingIndex];
            slots[existingIndex] = {
                ...existing,
                position: req.position,
                intent: req.requirementKey?.startsWith("explicit_") ? req.mustInclude : (existing.intent.includes(req.mustInclude) ? existing.intent : `${existing.intent}. Required: ${req.mustInclude}`),
                itemCount: req.itemCount ?? existing.itemCount,
                variant_hint: req.variantHint ?? existing.variant_hint ?? "strictly honor the prompt detail",
            };
            continue;
        }

        requiredSlots.add(slots.length);
        slots.push({
            slotType: req.slotType,
            position: req.position,
            intent: req.mustInclude,
            itemCount: req.itemCount,
            variant_hint: req.variantHint ?? "strictly honor the prompt detail",
        });
    }

    const requestedBodyOrder = sortedRequirements
        .filter((r) => r.position === "body")
        .map((r) => `${r.slotType}::${r.mustInclude}`);
    const bodyPriority = new Map<string, number>(requestedBodyOrder.map((key, index) => [key, index]));

    // Budget optional sections only after reserving explicit requirements.
    const chosen = new Set([...requiredSlots].slice(0, MAX_GENERATION_SLOTS));
    const exclusiveTypes = new Set(sortedRequirements.filter((r) => r.requirementKey?.startsWith("explicit_")).map((r) => r.slotType));
    for (let i = 0; i < slots.length && chosen.size < MAX_GENERATION_SLOTS; i++) {
        if (exclusiveTypes.has(slots[i].slotType) && !requiredSlots.has(i)) continue;
        chosen.add(i);
    }
    const selectedSlots = slots.filter((_, index) => chosen.has(index));
    const bodySlots = selectedSlots
        .map((slot, index) => ({ slot, index }))
        .filter(({ slot }) => slot.position === "body")
        .sort((a, b) => {
            const aKey = `${a.slot.slotType}::${a.slot.intent}`;
            const bKey = `${b.slot.slotType}::${b.slot.intent}`;
            const aPriority = bodyPriority.get(aKey);
            const bPriority = bodyPriority.get(bKey);
            if (aPriority !== undefined && bPriority !== undefined) return aPriority - bPriority;
            if (aPriority !== undefined) return -1;
            if (bPriority !== undefined) return 1;
            return a.index - b.index;
        })
        .map(({ slot }) => slot);
    const topSlots = selectedSlots.filter((s) => s.position === "top");
    const bottomSlots = selectedSlots.filter((s) => s.position === "bottom");
    const overlaySlots = selectedSlots.filter((s) => s.position === "overlay");

    return {
        ...plan,
        slots: [...topSlots, ...bodySlots, ...bottomSlots, ...overlaySlots].slice(0, MAX_GENERATION_SLOTS),
    };
}
