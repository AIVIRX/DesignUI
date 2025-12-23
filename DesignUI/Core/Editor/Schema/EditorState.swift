import Foundation
import SwiftUI

// MARK: - Editor State
/// The complete, serializable state of the SwiftUI editor
/// This is the main document model that can be saved/loaded from database
struct EditorState: Codable {
    // Core State
    var canvas: DesignCanvas
    var components: [String: DesignComponent]
    var layers: LayerManager
    var selection: SelectionState
    
    // Action System
    var actions: ActionSystem
    
    // AI Integration
    var aiIntegration: AIIntegration
    
    // Project Metadata
    var metadata: ProjectMetadata
    
    // Export Settings
    var exportSettings: ExportSettings
    
    init(
        canvas: DesignCanvas = DesignCanvas(),
        components: [String: DesignComponent] = [:],
        layers: LayerManager = LayerManager(),
        selection: SelectionState = SelectionState(),
        actions: ActionSystem = ActionSystem(),
        aiIntegration: AIIntegration = AIIntegration(),
        metadata: ProjectMetadata = ProjectMetadata(),
        exportSettings: ExportSettings = ExportSettings()
    ) {
        self.canvas = canvas
        self.components = components
        self.layers = layers
        self.selection = selection
        self.actions = actions
        self.aiIntegration = aiIntegration
        self.metadata = metadata
        self.exportSettings = exportSettings
    }
    
    // MARK: - Component Operations
    
    mutating func addComponent(_ component: DesignComponent) {
        components[component.id] = component
        layers.addLayer(component.id)
        
        // Update parent's children list
        if let parentId = component.parentId,
           var parent = components[parentId] {
            parent.childrenIds.append(component.id)
            components[parentId] = parent
        }
    }
    
    mutating func removeComponent(_ componentId: String, recursive: Bool = true) {
        guard let component = components[componentId] else { return }
        
        // Recursively remove children
        if recursive {
            for childId in component.childrenIds {
                removeComponent(childId, recursive: true)
            }
        }
        
        // Remove from parent's children list
        if let parentId = component.parentId,
           var parent = components[parentId] {
            parent.childrenIds.removeAll { $0 == componentId }
            components[parentId] = parent
        }
        
        // Remove from components and layers
        components.removeValue(forKey: componentId)
        layers.removeLayer(componentId)
        
        // Clear selection if removed
        selection.deselect(componentId)
    }
    
    func getComponent(_ id: String) -> DesignComponent? {
        components[id]
    }
    
    mutating func updateComponent(_ component: DesignComponent) {
        components[component.id] = component
    }
    
    func getChildren(of componentId: String) -> [DesignComponent] {
        guard let component = components[componentId] else { return [] }
        return component.childrenIds.compactMap { components[$0] }
    }
    
    func getRootComponents() -> [DesignComponent] {
        components.values.filter { $0.parentId == nil }
    }
    
    // MARK: - Hierarchy Operations
    
    func buildHierarchy() -> [ComponentNode] {
        let roots = getRootComponents()
        return roots.map { buildNode(from: $0) }
    }
    
    private func buildNode(from component: DesignComponent) -> ComponentNode {
        let children = getChildren(of: component.id).map { buildNode(from: $0) }
        return ComponentNode(component: component, children: children)
    }
    
    // MARK: - Serialization
    
    func toJSON(prettyPrinted: Bool = true) -> String? {
        let encoder = JSONEncoder()
        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    static func fromJSON(_ json: String) -> EditorState? {
        guard let data = json.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(EditorState.self, from: data)
    }
    
    func toData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(self)
    }
    
    static func fromData(_ data: Data) -> EditorState? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(EditorState.self, from: data)
    }
}

// MARK: - Component Node (for hierarchy representation)
struct ComponentNode: Identifiable {
    let id: String
    let component: DesignComponent
    let children: [ComponentNode]
    
    init(component: DesignComponent, children: [ComponentNode] = []) {
        self.id = component.id
        self.component = component
        self.children = children
    }
}

// MARK: - Project Metadata
struct ProjectMetadata: Codable {
    var id: String
    var name: String
    var description: String
    var version: String
    var createdAt: Date
    var updatedAt: Date
    var author: Author?
    var device: DeviceConfig
    var colorScheme: String
    var tags: [String]
    
    init(
        id: String = UUID().uuidString,
        name: String = "Untitled Project",
        description: String = "",
        version: String = "1.0.0",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        author: Author? = nil,
        device: DeviceConfig = .iPhone14Pro,
        colorScheme: String = "light",
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.author = author
        self.device = device
        self.colorScheme = colorScheme
        self.tags = tags
    }
}

struct Author: Codable {
    var id: String
    var name: String
    var email: String?
}

struct DeviceConfig: Codable {
    var name: String
    var width: CGFloat
    var height: CGFloat
    var scale: CGFloat
    var hasNotch: Bool
    
    static let iPhone14Pro = DeviceConfig(name: "iPhone 14 Pro", width: 390, height: 844, scale: 3, hasNotch: true)
    static let iPhone14ProMax = DeviceConfig(name: "iPhone 14 Pro Max", width: 430, height: 932, scale: 3, hasNotch: true)
    static let iPhoneSE = DeviceConfig(name: "iPhone SE", width: 375, height: 667, scale: 2, hasNotch: false)
}

// MARK: - Export Settings
struct ExportSettings: Codable {
    var format: ExportFormat
    var options: ExportOptions
    
    init(
        format: ExportFormat = .swiftui,
        options: ExportOptions = ExportOptions()
    ) {
        self.format = format
        self.options = options
    }
}

enum ExportFormat: String, Codable {
    case swiftui = "swiftui"
    case json = "json"
    case png = "png"
    case pdf = "pdf"
}

struct ExportOptions: Codable {
    var includeComments: Bool
    var useEnvironmentValues: Bool
    var generatePreview: Bool
    var optimizeForProduction: Bool
    var targetSwiftVersion: String
    
    init(
        includeComments: Bool = true,
        useEnvironmentValues: Bool = true,
        generatePreview: Bool = true,
        optimizeForProduction: Bool = false,
        targetSwiftVersion: String = "5.9"
    ) {
        self.includeComments = includeComments
        self.useEnvironmentValues = useEnvironmentValues
        self.generatePreview = generatePreview
        self.optimizeForProduction = optimizeForProduction
        self.targetSwiftVersion = targetSwiftVersion
    }
}

// MARK: - Example State Factory
enum EditorStateFactory {
    /// Creates a demo editor state with sample components
    static func createDemo() -> EditorState {
        var state = EditorState()
        state.metadata.name = "SwiftUI Editor Demo"
        state.metadata.description = "A demonstration of the Figma-style SwiftUI editor"
        
        // Create root ZStack
        let rootId = "component_zstack_root"
        var root = DesignComponent.zStack(alignment: "center", id: rootId)
        root.name = "Root Container"
        root.modifiers = [
            ModifierFactory.frame(maxWidth: .infinity, maxHeight: .infinity),
            ModifierFactory.background(color: "#F5F5F7")
        ]
        
        // Create main VStack
        let vstackId = "component_vstack_main"
        var vstack = DesignComponent.vStack(alignment: "center", spacing: 16, id: vstackId)
        vstack.name = "Main Content"
        vstack.parentId = rootId
        vstack.modifiers = [ModifierFactory.padding(20)]
        
        // Create title text
        let titleId = "component_text_title"
        var title = DesignComponent.text("Welcome to SwiftUI Editor", id: titleId)
        title.name = "Title"
        title.parentId = vstackId
        title.properties.fontSize = 28
        title.properties.fontWeight = "bold"
        title.modifiers = [
            ModifierFactory.foregroundColor("#1D1D1F")
        ]
        
        // Create hero image
        let imageId = "component_image_hero"
        var heroImage = DesignComponent.image(systemName: "wand.and.stars", id: imageId)
        heroImage.name = "Hero Image"
        heroImage.parentId = vstackId
        heroImage.modifiers = [
            ModifierFactory.frame(width: 120, height: 120),
            ModifierFactory.foregroundColor("#007AFF"),
            ModifierFactory.shadow(color: "#00000033", radius: 10, y: 4)
        ]
        
        // Create button HStack
        let hstackId = "component_hstack_buttons"
        var hstack = DesignComponent.hStack(alignment: "center", spacing: 12, id: hstackId)
        hstack.name = "Button Row"
        hstack.parentId = vstackId
        hstack.modifiers = [ModifierFactory.paddingEdges(horizontal: nil, vertical: 16)]
        
        // Create primary button
        let primaryBtnId = "component_button_primary"
        var primaryBtn = DesignComponent.button("Get Started", id: primaryBtnId)
        primaryBtn.name = "Primary Button"
        primaryBtn.parentId = hstackId
        primaryBtn.modifiers = [
            ModifierFactory.padding(horizontal: 24, vertical: 12),
            ModifierFactory.background(color: "#007AFF"),
            ModifierFactory.foregroundColor("#FFFFFF"),
            ModifierFactory.cornerRadius(12),
            ModifierFactory.font(weight: "semibold")
        ]
        
        // Create secondary button
        let secondaryBtnId = "component_button_secondary"
        var secondaryBtn = DesignComponent.button("Learn More", id: secondaryBtnId)
        secondaryBtn.name = "Secondary Button"
        secondaryBtn.parentId = hstackId
        secondaryBtn.modifiers = [
            ModifierFactory.padding(horizontal: 24, vertical: 12),
            ModifierFactory.background(color: "#E5E5EA"),
            ModifierFactory.foregroundColor("#1D1D1F"),
            ModifierFactory.cornerRadius(12)
        ]
        
        // Build parent-child relationships
        root.childrenIds = [vstackId]
        vstack.childrenIds = [titleId, imageId, hstackId]
        hstack.childrenIds = [primaryBtnId, secondaryBtnId]
        
        // Add all components
        state.addComponent(root)
        state.addComponent(vstack)
        state.addComponent(title)
        state.addComponent(heroImage)
        state.addComponent(hstack)
        state.addComponent(primaryBtn)
        state.addComponent(secondaryBtn)
        
        // Set initial selection
        state.selection.select(titleId)
        
        return state
    }
}

// MARK: - ModifierFactory Extension for EditorStateFactory Demo
extension ModifierFactory {
    static func frame(
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> DesignModifier {
        .frame(
            id: UUID().uuidString,
            width: width,
            height: height,
            maxWidth: maxWidth,
            maxHeight: maxHeight
        )
    }
    
    static func font(style: String? = nil, size: CGFloat? = nil, weight: String? = nil) -> DesignModifier {
        .font(id: UUID().uuidString, style: style, size: size, weight: weight, design: nil)
    }
    
    static func paddingEdges(horizontal: CGFloat?, vertical: CGFloat?) -> DesignModifier {
        .padding(id: UUID().uuidString, horizontal: horizontal, vertical: vertical)
    }
}

