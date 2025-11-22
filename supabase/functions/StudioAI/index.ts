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
    description: "Generate a SwiftUI component structure based on user description",
    parameters: {
      type: "object",
      properties: {
        component: {
          type: "object",
          description: "A SwiftUI component structure",
          properties: {
            type: {
              type: "string",
              enum: ["Text", "Image", "Button", "VStack", "HStack", "ZStack", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "List", "ScrollView", "SF Symbol"],
              description: "The type of SwiftUI component"
            },
            properties: {
              type: "object",
              description: "Component properties as key-value pairs",
              additionalProperties: true,
              properties: {
                text: { type: "string", description: "Text content for Text components" },
                fontSize: { type: "number", description: "Font size (default: 17)" },
                fontWeight: { type: "string", enum: ["regular", "medium", "semibold", "bold"], description: "Font weight" },
                foregroundColor: { type: "string", description: "Text color: 'primary', 'secondary', 'blue', 'red', 'green', etc., or 'rgb(r,g,b)' or 'rgba(r,g,b,a)'" },
                alignment: { type: "string", enum: ["leading", "center", "trailing"], description: "Text alignment" },
                spacing: { type: "number", description: "Spacing for stacks (default: 8)" },
                imageName: { type: "string", description: "SF Symbol name (e.g., 'star.fill', 'heart')" },
                cornerRadius: { type: "number", description: "Corner radius for rounded shapes" },
                backgroundColor: { type: "string", description: "Background color" },
                width: { type: "number", description: "Component width" },
                height: { type: "number", description: "Component height" }
              }
            },
            frame: {
              type: "object",
              description: "Component position and size",
              properties: {
                x: { type: "number", description: "X position (default: 0)" },
                y: { type: "number", description: "Y position (default: 0)" },
                width: { type: "number", description: "Width (0 means auto-size)" },
                height: { type: "number", description: "Height (0 means auto-size)" }
              }
            },
            children: {
              type: "array",
              description: "Nested child components (for containers like VStack, HStack, ZStack)",
              items: { $ref: "#/properties/component" }
            },
            modifiers: {
              type: "array",
              description: "Component modifiers (optional)",
              items: {
                type: "object",
                properties: {
                  type: { type: "string", enum: ["background", "foregroundColor", "padding", "cornerRadius", "shadow", "border", "opacity", "rotation", "scale", "offset"], description: "Modifier type" },
                  properties: {
                    type: "object",
                    additionalProperties: true,
                    description: "Modifier-specific properties"
                  }
                }
              }
            }
          },
          required: ["type"]
        }
      },
      required: ["component"]
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
          ? `You are a SwiftUI FULL VIEW/TEMPLATE generator. When users request views, screens, or templates, generate COMPLETE, FULL-SCREEN view structures with ALL necessary components.

CRITICAL REQUIREMENTS:
- ALWAYS create a root VStack, HStack, or ZStack that represents the ENTIRE view/screen
- The root container should have full-screen dimensions (width: 350-400, height: 600-900 for mobile views)
- Include EVERY component mentioned in the user's request (buttons, text fields, images, etc.)
- Use proper nesting: root container → child components → nested children
- For "sign in view", include: title, subtitle, all buttons, input fields, dividers, spacing
- For "profile view", include: avatar, name, bio, all buttons, sections
- For "settings view", include: header, all options, sections, dividers
- Set appropriate spacing (20-30 for main sections, 8-16 for related items)
- Use center alignment for full views
- Add padding to root container (20-30px)
- Make it look like a COMPLETE, PRODUCTION-READY screen

Example for "sign in view with sign in with apple button":
Root: VStack (spacing: 24, alignment: center, padding: 30)
  - Text: "Sign In" (title, large, bold)
  - Text: "Welcome back" (subtitle, secondary color)
  - Spacer (flexible)
  - Button: "Sign in with Apple" (full width, styled)
  - Button: "Sign in with Email" (full width, styled)
  - Divider with "or" text
  - Text: "Don't have an account? Sign up" (footer)
  - Spacer (flexible)

Generate COMPLETE TEMPLATES, not individual components. Every view should be a full, usable screen.`
          : "You are a helpful SwiftUI assistant. Provide clear, concise answers about SwiftUI development."
      },
      {
        role: "user",
        content: prompt
      }
    ];

    // Build request options - use type assertion to allow tools property
    const baseOptions = {
      model: "gpt-4o-mini",
      messages: messages,
      temperature: 0.7,
      max_tokens: 2000
    };

    // Add function calling for component generation
    const requestOptions: any = schemaType === "component" 
      ? {
          ...baseOptions,
          tools: [
            {
              type: "function",
              function: FUNCTIONS[0]
            }
          ],
          tool_choice: { type: "function", function: { name: "generate_swiftui_component" } }
        }
      : baseOptions;

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

