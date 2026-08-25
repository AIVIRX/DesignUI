import type { Density, ScreenTokens, ThemeSurfaces, ThemeTokens } from "./types.ts";
import { callOpenAI, STANDARD_TOKENS_MODEL, THEME_EXTRACT_MAX_TOKENS, THEME_MODEL } from "./openai.ts";
import { THEME_RESPONSE_FORMAT } from "./schema.ts";
import { isJsonParseError, isObject, normalizeDensity, normalizeSurfaceStyle, parseJsonSafe } from "./utils.ts";

// ─── Theme extraction ────────────────────────────────────────────────────────

export const THEME_EXTRACTOR_SYSTEM_PROMPT = `You are a senior mobile UI/UX designer and brand strategist.
Given a product prompt, extract a complete design theme for a mobile app screen.
Return JSON only. No markdown, no explanation.

Shape:
{
  "accentColor": string,
  "secondaryColor": string,
  "surfaceStyle": string,
  "density": string,
  "fontDesign": string,
  "cornerRadiusScale": string,
  "usesGradient": boolean,
  "appName": string,
  "voiceTone": string,
  "mascotSymbol": string,
  "itemNoun": string,
  "ctaVerb": string,
  "primaryMetricLabel": string,
  "primaryMetricUnit": string,
  "sampleItems": string[],
  "sampleMetrics": string[],
  "sampleRailItems": string[],
  "ctaText": string,
  "domainTags": string[],
  "sharedFacts": {
    "greeting": string,
    "userName": string,
    "primaryMetricValue": string,
    "secondaryMetricValue": string,
    "streakValue": string,
    "progressPercent": number,
    "todayDate": string
  }
}

accentColor / secondaryColor: use "colorname:1.0" format. Prefer restrained system-like colors such as gray:1.0, blue:1.0, or teal:1.0 unless the user explicitly asks for something louder.
surfaceStyle: "minimal"|"editorial"|"utility"|"immersive"|"calm"
density: "compact"|"regular"|"airy"
fontDesign: "default"|"serif"|"rounded"|"monospaced"
cornerRadiusScale: "sharp"|"medium"|"pill"
voiceTone: "playful"|"calm"|"professional"|"urgent"

Color rules:
- Duolingo/gamified learning → green:1.0 primary, yellow:1.0 secondary
- Spotify/music → green:1.0, immersive surface
- Netflix/video → red:1.0, immersive surface
- Meditation/sleep/wellness → purple:1.0 or teal:1.0, calm, airy
- Nike/fitness/running → orange:1.0, urgent, sharp
- Finance/banking → blue:1.0, professional, sharp/medium
- Food/recipes → orange:1.0, editorial
- Health tracking → teal:1.0 or green:1.0
- Social → pink:1.0 or blue:1.0
- Productivity/tasks → blue:1.0, utility, compact
- Travel → teal:1.0, editorial
- Gaming → purple:1.0 or red:1.0, immersive
- Shopping → orange:1.0 or pink:1.0
- News → red:1.0, editorial, serif
- Weather → blue:1.0 or teal:1.0, calm
- City guide / local discovery / premium travel → teal:1.0 or blue:1.0, minimal or editorial, airy, refined, never random purple unless explicitly requested

cornerRadiusScale: pill=playful/consumer, medium=balanced/modern, sharp=professional/premium
voiceTone: playful=gamified/social, calm=wellness/journal, professional=finance/productivity, urgent=fitness/timers

mascotSymbol — REAL SF Symbol names only:
- Fitness: figure.run, figure.walk, bolt.fill, flame.fill
- Learning: brain.head.profile, book.fill, graduationcap.fill
- Wellness: leaf.fill, moon.fill, heart.fill
- Finance: dollarsign.circle.fill, chart.line.uptrend.xyaxis
- Gamified: star.fill, trophy.fill, checkmark.seal.fill, flame.fill
- Creative: paintbrush.fill, pencil.and.outline, music.note
- Travel: airplane, map.fill, globe.americas.fill
- Social: person.2.fill, bubble.left.fill, heart.fill
- Weather: cloud.sun.fill, thermometer.medium, wind
- Shopping: cart.fill, bag.fill, creditcard.fill

sampleItems: EXACTLY 4 items. Format "Title:Subtitle:Trailing". Domain-specific, concrete content. NOT generic "Item 1:Description:Open".
sampleMetrics: EXACTLY 4 metrics. Format "Label:Value:Trend". Realistic numbers.
sampleRailItems: EXACTLY 5 rail card titles. Domain-specific.
ctaText: match voiceTone — playful:"Keep the Streak! 🔥" | calm:"Begin Session" | professional:"Review Now" | urgent:"Start Run"
domainTags: lowercase single words, 2-4 of them.

Specificity rules:
- Echo the user's actual nouns, entities, places, moods, and product language when present.
- Do not default to familiar app clichés like "Featured", "Popular", "Saved", "Recent", "Item 1", or generic dashboard wording unless the user explicitly asked for that.
- Do not inject famous brand feature names unless the user explicitly asked for them.
- If the prompt is niche or unusual, make sampleItems and sampleRailItems feel equally niche and unusual.
- If the prompt says premium, luxury, refined, editorial, or calm luxury, prefer restrained palettes and typography. Avoid loud purple/pink accents unless the user explicitly asked for them.
- Default to Apple-like restraint: white, gray, black, and a single controlled accent. Do not wash cards and rows in tinted low-opacity accent fills unless the user explicitly wants a colorful expressive UI.

sharedFacts: these are CONSISTENT VALUES that every section of the screen should reference.
- greeting: personalized "Good morning, Alex" style or "Welcome back"
- userName: a realistic first name
- primaryMetricValue: the main metric NUMBER (e.g. "14 days", "$4,280", "7.4h")
- secondaryMetricValue: a secondary metric
- streakValue: streak/consecutive count
- progressPercent: 0-100, how far along today's goal
- todayDate: human-friendly date like "Mon, Jan 15"

These sharedFacts ensure all sections agree on the same numbers and user identity.

Dark mode: surfaceStyle:"immersive" for media/gaming.

Examples:
- "todo app with duolingo theme" → accentColor:"green:1.0", secondaryColor:"yellow:1.0", cornerRadiusScale:"pill", voiceTone:"playful", appName:"DuoTasks", domainTags:["productivity","gamified"], sharedFacts:{greeting:"Great job, Alex!",userName:"Alex",primaryMetricValue:"14 day streak",secondaryMetricValue:"240 XP today",streakValue:"14 days",progressPercent:72,todayDate:"Mon, Jan 15"}
- "calm meditation app" → accentColor:"purple:1.0", surfaceStyle:"calm", density:"airy", voiceTone:"calm", cornerRadiusScale:"pill", domainTags:["meditation","wellness"], sharedFacts:{greeting:"Welcome back, Maya",userName:"Maya",primaryMetricValue:"47 minutes",secondaryMetricValue:"12 sessions",streakValue:"5 days",progressPercent:60,todayDate:"Tue, Mar 4"}`;

export async function extractThemeTokens(prompt: string): Promise<ThemeTokens> {
    const fallback: ThemeTokens = {
        accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "minimal",
        density: "regular", fontDesign: "default", cornerRadiusScale: "medium", usesGradient: false,
        appName: "MyApp", voiceTone: "professional", mascotSymbol: "", itemNoun: "items",
        ctaVerb: "Start", primaryMetricLabel: "Progress", primaryMetricUnit: "%",
        sampleItems: ["Core flow:Primary path:Ready", "Secondary path:Needs review:Queued", "Live context:Updated now:Active", "Next step:Awaiting choice:Open"],
        sampleMetrics: ["Progress:68%:+12%", "Streak:5 days:+1", "Completed:12:+3", "Score:840:+60"],
        sampleRailItems: ["Overview", "Live", "Compare", "Recent", "Explore"],
        ctaText: "Continue", domainTags: ["productivity"],
        sharedFacts: { greeting: "Welcome back", userName: "Alex", primaryMetricValue: "68%", secondaryMetricValue: "12 completed", streakValue: "5 days", progressPercent: 68, todayDate: "Mon, Jan 15" },
    };
    const domainDefaults = inferDomainDefaults(prompt);
    const explicitAccent = extractExplicitAccentFromPrompt(prompt);
    const baseline: ThemeTokens = mergeThemeWithDefaults(fallback, domainDefaults);

    const response = await callOpenAI({
        model: THEME_MODEL,
        messages: [
            { role: "system", content: THEME_EXTRACTOR_SYSTEM_PROMPT },
            { role: "system", content: `DOMAIN DEFAULTS (starting point, refine for this app):\n${JSON.stringify(domainDefaults)}` },
            { role: "user", content: prompt },
        ],
        temperature: 0.2, maxTokens: THEME_EXTRACT_MAX_TOKENS, responseFormat: THEME_RESPONSE_FORMAT,
    });

    if (!response.ok) return baseline;
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) return baseline;
    const v = parsed.value as Record<string, unknown>;

    const rawFacts = isObject(v.sharedFacts) ? v.sharedFacts as Record<string, unknown> : {};

    const extracted: ThemeTokens = {
        accentColor: typeof v.accentColor === "string" ? v.accentColor : baseline.accentColor,
        secondaryColor: typeof v.secondaryColor === "string" ? v.secondaryColor : baseline.secondaryColor,
        surfaceStyle: normalizeSurfaceStyle(v.surfaceStyle, baseline.surfaceStyle),
        density: normalizeDensity(v.density, baseline.density),
        fontDesign: (["default", "serif", "rounded", "monospaced"] as const).includes(v.fontDesign as never) ? v.fontDesign as string : "default",
        cornerRadiusScale: (v.cornerRadiusScale === "sharp" || v.cornerRadiusScale === "medium" || v.cornerRadiusScale === "pill") ? v.cornerRadiusScale : "medium",
        usesGradient: typeof v.usesGradient === "boolean" ? v.usesGradient : false,
        appName: typeof v.appName === "string" ? v.appName : baseline.appName,
        voiceTone: (v.voiceTone === "playful" || v.voiceTone === "calm" || v.voiceTone === "professional" || v.voiceTone === "urgent") ? v.voiceTone : "professional",
        mascotSymbol: typeof v.mascotSymbol === "string" ? v.mascotSymbol : "",
        itemNoun: typeof v.itemNoun === "string" ? v.itemNoun : "items",
        ctaVerb: typeof v.ctaVerb === "string" ? v.ctaVerb : "Start",
        primaryMetricLabel: typeof v.primaryMetricLabel === "string" ? v.primaryMetricLabel : baseline.primaryMetricLabel,
        primaryMetricUnit: typeof v.primaryMetricUnit === "string" ? v.primaryMetricUnit : baseline.primaryMetricUnit,
        sampleItems: Array.isArray(v.sampleItems) ? (v.sampleItems as unknown[]).filter((x): x is string => typeof x === "string").slice(0, 5) : baseline.sampleItems,
        sampleMetrics: Array.isArray(v.sampleMetrics) ? (v.sampleMetrics as unknown[]).filter((x): x is string => typeof x === "string").slice(0, 4) : baseline.sampleMetrics,
        sampleRailItems: Array.isArray(v.sampleRailItems) ? (v.sampleRailItems as unknown[]).filter((x): x is string => typeof x === "string").slice(0, 6) : baseline.sampleRailItems,
        ctaText: typeof v.ctaText === "string" ? v.ctaText : baseline.ctaText,
        domainTags: Array.isArray(v.domainTags) ? (v.domainTags as unknown[]).filter((x): x is string => typeof x === "string").map((x) => x.toLowerCase()).slice(0, 6) : baseline.domainTags,
        sharedFacts: {
            greeting: typeof rawFacts.greeting === "string" ? rawFacts.greeting : baseline.sharedFacts.greeting,
            userName: typeof rawFacts.userName === "string" ? rawFacts.userName : baseline.sharedFacts.userName,
            primaryMetricValue: typeof rawFacts.primaryMetricValue === "string" ? rawFacts.primaryMetricValue : baseline.sharedFacts.primaryMetricValue,
            secondaryMetricValue: typeof rawFacts.secondaryMetricValue === "string" ? rawFacts.secondaryMetricValue : baseline.sharedFacts.secondaryMetricValue,
            streakValue: typeof rawFacts.streakValue === "string" ? rawFacts.streakValue : baseline.sharedFacts.streakValue,
            progressPercent: typeof rawFacts.progressPercent === "number" ? rawFacts.progressPercent : baseline.sharedFacts.progressPercent,
            todayDate: typeof rawFacts.todayDate === "string" ? rawFacts.todayDate : baseline.sharedFacts.todayDate,
        },
    };
    let merged = mergeThemeWithDefaults(extracted, domainDefaults);
    if (explicitAccent) {
        merged.accentColor = explicitAccent;
        if (!merged.secondaryColor || merged.secondaryColor === domainDefaults.secondaryColor) {
            merged.secondaryColor = explicitAccent;
        }
    }
    merged = applyPromptThemeCorrections(prompt, merged, explicitAccent);
    return merged;
}

export function inferDomainDefaults(prompt: string): Partial<ThemeTokens> {
    const p = prompt.toLowerCase();
    if (/\bcity guide\b|\blocal discovery\b|\bneighborhood\b|\bcurated places\b|\bcity map\b|\bguide app\b/.test(p)) {
        const luxuryLike = /\bpremium\b|\bluxury\b|\brefined\b|\bcalm luxury\b|\beditorial\b/.test(p);
        return {
            accentColor: luxuryLike ? "teal:1.0" : "blue:1.0",
            secondaryColor: "gray:1.0",
            surfaceStyle: luxuryLike ? "minimal" : "editorial",
            density: luxuryLike ? "airy" : "regular",
            voiceTone: "professional",
            fontDesign: luxuryLike ? "serif" : "default",
            cornerRadiusScale: luxuryLike ? "sharp" : "medium",
            domainTags: ["city", "guide", "places", "map"],
            itemNoun: "places",
            ctaText: "Explore Places",
        };
    }
    if (/\bmeditation\b|\bmindful\b|\bcalm\b|\bbreathe\b|\bzen\b/.test(p)) {
        return { accentColor: "teal:1.0", secondaryColor: "gray:1.0", surfaceStyle: "calm", density: "airy", voiceTone: "calm", cornerRadiusScale: "medium", domainTags: ["meditation", "wellness"], itemNoun: "sessions", ctaText: "Begin Session" };
    }
    if (/\bfinance\b|\bbank\b|\binvest\b|\bportfolio\b|\bstock\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "minimal", density: "regular", voiceTone: "professional", cornerRadiusScale: "sharp", domainTags: ["finance", "analytics"], itemNoun: "positions", ctaText: "Review Now" };
    }
    if (/\bmusic\b|\bplaylist\b|\bspotify\b|\bartist\b|\balbum\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "immersive", density: "regular", voiceTone: "professional", cornerRadiusScale: "medium", domainTags: ["music", "media"], itemNoun: "tracks", ctaText: "Play Now" };
    }
    if (/\btravel\b|\bitinerary\b|\btrip\b|\bflight\b|\bhotel\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "minimal", density: "airy", voiceTone: "professional", cornerRadiusScale: "sharp", domainTags: ["travel", "planning"], itemNoun: "stops", ctaText: "View Trip" };
    }
    if (/\buber\b|\blyft\b|\brideshare\b|\bride share\b|\bpickup\b|\bdrop[\s-]*off\b|\bdestination\b|\bdriver\b|\beta\b/.test(p)) {
        return {
            accentColor: "blue:1.0",
            secondaryColor: "gray:1.0",
            surfaceStyle: "minimal",
            density: "regular",
            voiceTone: "professional",
            cornerRadiusScale: "medium",
            domainTags: ["transport", "rideshare", "map"],
            ctaText: "Confirm Ride",
            itemNoun: "rides",
        };
    }
    if (/\bcoffee\b|\bcafe\b|\bcafé\b|\blatte\b|\bespresso\b|\broaster\b|\bbrew\b/.test(p)) {
        return {
            accentColor: "blue:1.0",
            secondaryColor: "gray:1.0",
            surfaceStyle: "minimal",
            density: "regular",
            voiceTone: "calm",
            cornerRadiusScale: "medium",
            domainTags: ["coffee", "cafe", "local"],
            ctaText: "Find a Cafe",
            itemNoun: "cafes",
        };
    }
    if (/\bfitness\b|\bworkout\b|\btraining\b|\brun\b|\bactivity\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "minimal", density: "compact", voiceTone: "professional", cornerRadiusScale: "medium", domainTags: ["fitness", "health"], itemNoun: "workouts", ctaText: "Start Run" };
    }
    if (/\bshopping\b|\bstore\b|\becommerce\b|\bcheckout\b|\bcart\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "minimal", density: "regular", voiceTone: "professional", cornerRadiusScale: "medium", domainTags: ["commerce", "retail"], itemNoun: "products", ctaText: "Shop Now" };
    }
    if (/\bnews\b|\barticle\b|\breader\b|\bmagazine\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "editorial", density: "regular", voiceTone: "professional", cornerRadiusScale: "sharp", domainTags: ["news", "content"], itemNoun: "stories", ctaText: "Read More" };
    }
    if (/\bchat\b|\bmessage\b|\binbox\b|\bdm\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "minimal", density: "compact", voiceTone: "professional", cornerRadiusScale: "medium", domainTags: ["messaging", "social"], itemNoun: "messages", ctaText: "Send Message" };
    }
    return {};
}

export function extractExplicitAccentFromPrompt(prompt: string): string | null {
    const p = prompt.toLowerCase();
    const colorMap: Array<{ re: RegExp; color: string }> = [
        { re: /\byellow\b|\bgold(en)?\b/, color: "yellow:1.0" },
        { re: /\bgreen\b/, color: "green:1.0" },
        { re: /\bblue\b/, color: "blue:1.0" },
        { re: /\bred\b/, color: "red:1.0" },
        { re: /\borange\b/, color: "orange:1.0" },
        { re: /\bpurple\b|\bviolet\b/, color: "purple:1.0" },
        { re: /\bpink\b/, color: "pink:1.0" },
        { re: /\bteal\b|\bcyan\b/, color: "teal:1.0" },
        { re: /\bindigo\b/, color: "indigo:1.0" },
    ];
    for (const entry of colorMap) {
        if (entry.re.test(p)) return entry.color;
    }
    return null;
}

export function mergeThemeWithDefaults(base: ThemeTokens, defaults: Partial<ThemeTokens>): ThemeTokens {
    return {
        ...base,
        ...defaults,
        sharedFacts: {
            ...base.sharedFacts,
            ...(defaults.sharedFacts ?? {}),
        },
    };
}

function applyPromptThemeCorrections(prompt: string, theme: ThemeTokens, explicitAccent: string | null): ThemeTokens {
    const p = prompt.toLowerCase();
    const isCityGuideLike = /\bcity guide\b|\blocal discovery\b|\bcurated places\b|\bguide app\b|\bneighborhood\b/.test(p);
    const wantsLuxury = /\bpremium\b|\bluxury\b|\brefined\b|\bcalm luxury\b/.test(p);
    const wantsMapFirst = /\bmap-first\b|\bmap first\b|\blive search\b|\bglass overlays\b|\bbottom action tray\b/.test(p);

    if (!explicitAccent && isCityGuideLike && (wantsLuxury || wantsMapFirst)) {
        const loudAccent = ["purple:1.0", "pink:1.0", "indigo:1.0"].includes(theme.accentColor);
        const loudSecondary = ["purple:1.0", "pink:1.0", "indigo:1.0"].includes(theme.secondaryColor);
        return {
            ...theme,
            accentColor: loudAccent ? "teal:1.0" : theme.accentColor,
            secondaryColor: loudSecondary ? "gray:1.0" : theme.secondaryColor,
            surfaceStyle: theme.surfaceStyle === "calm" || theme.surfaceStyle === "utility"
                ? (wantsLuxury ? "minimal" : "editorial")
                : theme.surfaceStyle,
            density: theme.density === "compact" ? "regular" : theme.density,
            fontDesign: theme.fontDesign === "rounded" ? (wantsLuxury ? "serif" : "default") : theme.fontDesign,
            cornerRadiusScale: theme.cornerRadiusScale === "pill" ? "sharp" : theme.cornerRadiusScale,
            voiceTone: theme.voiceTone === "playful" ? "professional" : theme.voiceTone,
            itemNoun: theme.itemNoun === "items" ? "places" : theme.itemNoun,
        };
    }

    const wantsAppleRestraint = /\bapple\b|\bnative\b|\bclean\b|\bminimal\b|\bpremium\b|\brefined\b|\bluxury\b|\bcalm luxury\b/.test(p);
    if (!explicitAccent && wantsAppleRestraint) {
        const loudAccent = ["purple:1.0", "pink:1.0", "indigo:1.0", "orange:1.0", "red:1.0", "green:1.0", "yellow:1.0"].includes(theme.accentColor);
        return {
            ...theme,
            accentColor: loudAccent ? "blue:1.0" : theme.accentColor,
            secondaryColor: "gray:1.0",
            surfaceStyle: theme.surfaceStyle === "utility" ? "minimal" : theme.surfaceStyle,
            fontDesign: theme.fontDesign === "rounded" ? "default" : theme.fontDesign,
            cornerRadiusScale: theme.cornerRadiusScale === "pill" ? "medium" : theme.cornerRadiusScale,
            voiceTone: theme.voiceTone === "playful" ? "professional" : theme.voiceTone,
        };
    }

    return theme;
}

// ─── Standard screen tokens (non-full-canvas mode) ──────────────────────────

export async function generateScreenTokens(prompt: string): Promise<ScreenTokens> {
    const systemPrompt = `You are a mobile UI visual designer. Return design tokens as JSON only.
{ "accentColor": string, "surfaceStyle": "minimal"|"editorial"|"utility"|"immersive"|"calm", "density": "compact"|"regular"|"airy", "fontDesign": "default"|"serif"|"rounded"|"monospaced" }
- accentColor: blue:1.0 orange:1.0 green:1.0 red:1.0 purple:1.0
- surfaceStyle: utility=productivity, immersive=media, calm=wellness, editorial=content, minimal=clean
- density: compact=data-heavy, airy=premium/calm, regular=general
- fontDesign: rounded=friendly, serif=editorial, monospaced=dev, default=most`;

    const response = await callOpenAI({
        model: STANDARD_TOKENS_MODEL,
        messages: [{ role: "system", content: systemPrompt }, { role: "user", content: prompt }],
        temperature: 0.1, maxTokens: 120, responseFormat: { type: "json_object" },
    });

    const fallback: ScreenTokens = { accentColor: "blue:1.0", surfaceStyle: "utility", density: "regular", fontDesign: "default" };
    if (!response.ok) return fallback;
    const parsed = parseJsonSafe(response.content);
    if (isJsonParseError(parsed) || !isObject(parsed.value)) return fallback;
    const v = parsed.value as Record<string, unknown>;
    return {
        accentColor: typeof v.accentColor === "string" ? v.accentColor : fallback.accentColor,
        surfaceStyle: normalizeSurfaceStyle(v.surfaceStyle, fallback.surfaceStyle),
        density: normalizeDensity(v.density, fallback.density),
        fontDesign: (["default", "serif", "rounded", "monospaced"] as const).includes(v.fontDesign as never) ? v.fontDesign as string : "default",
    };
}

export function buildBaselineTheme(tokens: ScreenTokens): ThemeTokens {
    return {
        accentColor: tokens.accentColor,
        secondaryColor: tokens.accentColor,
        surfaceStyle: tokens.surfaceStyle,
        density: tokens.density,
        fontDesign: tokens.fontDesign,
        cornerRadiusScale: "medium",
        usesGradient: false,
        appName: "Workspace",
        voiceTone: "professional",
        mascotSymbol: "",
        itemNoun: "items",
        ctaVerb: "Open",
        primaryMetricLabel: "Progress",
        primaryMetricUnit: "%",
        sampleItems: ["Core flow:Ready to begin:Open", "Selection state:Waiting input:Active", "Supporting context:Updated now:Live", "Next step:Needs decision:Queued"],
        sampleMetrics: ["Progress:72%:+6%", "Focus:14:+2", "Active:9:+1", "Done:5:+1"],
        sampleRailItems: ["Overview", "Current", "Nearby", "Compare", "Explore"],
        ctaText: "Continue",
        domainTags: ["productivity"],
        sharedFacts: {
            greeting: "Welcome back",
            userName: "Alex",
            primaryMetricValue: "72%",
            secondaryMetricValue: "14 active",
            streakValue: "5 days",
            progressPercent: 72,
            todayDate: "Mon, Jan 15",
        },
    };
}

export function computeThemeSurfaces(theme: ThemeTokens): ThemeSurfaces {
    const cornerCard = theme.cornerRadiusScale === "pill" ? 22 : theme.cornerRadiusScale === "sharp" ? 12 : 16;
    const cornerRow = theme.cornerRadiusScale === "pill" ? 18 : theme.cornerRadiusScale === "sharp" ? 12 : 12;
    const spacing = theme.density === "compact" ? 8 : theme.density === "airy" ? 16 : 12;

    const immersive = theme.surfaceStyle === "immersive";
    const cardFill = immersive ? "secondarySystemFill:1.0" : "secondarySystemBackground:1.0";
    const rowFill = immersive ? "tertiarySystemFill:1.0" : "tertiarySystemBackground:1.0";
    const subtleFill = "quaternarySystemFill:1.0";

    return {
        cardFill,
        rowFill,
        subtleFill,
        primaryText: "primary:1.0",
        secondaryText: "secondary:1.0",
        iconTint: "tertiary:1.0",
        dividerTint: "quaternary:1.0",
        cornerCard,
        cornerRow,
        spacing,
    };
}
