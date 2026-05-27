import type { Density, ScreenTokens, ThemeSurfaces, ThemeTokens } from "./types.ts";
import { callOpenAI, STANDARD_TOKENS_MODEL, THEME_EXTRACT_MAX_TOKENS, THEME_MODEL } from "./openai.ts";
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

accentColor / secondaryColor: use "colorname:1.0" format. Pick from: blue:1.0 orange:1.0 green:1.0 red:1.0 purple:1.0 yellow:1.0 teal:1.0 pink:1.0
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
        accentColor: "blue:1.0", secondaryColor: "purple:1.0", surfaceStyle: "utility",
        density: "regular", fontDesign: "default", cornerRadiusScale: "medium", usesGradient: false,
        appName: "MyApp", voiceTone: "professional", mascotSymbol: "", itemNoun: "items",
        ctaVerb: "Start", primaryMetricLabel: "Progress", primaryMetricUnit: "%",
        sampleItems: ["First task:Get started:Open", "Second task:Keep going:In Progress", "Third task:Almost there:Due Soon", "Fourth task:Finish strong:Pending"],
        sampleMetrics: ["Progress:68%:+12%", "Streak:5 days:+1", "Completed:12:+3", "Score:840:+60"],
        sampleRailItems: ["Featured", "Continue", "New", "Popular", "Saved"],
        ctaText: "Get Started", domainTags: ["productivity"],
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
        temperature: 0.2, maxTokens: THEME_EXTRACT_MAX_TOKENS, responseFormat: { type: "json_object" },
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
    const merged = mergeThemeWithDefaults(extracted, domainDefaults);
    if (explicitAccent) {
        merged.accentColor = explicitAccent;
        if (!merged.secondaryColor || merged.secondaryColor === domainDefaults.secondaryColor) {
            merged.secondaryColor = explicitAccent;
        }
    }
    return merged;
}

export function inferDomainDefaults(prompt: string): Partial<ThemeTokens> {
    const p = prompt.toLowerCase();
    if (/\bmeditation\b|\bmindful\b|\bcalm\b|\bbreathe\b|\bzen\b/.test(p)) {
        return { accentColor: "purple:1.0", secondaryColor: "indigo:1.0", surfaceStyle: "calm", density: "airy", voiceTone: "calm", cornerRadiusScale: "pill", domainTags: ["meditation", "wellness"], ctaText: "Begin Session" };
    }
    if (/\bfinance\b|\bbank\b|\binvest\b|\bportfolio\b|\bstock\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "teal:1.0", surfaceStyle: "utility", density: "regular", voiceTone: "professional", cornerRadiusScale: "medium", domainTags: ["finance", "analytics"], ctaText: "Review Now" };
    }
    if (/\bmusic\b|\bplaylist\b|\bspotify\b|\bartist\b|\balbum\b/.test(p)) {
        return { accentColor: "green:1.0", secondaryColor: "purple:1.0", surfaceStyle: "immersive", density: "regular", voiceTone: "playful", cornerRadiusScale: "medium", domainTags: ["music", "media"], ctaText: "Play Now" };
    }
    if (/\btravel\b|\bitinerary\b|\btrip\b|\bflight\b|\bhotel\b/.test(p)) {
        return { accentColor: "orange:1.0", secondaryColor: "blue:1.0", surfaceStyle: "editorial", density: "regular", voiceTone: "professional", cornerRadiusScale: "medium", domainTags: ["travel", "planning"], ctaText: "View Trip" };
    }
    if (/\bcoffee\b|\bcafe\b|\bcafé\b|\blatte\b|\bespresso\b|\broaster\b|\bbrew\b/.test(p)) {
        return {
            accentColor: "brown:1.0",
            secondaryColor: "orange:1.0",
            surfaceStyle: "editorial",
            density: "regular",
            voiceTone: "calm",
            cornerRadiusScale: "medium",
            domainTags: ["coffee", "cafe", "local"],
            ctaText: "Find a Cafe",
            itemNoun: "cafes",
            sampleRailItems: ["Morning", "Latte Lab", "Roasters", "Cozy Nook", "Pour Over"],
            sampleItems: [
                "Morning Brew:Fresh pastries today:4.8",
                "Cozy Corner:Window seats open:2 blocks",
                "Latte Art:Honey oat latte:New",
                "Daily Grind:Single-origin pour over:Open",
            ],
        };
    }
    if (/\bfitness\b|\bworkout\b|\btraining\b|\brun\b|\bactivity\b/.test(p)) {
        return { accentColor: "red:1.0", secondaryColor: "orange:1.0", surfaceStyle: "utility", density: "compact", voiceTone: "urgent", cornerRadiusScale: "medium", domainTags: ["fitness", "health"], ctaText: "Start Run" };
    }
    if (/\bshopping\b|\bstore\b|\becommerce\b|\bcheckout\b|\bcart\b/.test(p)) {
        return { accentColor: "indigo:1.0", secondaryColor: "pink:1.0", surfaceStyle: "editorial", density: "regular", voiceTone: "playful", cornerRadiusScale: "medium", domainTags: ["commerce", "retail"], ctaText: "Shop Now" };
    }
    if (/\bnews\b|\barticle\b|\breader\b|\bmagazine\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "gray:1.0", surfaceStyle: "editorial", density: "regular", voiceTone: "professional", cornerRadiusScale: "sharp", domainTags: ["news", "content"], ctaText: "Read More" };
    }
    if (/\bchat\b|\bmessage\b|\binbox\b|\bdm\b/.test(p)) {
        return { accentColor: "blue:1.0", secondaryColor: "green:1.0", surfaceStyle: "utility", density: "compact", voiceTone: "playful", cornerRadiusScale: "pill", domainTags: ["messaging", "social"], ctaText: "Send Message" };
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
        sampleItems: ["Priority item:Start here:Open", "Follow up:Keep momentum:In Progress", "Review:End of day:Soon", "Wrap up:Final check:Pending"],
        sampleMetrics: ["Progress:72%:+6%", "Focus:14:+2", "Active:9:+1", "Done:5:+1"],
        sampleRailItems: ["Featured", "Continue", "New", "Popular", "Saved"],
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
    const accentBase = theme.accentColor.split(":")[0];
    const cornerCard = theme.cornerRadiusScale === "pill" ? 22 : theme.cornerRadiusScale === "sharp" ? 8 : 16;
    const cornerRow = theme.cornerRadiusScale === "pill" ? 18 : theme.cornerRadiusScale === "sharp" ? 6 : 12;
    const spacing = theme.density === "compact" ? 8 : theme.density === "airy" ? 16 : 12;
    const surfaceCard = theme.surfaceStyle === "immersive" ? 0.16 : theme.surfaceStyle === "minimal" ? 0.05 : 0.08;
    const surfaceRow = theme.surfaceStyle === "immersive" ? 0.12 : theme.surfaceStyle === "minimal" ? 0.04 : 0.06;
    return {
        cardFill: `${accentBase}:${surfaceCard.toFixed(2)}`,
        rowFill: `${accentBase}:${surfaceRow.toFixed(2)}`,
        subtleFill: "gray:0.10",
        primaryText: "primary:1.0",
        secondaryText: theme.surfaceStyle === "immersive" ? "white:0.72" : "secondary:1.0",
        iconTint: "gray:0.62",
        dividerTint: "gray:0.18",
        cornerCard,
        cornerRow,
        spacing,
    };
}
