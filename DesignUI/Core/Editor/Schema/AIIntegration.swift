import Foundation

// MARK: - AI Integration
/// AI-driven editing integration for the SwiftUI editor
struct AIIntegration: Codable {
    var enabled: Bool
    var context: AIContext
    var capabilities: [AICapability]
    var suggestedActions: [AISuggestion]
    var promptTemplates: [String: String]
    
    init() {
        self.enabled = true
        self.context = AIContext()
        self.capabilities = AICapability.allCases
        self.suggestedActions = []
        self.promptTemplates = AIPromptTemplates.defaults
    }
}

// MARK: - AI Context
/// Current context for AI suggestions
struct AIContext: Codable {
    var currentSelection: [String]
    var recentActions: [EditorAction]
    var userIntent: String?
    var focusedProperty: String?
    var designGoals: [String]
    
    init(
        currentSelection: [String] = [],
        recentActions: [EditorAction] = [],
        userIntent: String? = nil,
        focusedProperty: String? = nil,
        designGoals: [String] = []
    ) {
        self.currentSelection = currentSelection
        self.recentActions = recentActions
        self.userIntent = userIntent
        self.focusedProperty = focusedProperty
        self.designGoals = designGoals
    }
}

// MARK: - AI Capabilities
enum AICapability: String, Codable, CaseIterable {
    case suggestComponent = "suggestComponent"
    case suggestModifier = "suggestModifier"
    case suggestPropertyChange = "suggestPropertyChange"
    case generateLayout = "generateLayout"
    case convertDesign = "convertDesign"
    case optimizePerformance = "optimizePerformance"
    case suggestAccessibility = "suggestAccessibility"
    case generateColorPalette = "generateColorPalette"
    case suggestTypography = "suggestTypography"
    case createAnimation = "createAnimation"
    case refactorHierarchy = "refactorHierarchy"
    case generateFromDescription = "generateFromDescription"
    
    var description: String {
        switch self {
        case .suggestComponent:
            return "Suggest new components to add based on context"
        case .suggestModifier:
            return "Suggest modifiers to improve styling"
        case .suggestPropertyChange:
            return "Suggest property value changes"
        case .generateLayout:
            return "Generate complete layouts from descriptions"
        case .convertDesign:
            return "Convert designs to match a style reference"
        case .optimizePerformance:
            return "Suggest performance optimizations"
        case .suggestAccessibility:
            return "Suggest accessibility improvements"
        case .generateColorPalette:
            return "Generate harmonious color palettes"
        case .suggestTypography:
            return "Suggest typography improvements"
        case .createAnimation:
            return "Create animations for components"
        case .refactorHierarchy:
            return "Suggest hierarchy refactoring"
        case .generateFromDescription:
            return "Generate UI from natural language"
        }
    }
}

// MARK: - AI Suggestion
/// A single AI-generated suggestion
struct AISuggestion: Identifiable, Codable {
    let id: String
    var type: AISuggestionType
    var confidence: Double
    var reasoning: String
    var action: EditorAction
    var preview: ComponentPreview?
    var timestamp: Date
    var applied: Bool
    var dismissed: Bool
    
    init(
        id: String = UUID().uuidString,
        type: AISuggestionType,
        confidence: Double,
        reasoning: String,
        action: EditorAction,
        preview: ComponentPreview? = nil
    ) {
        self.id = id
        self.type = type
        self.confidence = confidence
        self.reasoning = reasoning
        self.action = action
        self.preview = preview
        self.timestamp = Date()
        self.applied = false
        self.dismissed = false
    }
}

enum AISuggestionType: String, Codable {
    case component = "component"
    case modifier = "modifier"
    case property = "property"
    case layout = "layout"
    case style = "style"
    case accessibility = "accessibility"
    case animation = "animation"
    case refactor = "refactor"
}

struct ComponentPreview: Codable {
    var thumbnailData: Data?
    var previewJSON: String?
    var dimensions: CGSize?
}

// MARK: - AI Prompt Templates
enum AIPromptTemplates {
    static let defaults: [String: String] = [
        "generateLayout": "Create a {layoutType} layout with {description}",
        "suggestImprovements": "Analyze the current design and suggest improvements for {aspect}",
        "convertStyle": "Convert the current design to match {styleReference}",
        "addFeature": "Add {featureDescription} to the current layout",
        "createAnimation": "Create a {animationType} animation for the selected component",
        "generateColors": "Generate a color palette for {mood} with {colorCount} colors",
        "optimizeForDevice": "Optimize the current layout for {deviceType}",
        "addAccessibility": "Add accessibility features to improve {accessibilityAspect}",
        "createComponent": "Create a {componentType} component with {specifications}",
        "refactorHierarchy": "Simplify the component hierarchy for {goal}"
    ]
}

// MARK: - AI Request
/// Request structure for AI operations
struct AIRequest: Codable {
    var capability: AICapability
    var prompt: String
    var context: AIContext
    var parameters: [String: AnyCodable]?
    var maxSuggestions: Int
    
    init(
        capability: AICapability,
        prompt: String,
        context: AIContext,
        parameters: [String: AnyCodable]? = nil,
        maxSuggestions: Int = 3
    ) {
        self.capability = capability
        self.prompt = prompt
        self.context = context
        self.parameters = parameters
        self.maxSuggestions = maxSuggestions
    }
}

// MARK: - AI Response
/// Response structure from AI operations
struct AIResponse: Codable {
    var requestId: String
    var suggestions: [AISuggestion]
    var metadata: AIResponseMetadata?
    var error: AIError?
    
    var isSuccessful: Bool { error == nil && !suggestions.isEmpty }
}

struct AIResponseMetadata: Codable {
    var processingTime: TimeInterval
    var modelVersion: String
    var tokensUsed: Int?
}

struct AIError: Codable, Error {
    var code: String
    var message: String
    var recoverable: Bool
}

// MARK: - AI Manager Extension Points
protocol AIManagerProtocol {
    func generateSuggestions(request: AIRequest) async throws -> AIResponse
    func applySuggestion(_ suggestion: AISuggestion) async throws
    func dismissSuggestion(_ suggestion: AISuggestion)
    func refreshContext(with state: EditorState)
}

// MARK: - Predefined AI Suggestions Factory
enum AISuggestionFactory {
    static func suggestShadow(for componentId: String) -> AISuggestion {
        AISuggestion(
            type: .modifier,
            confidence: 0.85,
            reasoning: "Adding a subtle shadow improves depth and visual hierarchy",
            action: .addModifier(
                componentId: componentId,
                modifier: ModifierFactory.shadow(color: "#00000020", radius: 4, y: 2),
                insertIndex: nil
            )
        )
    }
    
    static func suggestPadding(for componentId: String) -> AISuggestion {
        AISuggestion(
            type: .modifier,
            confidence: 0.90,
            reasoning: "Adding padding improves readability and touch targets",
            action: .addModifier(
                componentId: componentId,
                modifier: ModifierFactory.padding(16),
                insertIndex: nil
            )
        )
    }
    
    static func suggestCornerRadius(for componentId: String, radius: CGFloat = 12) -> AISuggestion {
        AISuggestion(
            type: .modifier,
            confidence: 0.88,
            reasoning: "Rounded corners create a modern, friendly appearance",
            action: .addModifier(
                componentId: componentId,
                modifier: ModifierFactory.cornerRadius(radius),
                insertIndex: nil
            )
        )
    }
    
    static func suggestAccessibilityLabel(for componentId: String, label: String) -> AISuggestion {
        AISuggestion(
            type: .accessibility,
            confidence: 0.95,
            reasoning: "Adding accessibility labels improves VoiceOver support for all users",
            action: .addModifier(
                componentId: componentId,
                modifier: .accessibilityLabel(id: UUID().uuidString, label: label),
                insertIndex: nil
            )
        )
    }
}
