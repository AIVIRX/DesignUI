//
//  SwiftUIAssistantView.swift
//  DesignUI
//
//  SwiftUI AI Assistant - Answers questions and generates SwiftUI code
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

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
                ToolbarItem(placement: .navigationBarTrailing) {
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
                
                ForEach(message.segments) { segment in
                    switch segment.type {
                    case .text(let text):
                        Text(text)
                            .padding(12)
                            .background(isUser ? Color.blue : Color.gray.opacity(0.15))
                            .foregroundColor(isUser ? .white : .primary)
                            .cornerRadius(16)
                            .textSelection(.enabled)
                    case .code(let code, _):
                        CodeSnippetView(code: code)
                    }
                }
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

// MARK: - Message Segments & Helpers
struct MessageSegment: Identifiable {
    let id = UUID()
    let type: SegmentType
    
    enum SegmentType {
        case text(String)
        case code(String, language: String?)
    }
    
    static func parse(from text: String) -> [MessageSegment] {
        var segments: [MessageSegment] = []
        let parts = text.components(separatedBy: "```")
        
        for (index, part) in parts.enumerated() {
            if index % 2 == 0 {
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    segments.append(MessageSegment(type: .text(trimmed)))
                }
            } else {
                var codePart = part
                var language: String? = nil
                
                if let newlineRange = codePart.range(of: "\n") {
                    let firstLine = String(codePart[..<newlineRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let remainder = String(codePart[newlineRange.upperBound...])
                    if !firstLine.isEmpty, firstLine.rangeOfCharacter(from: .letters) != nil {
                        language = firstLine
                        codePart = remainder
                    }
                }
                
                let code = codePart.trimmingCharacters(in: .whitespacesAndNewlines)
                if !code.isEmpty {
                    segments.append(MessageSegment(type: .code(code, language: language)))
                }
            }
        }
        
        if segments.isEmpty {
            segments.append(MessageSegment(type: .text(text)))
        }
        
        return segments
    }
}

extension ChatMessage {
    var segments: [MessageSegment] {
        MessageSegment.parse(from: content)
    }
}

// MARK: - Code Snippet View
struct CodeSnippetView: View {
    let code: String
    @State private var didCopy = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(.horizontal, showsIndicators: true) {
                ScrollView {
                    Text(highlightedCode)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
            .background(Color.black.opacity(0.9))
            .cornerRadius(14)
            
            Button(action: copyToClipboard) {
                Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .padding(8)
                    .background(Color.white.opacity(0.15))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
            }
        }
    }
    
    private func copyToClipboard() {
#if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(code, forType: .string)
#else
        UIPasteboard.general.string = code
#endif
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            didCopy = false
        }
    }
    
    private var highlightedCode: AttributedString {
        var attributed = AttributedString(code)
        let keywords = [
            "struct", "var", "let", "func", "import", "body", "some", "View",
            "@State", "@Binding", "@ObservedObject", "@Environment", "VStack", "HStack",
            "ZStack", "Button", "Text", "Spacer", "NavigationStack", "ScrollView"
        ]
        
        for keyword in keywords {
            var searchRange = attributed.startIndex..<attributed.endIndex
            while let range = attributed.range(of: keyword, options: .caseInsensitive, range: searchRange) {
                attributed[range].foregroundColor = .keywordBlue
                attributed[range].font = .system(size: 15, weight: .semibold, design: .monospaced)
                searchRange = range.upperBound..<attributed.endIndex
            }
        }
        
        // Highlight string literals
        var stringRange = attributed.startIndex..<attributed.endIndex
        while let start = attributed[stringRange].firstIndex(of: "\"") {
            let afterStart = attributed.index(after: start)
            if let end = attributed[afterStart...].firstIndex(of: "\"") {
                let range = start...end
                attributed[range].foregroundColor = .stringOrange
                attributed[range].font = .system(size: 15, weight: .regular, design: .monospaced)
                stringRange = attributed.index(after: end)..<attributed.endIndex
            } else {
                break
            }
        }
        
        return attributed
    }
}

#Preview {
    SwiftUIAssistantView()
}

// MARK: - Color helpers
private extension Color {
    static let keywordBlue = Color(red: 0.3, green: 0.7, blue: 1.0)
    static let stringOrange = Color(red: 1.0, green: 0.65, blue: 0.2)
}

