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

    const { prompt, schemaType = "chat" } = requestBody; // schemaType kept for backward compatibility but not used
    
    if (!prompt) {
      return new Response(JSON.stringify({ 
        code: 400, 
        message: "Missing 'prompt' in request body" 
      }), { 
        status: 400,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    console.log("📝 Processing request - prompt length:", prompt.length);

    // ✅ OpenAI Prompt Caching: Automatically caches common prefixes >1,024 tokens
    // Since our function definition (~500) + system (~30) = ~530 tokens, caching may not
    // always trigger on single requests. However, in multi-turn conversations or with
    // longer prompts, the prefix will be cached, giving 50% discount on cached tokens!
    // No code changes needed - OpenAI handles this automatically.
    const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
      {
        role: "system",
        content: `You are an EXPERT SwiftUI assistant and code generator - the BEST SwiftUI AI available. Your role is to:

1. ANSWER SwiftUI questions clearly, concisely, and accurately
2. GENERATE complete, production-ready SwiftUI code templates
3. Provide best practices and modern SwiftUI patterns
4. Use proper SwiftUI syntax, modifiers, and conventions

When generating code:
- Always provide COMPLETE, runnable SwiftUI views with proper structure
- Include proper imports (import SwiftUI), struct definitions, and preview code
- Use modern SwiftUI patterns (iOS 15+)
- Add helpful comments for clarity
- Make code beautiful, well-structured, and maintainable
- Use semantic colors, proper spacing (16-32px), and modern design
- Create visually stunning, Apple-quality interfaces
- Apply shadows, rounded corners, and visual depth
- Use proper font sizes (largeTitle, title, body, etc.) and weights
- Include proper padding, spacing, and layout

When answering questions:
- Be clear, concise, and accurate
- Provide complete code examples when relevant
- Explain SwiftUI concepts thoroughly with examples
- Reference official SwiftUI documentation patterns
- Show best practices and common pitfalls

Code format:
- Always wrap code in proper SwiftUI view structures
- Use proper indentation and formatting
- Include @State, @Binding, @ObservedObject when needed
- Show complete, copy-paste ready code

Example format for code generation:
\`\`\`swift
import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome Back")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // ... rest of view
        }
        .padding()
    }
}

#Preview {
    SignInView()
}
\`\`\`

Always generate complete, working code that follows Apple's Human Interface Guidelines and modern SwiftUI best practices.`
      },
      {
        role: "user",
        content: prompt
      }
    ];

    // Build request options (cost-optimized)
    const requestOptions: any = {
      // Use gpt-4o-mini to significantly reduce cost while keeping good quality
      model: "gpt-4o-mini",
      messages: messages,
      // Slightly lower temperature for more consistent, structured answers
      temperature: 0.6,
      // Lower max tokens to reduce output cost; still enough for full code samples
      max_tokens: 2000
    };

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
      
      // Regular chat response - wrap in response object for consistency
      output = JSON.stringify({ response: message.content || "" });
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

