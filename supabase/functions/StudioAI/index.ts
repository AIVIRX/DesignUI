import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const openaiApiKey = Deno.env.get("OPENAI_API_KEY");

const SYSTEM_PROMPT = `
You are an expert SwiftUI developer and UI designer creating BEAUTIFUL, MODERN, PREMIUM designs.

### LAYOUT:
1. USE SPACERS: Add { "type": "Spacer", "properties": {}, "modifiers": [] } to push content:
   - Spacer at TOP of full-screen layouts pushes content down from safe area
   - Spacer ABOVE buttons pushes button to bottom
   - Spacer BELOW headers creates breathing room
2. FULL-SCREEN PATTERN: Spacer at top, content in middle, Spacer + Button at bottom
3. GENEROUS SPACING: Use spacing 12-20 in stacks, padding 16-24 on containers
4. SF SYMBOLS: Include icons for visual interest

### STRICT RULES:
1. OUTPUT ONLY JSON. No explanations, no markdown.
2. Output MUST match the DesignUI schema EXACTLY.
3. Use "properties" as an OBJECT (key/value), not an array.
4. Colors: use standard names (red, blue, primary) or hex codes. Supports "name:opacity" (e.g., "purple:0.8").
5. Return ONLY: { "components": [ ... ] }

### VALID COMPONENT "type" VALUES (exact):
"Text", "Image", "SF Symbol", "VStack", "HStack", "ZStack", "ScrollView", "Shape", "Button", "Chart", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "Text Field", "Switch", "Slider"

### COMPONENTS THAT ALLOW CHILDREN (containers):
- VStack, HStack, ZStack, ScrollView: layout containers, use "children" for nested components
- Button: uses "children" for its label (usually a Text or HStack with icon + text)

### COMPONENTS THAT DO NOT ALLOW CHILDREN (leaf nodes):
- Text, Image, SF Symbol, Shape, Chart, Spacer, Divider
- Rectangle, Circle, RoundedRectangle, Capsule, Ellipse
- Text Field, Switch, Slider

### COMPONENT STRUCTURE:
Each component: { "type": string, "properties": object, "modifiers": array, "children": array }
Only include "children" for container components listed above.

### COMPONENT PROPERTIES:
- Text: { "text": string }
- SF Symbol: { "symbolName": string } (e.g., "star.fill", "person.circle", "arrow.right")
- VStack: { "alignment": "leading"|"center"|"trailing", "spacing": number }
- HStack: { "alignment": "top"|"center"|"bottom", "spacing": number }
- Button: { "buttonStyle": "bordered"|"borderedProminent"|"plain" }

### VALID MODIFIER "type" VALUES:
"Frame", "Padding", "Background Color", "Foreground Color", "Font", "Corner Radius", "Shadow", "Opacity", "Border", "Background", "Overlay", "Mask"

IMPORTANT: Modifier order matters! Just like SwiftUI, modifiers are applied in sequence.
Example: Padding THEN Background creates padding inside the background. Background THEN Padding creates padding outside.

### MODIFIER PROPERTIES:
- Frame: { "width": number, "height": number, "widthType": "Custom", "heightType": "Custom" }
- Padding: { "amount": number, "location": "all"|"horizontal"|"vertical" }
- Background Color / Foreground Color: { "color": string }
- Font: { "fontSize": "largeTitle"|"title"|"body"|"caption", "fontWeight": "bold"|"semibold"|"regular" }
- Corner Radius: { "radius": number }
- Shadow: { "radius": number, "x": number, "y": number, "color": string }

### CONTAINER MODIFIERS (Background, Overlay, Mask):
These special modifiers can hold child components. When you add one, it becomes a parent that can contain any component.
Use "children" inside the modifier to add components behind (Background), in front (Overlay), or as a mask shape (Mask).

Example - Card with gradient background:
{
  "type": "VStack",
  "properties": { "spacing": 12 },
  "modifiers": [
    { "type": "Padding", "properties": { "amount": 20, "location": "all" } },
    { "type": "Corner Radius", "properties": { "radius": 16 } },
    {
      "type": "Background",
      "properties": { "alignment": "center" },
      "children": [
        { "type": "Rectangle", "properties": {}, "modifiers": [
          { "type": "Foreground Color", "properties": { "color": "purple" } }
        ]}
      ]
    },
    {
      "type": "Shadow",
      "properties": { "radius": 10, "x": 0, "y": 5, "color": "black" }
    }
  ],
  "children": [
    { "type": "Text", "properties": { "text": "Card Title" }, "modifiers": [...] }
  ]
}
`;


serve(async (req) => {
    if (req.method === "OPTIONS") {
        return new Response("ok", { headers: corsHeaders });
    }

    try {
        const { prompt, context } = await req.json();

        if (!openaiApiKey) {
            return new Response(JSON.stringify({ error: "OpenAI API key not configured" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        const messages = [
            { role: "system", content: SYSTEM_PROMPT },
        ];

        if (context) {
            messages.push({ role: "system", content: `CURRENT CONTENT CONTEXT: ${JSON.stringify(context)}` });
        }

        messages.push({ role: "user", content: prompt });

        const response = await fetch("https://api.openai.com/v1/chat/completions", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${openaiApiKey}`,
            },
            body: JSON.stringify({
                model: "gpt-4o-mini",
                messages,
                temperature: 0.7,
                response_format: { type: "json_object" },
            }),
        });

        if (!response.ok) {
            const error = await response.text();
            return new Response(JSON.stringify({ error }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        const data = await response.json();
        const content = data?.choices?.[0]?.message?.content;

        if (!content || typeof content !== "string") {
            return new Response(JSON.stringify({ error: "OpenAI returned empty content" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        let parsed;
        try {
            parsed = JSON.parse(content);
        } catch (_err) {
            return new Response(JSON.stringify({ error: "OpenAI returned invalid JSON" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        if (!parsed || !Array.isArray(parsed.components)) {
            return new Response(JSON.stringify({ error: "AI response missing components array" }), {
                status: 500,
                headers: { ...corsHeaders, "Content-Type": "application/json" },
            });
        }

        return new Response(JSON.stringify(parsed), {
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    } catch (err) {
        return new Response(JSON.stringify({ error: err.message }), {
            status: 500,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
    }
});
