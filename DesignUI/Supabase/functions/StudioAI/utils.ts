import type { SurfaceStyle, Density } from "./types.ts";

const INSTRUCTIONAL_COPY_PATTERNS: RegExp[] = [
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

export type JsonParseResult = { ok: true; value: unknown } | { ok: false; error: string };
export function parseJsonSafe(content: string): JsonParseResult {
    try { return { ok: true, value: JSON.parse(content) }; }
    catch (err) { return { ok: false, error: `Invalid JSON: ${err instanceof Error ? err.message : String(err)}` }; }
}
export function isJsonParseError(r: JsonParseResult): r is { ok: false; error: string } { return r.ok === false; }
export function isObject(v: unknown): v is Record<string, unknown> { return Boolean(v) && typeof v === "object" && !Array.isArray(v); }
export function asString(v: unknown, fallback = ""): string { return typeof v === "string" ? v.trim() || fallback : fallback; }
export function normalizeSurfaceStyle(v: unknown, fallback: SurfaceStyle = "utility"): SurfaceStyle {
    if (v === "minimal" || v === "editorial" || v === "utility" || v === "immersive" || v === "calm") return v;
    return fallback;
}
export function normalizeDensity(v: unknown, fallback: Density = "regular"): Density {
    if (v === "compact" || v === "regular" || v === "airy") return v;
    return fallback;
}
export function normalizeSelectedComponent(value: unknown): Record<string, unknown> | null {
    if (typeof value === "string" && value.trim().length > 0) {
        const p = parseJsonSafe(value);
        if (!isJsonParseError(p)) return normalizeSelectedComponent(p.value);
        return null;
    }
    if (!isObject(value)) return null;
    if (isObject(value.component)) return value.component;
    return value;
}
