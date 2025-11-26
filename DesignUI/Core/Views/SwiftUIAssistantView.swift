//
//  SwiftUIAssistantView.swift
//  DesignUI
//
//  SwiftUI AI Assistant - Answers questions and generates SwiftUI code
//

import SwiftUI

struct SwiftUIAssistantView: View {
    @StateObject private var aiService = AIService()
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isGenerating: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if messages.isEmpty {
                                welcomeView
                            } else {
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if isGenerating {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Thinking...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input area
                inputArea
            }
            .navigationTitle("SwiftUI Assistant")
            .toolbar {
                ToolbarItem {
                    Button {
                        messages.removeAll()
                        inputText = ""
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
    
    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("SwiftUI Assistant")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Ask me anything about SwiftUI or request code templates!")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                ExamplePrompt(text: "How do I create a custom button style?") {
                    sendMessage("How do I create a custom button style?")
                }
                
                ExamplePrompt(text: "Generate a sign in view with email and password") {
                    sendMessage("Generate a sign in view with email and password")
                }
                
                ExamplePrompt(text: "Show me how to use @State and @Binding") {
                    sendMessage("Show me how to use @State and @Binding")
                }
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Ask about SwiftUI or request code...", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .focused($isInputFocused)
                .onSubmit {
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        sendMessage(inputText)
                    }
                }
            
            Button {
                if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sendMessage(inputText)
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.isEmpty ? .gray : .blue)
            }
            .disabled(inputText.isEmpty || isGenerating)
        }
        .padding()
    }
    
    private func sendMessage(_ text: String) {
        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        isInputFocused = false
        isGenerating = true
        
        Task {
            do {
                // Build conversation history
                var conversationMessages: [AIMessage] = [
                    AIMessage(role: .system, content: systemPrompt)
                ]
                
                // Add previous messages (last 10 for context)
                let recentMessages = messages.suffix(10)
                for msg in recentMessages {
                    let role: MessageRole = msg.role == .user ? .user : .assistant
                    conversationMessages.append(AIMessage(role: role, content: msg.content))
                }
                
                let response = try await aiService.sendMessage(
                    messages: conversationMessages,
                    schemaType: "chat"
                )
                
                if let content = response.choices.first?.message.content {
                    await MainActor.run {
                        let assistantMessage = ChatMessage(role: .assistant, content: content)
                        messages.append(assistantMessage)
                        isGenerating = false
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(
                        role: .assistant,
                        content: "❌ Error: \(error.localizedDescription)"
                    )
                    messages.append(errorMessage)
                    isGenerating = false
                }
            }
        }
    }
    
    private var systemPrompt: String {
        """
        You are an expert SwiftUI assistant and code generator. Your role is to:
        
        1. ANSWER SwiftUI questions clearly and concisely
        2. GENERATE complete, production-ready SwiftUI code templates
        3. Provide best practices and modern SwiftUI patterns
        4. Use proper SwiftUI syntax, modifiers, and conventions
        
        When generating code:
        - Always provide COMPLETE, runnable SwiftUI views
        - Include proper imports, struct definitions, and preview code
        - Use modern SwiftUI patterns (iOS 15+)
        - Add comments for clarity
        - Make code beautiful and well-structured
        - Use semantic colors, proper spacing, and modern design
        
        When answering questions:
        - Be clear and concise
        - Provide code examples when relevant
        - Explain SwiftUI concepts thoroughly
        - Reference official SwiftUI documentation patterns
        
        Format code blocks with proper Swift syntax. Always generate complete, working code.
        """
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

struct MessageBubble: View {
    let message: ChatMessage
    @Environment(\.colorScheme) var colorScheme
    
    var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack {
            if isUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Assistant")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(message.content)
                    .padding(12)
                    .background(isUser ? Color.blue : Color.gray.opacity(0.15))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(16)
                    .textSelection(.enabled)
            }
            
            if !isUser {
                Spacer(minLength: 50)
            }
        }
    }
}

struct ExamplePrompt: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.12))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SwiftUIAssistantView()
}

