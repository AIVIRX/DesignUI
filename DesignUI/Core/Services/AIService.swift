//
//  AIService.swift
//  DesignUI
//
//  Created for AI Panel integration
//

import Foundation
import Supabase

@MainActor
class AIService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    /// Send a message to ChatGPT via Supabase Edge Function
    func sendMessage(
        messages: [AIMessage],
        model: String = "gpt-4o-mini",
        temperature: Double = 0.7,
        maxTokens: Int = 1000,
        schemaType: String = "chat" // "chat" or "component"
    ) async throws -> AIResponse {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Check if user is authenticated first
            guard let currentUser = supabase.auth.currentUser else {
                print("❌ No authenticated user found")
                throw AIError.unauthorized
            }
            
            // Get the current user's session token
            // Note: autoRefreshToken is enabled in SupabaseManager, so tokens refresh automatically
            let session = try await supabase.auth.session
            let accessToken = session.accessToken
            
            print("✅ User authenticated: \(currentUser.id.uuidString.prefix(8))...")
            print("🔑 Token preview: \(accessToken.prefix(20))...")
            
            // Convert messages to a single prompt (combining conversation history)
            // Format: System messages first, then user/assistant conversation
            var promptParts: [String] = []
            var conversationParts: [String] = []
            
            for message in messages {
                switch message.role {
                case .system:
                    promptParts.append(message.content)
                case .user:
                    conversationParts.append("User: \(message.content)")
                case .assistant:
                    conversationParts.append("Assistant: \(message.content)")
                }
            }
            
            // Combine into final prompt
            var finalPrompt = promptParts.joined(separator: "\n\n")
            if !conversationParts.isEmpty {
                if !finalPrompt.isEmpty {
                    finalPrompt += "\n\n"
                }
                finalPrompt += conversationParts.joined(separator: "\n\n")
            }
            
            // Schema is cached on server - just send the type
            struct RequestBody: Encodable {
                let prompt: String
                let schemaType: String // "chat" or "component"
            }
            
            let requestBody = RequestBody(
                prompt: finalPrompt,
                schemaType: schemaType // Use provided schema type (chat or component)
            )
            
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(requestBody)
            
            // Call the Supabase Edge Function (StudioAI) using HTTP directly
            // Note: Using URLSession because functions.invoke returns void in this Supabase client version
            let supabaseURL = URL(string: "https://dwxfipenxnqkhgtwggrv.supabase.co")!
            let functionURL = supabaseURL.appendingPathComponent("functions/v1/StudioAI")
            
            var request = URLRequest(url: functionURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // Add Supabase anon key as apikey header (required for edge functions)
            let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eGZpcGVueG5xa2hndHdnZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwNjU4OTMsImV4cCI6MjA0MzY0MTg5M30.0mg37FPNXhj0drM0TFSlSzpl2Ofc7nyaHqOTnobvjac"
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.httpBody = bodyData
            
            print("📤 Sending request to: \(functionURL.absoluteString)")
            print("📤 Request body size: \(bodyData.count) bytes")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            print("📥 Received response: \(data.count) bytes")
            
            // Check for HTTP errors
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response type")
                throw AIError.networkError
            }
            
            if httpResponse.statusCode >= 400 {
                var errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Edge function error (\(httpResponse.statusCode)): \(errorMessage)")
                
                // Try to parse error JSON if available
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? String {
                    errorMessage = error
                }
                
                if httpResponse.statusCode == 401 {
                    throw AIError.unauthorized
                } else {
                    throw AIError.networkError
                }
            }
            
            // Parse response from your edge function format
            struct EdgeFunctionResponse: Codable {
                let user_id: String
                let output: String
            }
            
            let decoder = JSONDecoder()
            let edgeResponse = try decoder.decode(EdgeFunctionResponse.self, from: data)
            
            // Parse the output - it might be a JSON string with {"response": "..."} or just the content
            var messageContent = edgeResponse.output
            
            // Try to parse as JSON first (for chat responses)
            if let jsonData = edgeResponse.output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
               let response = json["response"] as? String {
                messageContent = response
            }
            // Otherwise, use output directly (for function call responses)
            
            // Convert to AIResponse format for compatibility
            let aiMessage = AIMessage(role: .assistant, content: messageContent)
            let aiChoice = AIChoice(index: 0, message: aiMessage, finishReason: "stop")
            let aiResponse = AIResponse(
                id: UUID().uuidString,
                object: "chat.completion",
                created: Int(Date().timeIntervalSince1970),
                model: model,
                choices: [aiChoice],
                usage: nil
            )
            
            return aiResponse
        } catch let error as DecodingError {
            // Better error handling for decoding errors
            let errorMsg: String
            switch error {
            case .typeMismatch(let type, let context):
                errorMsg = "Type mismatch: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .valueNotFound(let type, let context):
                errorMsg = "Value not found: \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .keyNotFound(let key, let context):
                errorMsg = "Key not found: \(key.stringValue) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
            case .dataCorrupted(let context):
                errorMsg = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                errorMsg = "Decoding error: \(error.localizedDescription)"
            }
            print("❌ Decoding error: \(errorMsg)")
            errorMessage = "Failed to parse response: \(errorMsg)"
            throw AIError.invalidResponse
        } catch {
            print("❌ Network/Auth error: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Get the JSON schema for component generation
    private func getComponentSchema() -> [String: Any] {
        return [
            "type": "object",
            "properties": [
                "component": [
                    "type": "object",
                    "description": "A SwiftUI component structure",
                    "properties": [
                        "type": [
                            "type": "string",
                            "enum": ["Text", "Image", "Button", "VStack", "HStack", "ZStack", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "List", "ScrollView", "SF Symbol"],
                            "description": "The type of SwiftUI component"
                        ],
                        "properties": [
                            "type": "object",
                            "description": "Component properties as key-value pairs",
                            "additionalProperties": true,
                            "properties": [
                                "text": ["type": "string", "description": "Text content for Text components"],
                                "foregroundColor": ["type": "string", "description": "Text color: 'primary', 'secondary', 'blue', 'red', 'green', etc., or 'rgb(r,g,b)' or 'rgba(r,g,b,a)'"],
                                "alignment": ["type": "string", "enum": ["leading", "center", "trailing"], "description": "Text alignment"],
                                "spacing": ["type": "number", "description": "Spacing for stacks (default: 8)"],
                                "imageName": ["type": "string", "description": "SF Symbol name (e.g., 'star.fill', 'heart')"],
                                "backgroundColor": ["type": "string", "description": "Background color"],
                                "width": ["type": "number", "description": "Component width"],
                                "height": ["type": "number", "description": "Component height"]
                            ]
                        ],
                        "frame": [
                            "type": "object",
                            "description": "Component position and size",
                            "properties": [
                                "x": ["type": "number", "description": "X position (default: 0)"],
                                "y": ["type": "number", "description": "Y position (default: 0)"],
                                "width": ["type": "number", "description": "Width (0 means auto-size)"],
                                "height": ["type": "number", "description": "Height (0 means auto-size)"]
                            ]
                        ],
                        "children": [
                            "type": "array",
                            "description": "Nested child components (for containers like VStack, HStack, ZStack)",
                            "items": ["$ref": "#/properties/component"]
                        ],
                        "modifiers": [
                            "type": "array",
                            "description": "Component modifiers (optional)",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "type": ["type": "string", "enum": ["background", "foregroundColor", "font", "fontSize", "padding", "cornerRadius", "shadow", "border", "opacity", "rotation", "scale", "offset"], "description": "Modifier type"],
                                    "properties": [
                                        "type": "object",
                                        "additionalProperties": true,
                                        "description": "Modifier-specific properties"
                                    ]
                                ]
                            ]
                        ]
                    ],
                    "required": ["type"]
                ]
            ],
            "required": ["component"]
        ]
    }
    
    /// Get the JSON schema for chat responses
    private func getChatSchema() -> [String: Any] {
        return [
            "type": "object",
            "properties": [
                "response": [
                    "type": "string",
                    "description": "The AI assistant's helpful response to the user"
                ]
            ],
            "required": ["response"]
        ]
    }
    
    /// Generate UI component suggestions based on a description
    func generateComponentSuggestion(description: String) async throws -> String {
        let systemPrompt = """
        You are a SwiftUI expert assistant. Help users create UI components by providing:
        1. Clear, concise suggestions
        2. SwiftUI best practices
        3. Code examples when helpful
        4. Component structure recommendations
        
        Keep responses focused and actionable.
        """
        
        let messages = [
            AIMessage(role: .system, content: systemPrompt),
            AIMessage(role: .user, content: description)
        ]
        
        let response = try await sendMessage(messages: messages, maxTokens: 500)
        return response.choices.first?.message.content ?? "No response generated"
    }
    
    /// Generate a UI component structure from a description
    func generateComponent(description: String) async throws -> [String: Any]? {
        let systemPrompt = """
        You are a SwiftUI FULL VIEW/TEMPLATE generator. When users request views, screens, pages, or templates, generate COMPLETE, FULL-SCREEN view structures.
        Always return an array of components (use "components" key). For full views, return a single root VStack/HStack/ZStack with all child components nested inside.
        The root container should have full-screen dimensions (width: 350-400, height: 600-900 for mobile).
        Include EVERY component mentioned in the user's request. Use proper spacing, padding, and alignment.
        Generate COMPLETE TEMPLATES, not individual components. Every view should be a full, usable screen.
        """
        
        let messages = [
            AIMessage(role: .system, content: systemPrompt),
            AIMessage(role: .user, content: "Generate a SwiftUI component for: \(description)")
        ]
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Check if user is authenticated first
            guard let currentUser = supabase.auth.currentUser else {
                print("❌ No authenticated user found")
                throw AIError.unauthorized
            }
            
            // Get the current user's session token
            // Note: autoRefreshToken is enabled in SupabaseManager, so tokens refresh automatically
            let session = try await supabase.auth.session
            let accessToken = session.accessToken
            
            print("✅ User authenticated: \(currentUser.id.uuidString.prefix(8))...")
            
            // Format prompt - schema is cached on server, just send the type
            let prompt = messages.map { message in
                let rolePrefix = message.role == .system ? "System: " : 
                                message.role == .user ? "User: " : "Assistant: "
                return "\(rolePrefix)\(message.content)"
            }.joined(separator: "\n\n")
            
            struct RequestBody: Encodable {
                let prompt: String
                let schemaType: String // Just send "component" or "chat" instead of full schema
            }
            
            let requestBody = RequestBody(
                prompt: prompt,
                schemaType: "component" // Server will use cached component schema
            )
            
            let encoder = JSONEncoder()
            let bodyData = try encoder.encode(requestBody)
            
            // Call the Supabase Edge Function (StudioAI) using HTTP directly
            // Note: Using URLSession because functions.invoke returns void in this Supabase client version
            let supabaseURL = URL(string: "https://dwxfipenxnqkhgtwggrv.supabase.co")!
            let functionURL = supabaseURL.appendingPathComponent("functions/v1/StudioAI")
            
            var request = URLRequest(url: functionURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            // Add Supabase anon key as apikey header (required for edge functions)
            let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eGZpcGVueG5xa2hndHdnZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwNjU4OTMsImV4cCI6MjA0MzY0MTg5M30.0mg37FPNXhj0drM0TFSlSzpl2Ofc7nyaHqOTnobvjac"
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.httpBody = bodyData
            
            let (data, httpResponse) = try await URLSession.shared.data(for: request)
            
            // Check for HTTP errors
            if let httpResponse = httpResponse as? HTTPURLResponse,
               httpResponse.statusCode >= 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ Edge function error (\(httpResponse.statusCode)): \(errorMessage)")
                throw AIError.networkError
            }
            
            struct EdgeFunctionResponse: Codable {
                let user_id: String
                let output: String
            }
            
            let decoder = JSONDecoder()
            let edgeResponse = try decoder.decode(EdgeFunctionResponse.self, from: data)
            
            // Try to parse the JSON output to extract components
            if let jsonData = edgeResponse.output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                // New format: components array
                if let componentsArray = json["components"] as? [[String: Any]], !componentsArray.isEmpty {
                    // Return the first component (for full views, there's typically one root component)
                    return componentsArray[0]
                }
                // Old format: single component (for backward compatibility)
                else if let component = json["component"] as? [String: Any] {
                    return component
                }
            }
            
            return nil
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Get design suggestions for the current canvas
    func getDesignSuggestions(componentDescription: String) async throws -> String {
        let systemPrompt = """
        You are a UI/UX design expert. Analyze the user's component description and provide:
        1. Design improvement suggestions
        2. Accessibility recommendations
        3. Best practices for the component type
        4. Color and spacing recommendations
        
        Be concise and actionable.
        """
        
        let messages = [
            AIMessage(role: .system, content: systemPrompt),
            AIMessage(role: .user, content: "Component: \(componentDescription)")
        ]
        
        let response = try await sendMessage(messages: messages, maxTokens: 600)
        return response.choices.first?.message.content ?? "No suggestions available"
    }
}

// MARK: - Data Models

struct AIMessage: Codable {
    let role: MessageRole
    let content: String
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

struct AIResponse: Codable {
    let id: String
    let object: String
    let created: Int
    let model: String
    let choices: [AIChoice]
    let usage: AIUsage?
}

struct AIChoice: Codable {
    let index: Int
    let message: AIMessage
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct AIUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

enum AIError: LocalizedError {
    case unauthorized
    case invalidResponse
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "You must be signed in to use AI features"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError:
            return "Network error. Please check your connection"
        }
    }
}

