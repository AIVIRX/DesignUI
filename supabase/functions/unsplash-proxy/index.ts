// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// 1. Set this in your Supabase Dashboard -> Settings -> Functions -> Secrets
// Key: UNSPLASH_ACCESS_KEY
const unsplashAccessKey = Deno.env.get('UNSPLASH_ACCESS_KEY')

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface UserRequest {
    action: string;
    query?: string;
    page?: number;
    photoId?: string;
}

console.info('Unsplash Proxy Function Started');

Deno.serve(async (req: Request) => {
    // Handle CORS preflight requests
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        // Parse the request body
        const { action, query, page, photoId }: UserRequest = await req.json()

        if (!unsplashAccessKey) {
            throw new Error("Missing Server-Side Configuration (UNSPLASH_ACCESS_KEY)")
        }

        let url = ''

        if (action === 'search') {
            if (!query) throw new Error('Query is required for search')
            const p = page || 1
            url = `https://api.unsplash.com/search/photos?page=${p}&query=${encodeURIComponent(query)}&client_id=${unsplashAccessKey}`
        }
        else if (action === 'list') {
            const p = page || 1
            url = `https://api.unsplash.com/photos?page=${p}&client_id=${unsplashAccessKey}`
        }
        else if (action === 'download_track') {
            if (!photoId) throw new Error('photoId is required for tracking')
            // Trigger the download endpoint for attribution
            // We don't return data here, just status
            url = `https://api.unsplash.com/photos/${photoId}/download?client_id=${unsplashAccessKey}`
        }
        else {
            throw new Error(`Unknown action: ${action}`)
        }

        // Call Unsplash
        const response = await fetch(url)

        // For download tracking, we just want to know if it succeeded
        if (action === 'download_track') {
            return new Response(JSON.stringify({ success: response.ok }), {
                headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            })
        }

        const data = await response.json()

        // Pass back result
        return new Response(JSON.stringify(data), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        })

    } catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error'
        return new Response(JSON.stringify({ error: message }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 400,
        })
    }
})
