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
    private let maxMessageLength = 5000
    
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
            
            // Selected Component Indicator
            if let selected = selectedComponent {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                        .foregroundColor(.accentColor)
                    Text("Selected: \(selected.type.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let textProp = selected.properties.first(where: { $0.key == "text" }),
                       let text = textProp.value as? String {
                        Text("\"\(text.prefix(20))...\"")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            }
            
            // Input Area - iMessage style
            VStack(spacing: 4) {
                HStack(alignment: .bottom, spacing: 0) {
                    // Text field container with send button inside
                    HStack(alignment: .bottom, spacing: 8) {
                        // Scrollable text field
                        TextField("Describe what you want...", text: $inputText, axis: .vertical)
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
        
        let userPromptText = inputText
        inputText = ""
        isTyping = true
        
        Task {
            do {
                var aiMessages: [AIMessage] = []
                
                // 1. Build System Prompt with Design Context and Selected Component
                let canvasJSON = canvasManager.getDesignAsJSON()
                
                // Build selected component context
                var selectedContext = ""
                if let selected = selectedComponent {
                    var props: [String] = []
                    for prop in selected.properties {
                        if let strVal = prop.value as? String {
                            props.append("\(prop.key): \"\(strVal)\"")
                        }
                    }
                    selectedContext = """
                    
                    CURRENTLY SELECTED COMPONENT:
                    - ID: "\(selected.id.uuidString)"
                    - Type: \(selected.type.rawValue)
                    \(props.isEmpty ? "" : "- Properties: \(props.joined(separator: ", "))")
                    
                    When user says "this", "it", "the selected", or "current", they mean this component. Use its exact ID for updates.
                    """
                }
                
                let systemPrompt = """
                You are a SwiftUI Design Assistant for DesignUI Studio.
                
                ACTIONS:
                - "add": Add new components to canvas.
                - "update": Modify existing components. Use the EXACT "id" UUID from the design.
                - "replace": Create a completely new view (replaces entire canvas).
                - "chat": Simple text response only.
                
                ⚠️ CRITICAL - ONLY USE THESE COMPONENT TYPES (exact spelling required):
                "Text", "Image", "Button", "VStack", "HStack", "ZStack", "Spacer", "Divider", "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse", "ScrollView", "SF Symbol", "Text Field", "Toggle", "Slider", "LazyVGrid"
                
                ❌ DO NOT USE: List, ForEach, NavigationView, TabView, Form, or any other SwiftUI views not listed above.
                
                COMPONENT STRUCTURE:
                {
                  "type": "VStack",
                  "properties": { "spacing": 10, "alignment": "leading" },
                  "children": [...],
                  "modifiers": [
                    { "type": "Background", "properties": { "color": "blue" } },
                    { "type": "Padding", "properties": { "amount": 16, "location": "all" } },
                    { "type": "Corner Radius", "properties": { "radius": 12 } }
                  ]
                }
                
                Text properties: { "text": "Hello World" }
                Button properties: { "title": "Click Me", "backgroundColor": "blue" }
                Image properties: { "systemName": "star.fill" } (use SF Symbols)
                SF Symbol properties: { "symbolName": "star.fill" }
                \(selectedContext)
                
                CURRENT DESIGN:
                \(canvasJSON)
                
                RESPONSE FORMAT (JSON only):
                {
                  "action": "add" | "update" | "replace" | "chat",
                  "message": "Explain changes",
                  "components": [...]
                }
                """
                
                aiMessages.append(AIMessage(role: .system, content: systemPrompt))
                
                // 2. Add Conversation History
                aiMessages.append(contentsOf: messages.map { message in
                    AIMessage(role: message.role, content: message.content)
                })
                
                // Determine if we should use component schema based on intent
                let componentKeywords = ["create", "build", "make", "generate", "add", "design", "ui", "change", "update", "red", "blue", "screen", "page", "dummy", "data", "text", "title", "color", "button", "background"]
                let likelyNeedsComponent = componentKeywords.contains { userPromptText.lowercased().contains($0) }
                
                let schemaType = likelyNeedsComponent ? "component" : "chat"
                print("🤖 AI Request - Schema: \(schemaType), Prompt: \(userPromptText.prefix(50))...")
                let response = try await aiService.sendMessage(messages: aiMessages, schemaType: schemaType)
                
                if let content = response.choices.first?.message.content {
                    print("🤖 AI Response: \(content.prefix(500))...")
                    await MainActor.run {
                        handleAIResponse(content)
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
    
    private func handleAIResponse(_ content: String) {
        // First, check if it's a simple chat response wrapped in {"response": "..."}
        if let jsonData = content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let response = json["response"] as? String,
           json["action"] == nil {
            // This is a plain chat response from the old format
            messages.append(ChatMessage(role: .assistant, content: response))
            return
        }
        
        // Try to parse as our intelligent JSON structure
        guard let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            // Plain text fallback
            messages.append(ChatMessage(role: .assistant, content: content))
            return
        }
        
        let action = (json["action"] as? String)?.lowercased() ?? "chat"
        let message = json["message"] as? String ?? ""
        
        if action == "chat" {
            messages.append(ChatMessage(role: .assistant, content: message.isEmpty ? content : message))
        } else {
            // Parse components
            var parsedComponents: [UIComponent] = []
            if let componentsArray = json["components"] as? [[String: Any]] {
                parsedComponents = componentsArray.compactMap { parseComponent(from: $0) }
            } else if let componentDict = json["component"] as? [String: Any],
                      let component = parseComponent(from: componentDict) {
                parsedComponents = [component]
            }
            
            switch action {
            case "add":
                for comp in parsedComponents {
                    canvasManager.addComponent(comp)
                }
                messages.append(ChatMessage(role: .assistant, content: "✅ Added: \(message)"))
                if let last = parsedComponents.last { selectedComponent = last }
                
            case "update":
                // For updates, we need to match by ID and apply changes to existing components
                if let componentsArray = json["components"] as? [[String: Any]] {
                    applyUpdatesToExistingComponents(componentsArray)
                }
                messages.append(ChatMessage(role: .assistant, content: "✨ Updated: \(message)"))
                
            case "replace":
                print("📱 Replacing design with \(parsedComponents.count) components")
                if parsedComponents.isEmpty {
                    messages.append(ChatMessage(role: .assistant, content: "⚠️ No valid components were parsed. The AI may have used unsupported component types."))
                } else {
                    canvasManager.replaceDesign(with: parsedComponents)
                    messages.append(ChatMessage(role: .assistant, content: "📱 Created: \(message) (\(parsedComponents.count) components)"))
                    if let last = parsedComponents.last { selectedComponent = last }
                }
                
            default:
                messages.append(ChatMessage(role: .assistant, content: message.isEmpty ? content : message))
            }
        }
    }
    
    /// Apply updates from AI response directly to existing components using their IDs
    private func applyUpdatesToExistingComponents(_ updates: [[String: Any]]) {
        print("🔄 Attempting to update \(updates.count) components")
        
        for updateDict in updates {
            // Get the ID from the AI response
            guard let idString = updateDict["id"] as? String else {
                print("⚠️ No 'id' field in update: \(updateDict)")
                continue
            }
            
            guard let uuid = UUID(uuidString: idString) else {
                print("⚠️ Invalid UUID format: \(idString)")
                continue
            }
            
            guard let existing = canvasManager.findComponent(by: uuid) else {
                print("⚠️ Component not found with id: \(idString)")
                // Debug: List all available component IDs
                print("📋 Available IDs in design:")
                for comp in canvasManager.components {
                    printComponentIds(comp, indent: "  ")
                }
                continue
            }
            
            print("✅ Found component: \(existing.type.rawValue) with id: \(idString.prefix(8))")
            
            // Apply property updates
            if let propertiesDict = updateDict["properties"] as? [String: Any] {
                for (key, value) in propertiesDict {
                    print("   📝 Setting \(key) = \(value)")
                    existing.setProperty(key: key, value: value)
                }
            }
            
            // Apply modifier updates
            if let modifiersArray = updateDict["modifiers"] as? [[String: Any]] {
                existing.modifiers = modifiersArray.compactMap { parseModifier(from: $0) }
            }
            
            // Apply frame updates if provided
            if let frameDict = updateDict["frame"] as? [String: Any] {
                let x = (frameDict["x"] as? Double) ?? Double(existing.frame.origin.x)
                let y = (frameDict["y"] as? Double) ?? Double(existing.frame.origin.y)
                let width = (frameDict["width"] as? Double) ?? Double(existing.frame.width)
                let height = (frameDict["height"] as? Double) ?? Double(existing.frame.height)
                existing.frame = CGRect(x: x, y: y, width: width, height: height)
            }
            
            // Force UI update
            existing.objectWillChange.send()
        }
        
        // Trigger canvas refresh
        canvasManager.objectWillChange.send()
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    /// Helper to print all component IDs recursively for debugging
    private func printComponentIds(_ component: UIComponent, indent: String) {
        print("\(indent)\(component.type.rawValue): \(component.id.uuidString)")
        for child in component.children {
            printComponentIds(child, indent: indent + "  ")
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
        
        // Check if it's wrapped in a "components" array (new format)
        if let componentsArray = json["components"] as? [[String: Any]], !componentsArray.isEmpty {
            // Return the first component (for full views, there's typically one root component)
            return parseComponent(from: componentsArray[0])
        }
        // Check if it's wrapped in a "component" key (old format for backward compatibility)
        else if let componentDict = json["component"] as? [String: Any] {
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
        
        // Parse frame - supports both array format [[x, y], [width, height]] and object format {x, y, width, height}
        var frame = CGRect.zero
        if let frameArray = dict["frame"] as? [[Double]], frameArray.count == 2 {
            // New array format: [[x, y], [width, height]]
            let position = frameArray[0]
            let size = frameArray[1]
            if position.count >= 2 && size.count >= 2 {
                frame = CGRect(x: position[0], y: position[1], width: size[0], height: size[1])
            }
        } else if let frameDict = dict["frame"] as? [String: Any] {
            // Old object format: {x, y, width, height}
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

