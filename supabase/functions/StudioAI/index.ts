// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import OpenAI from "https://deno.land/x/openai@v4.69.0/mod.ts";

// Use SUPABASE_URL (standard) or fallback to SUPABASE_DB_URL for compatibility
const supabaseUrl = Deno.env.get("SUPABASE_URL");
if (!supabaseUrl) {
  throw new Error("Missing SUPABASE_URL or SUPABASE_DB_URL environment variable");
}
// Use service role key for admin operations, or anon key for user verification
// For getUser() to work with user JWTs, we can use anon key
const supabaseKey = Deno.env.get("SUPABASE_ANON_KEY");
if (!supabaseKey) {
  throw new Error("Missing SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE_KEY environment variable");
}
const supabase = createClient(supabaseUrl, supabaseKey);

const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
if (!openaiApiKey) {
  throw new Error("Missing OPENAI_API_KEY environment variable");
}
const openai = new OpenAI({
  apiKey: openaiApiKey
});

// ⚠️ Note: OpenAI doesn't actually cache function definitions to reduce token costs
// However, using function calling is the standard pattern and more efficient than
// including schema in prompts. The function definition is still sent each time.
// 
// For true cost reduction, we:
// 1. Cache schema on our server (done above)
// 2. Use function calling (standard pattern)
// 3. Only send schemaType parameter from client (minimal tokens)
const FUNCTIONS = [
  {
    name: "generate_swiftui_component",
    description: "Generate a complete SwiftUI view structure (full screen/page) based on user description. Always return an array of root components, not a single component.",
    parameters: {
      type: "object",
      properties: {
        components: {
          type: "array",
          description: "Array of root UI components. For full views, typically contains a single root VStack/HStack/ZStack with all child components nested inside.",
          items: {
            type: "object",
            description: "A SwiftUI component structure",
            properties: {
              type: {
                type: "string",
                enum: ["Text", "Image", "Button", "VStack", "HStack", "ZStack", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "ScrollView", "SF Symbol"],
                description: "The type of SwiftUI component"
              },
              id: {
                type: "string",
                description: "Unique identifier (UUID format)"
              },
              properties: {
                type: "object",
                description: "Component properties as key-value pairs",
                additionalProperties: true,
                properties: {
                  // Text properties
                  text: { type: "string", description: "Text content for Text components" },
                  // SF Symbol properties
                  symbolName: { type: "string", description: "SF Symbol name (e.g., 'star.fill', 'heart.fill', 'person.fill')" },
                  // Color properties
                  foregroundColor: { type: "string", description: "Foreground/text color: 'primary', 'secondary', 'blue', 'red', 'green', 'yellow', 'orange', 'purple', 'pink', 'white', 'black', 'gray', 'clear', or 'rgb(r,g,b)' or 'rgba(r,g,b,a)'" },
                  backgroundColor: { type: "string", description: "Background color: same options as foregroundColor" },
                  // Layout properties
                  alignment: { 
                    type: "string", 
                    enum: ["leading", "center", "trailing", "top", "bottom", "firstTextBaseline", "lastTextBaseline"], 
                    description: "Alignment for stacks and text" 
                  },
                  spacing: { 
                    type: ["number", "string"], 
                    description: "Spacing for stacks. Can be a number (8, 16, 20, etc.) or 'default'" 
                  },
                  // Button properties
                  title: { type: "string", description: "Button title text" },
                  cornerRadius: { type: "number", description: "Corner radius for buttons and rounded rectangles" },
                  // Image properties
                  aspectRatio: { type: "string", enum: ["fit", "fill", "none"], description: "Image aspect ratio mode" },
                  // Font properties
                  fontSize: { 
                    type: "string", 
                    enum: ["largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"],
                    description: "Font size for text" 
                  },
                  fontWeight: { 
                    type: "string", 
                    enum: ["regular", "bold", "light", "medium", "semibold", "heavy", "black"],
                    description: "Font weight for text" 
                  },
                  // Spacer properties
                  minLength: { type: "number", description: "Minimum length for Spacer (default: 0)" }
                }
              },
              frame: {
                type: "array",
                description: "Component position and size as [[x, y], [width, height]]. Use [0, 0] for auto-position, [0, 0] for auto-size. For full views, root container should be [0, 0] for position and [350-400, 600-900] for size.",
                items: {
                  type: "array",
                  items: { type: "number" },
                  minItems: 2,
                  maxItems: 2
                },
                minItems: 2,
                maxItems: 2
              },
              children: {
                type: "array",
                description: "Nested child components (for containers like VStack, HStack, ZStack, ScrollView)",
                items: { $ref: "#/properties/components/items" }
              },
              modifiers: {
                type: "array",
                description: "Component modifiers (optional)",
                items: {
                  type: "object",
                  properties: {
                    type: { 
                      type: "string", 
                      enum: [
                        "Frame", "Padding", "Background", "Foreground Color", "Font Weight", 
                        "Font Size", "Corner Radius", "Shadow", "Border", "Opacity", 
                        "Rotation", "Scale", "Offset", "Blur", "Overlay", "Clip Shape", 
                        "Mask", "Text Alignment", "Fill"
                      ], 
                      description: "Modifier type" 
                    },
                    properties: {
                      type: "object",
                      additionalProperties: true,
                      description: "Modifier-specific properties. Examples: Padding: {amount: number, location: 'all'|'top'|'bottom'|'leading'|'trailing'|'horizontal'|'vertical'}, Frame: {width: number, height: number, widthType: 'Default'|'Custom'|'Full', heightType: 'Default'|'Custom'}, Shadow: {radius: number, x: number, y: number, color: string}, etc."
                    }
                  },
                  required: ["type"]
                }
              },
              zIndex: { type: "number", description: "Z-index for layering (default: 0)" },
              isVisible: { type: "boolean", description: "Whether component is visible (default: true)" },
              isSelected: { type: "boolean", description: "Whether component is selected (default: false)" },
              isOverlay: { type: "boolean", description: "Whether component is an overlay (default: false)" }
            },
            required: ["type", "id"]
          }
        }
      },
      required: ["components"]
    }
  }
];

Deno.serve(async (req) => {
  try {
    console.log("📥 Request received:", req.method, req.url);
    
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      console.error("❌ Missing Authorization header");
      return new Response(JSON.stringify({ code: 401, message: "Missing Authorization header" }), { 
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }

    const token = authHeader.replace("Bearer ", "");
    console.log("🔑 Received token:", token.substring(0, 20) + "...");

    // ✅ Verify user - use the existing supabase client to verify the JWT
    // The supabase client is already initialized with the anon key
    console.log("🔍 Verifying user token...");
    let user, authError;
    try {
      const authResult = await supabase.auth.getUser(token);
      user = authResult.data?.user;
      authError = authResult.error;
    } catch (err) {
      console.error("❌ Exception during auth.getUser:", err);
      return new Response(JSON.stringify({ 
        code: 500, 
        message: `Auth verification failed: ${err instanceof Error ? err.message : String(err)}` 
      }), { 
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    if (authError) {
      console.error("❌ Auth error:", authError.message);
      return new Response(JSON.stringify({ 
        code: 401, 
        message: `Invalid JWT: ${authError.message}` 
      }), { 
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    if (!user) {
      console.error("❌ User not found after verification");
      return new Response(JSON.stringify({ 
        code: 401, 
        message: "User not found" 
      }), { 
        status: 401,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    console.log("✅ User verified:", user.id);

    // Parse request body
    let requestBody;
    try {
      requestBody = await req.json();
    } catch (parseError) {
      console.error("❌ JSON parse error:", parseError);
      return new Response(JSON.stringify({ 
        code: 400, 
        message: "Invalid JSON in request body" 
      }), { 
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }

    const { prompt, schemaType = "chat" } = requestBody;
    
    if (!prompt) {
      return new Response(JSON.stringify({ 
        code: 400, 
        message: "Missing 'prompt' in request body" 
      }), { 
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    console.log("📝 Processing request - schemaType:", schemaType, "prompt length:", prompt.length);

    // ✅ OpenAI Prompt Caching: Automatically caches common prefixes >1,024 tokens
    // Since our function definition (~500) + system (~30) = ~530 tokens, caching may not
    // always trigger on single requests. However, in multi-turn conversations or with
    // longer prompts, the prefix will be cached, giving 50% discount on cached tokens!
    // No code changes needed - OpenAI handles this automatically.
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      {
        role: "system",
        content: schemaType === "component" 
          ? `You are an EXPERT SwiftUI designer and the BEST SwiftUI AI generator. Your designs are MODERN, BEAUTIFUL, and PRODUCTION-READY. You create visually stunning, Apple-quality interfaces that follow Human Interface Guidelines while being creative and engaging.

🎨 DESIGN PHILOSOPHY - CREATE BEAUTIFUL, MODERN DESIGNS:
- NEVER create boring, plain, or basic designs
- Use visual hierarchy, creative layouts, and modern design patterns
- Apply shadows, gradients, rounded corners, and visual depth
- Use SF Symbols creatively with proper sizing and colors
- Create card-based layouts with proper spacing and elevation
- Use color strategically - not just primary/secondary, but vibrant, modern palettes
- Add visual interest with backgrounds, overlays, and creative compositions

📐 LAYOUT & SPACING EXCELLENCE:
- Use generous, breathing room (24-32px between major sections)
- Create visual groups with consistent spacing (12-16px for related items)
- Use asymmetric layouts when appropriate - not everything centered
- Apply proper padding (24-32px on edges, 16-20px internally)
- Use Spacer strategically to create balanced compositions
- Consider safe areas and visual flow

🎯 VISUAL HIERARCHY:
- Main titles: largeTitle (34pt) with bold/semibold weight
- Section headers: title (28pt) or title2 (22pt) with semibold
- Body text: body (17pt) or callout (16pt) for readability
- Secondary text: subheadline (15pt) or footnote (13pt) in secondary color
- Use font weight variations (bold, semibold) to create emphasis
- Create contrast with size, weight, and color

🌈 COLOR & STYLING:
- Use vibrant, modern color palettes (not just blue/red - use purple, pink, orange, teal, mint)
- Apply gradients for backgrounds when appropriate
- Use semantic colors (primary, secondary) for text hierarchy
- Add subtle shadows (radius: 8-12, y: 4-6) for depth
- Use corner radius: 12-16 for cards, 8-10 for buttons, 20+ for pills
- Apply opacity variations (0.1-0.3 for subtle backgrounds)
- Use foregroundColor modifiers on SF Symbols for visual interest

✨ CREATIVE ELEMENTS:
- Add decorative SF Symbols (star.fill, sparkles, heart.fill) with creative colors
- Use ZStack for layered compositions (backgrounds, overlays)
- Create card-based designs with rounded rectangles and shadows
- Add visual separators (Dividers) with proper spacing
- Use HStack for horizontal layouts (icons + text, buttons side-by-side)
- Create visual interest with alternating layouts and compositions

🔧 TECHNICAL REQUIREMENTS:
1. ALWAYS return an array of components (use "components" key, not "component")
2. For full views, return a single root component (typically VStack, HStack, or ZStack)
3. Frame format: [[x, y], [width, height]] - Position: [0, 0], Size: [375, 812] for mobile
4. Include EVERY component mentioned in user's request PLUS creative enhancements
5. Use proper nesting: root → sections → components → nested elements
6. Generate unique UUIDs for all component IDs
7. Add modifiers for shadows, corner radius, padding, and visual effects
8. Make buttons visually appealing with proper sizing, colors, and corner radius

EXAMPLE - Beautiful Sign In View (NOT boring):
{
  "components": [
    {
      "id": "root-uuid",
      "type": "VStack",
      "frame": [[0, 0], [375, 812]],
      "properties": {
        "alignment": "center",
        "spacing": 32,
        "backgroundColor": "clear"
      },
      "modifiers": [
        {"type": "Padding", "properties": {"amount": 32, "location": "all"}}
      ],
      "children": [
        {"id": "spacer-top", "type": "Spacer", "frame": [[0, 0], [0, 0]], "properties": {"minLength": 0}, "children": []},
        {
          "id": "header-section",
          "type": "VStack",
          "frame": [[0, 0], [0, 0]],
          "properties": {"alignment": "center", "spacing": 12},
          "children": [
            {
              "id": "title",
              "type": "Text",
              "frame": [[0, 0], [0, 0]],
              "properties": {
                "text": "Welcome Back",
                "fontSize": "largeTitle",
                "fontWeight": "bold",
                "foregroundColor": "primary"
              },
              "modifiers": [
                {"type": "Font Weight", "properties": {"fontWeight": "bold"}},
                {"type": "Font Size", "properties": {"fontSize": "largeTitle"}}
              ],
              "children": []
            },
            {
              "id": "subtitle",
              "type": "Text",
              "frame": [[0, 0], [0, 0]],
              "properties": {
                "text": "Sign in to continue",
                "fontSize": "body",
                "foregroundColor": "secondary"
              },
              "children": []
            }
          ],
          "modifiers": []
        },
        {"id": "spacer-1", "type": "Spacer", "frame": [[0, 0], [0, 0]], "properties": {"minLength": 0}, "children": []},
        {
          "id": "apple-button",
          "type": "Button",
          "frame": [[0, 0], [0, 0]],
          "properties": {
            "title": "Sign in with Apple",
            "backgroundColor": "black",
            "foregroundColor": "white",
            "cornerRadius": 12
          },
          "modifiers": [
            {"type": "Frame", "properties": {"width": 311, "widthType": "Full", "height": 56, "heightType": "Custom"}},
            {"type": "Corner Radius", "properties": {"radius": 12}},
            {"type": "Shadow", "properties": {"radius": 8, "x": 0, "y": 4, "color": "black"}}
          ],
          "children": []
        },
        {
          "id": "email-button",
          "type": "Button",
          "frame": [[0, 0], [0, 0]],
          "properties": {
            "title": "Continue with Email",
            "backgroundColor": "blue",
            "foregroundColor": "white",
            "cornerRadius": 12
          },
          "modifiers": [
            {"type": "Frame", "properties": {"width": 311, "widthType": "Full", "height": 56, "heightType": "Custom"}},
            {"type": "Corner Radius", "properties": {"radius": 12}},
            {"type": "Shadow", "properties": {"radius": 8, "x": 0, "y": 4, "color": "blue"}}
          ],
          "children": []
        },
        {"id": "spacer-2", "type": "Spacer", "frame": [[0, 0], [0, 0]], "properties": {"minLength": 0}, "children": []}
      ],
      "zIndex": 0,
      "isVisible": true,
      "isSelected": false,
      "isOverlay": false
    }
  ]
}

🎯 REMEMBER:
- Add visual depth with shadows, rounded corners, and proper spacing
- Use creative color combinations (not just blue/black)
- Make buttons prominent with proper sizing (56px height) and shadows
- Create visual hierarchy with font sizes and weights
- Add decorative elements (SF Symbols) for visual interest
- Use generous spacing for modern, breathing layouts
- Every design should look like it belongs in a premium app

Generate BEAUTIFUL, MODERN, PRODUCTION-READY designs that users will love!`
          : "You are a helpful SwiftUI assistant. Provide clear, concise answers about SwiftUI development."
      },
      {
        role: "user",
        content: prompt
      }
    ];

    // Build request options - use type assertion to allow tools property
    const baseOptions: any = {
      model: "gpt-4o", // Upgraded for better design creativity and quality
      messages: messages,
      temperature: 0.6, // Balanced: creative but structured for JSON
      max_tokens: 6000
    };

    // Add function calling for component generation
    let requestOptions: any;
    if (schemaType === "component") {
      requestOptions = {
        model: baseOptions.model,
        messages: baseOptions.messages,
        temperature: baseOptions.temperature,
        max_tokens: baseOptions.max_tokens,
        tools: [
          {
            type: "function",
            function: FUNCTIONS[0]
          }
        ],
        tool_choice: { type: "function", function: { name: "generate_swiftui_component" } }
      };
    } else {
      requestOptions = baseOptions;
    }

    console.log("🤖 Calling OpenAI API...");
    console.log("Request options:", JSON.stringify({
      model: requestOptions.model,
      messages_count: requestOptions.messages.length,
      has_tools: !!requestOptions.tools,
      temperature: requestOptions.temperature,
      max_tokens: requestOptions.max_tokens
    }));
    
    let response;
    try {
      response = await openai.chat.completions.create(requestOptions);
      console.log("✅ OpenAI response received");
      console.log("Response choices count:", response.choices?.length || 0);
    } catch (openaiError) {
      console.error("❌ OpenAI API error:", openaiError);
      console.error("OpenAI error type:", openaiError?.constructor?.name);
      console.error("OpenAI error message:", openaiError instanceof Error ? openaiError.message : String(openaiError));
      console.error("OpenAI error stack:", openaiError instanceof Error ? openaiError.stack : "No stack trace");
      
      const errorDetails = openaiError instanceof Error ? {
        message: openaiError.message,
        stack: openaiError.stack,
        name: openaiError.name
      } : { message: String(openaiError) };
      
      return new Response(JSON.stringify({ 
        code: 500, 
        message: `OpenAI API error: ${errorDetails.message}`,
        details: errorDetails
      }), { 
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }

    // Extract output from function call or regular message
    let output: string;
    try {
      const message = response.choices[0]?.message;
      if (!message) {
        throw new Error("No message in OpenAI response");
      }
      
      if (message.tool_calls && message.tool_calls.length > 0) {
        // Function was called - extract the arguments (these are the component data)
        const functionCall = message.tool_calls[0];
        if (functionCall.type === "function" && functionCall.function.arguments) {
          // The arguments are already a JSON string
          output = functionCall.function.arguments;
        } else {
          output = JSON.stringify({ error: "Invalid function call response" });
        }
      } else {
        // Regular chat response - wrap in response object for consistency
        output = JSON.stringify({ response: message.content || "" });
      }
      console.log("✅ Output extracted, length:", output.length);
    } catch (parseError) {
      console.error("❌ Error parsing OpenAI response:", parseError);
      return new Response(JSON.stringify({ 
        code: 500, 
        message: `Failed to parse OpenAI response: ${parseError instanceof Error ? parseError.message : String(parseError)}` 
      }), { 
        status: 500,
        headers: { "Content-Type": "application/json" }
      });
    }

    return new Response(
      JSON.stringify({
        user_id: user.id,
        output
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        }
      }
    );
  } catch (err) {
    // Log the full error with stack trace
    console.error("❌ Unhandled error:", err);
    console.error("Error type:", err?.constructor?.name);
    console.error("Error message:", err instanceof Error ? err.message : String(err));
    console.error("Error stack:", err instanceof Error ? err.stack : "No stack trace");
    
    const errorMessage = err instanceof Error ? err.message : String(err);
    const errorStack = err instanceof Error ? err.stack : undefined;
    
    // Return detailed error response
    const errorResponse = {
      code: 500,
      message: errorMessage,
      details: errorStack,
      type: err?.constructor?.name || typeof err
    };
    
    console.error("Returning error response:", JSON.stringify(errorResponse, null, 2));
    
    return new Response(
      JSON.stringify(errorResponse), 
      { 
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        }
      }
    );
  }
});

