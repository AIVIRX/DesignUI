//
//  AIPanelView.swift
//  DesignUI
//
//  AI Assistant Panel for UI Editor
//

import SwiftUI

struct AIPanelView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    @StateObject private var aiService = AIService()
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @FocusState private var isInputFocused: Bool
    private let maxMessageLength = 1000 // Character limit for cost/performance optimization
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("AI Assistant")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if aiService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            
            Divider()
            
            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if messages.isEmpty {
                            welcomeView
                        } else {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isTyping {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("AI is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.vertical, 12)
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
            
            // Input Area - iMessage style
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 0) {
                    // Text field container with send button inside
                    HStack(alignment: .bottom, spacing: 8) {
                        // Scrollable text field
                        TextField("Message", text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .lineLimit(1...10)
                            .frame(minHeight: 20)
                            .focused($isInputFocused)
                            .onChange(of: inputText) { oldValue, newValue in
                                // Enforce character limit
                                if newValue.count > maxMessageLength {
                                    inputText = String(newValue.prefix(maxMessageLength))
                                }
                            }
                            .onSubmit {
                                if !inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    sendMessage()
                                }
                            }
                            .disabled(aiService.isLoading)
                        
                        // Send button inside the field
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty || aiService.isLoading ? .gray : .blue)
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || aiService.isLoading)
                        .buttonStyle(.plain)
                        .padding(.leading, 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                    )
                }
                
                // Character count indicator (shows when approaching limit)
                if inputText.count > maxMessageLength * 7 / 10 {
                    HStack {
                        Spacer()
                        Text("\(inputText.count)/\(maxMessageLength)")
                            .font(.caption2)
                            .foregroundColor(inputText.count >= maxMessageLength ? .red : .secondary)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if let error = aiService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .background(.thinMaterial)
    }
    
    private var welcomeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("👋 Hi! I'm your AI assistant")
                .font(.headline)
                .padding(.bottom, 4)
            
            Text("I can help you with:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                QuickActionButton(
                    icon: "sparkles",
                    title: "Generate Component",
                    description: "Describe a component and I'll help you create it"
                ) {
                    inputText = "Help me create a "
                    isInputFocused = true
                }
                
                QuickActionButton(
                    icon: "paintbrush",
                    title: "Design Suggestions",
                    description: "Get design improvements for your current component"
                ) {
                    if let component = selectedComponent {
                        let description = "\(component.type.rawValue) component"
                        inputText = "Suggest design improvements for my \(description)"
                        sendMessage()
                    } else {
                        inputText = "Suggest design improvements for my UI"
                        sendMessage()
                    }
                }
                
                QuickActionButton(
                    icon: "questionmark.circle",
                    title: "Ask Questions",
                    description: "Get help with SwiftUI best practices"
                ) {
                    inputText = "What are best practices for "
                    isInputFocused = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = ChatMessage(role: .user, content: inputText)
        messages.append(userMessage)
        
        let userPrompt = inputText.lowercased()
        inputText = ""
        isTyping = true
        
        Task {
            do {
                let aiMessages = messages.map { message in
                    AIMessage(role: message.role, content: message.content)
                }
                
                // Detect if user wants to generate a component
                // Keywords that suggest component generation
                let componentKeywords = ["create", "build", "make", "generate", "add", "design", "ui", "component", "button", "text", "image", "stack", "list", "todo"]
                let wantsComponent = componentKeywords.contains { keyword in
                    userPrompt.contains(keyword)
                }
                
                let schemaType = wantsComponent ? "component" : "chat"
                
                let response = try await aiService.sendMessage(messages: aiMessages, schemaType: schemaType)
                
                if let content = response.choices.first?.message.content {
                    await MainActor.run {
                        // If it's a component response, try to parse and add to canvas
                        if schemaType == "component" {
                            if let component = parseComponentFromJSON(content) {
                                canvasManager.addComponent(component)
                                selectedComponent = component
                                let aiMessage = ChatMessage(role: .assistant, content: "✅ Component added to canvas!")
                                messages.append(aiMessage)
                            } else {
                                // If parsing fails, show the raw JSON
                                let aiMessage = ChatMessage(role: .assistant, content: "Generated component:\n\(content)")
                                messages.append(aiMessage)
                            }
                        } else {
                            // Regular chat response
                            let aiMessage = ChatMessage(role: .assistant, content: content)
                            messages.append(aiMessage)
                        }
                        isTyping = false
                    }
                }
            } catch {
                await MainActor.run {
                    isTyping = false
                    if let aiError = error as? AIError {
                        aiService.errorMessage = aiError.errorDescription
                    } else {
                        aiService.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }
    
    // MARK: - Component Parsing
    private func parseComponentFromJSON(_ jsonString: String) -> UIComponent? {
        guard let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            // Try parsing if it's already a component object (not wrapped)
            if let jsonData = jsonString.data(using: .utf8),
               let componentDict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                return parseComponent(from: componentDict)
            }
            return nil
        }
        
        // Check if it's wrapped in a "component" key
        if let componentDict = json["component"] as? [String: Any] {
            return parseComponent(from: componentDict)
        } else {
            // Assume the JSON itself is the component
            return parseComponent(from: json)
        }
    }
    
    private func parseComponent(from dict: [String: Any]) -> UIComponent? {
        // Parse component type
        guard let typeString = dict["type"] as? String,
              let componentType = ComponentType(rawValue: typeString) else {
            print("❌ Invalid component type: \(dict["type"] ?? "nil")")
            return nil
        }
        
        // Parse frame
        var frame = CGRect.zero
        if let frameDict = dict["frame"] as? [String: Any] {
            let x = (frameDict["x"] as? Double) ?? 0
            let y = (frameDict["y"] as? Double) ?? 0
            let width = (frameDict["width"] as? Double) ?? 0
            let height = (frameDict["height"] as? Double) ?? 0
            frame = CGRect(x: x, y: y, width: width, height: height)
        }
        
        // Parse properties
        var properties: [ComponentProperty] = []
        if let propertiesDict = dict["properties"] as? [String: Any] {
            properties = parseProperties(from: propertiesDict, for: componentType)
        }
        
        // Parse children recursively
        var children: [UIComponent] = []
        if let childrenArray = dict["children"] as? [[String: Any]] {
            children = childrenArray.compactMap { parseComponent(from: $0) }
        }
        
        // Parse modifiers
        var modifiers: [ComponentModifier] = []
        if let modifiersArray = dict["modifiers"] as? [[String: Any]] {
            modifiers = modifiersArray.compactMap { parseModifier(from: $0) }
        }
        
        let component = UIComponent(
            type: componentType,
            properties: properties,
            children: children,
            frame: frame,
            modifiers: modifiers
        )
        
        return component
    }
    
    private func parseProperties(from dict: [String: Any], for componentType: ComponentType) -> [ComponentProperty] {
        var properties: [ComponentProperty] = []
        
        // Get default properties for this component type
        let defaultProps = UIComponent.defaultProperties(for: componentType)
        
        // Parse each property from the dict
        for (key, value) in dict {
            // Find matching default property to get type info
            if let defaultProp = defaultProps.first(where: { $0.key == key }) {
                let property = ComponentProperty(
                    key: key,
                    displayName: defaultProp.displayName,
                    type: defaultProp.type,
                    value: value,
                    defaultValue: defaultProp.defaultValue
                )
                properties.append(property)
            } else {
                // Create a new property with inferred type
                let propertyType: PropertyType = inferPropertyType(from: value)
                let property = ComponentProperty(
                    key: key,
                    displayName: ComponentProperty.properDisplayName(for: key),
                    type: propertyType,
                    value: value,
                    defaultValue: value
                )
                properties.append(property)
            }
        }
        
        // Add any default properties that weren't in the dict
        for defaultProp in defaultProps {
            if !properties.contains(where: { $0.key == defaultProp.key }) {
                properties.append(defaultProp)
            }
        }
        
        return properties
    }
    
    private func inferPropertyType(from value: Any) -> PropertyType {
        if value is String {
            // Check if it's a color string
            if let colorString = value as? String,
               (colorString.hasPrefix("rgb") || ["primary", "secondary", "blue", "red", "green", "black", "white"].contains(colorString.lowercased())) {
                return .color
            }
            return .string
        } else if value is Int || value is Double {
            return .number
        } else if value is Bool {
            return .boolean
        }
        return .string
    }
    
    private func parseModifier(from dict: [String: Any]) -> ComponentModifier? {
        guard let typeString = dict["type"] as? String,
              let modifierType = ModifierType(rawValue: typeString) else {
            return nil
        }
        
        var properties: [String: Any] = [:]
        if let propertiesDict = dict["properties"] as? [String: Any] {
            properties = propertiesDict
        }
        
        return ComponentModifier(type: modifierType, properties: properties)
    }
}

// MARK: - Supporting Views

struct ChatBubble: View {
    let message: ChatMessage
    @State private var displayedText: String = ""
    @State private var typingTask: Task<Void, Never>?
    @State private var hasTyped = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role == .user ? message.content : displayedText)
                    .font(.system(size: 13))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        message.role == .user
                            ? Color.blue
                            : Color.secondary.opacity(0.1)
                    )
                    .cornerRadius(12)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal, 16)
        .onAppear {
            if message.role == .assistant && !hasTyped {
                startTypingEffect()
            } else if message.role == .user {
                displayedText = message.content
            }
        }
        .onDisappear {
            typingTask?.cancel()
        }
    }
    
    private func startTypingEffect() {
        guard !hasTyped else { return }
        typingTask?.cancel()
        displayedText = ""
        hasTyped = true
        
        let fullText = message.content
        let characters = Array(fullText)
        var currentIndex = 0
        
        typingTask = Task {
            while currentIndex < characters.count {
                // Check if task was cancelled
                if Task.isCancelled {
                    break
                }
                
                // Add next character(s) - can adjust speed here
                let chunkSize = 1 // Characters per update (increase for faster typing)
                let endIndex = min(currentIndex + chunkSize, characters.count)
                let chunk = String(characters[currentIndex..<endIndex])
                
                await MainActor.run {
                    displayedText += chunk
                }
                
                currentIndex = endIndex
                
                // Delay between characters (adjust for speed: lower = faster)
                // 20ms per character = ~50 chars/sec
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Chat Message Model

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp = Date()
}

