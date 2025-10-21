//
//  CanvasManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

class CanvasManager: ObservableObject {
    @Published var components: [UIComponent] = []
    @Published var selectedComponent: UIComponent?
    @Published var zoomLevel: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    
    // Special status bar component
    @Published var statusBarComponent: UIComponent?
    
    // Undo/Redo
    private var undoStack: [CanvasState] = []
    private var redoStack: [CanvasState] = []
    private let maxUndoSteps = 50
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    init() {
        // Start with an empty canvas; no predefined root container
        components = []
        selectedComponent = nil
        statusBarComponent = createStatusBarComponent()
        saveState()
    }
    
    // MARK: - Status Bar Management
    private func createStatusBarComponent() -> UIComponent {
        let statusBarComponent = UIComponent(
            type: .text, // Using text type as a placeholder
            properties: [
                ComponentProperty(key: "text", type: .string, value: "Status Bar", defaultValue: "Status Bar"),
                ComponentProperty(key: "backgroundColor", type: .color, value: Color.white.opacity(0.95), defaultValue: Color.white.opacity(0.95)),
                ComponentProperty(key: "cornerRadius", type: .cornerRadius, value: 0.0, defaultValue: 0.0)
            ],
            frame: CGRect(x: 0, y: 0, width: 393, height: 53) // Default iPhone width
        )
        return statusBarComponent
    }
    
    // MARK: - Component Management
    func addComponent(_ component: UIComponent) {
        components.append(component)
        selectedComponent = component
        saveState()
    }
    
    func addComponentToContainer(_ component: UIComponent, container: UIComponent) {
        // Check if the container can accept children (like ScrollView, VStack, etc.)
        if canAcceptChildren(container) {
            container.addChild(component)
            selectedComponent = component
            saveState()
        } else {
            // Fallback to adding to main canvas
            addComponent(component)
        }
    }
    
    func canAcceptChildren(_ component: UIComponent) -> Bool {
        switch component.type {
        case .scrollView, .vstack, .hstack, .zstack, .list, .navigationView, .tabView, .form:
            return true
        default:
            return false
        }
    }
    
    func removeComponent(_ component: UIComponent) {
        components.removeAll { $0.id == component.id }
        if selectedComponent?.id == component.id {
            selectedComponent = nil
        }
        saveState()
    }
    
    func selectComponent(_ component: UIComponent) {
        selectedComponent = component
    }
    
    func deselectAll() {
        selectedComponent = nil
    }
    
    // MARK: - Component Manipulation
    func moveComponent(_ component: UIComponent, by offset: CGSize) {
        if let index = components.firstIndex(where: { $0.id == component.id }) {
            components[index].frame.origin.x += offset.width
            components[index].frame.origin.y += offset.height
        }
    }

    // MARK: - Hierarchy Manipulation
    /// Move a component in the hierarchy to a new parent and position
    func moveComponentInHierarchy(componentId: UUID, newParentId: UUID?, toIndex: Int) {
        guard let moved = removeComponentRecursively(id: componentId) else { return }

        if let parentId = newParentId, let parent = findComponent(by: parentId) {
            // Only allow inserting into container-like components
            if canAcceptChildren(parent) {
                let safeIndex = max(0, min(toIndex, parent.children.count))
                parent.children.insert(moved, at: safeIndex)
            } else {
                // Fallback: insert after parent in its parent list
                if let grandParentId = findParentId(of: parentId), let grandParent = findComponent(by: grandParentId) {
                    let parentIndex = grandParent.children.firstIndex(where: { $0.id == parentId }) ?? grandParent.children.count
                    grandParent.children.insert(moved, at: min(parentIndex + 1, grandParent.children.count))
                } else {
                    let parentIndex = components.firstIndex(where: { $0.id == parentId }) ?? components.count
                    components.insert(moved, at: min(parentIndex + 1, components.count))
                }
            }
        } else {
            let safeIndex = max(0, min(toIndex, components.count))
            components.insert(moved, at: safeIndex)
        }

        saveState()
    }

    /// Find parent id for a node anywhere in the tree
    private func findParentId(of targetId: UUID) -> UUID? {
        for root in components {
            if root.children.contains(where: { $0.id == targetId }) {
                return root.id
            }
            if let id = findParentIdRec(in: root, targetId: targetId) { return id }
        }
        return nil
    }

    private func findParentIdRec(in node: UIComponent, targetId: UUID) -> UUID? {
        if node.children.contains(where: { $0.id == targetId }) { return node.id }
        for child in node.children {
            if let id = findParentIdRec(in: child, targetId: targetId) { return id }
        }
        return nil
    }

    /// Find a component by id anywhere in the hierarchy
    func findComponent(by id: UUID) -> UIComponent? {
        if let found = components.first(where: { $0.id == id }) { return found }
        for root in components {
            if let found = findComponentRecursively(in: root, id: id) { return found }
        }
        return nil
    }

    private func findComponentRecursively(in node: UIComponent, id: UUID) -> UIComponent? {
        if node.id == id { return node }
        for child in node.children {
            if let found = findComponentRecursively(in: child, id: id) { return found }
        }
        return nil
    }

    /// Remove a component by id anywhere in the hierarchy and return it
    @discardableResult
    private func removeComponentRecursively(id: UUID) -> UIComponent? {
        if let index = components.firstIndex(where: { $0.id == id }) {
            let removed = components.remove(at: index)
            return removed
        }
        for root in components {
            if let removed = removeComponentRecursively(in: root, id: id) { return removed }
        }
        return nil
    }

    private func removeComponentRecursively(in node: UIComponent, id: UUID) -> UIComponent? {
        if let index = node.children.firstIndex(where: { $0.id == id }) {
            let removed = node.children.remove(at: index)
            return removed
        }
        for child in node.children {
            if let removed = removeComponentRecursively(in: child, id: id) { return removed }
        }
        return nil
    }
    
    func duplicateComponent(_ component: UIComponent) {
        let duplicatedComponent = UIComponent(
            type: component.type,
            properties: component.properties,
            children: component.children,
            frame: CGRect(
                x: component.frame.origin.x + 20,
                y: component.frame.origin.y + 20,
                width: component.frame.width,
                height: component.frame.height
            )
        )
        addComponent(duplicatedComponent)
    }
    
    // MARK: - Canvas Controls
    func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 5.0)
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.1)
    }
    
    func resetZoom() {
        zoomLevel = 1.0
        canvasOffset = .zero
    }
    
    func resetZoomAndCenter() {
        // Reset to 1.0 zoom and center
        zoomLevel = 1.0
        canvasOffset = .zero
    }
    
    func resetZoomToFit() {
        // Reset zoom but ensure content fits
        zoomLevel = 1.0
        canvasOffset = .zero
        // Force a zoom to fit to ensure everything is visible
        zoomToFit()
    }
    
    func centerView() {
        canvasOffset = .zero
    }
    
    func setZoomLevel(_ level: CGFloat) {
        zoomLevel = min(max(level, 0.1), 3.0)
    }
    
    func zoomToFit() {
        // If there are components, fit to components
        if !components.isEmpty {
            let minX = components.map { $0.frame.minX }.min() ?? 0
            let minY = components.map { $0.frame.minY }.min() ?? 0
            let maxX = components.map { $0.frame.maxX }.max() ?? 0
            let maxY = components.map { $0.frame.maxY }.max() ?? 0
            
            let contentWidth = maxX - minX
            let contentHeight = maxY - minY
            
            // Add some padding
            let padding: CGFloat = 50
            let targetWidth = contentWidth + padding * 2
            let targetHeight = contentHeight + padding * 2
            
            // Calculate zoom level to fit content
            let zoomX = 1.0 / (targetWidth / 800) // Assuming 800pt canvas width
            let zoomY = 1.0 / (targetHeight / 600) // Assuming 600pt canvas height
            zoomLevel = min(zoomX, zoomY, 1.0)
            
            // Center the content
            canvasOffset = CGSize(
                width: -minX + padding,
                height: -minY + padding
            )
        } else {
            // If no components, just center and reset zoom
            zoomLevel = 1.0
            canvasOffset = .zero
        }
    }
    
    func zoomToFitDevice(_ deviceSize: CGSize, canvasSize: CGSize) {
        // Calculate zoom to fit device within canvas
        let padding: CGFloat = 50
        let availableWidth = canvasSize.width - padding * 2
        let availableHeight = canvasSize.height - padding * 2
        
        let zoomX = availableWidth / deviceSize.width
        let zoomY = availableHeight / deviceSize.height
        
        // Use the smaller zoom to ensure device fits
        zoomLevel = min(zoomX, zoomY, 1.0)
        canvasOffset = .zero
    }
    
    // MARK: - Undo/Redo
    private func saveState() {
        let state = CanvasState(
            components: components.map { $0 },
            selectedComponentId: selectedComponent?.id
        )
        
        undoStack.append(state)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        // Clear redo stack when new action is performed
        redoStack.removeAll()
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        let currentState = CanvasState(
            components: components.map { $0 },
            selectedComponentId: selectedComponent?.id
        )
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        restoreState(previousState)
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let currentState = CanvasState(
            components: components.map { $0 },
            selectedComponentId: selectedComponent?.id
        )
        undoStack.append(currentState)
        
        let nextState = redoStack.removeLast()
        restoreState(nextState)
    }
    
    private func restoreState(_ state: CanvasState) {
        components = state.components
        selectedComponent = components.first { $0.id == state.selectedComponentId }
    }
    
    // MARK: - Export
    func exportCode() -> String {
        var code = """
        import SwiftUI

        struct GeneratedView: View {
            var body: some View {
        """
        
        if components.isEmpty {
            code += "\n        Text(\"No components added yet\")"
        } else {
            // Create a ZStack to hold all components
            code += "\n        ZStack {"
            
            for component in components {
                let componentCode = CodeGenerator.generateCode(for: component, indentLevel: 3)
                code += "\n" + componentCode
            }
            
            code += "\n        }"
        }
        
        code += "\n    }\n}"
        
        return code
    }
}

// MARK: - Canvas State
struct CanvasState {
    let components: [UIComponent]
    let selectedComponentId: UUID?
}
