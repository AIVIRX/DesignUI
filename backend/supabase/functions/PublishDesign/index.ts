import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const ADMIN_USER_ID = "ab52fbc5-e8bc-47e9-82ff-7b8abd970d54";
const MAX_PREVIEW_BYTES = 3_000_000;

serve(async (req) => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const openAIKey = Deno.env.get("OPENAI_API_KEY");
    if (!supabaseUrl || !serviceRoleKey) return json({ error: "Server configuration missing" }, 500);

    const token = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Missing authorization token" }, 401);

    const admin = createClient(supabaseUrl, serviceRoleKey);
    const { data: authData, error: authError } = await admin.auth.getUser(token);
    if (authError || !authData.user) return json({ error: "Unauthorized" }, 401);
    if (authData.user.id !== ADMIN_USER_ID) return json({ error: "This account cannot publish designs" }, 403);

    try {
        const body = await req.json();
        const title = typeof body?.title === "string" ? body.title.trim().slice(0, 100) : "";
        const codeSnippet = typeof body?.code_snippet === "string" ? body.code_snippet : "";
        const previewBase64 = typeof body?.preview_png_base64 === "string" ? body.preview_png_base64 : "";
        const designJSON = body?.design_json;
        if (!title || !codeSnippet || !designJSON || !previewBase64) {
            return json({ error: "Title, design data, code, and preview image are required" }, 400);
        }

        const preview = decodeBase64(previewBase64);
        if (!preview || preview.byteLength > MAX_PREVIEW_BYTES) {
            return json({ error: "Preview image must be a valid PNG smaller than 3 MB" }, 400);
        }

        const id = crypto.randomUUID();
        const imagePath = `${ADMIN_USER_ID}/${id}/image.png`;
        const { error: imageError } = await admin.storage.from("preview-images").upload(imagePath, preview, {
            contentType: "image/png",
            cacheControl: "31536000",
            upsert: false,
        });
        if (imageError) throw new Error(`Could not upload preview image: ${imageError.message}`);

        const { data: publicURL } = admin.storage.from("preview-images").getPublicUrl(imagePath);
        const description = await generateDescription(title, codeSnippet, openAIKey);
        const slug = await uniqueSlug(admin, title);
        const { error: postError } = await admin.from("posts").insert({
            id,
            author_id: ADMIN_USER_ID,
            title,
            slug,
            description,
            code_snippet: codeSnippet,
            design_json: designJSON,
            preview_image_url: publicURL.publicUrl,
            public: true,
            post_type: "fullscreen",
        });
        if (postError) {
            await admin.storage.from("preview-images").remove([imagePath]);
            throw new Error(`Could not create post: ${postError.message}`);
        }

        return json({ id, slug, description, preview_image_url: publicURL.publicUrl });
    } catch (error) {
        const message = error instanceof Error ? error.message : "Could not publish design";
        console.error("PublishDesign failed", message);
        return json({ error: message }, 500);
    }
});

function decodeBase64(value: string): Uint8Array | null {
    try {
        const bytes = Uint8Array.from(atob(value), (character) => character.charCodeAt(0));
        return bytes.length > 0 ? bytes : null;
    } catch {
        return null;
    }
}

async function uniqueSlug(admin: ReturnType<typeof createClient>, title: string): Promise<string> {
    const base = slugify(title) || "design";
    for (let attempt = 0; attempt < 50; attempt += 1) {
        const candidate = attempt === 0 ? base : `${base}-${attempt + 1}`;
        const { data } = await admin.from("posts").select("id").eq("slug", candidate).maybeSingle();
        if (!data) return candidate;
    }
    return `${base}-${crypto.randomUUID().slice(0, 8)}`;
}

function slugify(value: string): string {
    return value.toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)+/g, "").slice(0, 80);
}

async function generateDescription(title: string, codeSnippet: string, openAIKey: string | undefined): Promise<string> {
    const fallback = `A production-ready SwiftUI ${title} design exported from DesignUI.`;
    if (!openAIKey) return fallback;

    try {
        const response = await fetch("https://api.openai.com/v1/responses", {
            method: "POST",
            headers: { "Content-Type": "application/json", Authorization: `Bearer ${openAIKey}` },
            body: JSON.stringify({
                model: "gpt-5.4-mini",
                reasoning: { effort: "none" },
                instructions: "Write one concise, accurate SEO description for a SwiftUI UI template. Return plain text only, no title, no markdown, max 155 characters.",
                input: `Template name: ${title}\n\nSwiftUI code:\n${codeSnippet.slice(0, 6000)}`,
                max_output_tokens: 100,
                store: false,
            }),
        });
        if (!response.ok) return fallback;
        const result = await response.json();
        const description = typeof result.output_text === "string" ? result.output_text.trim().replace(/\s+/g, " ") : "";
        return description ? description.slice(0, 155) : fallback;
    } catch {
        return fallback;
    }
}

function json(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
}
