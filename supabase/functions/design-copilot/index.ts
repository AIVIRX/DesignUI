// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import OpenAI from "https://deno.land/x/openai@v4.69.0/mod.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY")!;
const openaiApiKey = Deno.env.get("OPEN_AI_KEY")!;

const openai = new OpenAI({ apiKey: openaiApiKey });
const supabase = createClient(supabaseUrl, supabaseKey);

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// MARK: - Lean JSON System Prompt (Optimized for gpt-4o-mini & Full Screens)
// We use a text-based schema here to allow "Lean" output (omitting nulls), which saves tokens 
// and allows larger component trees (Full Screens) to fit in the context window.

const SYSTEM_PROMPT = `You are an expert SwiftUI designer. context: "SwiftUI UIComponent JSON".

**Goal**: Generate a UI component tree. Return a SINGLE JSON object.

**Schema Definitions**:
1. **Types**: 
   - Layout: "VStack", "HStack", "ZStack", "List", "ScrollView", "Spacer", "Divider"
   - Basic: "Text", "Image", "Button", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "SF Symbol", "Linear Gradient"
   - Form: "TextField", "Toggle", "Slider", "Stepper", "DatePicker", "Picker"

2. **Properties** (Key-Value pairs in "properties"):
   - "text", "imageName", "systemName", "spacing", "alignment"
   - "font", "fontWeight", "foregroundColor", "backgroundColor"

3. **Modifiers** (Array of objects in "modifiers"):
   - Structure: { "type": "Padding", "properties": { "amount": 10 } }
   - Supported: "Padding", "Frame", "Background Color", "Foreground Color", "Corner Radius", "Shadow", "Opacity", "Border", "Blur", "Rotation", "Scale", "Offset", "Clip Shape", "Aspect Ratio", "Z Index"

**CRITICAL RULES**:
1. **Lean JSON**: OMIT all null/empty values. Do NOT send "font": null. Only send what is needed.
2. **Shapes are Leaf Nodes**: "Rectangle", "Circle", "Capsule", "Image" etc. MUST NOT have "children".
3. **Layering**: Use "ZStack" to layer text over shapes. NEVER nest children inside a shape.
4. **Full Screens**: If asked for a screen, wrap everything in a root "VStack" or "ZStack".
5. **Defaults**: Make it look Premium (Apple Design). Add padding/spacing where appropriate.`;

Deno.serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { prompt, schemaType = "chat", context = {} } = await req.json();
        const isComponentRequest = schemaType === "component" || prompt.toLowerCase().includes("add") || prompt.toLowerCase().includes("create") || prompt.toLowerCase().includes("make");

        let messages = [];

        if (isComponentRequest) {
            messages = [
                { role: "system", content: SYSTEM_PROMPT },
                { role: "user", content: `Context: ${JSON.stringify(context)}\n\nRequest: ${prompt}` }
            ];

            const completion = await openai.chat.completions.create({
                model: "gpt-4o-mini", // Efficient & Cheap
                messages: messages,
                temperature: 0.3,
                response_format: { type: "json_object" }
            });

            const output = JSON.parse(completion.choices[0].message.content || "{}");

            return new Response(
                JSON.stringify(output),
                { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );

        } else {
            // Standard Chat
            messages = [
                { role: "system", content: "You are a helpful assistant for a UI design tool." },
                { role: "user", content: prompt }
            ];

            const completion = await openai.chat.completions.create({
                model: "gpt-4o-mini",
                messages: messages,
                max_tokens: 1000
            });

            const responseText = completion.choices[0].message.content || "";
            return new Response(
                JSON.stringify({ response: responseText }),
                { headers: { ...corsHeaders, "Content-Type": "application/json" } }
            );
        }

    } catch (err) {
        console.error("❌ Function Error:", err);
        return new Response(
            JSON.stringify({ error: err.message }),
            { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }
});
