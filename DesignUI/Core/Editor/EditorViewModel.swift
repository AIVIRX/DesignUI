import Foundation
import SwiftUI
import Combine

// MARK: - Editor ViewModel
/// Main view model for the SwiftUI editor
@MainActor
class EditorViewModel: ObservableObject {
    // MARK: - Published State
    @Published var state: EditorState
    @Published var isDragging: Bool = false
    @Published var draggedComponent: DesignComponent?
    @Published var hoveredComponentId: String?
    @Published var inspectorTab: InspectorTab = .properties
    @Published var componentPanelExpanded: [String: Bool] = [:]
    @Published var showAddComponentSheet: Bool = false
    @Published var showAISuggestions: Bool = true
    
    // MARK: - Computed Properties
    var selectedComponent: DesignComponent? {
        guard let id = state.selection.selectedIds.first else { return nil }
        return state.components[id]
    }
    
    var canUndo: Bool { state.actions.history.canUndo }
    var canRedo: Bool { state.actions.history.canRedo }
    
    var hierarchyNodes: [ComponentNode] {
        state.buildHierarchy()
    }
    
    var componentsByCategory: [String: [DesignComponentType]] {
        Dictionary(grouping: DesignComponentType.allCases) { $0.category }
    }
    
    // MARK: - Initialization
    init(state: EditorState? = nil) {
        self.state = state ?? EditorStateFactory.createDemo()
        
        // Initialize category expansion state
        for category in Set(DesignComponentType.allCases.map { $0.category }) {
            componentPanelExpanded[category] = true
        }
    }
    
    // MARK: - Selection
    func select(_ componentId: String, append: Bool = false) {
        state.selection.select(componentId, append: append)
    }
    
    func deselect(_ componentId: String) {
        state.selection.deselect(componentId)
    }
    
    func clearSelection() {
        state.selection.clearSelection()
    }
    
    func toggleSelection(_ componentId: String) {
        state.selection.toggleSelection(componentId)
    }
    
    // MARK: - Component Operations
    func addComponent(type: DesignComponentType, to parentId: String? = nil) {
        let registry = ComponentTypeRegistry.shared
        var component = registry.createComponent(type: type)
        
        // Set parent
        if let parentId = parentId {
            component.parentId = parentId
        } else if let selectedId = state.selection.selectedIds.first,
                  let selected = state.components[selectedId],
                  selected.type.isContainer {
            component.parentId = selectedId
        } else if let rootId = state.getRootComponents().first?.id {
            component.parentId = rootId
        }
        
        // Add to state
        state.addComponent(component)
        
        // Record action
        state.actions.dispatch(.addComponent(AddComponentPayload(
            componentType: type,
            parentId: component.parentId
        )))
        
        // Select new component
        select(component.id)
    }
    
    func removeSelectedComponent() {
        guard let componentId = state.selection.selectedIds.first else { return }
        state.removeComponent(componentId)
        state.actions.dispatch(.removeComponent(componentId: componentId, removeChildren: true))
    }
    
    func duplicateSelectedComponent() {
        guard let componentId = state.selection.selectedIds.first,
              let component = state.components[componentId] else { return }
        
        var copy = component
        copy = DesignComponent(
            id: UUID().uuidString,
            type: component.type,
            name: "\(component.name) Copy",
            parentId: component.parentId,
            childrenIds: [],
            zIndex: component.zIndex + 1,
            properties: component.properties,
            modifiers: component.modifiers
        )
        
        state.addComponent(copy)
        select(copy.id)
    }
    
    // MARK: - Property Updates
    func updateProperty<T>(_ keyPath: WritableKeyPath<DesignComponentProperties, T>, value: T) {
        guard let componentId = state.selection.selectedIds.first,
              var component = state.components[componentId] else { return }
        
        component.properties[keyPath: keyPath] = value
        state.updateComponent(component)
    }
    
    func updateText(_ text: String) {
        updateProperty(\.text, value: text)
    }
    
    func updateFontSize(_ size: CGFloat) {
        updateProperty(\.fontSize, value: size)
    }
    
    func updateFontWeight(_ weight: String) {
        updateProperty(\.fontWeight, value: weight)
    }
    
    func updateAlignment(_ alignment: String) {
        updateProperty(\.alignment, value: alignment)
    }
    
    func updateSpacing(_ spacing: CGFloat) {
        updateProperty(\.spacing, value: spacing)
    }
    
    // MARK: - Modifier Operations
    func addModifier(_ modifier: DesignModifier) {
        guard let componentId = state.selection.selectedIds.first,
              var component = state.components[componentId] else { return }
        
        component.modifiers.append(modifier)
        state.updateComponent(component)
    }
    
    func removeModifier(at index: Int) {
        guard let componentId = state.selection.selectedIds.first,
              var component = state.components[componentId],
              index < component.modifiers.count else { return }
        
        component.modifiers.remove(at: index)
        state.updateComponent(component)
    }
    
    func updateModifier(at index: Int, with modifier: DesignModifier) {
        guard let componentId = state.selection.selectedIds.first,
              var component = state.components[componentId],
              index < component.modifiers.count else { return }
        
        component.modifiers[index] = modifier
        state.updateComponent(component)
    }
    
    // MARK: - Layer Operations
    func toggleVisibility(_ componentId: String) {
        state.layers.toggleVisibility(componentId)
    }
    
    func toggleLocked(_ componentId: String) {
        state.layers.toggleLocked(componentId)
    }
    
    func moveLayer(_ componentId: String, direction: Int) {
        let currentZ = state.layers.zIndex(for: componentId)
        let newZ = max(0, currentZ + direction)
        state.layers.moveLayer(componentId, to: newZ)
    }
    
    // MARK: - Undo/Redo
    func undo() {
        guard let _ = state.actions.history.undo() else { return }
        // In a full implementation, you'd restore the previous state
    }
    
    func redo() {
        guard let _ = state.actions.history.redo() else { return }
        // In a full implementation, you'd reapply the action
    }
    
    // MARK: - Serialization
    func exportToJSON() -> String {
        state.toJSON() ?? "{}"
    }
    
    func loadFromJSON(_ json: String) {
        if let loaded = EditorState.fromJSON(json) {
            state = loaded
        }
    }
    
    // MARK: - Canvas Operations
    func updateZoom(_ zoom: CGFloat) {
        state.canvas.zoom = max(0.25, min(4.0, zoom))
    }
    
    func toggleGrid() {
        state.canvas.gridEnabled.toggle()
    }
    
    func setBackgroundColor(_ color: String) {
        state.canvas.backgroundColor = color
    }
}

// MARK: - Inspector Tab
enum InspectorTab: String, CaseIterable {
    case properties = "Properties"
    case modifiers = "Modifiers"
    case layers = "Layers"
    
    var icon: String {
        switch self {
        case .properties: return "slider.horizontal.3"
        case .modifiers: return "paintbrush"
        case .layers: return "square.stack.3d.up"
        }
    }
}
