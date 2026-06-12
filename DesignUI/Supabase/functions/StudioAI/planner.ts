import { SCREEN_ARCHETYPES, SLOT_TYPES, VALID_SLOT_TYPES } from "./types.ts";
import type { AnyComponent, CanvasSettings, DesignManifest, PromptDesignSpec, RailVariant, ScreenArchetype, ScreenContract, ScreenPlan, SlotPlan, SlotPosition, SlotType, ThemeSurfaces, ThemeTokens } from "./types.ts";
import { ARCHETYPE_SLOT_TEMPLATES, CAPABILITY_MATRIX } from "./schema.ts";
import { ARCHETYPE_MAX_TOKENS, ARCHETYPE_MODEL, MAX_GENERATION_SLOTS, SLOT_PLANNER_MAX_TOKENS, SLOT_PLANNER_MODEL, callOpenAI } from "./openai.ts";
import { buildDesignManifest, compilePromptDesignSpec, enforcePlanRequirements, formatPromptDesignSpec } from "./manifest.ts";
import { isJsonParseError, isObject, parseJsonSafe } from "./utils.ts";
import { postProcessComponents } from "./postprocess.ts";


export function applyCapabilityMatrixToSlots(prompt: string, slots: SlotPlan[]): SlotPlan[] {
    const additions: SlotPlan[] = [];
    for (const rule of CAPABILITY_MATRIX) {
        if (!rule.keywords.some((re) => re.test(prompt))) continue;
        for (const add of rule.add) {
            additions.push({
                slotType: add.slotType,
                position: add.position,
                intent: add.intentTemplate,
                itemCount: add.itemCount,
                variant_hint: add.variant_hint,
            });
        }
    }
    if (additions.length === 0) return slots;
    const merged = [...slots];
    for (const add of additions) {
        const key = `${add.position}|${add.slotType}|${add.intent}`;
        const exists = merged.some((slot) => `${slot.position}|${slot.slotType}|${slot.intent}` === key);
        if (!exists) merged.push(add);
    }
    return merged;
}

export function buildReferenceStyleBlock(spec: PromptDesignSpec): string {
    const parts: string[] = [];
    const conceptGuides: Partial<Record<NonNullable<PromptDesignSpec["content"]["conceptTag"]>, string>> = {
        instagram_home: "Use exactly one story_rail for circular stories, social_feed_slot for post cards with avatar+image+actions rhythm, and nav_bar for 5 tabs. Do not add dashboard hero cards, gauges, follower summaries, streak metrics, or generic KPI sections unless the user explicitly asks for metrics.",
        modern_login: "Auth hero with brand copy, credential form with passkey affordance, social sign-in stack at bottom",
        post_apoc_barter: "Rugged scarcity metrics, trade offer rows, hazard accents, emergency resource chips",
        lux_fragrance: "Luxury editorial hero, mood filters, scent-note pyramid cards, refined serif hierarchy",
        deep_sea_research: "Submersible telemetry, sonar/glow charts, pressure warnings, mission timeline",
        moon_transit: "Crater route map, oxygen-safe paths, habitat ETAs, orbital transit chips",
        gothic_reading: "Candlelight atmosphere, ornate progress ribbons, quote vault cards, dark literary mood",
        streetwear_drop: "Drop countdown, heat bars, raffle status, size availability chips, hype-monitor feel",
        wildlife_field_log: "Geotag trail, species sighting cards, humidity/rain/risk field notes",
        mise_en_place: "Kitchen station timeline, prep lanes, heat zones, plating sequence, operational cooking metrics",
        legal_case_strategy: "Argument trees, hearing deadlines, evidence confidence, witness reliability rows",
        vinyl_collector: "Crate-style album shelves, pressing metadata, condition grading controls",
        film_prepro: "Scene boards, prop continuity checklist, weather-risk overlays, shot-list timeline",
        cyberpunk_bounty: "Neon bounty cards, threat meters, district heatmap, gear quick-switch chips",
        altitude_climb: "Acclimatization stages, camp logistics, oxygen reserve charts, storm-window risks",
        perfume_layering: "Top/mid/base accord modules, blend comparison, longevity prediction meters",
        tattoo_studio: "Ink motif gallery, placement silhouettes, pain-zone heatmap, studio session planning",
    };
    if (spec.content.conceptTag) {
        const guide = conceptGuides[spec.content.conceptTag] ?? "Use the concept as visual inspiration without copying a fixed layout.";
        parts.push(`STYLE CONCEPT: ${spec.content.conceptTag}\nVisual direction: ${guide}\nExpress this aesthetic through slot choices and variant_hints. Adapt to what the user actually asked for.`);
    }
    const patternGuides: Partial<Record<NonNullable<PromptDesignSpec["style"]["nativePattern"]>, string>> = {
        spotify_browse: "Chip filter row, media rails with distinct morphologies, mini-player bottom",
        mail_inbox: "Search bar, category pill tabs, dense thread rows with avatar+preview+date+unread dot",
        apple_store: "Product category tiles rail, accessory chip rail, large editorial product card",
        admob_dashboard: "Period selector header, dark sparkline metric cards stacked, minimal bottom nav",
        appstore_search: "Search bar top, flat suggestion rows with dividers only, no cards or hero sections",
    };
    if (spec.style.nativePattern) {
        const guide = patternGuides[spec.style.nativePattern] ?? "Use the native pattern as layout inspiration only.";
        parts.push(`NATIVE PATTERN: ${spec.style.nativePattern}\nStructure guidance: ${guide}\nUse as layout inspiration. User variations take priority.`);
    }
    return parts.join("\n\n");
}

// ─── Archetype Classification ────────────────────────────────────────────────

export const ARCHETYPE_CLASSIFIER_SYSTEM_PROMPT = `You classify mobile app prompts into a screen archetype.
Return JSON only: { "archetype": string }

VALID ARCHETYPES: ${SCREEN_ARCHETYPES.join(", ")}

Rules:
- "dashboard" = general overview with mixed metrics + lists (todo, habit tracker, etc.)
- "feed" / "social_feed" = scrolling content from other users
- "detail" = single item expanded view
- "onboarding" = welcome/intro/signup flow
- "settings" = preferences, account settings
- "media_browse" = Netflix/Spotify/podcast browsing
- "social_profile" = user profile page with stats + content grid
- "leaderboard" = ranked list / competition
- "chat" = messaging interface
- "marketplace" = product browsing / e-commerce
- "tracker" = habit/fitness/health tracking dashboard
- "journal" = diary/journal/notes
- "calendar" = date-based scheduling
- "workout" = exercise/fitness session
- "recipe" = cooking/recipe detail
- "music_player" = music/audio playback
- "news" = news/article feed
- "finance" = banking/budgeting/investing
- "travel" = trip planning/destination browsing
- "education" = learning/courses/language
- "health" = health/wellness tracking
- "portfolio" = investment portfolio
- "booking" = appointment/reservation
- "weather" = weather forecast
- "gaming" = game stats/progress
- "photography" = photo gallery/camera
- "meditation" = mindfulness/meditation
- "reading" = book/article reading list
- "shopping_cart" = checkout/cart
- "order_tracking" = delivery/order status
- "analytics" = data analytics dashboard
- "project_management" = project/task management

When multiple archetypes could fit, pick the one that best matches the DOMINANT interaction pattern. "todo app with gamification" → dashboard (not gaming). "instagram-like" → social_feed. "spotify clone" → media_browse.`;

export async function classifyArchetype(prompt: string): Promise<ScreenArchetype> {
    const response = await callOpenAI({
        model: ARCHETYPE_MODEL,
        messages: [
            { role: "system", content: ARCHETYPE_CLASSIFIER_SYSTEM_PROMPT },
            { role: "user", content: prompt },
        ],
        temperature: 0, maxTokens: ARCHETYPE_MAX_TOKENS, responseFormat: { type: "json_object" },
    });
    if (!response.ok) return "dashboard";
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) return "dashboard";
    const v = parsed.value as Record<string, unknown>;
    const arch = typeof v.archetype === "string" ? v.archetype : "dashboard";
    return (SCREEN_ARCHETYPES as readonly string[]).includes(arch) ? arch as ScreenArchetype : "dashboard";
}

// ─── Slot Planner ────────────────────────────────────────────────────────────

export const SLOT_PLANNER_SYSTEM_PROMPT = `You are a mobile UI screen architect.
Given an archetype and theme, output an ordered list of slots that compose a full screen.
Return JSON only: { "slots": [...], "canvas_settings": {...} }

Each slot:
{
  "slotType": string,    // from the VALID SLOT TYPES list
  "position": "top"|"body"|"bottom"|"overlay",
  "intent": string,      // 1-sentence specific to this app, e.g. "show daily XP streak and goal ring"
  "itemCount": number,   // for lists/grids/rails: how many items (2-6)
  "variant_hint": string // optional creative direction: "circular gauges", "card rows with progress bars", "floating pill chips"
}

VALID SLOT TYPES:
${SLOT_TYPES.join(", ")}

POSITION RULES:
- "top": app_header, search_bar (appears at top of ScrollView)
- "body": everything in the scrollable area
- "bottom": nav_bar, media_player, action_bar (fixed at bottom, NOT in ScrollView)
- "overlay": fab_button (floating over content)

GENERAL RULES:
- 3-7 slots total, ordered top → bottom.
- Maximum ONE app_header or search_bar (pick one based on the app's needs).
- Maximum ONE nav_bar.
- Maximum ONE media_player.
- Avoid duplicate slotTypes unless the intent is clearly different (e.g., two horizontal_rails with different content categories is fine).
- For the given archetype, use the DEFAULT TEMPLATE as a starting point but ADAPT it to the specific prompt and theme.
- For music_player archetype: do NOT add hero_banner unless the user explicitly asks for a hero/featured/banner section.
- For social_feed / Instagram-style home screens: do NOT add a dashboard hero, gauge, stats summary, streak block, or follower-count intro unless the user explicitly asks for analytics/profile metrics.
- variant_hint should guide the slot generator toward creative, theme-appropriate layouts. Be specific: "overlapping circular rings" not just "rings". "asymmetric poster cards with tag overlay" not just "cards".
- The plan should include one clear focal section and one supporting section with deliberate contrast (e.g., dense vs airy, editorial vs utility).
- Prefer intentional composition over safe defaults: asymmetry, overlap opportunities, or mixed section rhythms when appropriate.
- Do not create generic/repetitive plans where every section is the same card/list pattern.

CREATIVITY RULES (read these last, they override defaults):
- Reference patterns and templates above show common structures. Do NOT copy them slot-for-slot.
- Read the user's prompt word by word. Unusual words, specific combinations, and unique concepts MUST appear in your slot intents and variant_hints.
- variant_hint is your main creative lever. Use it to express what makes this specific screen unique.
- "spotify clone with gothic dark aesthetic" needs completely different variant_hints than default spotify.
- "minimal todo app" should have fewer slots than a "feature-rich dashboard" — match scope to the prompt.
- If the user described something you've never seen before, invent appropriate slots. Don't fall back to dashboard defaults.

VARIANT HINT IDEAS (use for inspiration):
- stat_group: "circular gauge rings", "horizontal pill stats", "large number cards with sparkline", "compact inline stats", "gradient background cards"
- content_list: "card rows with leading icon circles", "minimal rows with bold trailing", "swipeable task cards", "timeline-style connected rows", "grouped rows with section headers"
- horizontal_rail: "tall poster cards with gradient overlay", "square tiles with centered icon", "pill chips with icon", "wide landscape cards", "circular avatar items"
- hero_banner: "full-bleed gradient with overlay text", "compact stat banner with progress ring", "editorial large title with mascot", "immersive dark card with CTA"
- nav_bar: "floating rounded bar", "minimal icon-only", "pill highlight on active", "standard with divider"

canvas_settings:
- statusBarVisible: true (almost always)
- statusBarTopSafeArea: true (almost always)
- canvasColorScheme: "dark" only for immersive/media apps, otherwise omit`;

export function promptRequestsHeroSection(prompt: string): boolean {
    const p = prompt.toLowerCase();
    return /\bhero\b|\bfeatured\b|\bfeature\b|\bspotlight\b|\bbanner\b/.test(p);
}

export function applyArchetypeGuardrails(plan: ScreenPlan, prompt: string): ScreenPlan {
    if (plan.archetype !== "music_player") return plan;
    if (promptRequestsHeroSection(prompt)) return plan;
    return {
        ...plan,
        slots: plan.slots.filter((s) => s.slotType !== "hero_banner"),
    };
}

export async function planSlots(
    prompt: string,
    archetype: ScreenArchetype,
    theme: ThemeTokens,
    context: unknown,
    manifest?: DesignManifest,
    designSpec?: PromptDesignSpec,
    contractHint?: ScreenContract,
): Promise<ScreenPlan> {
    const template = ARCHETYPE_SLOT_TEMPLATES[archetype];
    const templateStr = JSON.stringify(template, null, 1);
    const resolvedManifest = manifest ?? buildDesignManifest(prompt);
    const resolvedSpec = designSpec ?? compilePromptDesignSpec(prompt, resolvedManifest);
    const promptRequirements = resolvedManifest.requirements;
    const requirementsBlock = promptRequirements.length > 0
        ? promptRequirements.map((r) => `- ${r.slotType} (${r.position}): ${r.mustInclude}${r.itemCount ? ` [count:${r.itemCount}]` : ""}${r.railSpec ? ` [rail_spec:${r.railSpec.variant}/${r.railSpec.itemShape}/text${r.railSpec.textRows}]` : ""}`).join("\n")
        : "- none";
    const hardRulesBlock = resolvedManifest.hardRules.length > 0
        ? resolvedManifest.hardRules.map((r) => `- ${r}`).join("\n")
        : "- none";

    const contractHintBlock = contractHint ? `
REFERENCE PATTERN (inspiration only — do not copy slot-for-slot):
This prompt resembles: ${contractHint}
Typical slots for this pattern: ${JSON.stringify(resolveContractAsPlan(contractHint, resolvedSpec).slots.map((slot) => slot.slotType))}
IMPORTANT: The user's actual words override this reference entirely. If they asked for something different, give them that.
` : "";
    const referenceStyleBlock = buildReferenceStyleBlock(resolvedSpec);

    const response = await callOpenAI({
        model: SLOT_PLANNER_MODEL,
        messages: [
            { role: "system", content: SLOT_PLANNER_SYSTEM_PROMPT },
            { role: "system", content: `ARCHETYPE: ${archetype}\nDEFAULT TEMPLATE:\n${templateStr}\n\nTHEME: appName="${theme.appName}" voiceTone="${theme.voiceTone}" surfaceStyle="${theme.surfaceStyle}" density="${theme.density}" itemNoun="${theme.itemNoun}" domainTags=[${theme.domainTags.join(",")}] accentColor="${theme.accentColor}" cornerRadiusScale="${theme.cornerRadiusScale}"\n\n${contractHintBlock}\n${referenceStyleBlock}\n\nPROMPT LOCKS (MUST HONOR):\n${requirementsBlock}\n\nDESIGN MANIFEST HARD RULES:\n${hardRulesBlock}\n\nPROMPT DSL SPEC (STRICT):\n${formatPromptDesignSpec(resolvedSpec)}\n\nIf prompt locks conflict with archetype template, prompt locks win.` },
            { role: "user", content: prompt },
        ],
        temperature: 0.3, maxTokens: SLOT_PLANNER_MAX_TOKENS, responseFormat: { type: "json_object" },
    });

    if (!response.ok) {
        const base = defaultPlanFromArchetype(archetype, theme, prompt);
        return applyArchetypeGuardrails(enforcePlanRequirements(base, promptRequirements), prompt);
    }
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) {
        const base = defaultPlanFromArchetype(archetype, theme, prompt);
        return applyArchetypeGuardrails(enforcePlanRequirements(base, promptRequirements), prompt);
    }
    return applyArchetypeGuardrails(enforcePlanRequirements(parseScreenPlan(parsed.value, archetype, theme, prompt), promptRequirements), prompt);
}

export function defaultPlanFromArchetype(archetype: ScreenArchetype, theme: ThemeTokens, prompt?: string): ScreenPlan {
    const template = ARCHETYPE_SLOT_TEMPLATES[archetype] ?? ARCHETYPE_SLOT_TEMPLATES.dashboard;
    const baseSlots = template.map((t) => ({
        slotType: t.slotType,
        position: t.position,
        intent: t.intentTemplate,
        itemCount: ["content_list", "content_grid", "horizontal_rail", "social_feed_slot", "timeline_list", "settings_list", "notification_list", "chat_bubble_list"].includes(t.slotType) ? 4 : undefined,
    }));
    const withCapabilities = prompt ? applyCapabilityMatrixToSlots(prompt, baseSlots) : baseSlots;
    return {
        archetype,
        slots: withCapabilities,
        canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: theme.surfaceStyle === "immersive" ? "dark" : undefined },
    };
}

export function parseScreenPlan(value: unknown, archetype: ScreenArchetype, theme: ThemeTokens, prompt?: string): ScreenPlan {
    if (!isObject(value)) return defaultPlanFromArchetype(archetype, theme, prompt);
    const planObject = value as Record<string, unknown>;
    const rawSlots = Array.isArray(planObject["slots"]) ? planObject["slots"] : [];
    const seen = new Set<string>();

    const parsed = rawSlots.map((item): SlotPlan | null => {
        if (!isObject(item)) return null;
        const st = typeof item.slotType === "string" ? item.slotType : "";
        if (!VALID_SLOT_TYPES.has(st)) return null;
        const position = typeof item.position === "string" && ["top", "body", "bottom", "overlay"].includes(item.position)
            ? item.position as SlotPosition : inferSlotPosition(st as SlotType);
        const intent = typeof item.intent === "string" ? item.intent : "";
        const itemCount = typeof item.itemCount === "number" ? Math.max(2, Math.min(8, item.itemCount)) : undefined;
        const variant_hint = typeof item.variant_hint === "string" ? item.variant_hint : undefined;

        // Allow duplicate slotTypes only for body slots with different intents
        const key = position === "body" ? `${st}::${intent.slice(0, 30)}` : st;
        if (seen.has(key) && position !== "body") return null;
        seen.add(key);

        return { slotType: st as SlotType, position, intent, itemCount, variant_hint };
    }).filter((x): x is NonNullable<typeof x> => x !== null).slice(0, MAX_GENERATION_SLOTS);

    const slots = parsed.length >= 2 ? parsed : defaultPlanFromArchetype(archetype, theme, prompt).slots;
    const enrichedSlots = prompt ? applyCapabilityMatrixToSlots(prompt, slots) : slots;
    const cs = isObject(planObject["canvas_settings"]) ? planObject["canvas_settings"] as Record<string, unknown> : {};
    return {
        archetype,
        slots: enrichedSlots,
        canvas_settings: {
            statusBarVisible: typeof cs["statusBarVisible"] === "boolean" ? cs["statusBarVisible"] : true,
            statusBarTopSafeArea: typeof cs["statusBarTopSafeArea"] === "boolean" ? cs["statusBarTopSafeArea"] : true,
            canvasColorScheme: cs["canvasColorScheme"] === "light" || cs["canvasColorScheme"] === "dark" ? cs["canvasColorScheme"] : (theme.surfaceStyle === "immersive" ? "dark" : undefined),
        },
    };
}

export function inferSlotPosition(slotType: SlotType): SlotPosition {
    if (["app_header", "search_bar"].includes(slotType)) return "top";
    if (["nav_bar", "media_player", "action_bar"].includes(slotType)) return "bottom";
    if (["fab_button"].includes(slotType)) return "overlay";
    return "body";
}

export function normalizeIntentKey(input: string): string {
    return input.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
}

export function withDistinctRailHints(slot: SlotPlan, railIndex: number): SlotPlan {
    if (slot.slotType !== "horizontal_rail") return slot;
    const forcedByIndex: RailVariant[] = ["media_track", "circular_people", "poster", "landscape", "chips"];
    const forced = forcedByIndex[railIndex % forcedByIndex.length];
    const existing = slot.variant_hint?.trim() ?? "";
    if (existing.toLowerCase().includes("force distinct rail morphology")) return slot;
    return {
        ...slot,
        variant_hint: existing.length > 0
            ? `${existing} | force distinct rail morphology: ${forced}`
            : `force distinct rail morphology: ${forced}`,
    };
}

export function refineScreenPlan(basePlan: ScreenPlan, manifest?: DesignManifest, designSpec?: PromptDesignSpec): ScreenPlan {
    const originalSlots = Array.isArray(basePlan.slots) ? basePlan.slots : [];
    if (originalSlots.length === 0) return basePlan;

    const seen = new Set<string>();
    const deduped: SlotPlan[] = [];

    for (const slot of originalSlots) {
        if (manifest?.forbiddenSlotTypes?.includes(slot.slotType)) continue;
        const intentKey = normalizeIntentKey(slot.intent);
        const dedupeKey = `${slot.position}|${slot.slotType}|${intentKey}`;
        if (seen.has(dedupeKey)) continue;
        seen.add(dedupeKey);
        deduped.push(slot);
    }

    const topSlots = deduped.filter((s) => s.position === "top");
    const bodySlots = deduped.filter((s) => s.position === "body");
    const bottomSlots = deduped.filter((s) => s.position === "bottom");
    const overlaySlots = deduped.filter((s) => s.position === "overlay");
    const rawPrompt = (manifest?.rawPrompt ?? "").toLowerCase();
    const isProfileLike = /\bsocial profile\b|\bprofile page\b|\bavatar\b.*\bstats?\b|\brecent content\b/.test(rawPrompt);
    const isInstagramHomeLike =
        designSpec?.content.conceptTag === "instagram_home" ||
        /\binstagram\b.*\bhome\b|\bhome feed\b|\bstor(y|ies)\b.*\bfeed\b/.test(rawPrompt);
    const effectiveTopSlots = isProfileLike
        ? topSlots.filter((s) => s.slotType !== "app_header" && s.slotType !== "search_bar")
        : topSlots;

    const primaryTop = effectiveTopSlots.find((s) => s.slotType === "search_bar")
        ?? effectiveTopSlots.find((s) => s.slotType === "app_header")
        ?? effectiveTopSlots[0];
    const refinedTop = primaryTop ? [primaryTop] : [];

    const keepSingleBottomType = (slots: SlotPlan[], type: SlotType): SlotPlan[] => {
        let kept = false;
        return slots.filter((s) => {
            if (s.slotType !== type) return true;
            if (kept) return false;
            kept = true;
            return true;
        });
    };

    let refinedBottom = [...bottomSlots];
    if (designSpec?.layout.forbidBottomControls) {
        refinedBottom = [];
    }
    refinedBottom = keepSingleBottomType(refinedBottom, "nav_bar");
    refinedBottom = keepSingleBottomType(refinedBottom, "media_player");
    refinedBottom = keepSingleBottomType(refinedBottom, "action_bar");

    const focalSlotTypes = new Set<SlotType>([
        "hero_banner",
        "card_detail",
        "progress_section",
        "chart_section",
        "weather_widget",
        "map_preview",
        "floating_card",
    ]);
    const supportSlotTypes = new Set<SlotType>([
        "content_list",
        "content_grid",
        "horizontal_rail",
        "settings_list",
        "social_feed_slot",
        "timeline_list",
        "notification_list",
    ]);

    let refinedBody = [...bodySlots];
    const hasFocal = refinedBody.some((s) => focalSlotTypes.has(s.slotType));
    const hasSupport = refinedBody.some((s) => supportSlotTypes.has(s.slotType));

    if (!designSpec?.isSearchResultsMode && !isInstagramHomeLike && basePlan.archetype !== "social_feed" && !hasFocal && refinedBody.length > 0) {
        refinedBody.unshift({
            slotType: "hero_banner",
            position: "body",
            intent: "primary focal section with headline + key value + CTA",
            variant_hint: "editorial focal block with strong hierarchy",
        });
    }

    if (!hasSupport && refinedBody.length > 0) {
        refinedBody.push({
            slotType: "content_list",
            position: "body",
            intent: "supporting list of recent items",
            itemCount: 4,
            variant_hint: "compact supporting rows with clear secondary information",
        });
    }

    if (isProfileLike) {
        // Profile pages should not inherit dashboard-style greeting/streak hero blocks.
        refinedBody = refinedBody.filter((s) =>
            s.slotType !== "hero_banner" &&
            s.slotType !== "progress_section" &&
            s.slotType !== "stat_group"
        );
    }

    if (isInstagramHomeLike) {
        let keptStoryRail = false;
        refinedBody = refinedBody
            .filter((s) => s.slotType !== "hero_banner" && s.slotType !== "progress_section" && s.slotType !== "stat_group" && s.slotType !== "chart_section")
            .map((slot) => {
                if (slot.slotType === "horizontal_rail") {
                    return {
                        ...slot,
                        slotType: "story_rail" as SlotType,
                        intent: slot.intent || "coffee shop stories row with circular avatars",
                        itemCount: slot.itemCount ?? 8,
                        variant_hint: `${slot.variant_hint ?? ""} | circular Instagram-style story avatars, not artist cards`.trim(),
                    };
                }
                if (slot.slotType === "social_feed_slot") {
                    return {
                        ...slot,
                        intent: slot.intent || "warm editorial coffee shop post feed",
                        variant_hint: `${slot.variant_hint ?? ""} | cozy cream and brown post cards with avatar header, image area, actions, caption`.trim(),
                    };
                }
                return slot;
            })
            .filter((slot) => {
                if (slot.slotType !== "story_rail") return true;
                if (keptStoryRail) return false;
                keptStoryRail = true;
                return true;
            });
    }

    if (designSpec?.content.wantsSettingsToggles) {
        const topHeader = topSlots.find((s) => s.slotType === "app_header") ?? {
            slotType: "app_header" as SlotType,
            position: "top" as SlotPosition,
            intent: "settings title and utility actions",
            variant_hint: "native settings header",
        };
        const settingsRows = refinedBody.find((s) => s.slotType === "settings_list") ?? {
            slotType: "settings_list" as SlotType,
            position: "body" as SlotPosition,
            intent: "settings toggles for notifications dark mode and sound",
            itemCount: 3,
            variant_hint: "switch rows not chevrons",
        };
        return {
            ...basePlan,
            slots: [topHeader, settingsRows].slice(0, MAX_GENERATION_SLOTS),
        };
    }

    if (designSpec?.content.statePack) {
        const stateSlots: SlotPlan[] = [
            {
                slotType: "segmented_tabs",
                position: "body",
                intent: "state switcher with tabs: Default Loading Empty Error",
                variant_hint: "four compact state chips with one active",
            },
            {
                slotType: "content_list",
                position: "body",
                intent: "default state content preview list",
                itemCount: 4,
                variant_hint: "normal populated state rows",
            },
            {
                slotType: "empty_state",
                position: "body",
                intent: "empty state block with guidance",
                variant_hint: "clear no-data messaging",
            },
            {
                slotType: "banner_alert",
                position: "body",
                intent: "error state summary with retry action",
                variant_hint: "inline error treatment with recovery affordance",
            },
        ];
        const top = refinedTop.length > 0 ? refinedTop : [];
        const bottom = designSpec.layout.allowBottomControls ? refinedBottom.slice(0, 1) : [];
        return {
            ...basePlan,
            slots: [...top, ...stateSlots, ...bottom].slice(0, MAX_GENERATION_SLOTS),
        };
    }

    // Search/results mode: enforce App Store-like query + suggestions/results structure.
    if (designSpec?.isSearchResultsMode) {
        const resultCount = typeof designSpec.layout.targetCardCount === "number"
            ? Math.max(1, Math.min(12, designSpec.layout.targetCardCount))
            : undefined;
        const ensureTop = topSlots.find((s) => s.slotType === "search_bar") ?? {
            slotType: "search_bar" as SlotType,
            position: "top" as SlotPosition,
            intent: "search query bar with quick access actions",
            variant_hint: "native iOS search field presentation",
        };
        const resultsList = refinedBody.find((s) => s.slotType === "content_list") ?? {
            slotType: "content_list" as SlotType,
            position: "body" as SlotPosition,
            intent: "search autocomplete suggestions",
            itemCount: 6,
            variant_hint: "app-store-like suggestion rows with subtle dividers",
        };
        const requestedFilterRail = refinedBody.find((s) =>
            s.slotType === "horizontal_rail"
            && /\b(filter|chip|category|categories|tag|segment)\b/i.test(s.intent || "")
        );

        if (typeof resultCount === "number") {
            resultsList.itemCount = resultCount;
        }
        refinedBody = requestedFilterRail ? [requestedFilterRail, resultsList] : [resultsList];
        refinedBottom = designSpec.layout.allowBottomControls
            ? refinedBottom.filter((s) => s.slotType === "nav_bar").slice(0, 1)
            : [];
        return {
            ...basePlan,
            slots: [ensureTop, ...refinedBody, ...refinedBottom].slice(0, MAX_GENERATION_SLOTS),
        };
    }

    // Diversify repeated horizontal rails up front to reduce same-looking sections.
    let railCount = 0;
    refinedBody = refinedBody.map((slot) => {
        if (slot.slotType !== "horizontal_rail") return slot;
        const next = withDistinctRailHints(slot, railCount);
        railCount += 1;
        return next;
    });

    // Enforce requested rail count when explicitly provided in the prompt DSL.
    if (typeof designSpec?.layout.targetRailCount === "number") {
        const targetRailCount = Math.max(0, Math.min(4, designSpec.layout.targetRailCount));
        const railIndices = refinedBody
            .map((slot, index) => ({ slot, index }))
            .filter(({ slot }) => slot.slotType === "horizontal_rail")
            .map(({ index }) => index);

        if (railIndices.length > targetRailCount) {
            const keep = new Set(railIndices.slice(0, targetRailCount));
            refinedBody = refinedBody.filter((slot, index) => slot.slotType !== "horizontal_rail" || keep.has(index));
        } else if (railIndices.length < targetRailCount) {
            const needed = targetRailCount - railIndices.length;
            for (let i = 0; i < needed; i++) {
                refinedBody.push(withDistinctRailHints({
                    slotType: "horizontal_rail",
                    position: "body",
                    intent: `curated category ${railIndices.length + i + 1}`,
                    itemCount: 5,
                    variant_hint: "distinct rail morphology with clear content identity",
                }, railIndices.length + i));
            }
        }
    }

    // If strict and a target card count exists, push it into stat/content card sections.
    if (designSpec?.strict && typeof designSpec.layout.targetCardCount === "number") {
        const exactCards = Math.max(1, Math.min(8, designSpec.layout.targetCardCount));
        refinedBody = refinedBody.map((slot) => {
            if (slot.slotType === "stat_group" || slot.slotType === "content_grid" || slot.slotType === "horizontal_rail") {
                return { ...slot, itemCount: exactCards };
            }
            return slot;
        });
    }

    // Keep within generation budget and maintain a sane minimum.
    let merged = [...refinedTop, ...refinedBody, ...refinedBottom, ...overlaySlots];

    // Enforce target section count when requested (applies to top+body+bottom, excludes overlays).
    if (typeof designSpec?.layout.targetSectionCount === "number") {
        const target = Math.max(2, Math.min(MAX_GENERATION_SLOTS, designSpec.layout.targetSectionCount));
        const overlays = merged.filter((s) => s.position === "overlay");
        let primary = merged.filter((s) => s.position !== "overlay");

        if (primary.length > target) {
            const top = primary.filter((s) => s.position === "top");
            const body = primary.filter((s) => s.position === "body");
            const bottom = primary.filter((s) => s.position === "bottom");
            const fixed = [...top.slice(0, 1), ...bottom.slice(0, 1)];
            const remaining = Math.max(0, target - fixed.length);
            primary = [...fixed, ...body.slice(0, remaining)];
        } else if (primary.length < target) {
            const needed = target - primary.length;
            for (let i = 0; i < needed; i++) {
                primary.push({
                    slotType: i % 2 === 0 ? "section_header" : "content_list",
                    position: "body",
                    intent: i % 2 === 0 ? `section ${i + 1}` : `supporting items ${i + 1}`,
                    itemCount: i % 2 === 0 ? undefined : 4,
                    variant_hint: "maintain visual hierarchy and avoid repetitive rows",
                });
            }
        }
        merged = [...primary, ...overlays];
    }

    if (merged.length < 3) {
        merged = [...merged, {
            slotType: "content_list",
            position: "body",
            intent: "supporting list content",
            itemCount: 4,
        }];
    }
    if (merged.length > MAX_GENERATION_SLOTS) merged = merged.slice(0, MAX_GENERATION_SLOTS);

    return {
        ...basePlan,
        slots: merged,
    };
}

export function resolveScreenContract(prompt: string, spec: PromptDesignSpec): ScreenContract | null {
    const p = prompt.toLowerCase();
    if (/\bsocial profile\b|\bprofile page\b|\bavatar\b.*\bstats?\b|\bstats?\b.*\bavatar\b|\brecent content\b/.test(p)) return "profile_social_v1";
    if (/\bcamera\b|\bcapture\b|\bphoto app\b/.test(p)) return "camera_capture_v1";
    if (/\badmin\b|\bdata table\b|\btable view\b/.test(p)) return "admin_table_v1";
    if (/\bsupport\b|\bhelp center\b|\bcustomer support\b/.test(p)) return "customer_support_v1";
    if (/\bhotel\b|\broom booking\b|\bstay booking\b/.test(p)) return "booking_hotel_v1";
    if (/\bnews\b|\breader\b|\barticles?\b/.test(p)) return "news_reader_v1";
    if (/\bhealth\b|\bactivity\b|\bsteps\b|\bworkout history\b/.test(p)) return "health_activity_v1";
    if (/\bprofile\b|\bfollowers?\b/.test(p)) return "profile_social_v1";
    if (/\bnotifications?\b|\bactivity inbox\b/.test(p)) return "notification_center_v1";
    if (/\bonboarding\b|\bget started flow\b/.test(p)) return "onboarding_flow_v1";
    if (/\bkanban\b|\bboard\b|\bcolumns?\b.*\bcards?\b/.test(p)) return "kanban_board_v1";
    if (/\bcalendar\b|\bweek view\b|\bschedule week\b/.test(p)) return "calendar_week_v1";
    if (/\bdelivery\b|\brestaurant\b|\bfood app\b/.test(p)) return "restaurant_delivery_v1";
    if (/\bloading\b|\bempty state\b|\berror state\b|\bskeleton\b/.test(p)) return "state_pack_v1";
    if (/\b2fa\b|\bone-time code\b|\bverification code\b|\bmagic link\b/.test(p)) return "auth_2fa_v1";
    if (/\bsettings\b|\bprivacy\b|\baccount\b/.test(p)) return "settings_account_v1";
    if (/\bcheckout\b|\bcart\b|\bpayment\b/.test(p)) return "checkout_flow_v1";
    if (/\bshorts?\b|\breels?\b|\btiktok\b|\bvideo feed\b/.test(p)) return "video_feed_v1";
    if (/\bmap\b|\blocation\b|\bnearby\b|\bdirections\b/.test(p)) return "maps_explore_v1";
    if (/\bchat thread\b|\bdm thread\b|\bconversation\b/.test(p)) return "chat_thread_v1";
    if (/\binbox\b|\bmessages\b|\bdms?\b/.test(p)) return "chat_inbox_v1";
    if (/\bspotify\b/.test(p)) return "music_discovery_v1";
    if (/\bcreator\b|\bcontent performance\b|\bdashboard\b.*\bcreator\b|\banalytics\b.*\bcreator\b/.test(p)) return "creator_dashboard_v1";
    if (/\becommerce\b|\bshop\b|\bstorefront\b|\bproduct grid\b|\bcart\b/.test(p)) return "ecommerce_home_v1";
    if (/\btravel\b|\bitinerary\b|\btrip planner\b|\bbooking\b|\bflights?\b|\bhotels?\b/.test(p)) return "travel_planner_v1";
    if (/\bfinance\b|\bportfolio\b|\bwatchlist\b|\ballocation\b|\binvest(ing|ment)?\b/.test(p)) return "finance_portfolio_v1";
    if (/\blearning\b|\bcourse\b|\blesson\b|\bstreak\b|\bstudy\b|\bpath\b/.test(p)) return "learning_path_v1";
    if (spec.content.conceptTag === "instagram_home") return "instagram_feed_v1";
    if (spec.content.conceptTag === "modern_login") return "modern_login_v1";
    if (spec.isSearchResultsMode || spec.style.nativePattern === "appstore_search") return "search_results_native_v1";
    if (/\binstagram\b/.test(p)) return "instagram_feed_v1";
    if (/\bmusic\b|\bplaylist\b|\bplaylists\b|\brecommendations?\b|\bdiscover(y)?\b/.test(p)) return "music_discovery_v1";
    return null;
}

export function resolveContractAsPlan(contract: ScreenContract, _spec: PromptDesignSpec): ScreenPlan {
    const make = (
        slotType: SlotType,
        position: SlotPosition,
        intent: string,
        itemCount?: number,
        variant_hint?: string,
    ): SlotPlan => ({ slotType, position, intent, itemCount, variant_hint });

    const base: ScreenPlan = {
        archetype: "dashboard",
        slots: [],
        canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true },
    };

    const plans: Record<ScreenContract, ScreenPlan> = {
        modern_login_v1: { ...base, archetype: "onboarding", slots: [
            make("hero_banner", "body", "welcome and trust-building headline"),
            make("form_section", "body", "email/password inputs with recovery affordances", 3),
            make("action_bar", "bottom", "primary sign-in CTA and secondary auth options"),
        ]},
        instagram_feed_v1: { ...base, archetype: "social_feed", slots: [
            make("app_header", "top", "social feed brand header with quick actions"),
            make("story_rail", "body", "stories row with circular avatars", 8),
            make("social_feed_slot", "body", "post feed with author, media, actions, caption", 4),
            make("nav_bar", "bottom", "social bottom navigation"),
        ]},
        music_discovery_v1: { ...base, archetype: "music_player", slots: [
            make("app_header", "top", "music browse header and controls"),
            make("segmented_tabs", "body", "music filters like all, playlists, podcasts"),
            make("horizontal_rail", "body", "featured albums and mixes", 6),
            make("content_list", "body", "recommended tracks and playlists", 6),
            make("media_player", "bottom", "mini player controls"),
        ]},
        creator_dashboard_v1: { ...base, archetype: "analytics", slots: [
            make("app_header", "top", "creator analytics header"),
            make("stat_group", "body", "key creator metrics cards", 4),
            make("chart_section", "body", "audience/performance trend chart"),
            make("content_list", "body", "recent posts with performance deltas", 5),
        ]},
        ecommerce_home_v1: { ...base, archetype: "marketplace", slots: [
            make("search_bar", "top", "store search and category quick filters"),
            make("hero_banner", "body", "featured sale/promo card with CTA"),
            make("content_grid", "body", "product grid with prices", 6),
            make("nav_bar", "bottom", "shopping app bottom navigation"),
        ]},
        travel_planner_v1: { ...base, archetype: "travel", slots: [
            make("app_header", "top", "trip planner overview"),
            make("timeline_list", "body", "itinerary timeline with day stops", 6),
            make("content_list", "body", "bookings and travel checklist rows", 5),
            make("action_bar", "bottom", "primary travel action controls"),
        ]},
        finance_portfolio_v1: { ...base, archetype: "finance", slots: [
            make("app_header", "top", "portfolio summary header with value and delta"),
            make("chart_section", "body", "allocation/performance chart"),
            make("content_list", "body", "watchlist rows ticker, price, change", 6),
            make("nav_bar", "bottom", "finance bottom tabs"),
        ]},
        learning_path_v1: { ...base, archetype: "education", slots: [
            make("app_header", "top", "learning progress header"),
            make("progress_section", "body", "course progress and streak visualization"),
            make("content_list", "body", "lesson list with status", 6),
            make("action_bar", "bottom", "continue learning CTA"),
        ]},
        chat_inbox_v1: { ...base, archetype: "chat", slots: [
            make("app_header", "top", "messages header and actions"),
            make("search_bar", "top", "search conversations"),
            make("chat_bubble_list", "body", "inbox thread preview list", 8),
            make("nav_bar", "bottom", "chat app navigation"),
        ]},
        chat_thread_v1: { ...base, archetype: "chat", slots: [
            make("app_header", "top", "conversation title and actions"),
            make("chat_bubble_list", "body", "message bubbles in active conversation", 10),
            make("action_bar", "bottom", "compose/send message controls"),
        ]},
        maps_explore_v1: { ...base, archetype: "travel", slots: [
            make("search_bar", "top", "location search and filters"),
            make("map_preview", "body", "nearby places map context"),
            make("horizontal_rail", "body", "nearby places cards", 5),
            make("action_bar", "bottom", "route and save actions"),
        ]},
        video_feed_v1: { ...base, archetype: "social_feed", slots: [
            make("social_feed_slot", "body", "full-bleed short video feed cards", 4),
            make("action_bar", "overlay", "vertical interaction actions"),
            make("nav_bar", "bottom", "video app tabs"),
        ]},
        checkout_flow_v1: { ...base, archetype: "shopping_cart", slots: [
            make("app_header", "top", "checkout title and step indicator"),
            make("content_list", "body", "cart items with quantities/prices", 4),
            make("form_section", "body", "shipping and payment sections", 3),
            make("action_bar", "bottom", "place order CTA"),
        ]},
        settings_account_v1: { ...base, archetype: "settings", slots: [
            make("app_header", "top", "account settings header"),
            make("profile_header", "body", "user avatar and account summary"),
            make("settings_list", "body", "settings rows with toggles and chevrons", 8),
        ]},
        auth_2fa_v1: { ...base, archetype: "onboarding", slots: [
            make("hero_banner", "body", "verification instructions and trust copy"),
            make("form_section", "body", "one-time code entry"),
            make("action_bar", "bottom", "verify and resend actions"),
        ]},
        state_pack_v1: { ...base, archetype: "dashboard", slots: [
            make("empty_state", "body", "empty/loading/error state compositions"),
            make("content_list", "body", "state explanation and recovery actions", 4),
        ]},
        restaurant_delivery_v1: { ...base, archetype: "order_tracking", slots: [
            make("search_bar", "top", "restaurant search and filters"),
            make("horizontal_rail", "body", "cuisine and featured restaurants", 6),
            make("content_list", "body", "restaurant cards with ETA and rating", 6),
            make("nav_bar", "bottom", "delivery app tabs"),
        ]},
        calendar_week_v1: { ...base, archetype: "calendar", slots: [
            make("app_header", "top", "weekly schedule overview"),
            make("calendar_strip", "body", "week day/date selector strip"),
            make("timeline_list", "body", "events/tasks by day timeline", 8),
        ]},
        kanban_board_v1: { ...base, archetype: "project_management", slots: [
            make("app_header", "top", "board title and filters"),
            make("segmented_tabs", "top", "board scope and grouping tabs"),
            make("content_grid", "body", "kanban columns with cards", 6),
        ]},
        onboarding_flow_v1: { ...base, archetype: "onboarding", slots: [
            make("onboarding_step", "body", "step hero with value proposition"),
            make("progress_section", "body", "onboarding progress indicator"),
            make("action_bar", "bottom", "next/skip controls"),
        ]},
        notification_center_v1: { ...base, archetype: "dashboard", slots: [
            make("app_header", "top", "notifications center header"),
            make("segmented_tabs", "top", "all/unread/filter tabs"),
            make("notification_list", "body", "notification rows with metadata", 8),
        ]},
        profile_social_v1: { ...base, archetype: "social_profile", slots: [
            make("profile_header", "body", "avatar, name, stats, follow actions"),
            make("segmented_tabs", "body", "content filters like posts/media/tagged"),
            make("content_grid", "body", "recent content cards", 6),
        ]},
        health_activity_v1: { ...base, archetype: "health", slots: [
            make("app_header", "top", "activity summary header"),
            make("stat_group", "body", "rings and activity metrics", 4),
            make("chart_section", "body", "daily/weekly trends"),
            make("timeline_list", "body", "recent workouts", 5),
        ]},
        news_reader_v1: { ...base, archetype: "news", slots: [
            make("app_header", "top", "news briefing header"),
            make("horizontal_rail", "body", "top stories rail", 5),
            make("content_list", "body", "article feed with sources/timestamps", 8),
        ]},
        booking_hotel_v1: { ...base, archetype: "booking", slots: [
            make("search_bar", "top", "destination/date/guest query"),
            make("hero_banner", "body", "featured stay offer"),
            make("content_list", "body", "hotel listing cards with price/rating", 6),
            make("action_bar", "bottom", "apply filters/sort actions"),
        ]},
        customer_support_v1: { ...base, archetype: "chat", slots: [
            make("app_header", "top", "support center header"),
            make("content_list", "body", "help topics and FAQ rows", 6),
            make("form_section", "body", "issue input and contact options", 3),
            make("action_bar", "bottom", "submit/start chat action"),
        ]},
        admin_table_v1: { ...base, archetype: "analytics", slots: [
            make("app_header", "top", "admin dataset controls"),
            make("search_bar", "top", "search/filter toolbar"),
            make("comparison_table", "body", "tabular records with row actions"),
            make("action_bar", "bottom", "page navigation controls"),
        ] as SlotPlan[] },
        camera_capture_v1: { ...base, archetype: "photography", slots: [
            make("hero_banner", "body", "live camera preview framing"),
            make("action_bar", "bottom", "shutter, mode, and capture actions"),
        ]},
        search_results_native_v1: { ...base, archetype: "news", slots: [
            make("search_bar", "top", "query input with native search affordance"),
            make("content_list", "body", "autocomplete suggestions and search results", 8),
            make("horizontal_rail", "body", "refinement chips and related categories", 6),
        ]},
    };

    return plans[contract] ?? base;
}

export function buildContractScreen(contract: ScreenContract, theme: ThemeTokens, surfaces: ThemeSurfaces): { components: AnyComponent[]; canvas_settings: CanvasSettings } {
    const full = { type: "Frame", properties: { widthType: "Full", heightType: "Full" } };
    const fullW = { type: "Frame", properties: { widthType: "Full", heightType: "Default" } };
    const mkText = (text: string, size: string, weight: string, color?: string): AnyComponent => ({
        type: "Text",
        properties: { text },
        modifiers: [{ type: "Font", properties: { fontSize: size, fontWeight: weight } }, ...(color ? [{ type: "Foreground Color", properties: { color } }] : [])],
    });
    const mkSym = (symbolName: string, color?: string, size = "body", weight = "semibold"): AnyComponent => ({
        type: "SF Symbol",
        properties: { symbolName },
        modifiers: [{ type: "Font", properties: { fontSize: size, fontWeight: weight } }, ...(color ? [{ type: "Foreground Color", properties: { color } }] : [])],
    });
    if (contract === "modern_login_v1") {
        const hero: AnyComponent = {
            type: "VStack",
            properties: { alignment: "leading", spacing: 12 },
            modifiers: [fullW],
            children: [
                { type: "Text", properties: { text: "Welcome back" }, modifiers: [{ type: "Font", properties: { fontSize: "largeTitle", fontWeight: "bold" } }] },
                { type: "Text", properties: { text: "Sign in to continue" }, modifiers: [{ type: "Foreground Color", properties: { color: surfaces.secondaryText } }] },
            ],
        };
        const fieldRow = (symbol: string, text: string): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 10, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 14 } }],
            children: [mkSym(symbol, surfaces.iconTint), { type: "Text", properties: { text }, modifiers: [{ type: "Foreground Color", properties: { color: surfaces.secondaryText } }] }],
        });
        const login: AnyComponent = {
            type: "VStack",
            properties: { alignment: "leading", spacing: 12 },
            modifiers: [fullW],
            children: [
                fieldRow("envelope", "Email"),
                fieldRow("lock", "Password"),
                {
                    type: "HStack",
                    properties: { spacing: 8, alignment: "center" },
                    modifiers: [fullW],
                    children: [mkSym("faceid", surfaces.iconTint), mkText("Use Passkey", "subheadline", "semibold", theme.accentColor), { type: "Spacer" }, mkText("Forgot?", "subheadline", "semibold", theme.accentColor)],
                },
                {
                    type: "Button",
                    properties: { title: "Sign In", buttonStyle: "plain" },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 13, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 14 } }],
                },
            ],
        };
        const social: AnyComponent = {
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            modifiers: [fullW],
            children: [
                mkText("or continue with", "caption", "regular", surfaces.secondaryText),
                {
                    type: "HStack",
                    properties: { spacing: 10, alignment: "center" },
                    modifiers: [fullW],
                    children: [
                        {
                            type: "HStack",
                            properties: { spacing: 8, alignment: "center" },
                            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "white:1.0" } }, { type: "Corner Radius", properties: { radius: 12 } }],
                            children: [mkSym("apple.logo", "black:1.0"), mkText("Apple", "body", "semibold", "black:1.0")],
                        },
                    ],
                },
            ],
        };
        const root: AnyComponent = {
            type: "ScrollView",
            properties: { axis: "vertical", showsIndicators: false },
            modifiers: [full],
            children: [{
                type: "VStack",
                properties: { alignment: "leading", spacing: 22 },
                modifiers: [fullW, { type: "Padding", properties: { amount: 20, location: "all" } }],
                children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 48 } }] }, hero, login, social],
            }],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "instagram_feed_v1") {
        const story = (name: string): AnyComponent => ({
            type: "VStack",
            properties: { spacing: 6, alignment: "center" },
            children: [
                { type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 62, heightType: "Custom", height: 62 } }, { type: "Stroke", properties: { color: theme.accentColor, lineWidth: 2 } }] },
                mkText(name, "caption", "regular"),
            ],
        });
        const postCard = (user: string): AnyComponent => ({
            type: "VStack",
            properties: { alignment: "leading", spacing: 10 },
            modifiers: [fullW],
            children: [
                { type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 34, heightType: "Custom", height: 34 } }, { type: "Fill", properties: { color: "gray:0.20" } }] }, mkText(user, "subheadline", "semibold"), { type: "Spacer" }, mkSym("ellipsis", surfaces.iconTint)] },
                {
                    type: "RoundedRectangle",
                    properties: { cornerRadius: 10 },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 320 } },
                        { type: "Fill", properties: { color: surfaces.cardFill } },
                    ],
                },
                { type: "HStack", properties: { spacing: 14, alignment: "center" }, children: [mkSym("heart", surfaces.primaryText), mkSym("bubble.right", surfaces.primaryText), mkSym("paperplane", surfaces.primaryText), { type: "Spacer" }, mkSym("bookmark", surfaces.primaryText)] },
                mkText("Liked by alex and 128 others", "caption", "semibold"),
                mkText("A clean post caption with enough detail for realism.", "caption", "regular", surfaces.secondaryText),
            ],
        });
        const root: AnyComponent = {
            type: "VStack",
            properties: { alignment: "leading", spacing: 0 },
            modifiers: [full],
            children: [
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 12 },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "horizontal" } }, { type: "Padding", properties: { amount: 8, location: "vertical" } }],
                    children: [
                        { type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [mkText("Designgram", "title3", "bold"), { type: "Spacer" }, mkSym("plus.app", surfaces.primaryText), mkSym("heart", surfaces.primaryText), mkSym("paperplane", surfaces.primaryText)] },
                        {
                            type: "ScrollView",
                            properties: { axis: "horizontal", showsIndicators: false },
                            modifiers: [fullW],
                            children: [{ type: "HStack", properties: { spacing: 12, alignment: "center" }, children: [story("you"), story("mia"), story("noah"), story("luna"), story("jules")] }],
                        },
                    ],
                },
                {
                    type: "ScrollView",
                    properties: { axis: "vertical", showsIndicators: false },
                    modifiers: [full],
                    children: [{ type: "VStack", properties: { alignment: "leading", spacing: 18 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "horizontal" } }, { type: "Padding", properties: { amount: 8, location: "vertical" } }], children: [postCard("mia.design"), postCard("noah.build")] }],
                },
            ],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "music_discovery_v1") {
        const chip = (label: string, active = false): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 0, alignment: "center" },
            modifiers: [
                { type: "Padding", properties: { amount: 10, location: "horizontal" } },
                { type: "Padding", properties: { amount: 8, location: "vertical" } },
                { type: "Background Color", properties: { color: active ? `${theme.accentColor.split(":")[0]}:0.24` : surfaces.rowFill } },
                { type: "Corner Radius", properties: { radius: 14 } },
            ],
            children: [mkText(label, "caption", active ? "semibold" : "regular", active ? "white:1.0" : surfaces.secondaryText)],
        });

        const hero: AnyComponent = {
            type: "ZStack",
            properties: { alignment: "topLeading" },
            modifiers: [fullW, { type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 224 } }, { type: "Corner Radius", properties: { radius: 18 } }],
            children: [
                {
                    type: "RoundedRectangle",
                    properties: { cornerRadius: 18 },
                    modifiers: [
                        { type: "Frame", properties: { widthType: "Full", heightType: "Full" } },
                        { type: "Fill", properties: { color: surfaces.cardFill } },
                    ],
                },
                {
                    type: "Linear Gradient",
                    properties: { colors: ["black:0.00", "black:0.75"], startPoint: "top", endPoint: "bottom" },
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }, { type: "Corner Radius", properties: { radius: 18 } }],
                },
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 6 },
                    modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }],
                    children: [
                        mkText("EDITORIAL PICK", "caption2", "semibold", surfaces.secondaryText),
                        mkText("Midnight Signal", "title2", "bold"),
                        mkText("A cinematic blend of alt-pop and deep house", "caption", "regular", "white:0.82"),
                        {
                            type: "HStack",
                            properties: { spacing: 10, alignment: "center" },
                            modifiers: [fullW],
                            children: [
                                { type: "Button", properties: { title: "Play Mix", buttonStyle: "plain" }, modifiers: [{ type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 10 } }] },
                                mkSym("waveform", "white:0.9", "caption"),
                                mkText("47 min", "caption", "regular", "white:0.86"),
                            ],
                        },
                    ],
                },
            ],
        };

        const trackRow = (title: string, artist: string): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 10, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [
                { type: "Text", properties: { text: "0:30" }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 38, heightType: "Default" } }, { type: "Foreground Color", properties: { color: surfaces.secondaryText } }, { type: "Font", properties: { fontSize: "caption", fontWeight: "regular" } }] },
                { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [mkText(title, "body", "semibold"), mkText(artist, "caption", "regular", surfaces.secondaryText)] },
                mkSym("play.fill", surfaces.iconTint, "caption"),
                mkSym("ellipsis", surfaces.iconTint, "caption"),
            ],
        });

        const radios = ["Neo Soul", "Alt Pop", "Lo-Fi", "House", "Jazz"].map((name) => ({
            type: "VStack",
            properties: { alignment: "center", spacing: 6 },
            modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 86, heightType: "Default" } }],
            children: [
                {
                    type: "Circle",
                    modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 66, heightType: "Custom", height: 66 } }, { type: "Fill", properties: { color: surfaces.rowFill } }],
                },
                mkText(name, "caption", "regular", surfaces.secondaryText),
            ],
        })) as AnyComponent[];

        const root: AnyComponent = {
            type: "ZStack",
            properties: { alignment: "topLeading" },
            modifiers: [full],
            children: [
                {
                    type: "ScrollView",
                    properties: { axis: "vertical", showsIndicators: false },
                    modifiers: [full],
                    children: [{
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 18 },
                        modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
                        children: [
                            { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] },
                            mkText("For You", "title2", "bold"),
                            hero,
                            {
                                type: "ScrollView",
                                properties: { axis: "horizontal", showsIndicators: false },
                                modifiers: [fullW],
                                children: [{ type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [chip("All", true), chip("New Releases"), chip("Mood"), chip("Artist Radios"), chip("Podcasts")] }],
                            },
                            mkText("Now Trending", "headline", "bold"),
                            {
                                type: "VStack",
                                properties: { alignment: "leading", spacing: 0 },
                                modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }],
                                children: [trackRow("Afterlight", "Vera Bloom"), { type: "Divider" }, trackRow("Night Transit", "Marlow"), { type: "Divider" }, trackRow("Soft Static", "Nova Rue")],
                            },
                            mkText("Artist Radios", "headline", "bold"),
                            {
                                type: "ScrollView",
                                properties: { axis: "horizontal", showsIndicators: false },
                                modifiers: [fullW],
                                children: [{ type: "HStack", properties: { spacing: 12, alignment: "top" }, children: radios }],
                            },
                            { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 86 } }] },
                        ],
                    }],
                },
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 0 },
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }],
                    children: [
                        { type: "Spacer" },
                        {
                            type: "HStack",
                            properties: { spacing: 10, alignment: "center" },
                            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.08" } }, { type: "Corner Radius", properties: { radius: 16 } }, { type: "Padding", properties: { amount: 12, location: "horizontal" } }, { type: "Padding", properties: { amount: 12, location: "bottom" } }],
                            children: [
                                { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 42, heightType: "Custom", height: 42 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] },
                                { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [mkText("Midnight Signal", "subheadline", "semibold"), mkText("Now Playing", "caption", "regular", surfaces.secondaryText)] },
                                mkSym("backward.fill", surfaces.iconTint, "caption"),
                                mkSym("play.fill", surfaces.primaryText, "body"),
                                mkSym("forward.fill", surfaces.iconTint, "caption"),
                            ],
                        },
                    ],
                },
            ],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "creator_dashboard_v1") {
        const fullDark = { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" as const };
        const performanceRow = (title: string, views: string, delta: string): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 10, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [
                { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 42, heightType: "Custom", height: 42 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] },
                { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [fullW], children: [mkText(title, "subheadline", "semibold"), mkText(`${views} views`, "caption", "regular", surfaces.secondaryText)] },
                mkText(delta, "caption", "semibold", "green:1.0"),
            ],
        });
        const root: AnyComponent = {
            type: "ScrollView",
            properties: { axis: "vertical", showsIndicators: false },
            modifiers: [full],
            children: [{
                type: "VStack",
                properties: { alignment: "leading", spacing: 16 },
                modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
                children: [
                    { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] },
                    mkText("Creator Hub", "title2", "bold"),
                    {
                        type: "HStack",
                        properties: { spacing: 12, alignment: "top" },
                        modifiers: [fullW],
                        children: [
                            { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 16 } }], children: [mkText("Total Reach", "caption", "regular", surfaces.secondaryText), mkText("1.2M", "title3", "bold"), mkText("+8.4%", "caption", "semibold", "green:1.0")] },
                            { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 16 } }], children: [mkText("Engagement", "caption", "regular", surfaces.secondaryText), mkText("7.9%", "title3", "bold"), mkText("+0.9%", "caption", "semibold", "green:1.0")] },
                        ],
                    },
                    mkText("Top Content", "headline", "bold"),
                    { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [performanceRow("Morning Routine Reel", "242K", "+12%"), { type: "Divider" }, performanceRow("Desk Setup Short", "198K", "+7%"), { type: "Divider" }, performanceRow("Q&A Clip", "133K", "+5%")] },
                    mkText("Quick Actions", "headline", "bold"),
                    { type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW], children: [{ type: "Button", properties: { title: "New Post", buttonStyle: "plain" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 12 } }] }, { type: "Button", properties: { title: "Schedule", buttonStyle: "plain" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }] }] },
                ],
            }],
        };
        return { components: postProcessComponents([root]), canvas_settings: fullDark };
    }

    if (contract === "ecommerce_home_v1") {
        const product = (name: string, price: string): AnyComponent => ({
            type: "VStack",
            properties: { alignment: "leading", spacing: 6 },
            modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }],
            children: [
                { type: "RoundedRectangle", properties: { cornerRadius: 10 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 118 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] },
                mkText(name, "subheadline", "semibold"),
                mkText(price, "subheadline", "bold", theme.accentColor),
            ],
        });
        const root: AnyComponent = {
            type: "ScrollView",
            properties: { axis: "vertical", showsIndicators: false },
            modifiers: [full],
            children: [{
                type: "VStack",
                properties: { alignment: "leading", spacing: 14 },
                modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
                children: [
                    { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] },
                    mkText("Shop", "title2", "bold"),
                    { type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkSym("magnifyingglass", surfaces.iconTint), mkText("Search products", "body", "regular", surfaces.secondaryText), { type: "Spacer" }, mkSym("slider.horizontal.3", surfaces.iconTint)] },
                    { type: "RoundedRectangle", properties: { cornerRadius: 16 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 154 } }, { type: "Fill", properties: { color: surfaces.cardFill } }] },
                    { type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false }, modifiers: [fullW], children: [{ type: "HStack", properties: { spacing: 8, alignment: "center" }, children: ["All", "Shoes", "Jackets", "Accessories", "New"].map((c, i) => ({ type: "HStack", properties: { spacing: 0, alignment: "center" }, modifiers: [{ type: "Padding", properties: { amount: 10, location: "horizontal" } }, { type: "Padding", properties: { amount: 8, location: "vertical" } }, { type: "Background Color", properties: { color: i === 0 ? `${theme.accentColor.split(":")[0]}:0.22` : surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkText(c, "caption", i === 0 ? "semibold" : "regular")] })) as AnyComponent[] }] },
                    mkText("Trending", "headline", "bold"),
                    { type: "HStack", properties: { spacing: 10, alignment: "top" }, modifiers: [fullW], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 10 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [product("Runner Pro", "$149"), product("City Pack", "$79")] }, { type: "VStack", properties: { alignment: "leading", spacing: 10 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [product("Trail Jacket", "$129"), product("Daily Tee", "$39")] }] },
                ],
            }],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "travel_planner_v1") {
        const itineraryRow = (time: string, title: string, meta: string): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 10, alignment: "top" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [{ type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 64, heightType: "Default" } }], children: [mkText(time, "caption", "semibold", theme.accentColor)] }, { type: "VStack", properties: { alignment: "leading", spacing: 2 }, modifiers: [fullW], children: [mkText(title, "subheadline", "semibold"), mkText(meta, "caption", "regular", surfaces.secondaryText)] }],
        });
        const root: AnyComponent = {
            type: "ScrollView",
            properties: { axis: "vertical", showsIndicators: false },
            modifiers: [full],
            children: [{
                type: "VStack",
                properties: { alignment: "leading", spacing: 14 },
                modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
                children: [
                    { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] },
                    mkText("Tokyo Trip", "title2", "bold"),
                    { type: "RoundedRectangle", properties: { cornerRadius: 16 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 160 } }, { type: "Fill", properties: { color: surfaces.cardFill } }] },
                    mkText("Today’s Itinerary", "headline", "bold"),
                    { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [itineraryRow("08:30", "Shibuya Breakfast", "2 km away"), { type: "Divider" }, itineraryRow("11:00", "TeamLab Planets", "Booked • 2 tickets"), { type: "Divider" }, itineraryRow("18:45", "Skytree Sunset", "Weather clear")] },
                    mkText("Bookings", "headline", "bold"),
                    { type: "HStack", properties: { spacing: 10, alignment: "top" }, modifiers: [fullW], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Flight", "caption", "regular", surfaces.secondaryText), mkText("JFK → HND", "subheadline", "semibold"), mkText("May 16, 9:20 AM", "caption", "regular", surfaces.secondaryText)] }, { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Hotel", "caption", "regular", surfaces.secondaryText), mkText("Shinjuku Stay", "subheadline", "semibold"), mkText("4 nights", "caption", "regular", surfaces.secondaryText)] }] },
                ],
            }],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "finance_portfolio_v1") {
        const watchRow = (sym: string, name: string, price: string, delta: string): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 10, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [{ type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 64, heightType: "Default" } }], children: [mkText(sym, "subheadline", "bold"), mkText(name, "caption", "regular", surfaces.secondaryText)] }, { type: "Spacer" }, mkText(price, "subheadline", "semibold"), mkText(delta, "caption", "semibold", delta.startsWith("-") ? "red:1.0" : "green:1.0")],
        });
        const root: AnyComponent = {
            type: "ScrollView",
            properties: { axis: "vertical", showsIndicators: false },
            modifiers: [full],
            children: [{
                type: "VStack",
                properties: { alignment: "leading", spacing: 14 },
                modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
                children: [
                    { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] },
                    mkText("Portfolio", "title2", "bold"),
                    { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 16 } }], children: [mkText("Total Value", "caption", "regular", surfaces.secondaryText), mkText("$128,430.92", "title2", "bold"), mkText("+$2,431 (1.9%) today", "caption", "semibold", "green:1.0")] },
                    mkText("Allocation", "headline", "bold"),
                    { type: "VStack", properties: { alignment: "leading", spacing: 8 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [{ type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW], children: [{ type: "RoundedRectangle", properties: { cornerRadius: 5 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 126, heightType: "Custom", height: 10 } }, { type: "Fill", properties: { color: theme.accentColor } }] }, { type: "RoundedRectangle", properties: { cornerRadius: 5 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 84, heightType: "Custom", height: 10 } }, { type: "Fill", properties: { color: "blue:0.80" } }] }, { type: "RoundedRectangle", properties: { cornerRadius: 5 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 62, heightType: "Custom", height: 10 } }, { type: "Fill", properties: { color: "orange:0.85" } }] }] }, mkText("Stocks 46% • ETFs 31% • Cash 23%", "caption", "regular", surfaces.secondaryText)] },
                    mkText("Watchlist", "headline", "bold"),
                    { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [watchRow("AAPL", "Apple", "$212.90", "+1.3%"), { type: "Divider" }, watchRow("NVDA", "NVIDIA", "$997.11", "+2.8%"), { type: "Divider" }, watchRow("TSLA", "Tesla", "$172.64", "-0.9%")] },
                ],
            }],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "learning_path_v1") {
        const lessonRow = (title: string, dur: string, done: boolean): AnyComponent => ({
            type: "HStack",
            properties: { spacing: 10, alignment: "center" },
            modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 22, heightType: "Custom", height: 22 } }, { type: "Fill", properties: { color: done ? "green:1.0" : surfaces.rowFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [fullW], children: [mkText(title, "subheadline", done ? "regular" : "semibold"), mkText(dur, "caption", "regular", surfaces.secondaryText)] }, done ? mkSym("checkmark", "green:1.0", "caption") : mkSym("play.fill", surfaces.iconTint, "caption")],
        });
        const root: AnyComponent = {
            type: "ZStack",
            properties: { alignment: "topLeading" },
            modifiers: [full],
            children: [
                {
                    type: "ScrollView",
                    properties: { axis: "vertical", showsIndicators: false },
                    modifiers: [full],
                    children: [{
                        type: "VStack",
                        properties: { alignment: "leading", spacing: 14 },
                        modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }],
                        children: [
                            { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] },
                            mkText("Learning Path", "title2", "bold"),
                            { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 16 } }], children: [mkText("SwiftUI Foundations", "headline", "bold"), mkText("63% complete", "caption", "regular", surfaces.secondaryText), { type: "Progress View", properties: { value: 0.63, color: theme.accentColor }, modifiers: [fullW] }] },
                            mkText("Next Lessons", "headline", "bold"),
                            { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [lessonRow("Stacks and Layout", "12 min", true), { type: "Divider" }, lessonRow("State and Binding", "18 min", false), { type: "Divider" }, lessonRow("Navigation Patterns", "16 min", false)] },
                            { type: "HStack", properties: { spacing: 10, alignment: "top" }, modifiers: [fullW], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Streak", "caption", "regular", surfaces.secondaryText), mkText("9 days", "title3", "bold")] }, { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Rank", "caption", "regular", surfaces.secondaryText), mkText("#14", "title3", "bold")] }] },
                            { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 84 } }] },
                        ],
                    }],
                },
                {
                    type: "VStack",
                    properties: { alignment: "leading", spacing: 0 },
                    modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }],
                    children: [{ type: "Spacer" }, { type: "Button", properties: { title: "Continue Lesson", buttonStyle: "plain" }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 14 } }, { type: "Padding", properties: { amount: 12, location: "horizontal" } }, { type: "Padding", properties: { amount: 12, location: "bottom" } }] }],
                },
            ],
        };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "chat_inbox_v1") {
        const row = (name: string, msg: string, time: string): AnyComponent => ({
            type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
            children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 44, heightType: "Custom", height: 44 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [fullW], children: [mkText(name, "subheadline", "semibold"), mkText(msg, "caption", "regular", surfaces.secondaryText)] }, mkText(time, "caption2", "regular", surfaces.secondaryText)],
        });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Messages", "title2", "bold"), { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [row("Alex", "Can you review this?", "2m"), { type: "Divider" }, row("Mia", "Pushed new branch", "9m"), { type: "Divider" }, row("Noah", "Ship it today?", "1h")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "chat_thread_v1") {
        const bubble = (text: string, sent: boolean): AnyComponent => ({ type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW], children: [...(!sent ? [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 28, heightType: "Custom", height: 28 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] } as AnyComponent] : []), { type: "VStack", properties: { alignment: sent ? "trailing" : "leading", spacing: 0 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [{ type: "Text", properties: { text }, modifiers: [{ type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: sent ? theme.accentColor : surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }] }] }, ...(sent ? [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 28, heightType: "Custom", height: 28 } }, { type: "Fill", properties: { color: "clear:0.0" } }] } as AnyComponent] : [])] });
        const root: AnyComponent = { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [full], children: [{ type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 10 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Alex", "headline", "bold"), bubble("Can you send the latest mock?", false), bubble("Yep, sending now.", true), bubble("Got it, thanks!", false), { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 76 } }] }] }] }, { type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }], children: [mkSym("plus", surfaces.iconTint), mkText("Message", "body", "regular", surfaces.secondaryText), { type: "Spacer" }, mkSym("paperplane.fill", theme.accentColor)] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "maps_explore_v1") {
        const root: AnyComponent = { type: "ZStack", properties: { alignment: "topLeading" }, modifiers: [full], children: [{ type: "RoundedRectangle", properties: { cornerRadius: 0 }, modifiers: [full, { type: "Fill", properties: { color: surfaces.cardFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 10 }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 40 } }] }, { type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkSym("magnifyingglass", surfaces.iconTint), mkText("Search places", "body", "regular", surfaces.secondaryText)] }, { type: "HStack", properties: { spacing: 8, alignment: "center" }, children: [{ type: "Button", properties: { title: "Nearby", buttonStyle: "plain" }, modifiers: [{ type: "Padding", properties: { amount: 8, location: "all" } }, { type: "Background Color", properties: { color: `${theme.accentColor.split(":")[0]}:0.24` } }, { type: "Corner Radius", properties: { radius: 12 } }] }, { type: "Button", properties: { title: "Food", buttonStyle: "plain" }, modifiers: [{ type: "Padding", properties: { amount: 8, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }] }] }, { type: "Spacer" }, { type: "VStack", properties: { alignment: "leading", spacing: 6 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "gray:0.08" } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkText("Blue Bottle Coffee", "subheadline", "semibold"), mkText("4 min • 0.3 mi", "caption", "regular", surfaces.secondaryText), mkText("Open route", "caption", "semibold", theme.accentColor)] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "video_feed_v1") {
        const card = (title: string): AnyComponent => ({ type: "ZStack", properties: { alignment: "bottomLeading" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 300 } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [{ type: "RoundedRectangle", properties: { cornerRadius: 14 }, modifiers: [fullW, { type: "Frame", properties: { widthType: "Full", heightType: "Full" } }, { type: "Fill", properties: { color: surfaces.cardFill } }] }, { type: "Linear Gradient", properties: { colors: ["black:0.00", "black:0.70"], startPoint: "top", endPoint: "bottom" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }, { type: "Corner Radius", properties: { radius: 14 } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 4 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }], children: [mkText(title, "headline", "bold"), mkText("@creator", "caption", "regular", "white:0.82")] }] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 42 } }] }, card("Street food in Tokyo"), card("3 editing tricks in 20s"), card("Minimal desk setup reveal")] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "checkout_flow_v1") {
        const root: AnyComponent = { type: "ZStack", properties: { alignment: "topLeading" }, modifiers: [full], children: [{ type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 42 } }] }, mkText("Checkout", "title2", "bold"), { type: "VStack", properties: { alignment: "leading", spacing: 6 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkText("Items", "caption", "regular", surfaces.secondaryText), mkText("Runner Pro + City Pack", "subheadline", "semibold"), mkText("$228.00", "headline", "bold")] }, { type: "VStack", properties: { alignment: "leading", spacing: 6 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkText("Shipping", "caption", "regular", surfaces.secondaryText), mkText("Home • 2-day delivery", "subheadline", "regular")] }, { type: "VStack", properties: { alignment: "leading", spacing: 6 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkText("Payment", "caption", "regular", surfaces.secondaryText), mkText("•••• 4242", "subheadline", "regular")] }, { type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 90 } }] }] }] }, { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Full" } }], children: [{ type: "Spacer" }, { type: "Button", properties: { title: "Place Order • $228.00", buttonStyle: "plain" }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 14 } }, { type: "Padding", properties: { amount: 12, location: "horizontal" } }, { type: "Padding", properties: { amount: 12, location: "bottom" } }] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "settings_account_v1") {
        const settingRow = (name: string, on = true): AnyComponent => ({ type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }], children: [mkText(name, "body", "regular"), { type: "Spacer" }, { type: "Switch", properties: { isOn: on } }] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Account Settings", "title2", "bold"), { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [settingRow("Push Notifications"), { type: "Divider" }, settingRow("Email Updates", false), { type: "Divider" }, settingRow("Private Account", true)] }, { type: "Button", properties: { title: "Sign Out", buttonStyle: "plain" }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: "red:0.20" } }, { type: "Corner Radius", properties: { radius: 12 } }] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "auth_2fa_v1") {
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 20, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 56 } }] }, mkText("Verify It’s You", "largeTitle", "bold"), mkText("Enter the 6-digit code we sent.", "subheadline", "regular", surfaces.secondaryText), { type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW], children: Array.from({ length: 6 }).map(() => ({ type: "RoundedRectangle", properties: { cornerRadius: 10 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 44, heightType: "Custom", height: 52 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] } as AnyComponent)) }, { type: "Button", properties: { title: "Verify", buttonStyle: "plain" }, modifiers: [fullW, { type: "Padding", properties: { amount: 13, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 12 } }] }, mkText("Resend code in 0:24", "caption", "regular", surfaces.secondaryText)] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "state_pack_v1") {
        const block = (title: string, subtitle: string, icon: string): AnyComponent => ({ type: "VStack", properties: { alignment: "center", spacing: 8 }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 14 } }], children: [mkSym(icon, theme.accentColor, "title3"), mkText(title, "headline", "semibold"), mkText(subtitle, "caption", "regular", surfaces.secondaryText)] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("States", "title2", "bold"), block("Loading", "Fetching latest data", "hourglass"), block("Empty", "No results found", "tray"), block("Error", "Something went wrong", "exclamationmark.triangle")] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "restaurant_delivery_v1") {
        const card = (name: string, eta: string): AnyComponent => ({ type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [{ type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 54, heightType: "Custom", height: 54 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [fullW], children: [mkText(name, "subheadline", "semibold"), mkText(eta, "caption", "regular", surfaces.secondaryText)] }, mkText("4.7", "caption", "semibold", theme.accentColor)] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 42 } }] }, mkText("Delivery", "title2", "bold"), { type: "HStack", properties: { spacing: 8, alignment: "center" }, children: ["All", "Burgers", "Sushi", "Pizza"].map((c, i) => ({ type: "HStack", properties: { spacing: 0, alignment: "center" }, modifiers: [{ type: "Padding", properties: { amount: 8, location: "all" } }, { type: "Background Color", properties: { color: i === 0 ? `${theme.accentColor.split(":")[0]}:0.24` : surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText(c, "caption", i === 0 ? "semibold" : "regular")] })) as AnyComponent[] }, card("Kumo Sushi", "25-35 min"), card("Firehouse Pizza", "15-25 min"), card("Nori Ramen", "30-40 min")] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "calendar_week_v1") {
        const dayCol = (d: string, active = false): AnyComponent => ({ type: "VStack", properties: { alignment: "center", spacing: 6 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [mkText(d, "caption", "regular", surfaces.secondaryText), { type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 26, heightType: "Custom", height: 26 } }, { type: "Fill", properties: { color: active ? theme.accentColor : surfaces.rowFill } }] }] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 42 } }] }, mkText("This Week", "title2", "bold"), { type: "HStack", properties: { spacing: 8, alignment: "top" }, modifiers: [fullW], children: [dayCol("Mon"), dayCol("Tue"), dayCol("Wed", true), dayCol("Thu"), dayCol("Fri"), dayCol("Sat"), dayCol("Sun")] }, { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("09:00 • Design Review", "subheadline", "semibold"), { type: "Divider" }, mkText("13:30 • Team Sync", "subheadline", "regular"), { type: "Divider" }, mkText("16:00 • Planning", "subheadline", "regular")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "kanban_board_v1") {
        const col = (title: string): AnyComponent => ({ type: "VStack", properties: { alignment: "leading", spacing: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 220, heightType: "Default" } }, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText(title, "subheadline", "bold"), { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 64 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }, { type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 64 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "horizontal", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 42 } }] }, mkText("Project Board", "title2", "bold"), { type: "HStack", properties: { spacing: 10, alignment: "top" }, children: [col("Backlog"), col("In Progress"), col("Done")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "onboarding_flow_v1") {
        const root: AnyComponent = { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [full], children: [{ type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 20, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 56 } }] }, { type: "RoundedRectangle", properties: { cornerRadius: 18 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 220 } }, { type: "Fill", properties: { color: surfaces.cardFill } }] }, mkText("Welcome to Flow", "title2", "bold"), mkText("Organize your day with smart priorities.", "body", "regular", surfaces.secondaryText)] }] }, { type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }], children: [{ type: "Button", properties: { buttonStyle: "plain" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Skip", "subheadline", "semibold")] }, { type: "Button", properties: { buttonStyle: "plain" }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Continue", "subheadline", "semibold")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "notification_center_v1") {
        const row = (t: string, s: string): AnyComponent => ({ type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }], children: [mkSym("bell.badge", theme.accentColor), { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [fullW], children: [mkText(t, "subheadline", "semibold"), mkText(s, "caption", "regular", surfaces.secondaryText)] }] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Notifications", "title2", "bold"), { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [row("Build finished", "2 min ago"), { type: "Divider" }, row("New comment on task", "11 min ago"), { type: "Divider" }, row("Release approved", "1 hr ago")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "profile_social_v1") {
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, { type: "HStack", properties: { spacing: 12, alignment: "center" }, children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 76, heightType: "Custom", height: 76 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 2 }, modifiers: [fullW], children: [mkText("@jordan", "headline", "bold"), mkText("UI Designer", "caption", "regular", surfaces.secondaryText)] }] }, { type: "HStack", properties: { spacing: 8, alignment: "top" }, modifiers: [fullW], children: [{ type: "VStack", properties: { alignment: "center", spacing: 2 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 8, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 10 } }], children: [mkText("214", "subheadline", "bold"), mkText("Posts", "caption2", "regular", surfaces.secondaryText)] }, { type: "VStack", properties: { alignment: "center", spacing: 2 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }, { type: "Padding", properties: { amount: 8, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 10 } }], children: [mkText("18k", "subheadline", "bold"), mkText("Followers", "caption2", "regular", surfaces.secondaryText)] }] }, { type: "RoundedRectangle", properties: { cornerRadius: 12 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 180 } }, { type: "Fill", properties: { color: surfaces.cardFill } }] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "health_activity_v1") {
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Activity", "title2", "bold"), { type: "Gauge", properties: { gaugeType: "circular", value: 0.72, color: theme.accentColor }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 140, heightType: "Custom", height: 140 } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Steps: 8,424", "subheadline", "semibold"), { type: "Divider" }, mkText("Workout: 43 min", "subheadline", "regular"), { type: "Divider" }, mkText("Calories: 621", "subheadline", "regular")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "news_reader_v1") {
        const article = (t: string, s: string): AnyComponent => ({ type: "HStack", properties: { spacing: 10, alignment: "top" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }], children: [{ type: "RoundedRectangle", properties: { cornerRadius: 8 }, modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 84, heightType: "Custom", height: 64 } }, { type: "Fill", properties: { color: surfaces.rowFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 2 }, modifiers: [fullW], children: [mkText(t, "subheadline", "semibold"), mkText(s, "caption", "regular", surfaces.secondaryText)] }] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Top Stories", "title2", "bold"), article("AI startup raises $100M", "Tech • 2h ago"), { type: "Divider" }, article("Markets close higher", "Business • 4h ago"), { type: "Divider" }, article("City unveils new transit plan", "Local • 5h ago")] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "booking_hotel_v1") {
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Book Stay", "title2", "bold"), { type: "RoundedRectangle", properties: { cornerRadius: 14 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Custom", height: 170 } }, { type: "Fill", properties: { color: surfaces.cardFill } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 6 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("2 Guests • 3 Nights", "subheadline", "regular"), mkText("$489 total", "headline", "bold")] }, { type: "Button", properties: { buttonStyle: "plain" }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Reserve Now", "subheadline", "semibold")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "customer_support_v1") {
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Support", "title2", "bold"), { type: "Text Field", properties: { placeholder: "Search help articles", text: "" }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.rowFill } }, { type: "Corner Radius", properties: { radius: 12 } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Order Issues", "subheadline", "semibold"), { type: "Divider" }, mkText("Billing and Refunds", "subheadline", "regular"), { type: "Divider" }, mkText("Account Access", "subheadline", "regular")] }, { type: "Button", properties: { buttonStyle: "plain" }, modifiers: [fullW, { type: "Padding", properties: { amount: 12, location: "all" } }, { type: "Background Color", properties: { color: theme.accentColor } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [mkText("Start Live Chat", "subheadline", "semibold")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "admin_table_v1") {
        const row = (a: string, b: string, c: string): AnyComponent => ({ type: "HStack", properties: { spacing: 8, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 8, location: "vertical" } }], children: [mkText(a, "caption", "regular"), { type: "Spacer" }, mkText(b, "caption", "regular"), { type: "Spacer" }, mkText(c, "caption", "regular")] });
        const root: AnyComponent = { type: "ScrollView", properties: { axis: "vertical", showsIndicators: false }, modifiers: [full], children: [{ type: "VStack", properties: { alignment: "leading", spacing: 12 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: [{ type: "Spacer", modifiers: [{ type: "Frame", properties: { widthType: "Default", heightType: "Custom", height: 44 } }] }, mkText("Admin", "title2", "bold"), { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Background Color", properties: { color: surfaces.cardFill } }, { type: "Corner Radius", properties: { radius: 12 } }], children: [row("Name", "Role", "Status"), { type: "Divider" }, row("Alex", "Owner", "Active"), { type: "Divider" }, row("Mia", "Editor", "Pending"), { type: "Divider" }, row("Noah", "Viewer", "Active")] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    if (contract === "camera_capture_v1") {
        const root: AnyComponent = { type: "ZStack", properties: { alignment: "topLeading" }, modifiers: [full], children: [{ type: "Rectangle", modifiers: [full, { type: "Fill", properties: { color: "black:1.0" } }] }, { type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [full], children: [{ type: "HStack", properties: { spacing: 10, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 14, location: "all" } }], children: [mkSym("xmark", "white:1.0"), { type: "Spacer" }, mkSym("bolt", "white:1.0"), mkSym("gearshape", "white:1.0")] }, { type: "Spacer" }, { type: "HStack", properties: { spacing: 20, alignment: "center" }, modifiers: [fullW, { type: "Padding", properties: { amount: 18, location: "all" } }], children: [{ type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 40, heightType: "Custom", height: 40 } }, { type: "Stroke", properties: { color: "white:1.0", lineWidth: 2 } }] }, { type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 74, heightType: "Custom", height: 74 } }, { type: "Stroke", properties: { color: "white:1.0", lineWidth: 5 } }] }, { type: "Circle", modifiers: [{ type: "Frame", properties: { widthType: "Custom", width: 40, heightType: "Custom", height: 40 } }, { type: "Fill", properties: { color: "white:0.18" } }] }] }] }] };
        return { components: postProcessComponents([root]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
    }

    const rows = Array.from({ length: 8 }).map((_, i) => ({
        type: "VStack",
        properties: { alignment: "leading", spacing: 0 },
        modifiers: [fullW],
        children: [
            {
                type: "HStack",
                properties: { spacing: 12, alignment: "center" },
                modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "vertical" } }],
                children: [mkSym("magnifyingglass", surfaces.iconTint), { type: "VStack", properties: { alignment: "leading", spacing: 1 }, modifiers: [{ type: "Frame", properties: { widthType: "Full", heightType: "Default" } }], children: [mkText(`Result ${i + 1}`, "title3", "regular"), mkText(i % 2 ? "Secondary metadata • Relevant match" : "Matched in title • Updated today", "body", "regular", surfaces.secondaryText)] }],
            },
            { type: "Divider" },
        ],
    })) as AnyComponent[];
    const searchContractRoot: AnyComponent = {
        type: "VStack",
        properties: { alignment: "leading", spacing: 0 },
        modifiers: [full],
        children: [
            {
                type: "HStack",
                properties: { spacing: 10, stackType: "horizontal" },
                modifiers: [fullW, { type: "Padding", properties: { amount: 10, location: "all" } }, { type: "Padding", properties: { amount: 8, location: "top" } }, { type: "Background Color", properties: { color: "gray:0.06" } }],
                children: [mkSym("magnifyingglass", surfaces.iconTint, "title3"), mkText("Search", "title3", "regular", surfaces.secondaryText), { type: "Spacer" }, mkSym("mic", surfaces.iconTint, "title3")],
            },
            {
                type: "ScrollView",
                properties: { axis: "vertical", showsIndicators: false },
                modifiers: [full],
                children: [{ type: "VStack", properties: { alignment: "leading", spacing: 0 }, modifiers: [fullW, { type: "Padding", properties: { amount: 16, location: "all" } }], children: rows }],
            },
        ],
    };
    return { components: postProcessComponents([searchContractRoot]), canvas_settings: { statusBarVisible: true, statusBarTopSafeArea: true, canvasColorScheme: "dark" } };
}
