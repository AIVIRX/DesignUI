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
    
    // Design name for code generation
    @Published var designName: String = "GeneratedView"
    
    // Undo/Redo
    private var undoStack: [CanvasState] = []
    private var redoStack: [CanvasState] = []
    private let maxUndoSteps = 50
    private var saveStateWorkItem: DispatchWorkItem?
    private let saveStateDebounceInterval: TimeInterval = 0.3 // Debounce property/modifier changes
    private var lastSavedState: CanvasState? // Track last saved state to prevent duplicates
    private var justSavedImmediately: Bool = false // Flag to prevent debounced save right after immediate save
    
    var canUndo: Bool { 
        // Can undo if we have more than one state (base state + at least one change)
        undoStack.count > 1
    }
    var canRedo: Bool { !redoStack.isEmpty }
    
    init() {
        // Start with an empty canvas; no predefined root container
        components = []
        selectedComponent = nil
        statusBarComponent = createStatusBarComponent()
        // Don't save state in init - wait until design is loaded
        
        // Listen for property and modifier changes
        NotificationCenter.default.addObserver(
            forName: .designChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveStateDebounced()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Status Bar Management
    private func createStatusBarComponent() -> UIComponent {
        let statusBarComponent = UIComponent(
            type: .statusBar,
            properties: [],
            frame: CGRect(x: 0, y: 0, width: 393, height: 53) // Default iPhone width
        )
        return statusBarComponent
    }
    
    // MARK: - Component Management
    func addComponent(_ component: UIComponent) {
        // Cancel any pending debounced saves
        saveStateWorkItem?.cancel()
        saveStateWorkItem = nil
        
        // Save state BEFORE making the change - FORCE save to ensure we capture the state before addition
        saveState(force: true)
        
        components.append(component)
        selectedComponent = component
    }
    
    func addComponentToContainer(_ component: UIComponent, container: UIComponent) {
        // Check if the container can accept children (like ScrollView, VStack, etc.)
        if canAcceptChildren(container) {
            // Cancel any pending debounced saves
            saveStateWorkItem?.cancel()
            saveStateWorkItem = nil
            
            // Save state BEFORE making the change - FORCE save to ensure we capture the state before change
            saveState(force: true)
            
            // Remove component from root level if it exists there
            components.removeAll { $0.id == component.id }
            
            // Add to container
            container.addChild(component)
            selectedComponent = component
        } else {
            // Fallback to adding to main canvas
            addComponent(component)
        }
    }
    
    func canAcceptChildren(_ component: UIComponent) -> Bool {
        switch component.type {
        case .scrollView, .vstack, .hstack, .zstack, .list, .button:
            return true
        default:
            return false
        }
    }
    
    func removeComponent(_ component: UIComponent) {
        print("🗑️ removeComponent: Removing component \(component.id.uuidString.prefix(8)), current count: \(components.count)")
        
        // Cancel any pending debounced saves
        saveStateWorkItem?.cancel()
        saveStateWorkItem = nil
        
        // Save state BEFORE making the change - FORCE save to ensure we capture the state with component
        saveState(force: true)
        
        // Find the actual component in the hierarchy to get its full children tree
        guard let actualComponent = findComponent(by: component.id) else {
            print("⚠️ removeComponent: Component not found in hierarchy")
            return
        }
        
        // Collect all descendant IDs (including the component itself and all its children recursively)
        var idsToRemove: Set<UUID> = [actualComponent.id]
        collectDescendantIds(from: actualComponent, into: &idsToRemove)
        
        print("🗑️ removeComponent: Removing \(idsToRemove.count) components (including \(idsToRemove.count - 1) children)")
        
        // Remove from nested children recursively (this handles both top-level and nested components)
        removeComponentsRecursively(ids: idsToRemove, from: &components)
        
        // Clear selection if the selected component or any of its descendants were removed
        if let selectedId = selectedComponent?.id, idsToRemove.contains(selectedId) {
            selectedComponent = nil
        }
        
        print("🗑️ removeComponent: After removal, count: \(components.count)")
    }
    
    /// Recursively collect all descendant IDs from a component
    private func collectDescendantIds(from component: UIComponent, into ids: inout Set<UUID>) {
        for child in component.children {
            ids.insert(child.id)
            collectDescendantIds(from: child, into: &ids)
        }
    }
    
    /// Recursively remove components with given IDs from a component tree
    private func removeComponentsRecursively(ids: Set<UUID>, from components: inout [UIComponent]) {
        for i in components.indices.reversed() {
            // Remove children recursively first
            removeComponentsRecursively(ids: ids, from: &components[i].children)
            
            // Remove the component itself if it's in the set
            if ids.contains(components[i].id) {
                components.remove(at: i)
            }
        }
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
        // Use reasonable padding for better visibility
        let padding: CGFloat = 100
        let availableWidth = canvasSize.width - padding * 2
        let availableHeight = canvasSize.height - padding * 2
        
        // Only scale down if device is larger than available space
        // Otherwise, scale up to make it closer to actual simulator size
        let zoomX = availableWidth / deviceSize.width
        let zoomY = availableHeight / deviceSize.height
        
        // Use the smaller zoom to ensure device fits
        // Don't cap at 1.0 - allow scaling up if canvas is large enough
        // This makes components appear closer to actual simulator size
        let calculatedZoom = min(zoomX, zoomY)
        
        // If the calculated zoom would make things too small, use a minimum scale
        // This ensures the device appears at a reasonable size (at least 0.8x, up to 2.0x)
        zoomLevel = max(min(calculatedZoom, 2.0), 0.8)
        canvasOffset = .zero
    }
    
    // MARK: - Undo/Redo
    
    /// Save the initial state when loading a design file
    /// This creates the base state that undo can return to
    func saveInitialState() {
        let state = CanvasState(
            components: deepCopyComponents(components),
            selectedComponentId: selectedComponent?.id
        )
        
        // Clear any existing stack and set this as the only state
        undoStack = [state]
        redoStack.removeAll()
        lastSavedState = state
        
        print("💾 saveInitialState: Saved initial state with \(state.components.count) components")
    }
    
    func saveState(force: Bool = false) {
        let state = CanvasState(
            components: deepCopyComponents(components),
            selectedComponentId: selectedComponent?.id
        )
        
        // Prevent saving duplicate states (same component count and selection)
        // But allow forcing a save for structural changes (add/remove components)
        if !force {
            if let lastState = lastSavedState {
                if lastState.components.count == state.components.count &&
                   lastState.selectedComponentId == state.selectedComponentId {
                    // Check if components are actually different by comparing IDs
                    let lastIds = Set(lastState.components.map { $0.id })
                    let currentIds = Set(state.components.map { $0.id })
                    if lastIds == currentIds {
                        // Same state, don't save
                        print("🔄 saveState: Skipping duplicate state (same components)")
                        return
                    }
                }
            }
        }
        
        print("💾 saveState: Saving state with \(state.components.count) components, selected: \(state.selectedComponentId?.uuidString.prefix(8) ?? "nil"), force=\(force)")
        print("💾 saveState: Stack size before: \(undoStack.count)")
        
        undoStack.append(state)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        print("💾 saveState: Stack size after: \(undoStack.count)")
        
        // Clear redo stack when new action is performed
        redoStack.removeAll()
        
        // Update last saved state
        lastSavedState = state
        
        // Set flag to prevent debounced save for a short time
        // Use a longer window to ensure debounced saves are blocked
        justSavedImmediately = true
        DispatchQueue.main.asyncAfter(deadline: .now() + saveStateDebounceInterval + 0.2) { [weak self] in
            self?.justSavedImmediately = false
            print("🔄 saveState: justSavedImmediately flag cleared")
        }
        print("🔄 saveState: Set justSavedImmediately=true, will clear in \(saveStateDebounceInterval + 0.2)s")
    }
    
    /// Debounced version of saveState for property/modifier changes
    private func saveStateDebounced() {
        print("🔄 saveStateDebounced: Called, justSavedImmediately=\(justSavedImmediately)")
        
        // Skip if we just saved immediately (prevents duplicate saves from component add/remove)
        if justSavedImmediately {
            print("🔄 saveStateDebounced: Skipping because justSavedImmediately=true")
            return
        }
        
        // Cancel any pending save
        saveStateWorkItem?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem { [weak self] in
            print("🔄 saveStateDebounced: Executing debounced save")
            self?.saveState()
        }
        saveStateWorkItem = workItem
        
        // Schedule after debounce interval
        DispatchQueue.main.asyncAfter(deadline: .now() + saveStateDebounceInterval, execute: workItem)
    }
    
    /// Create deep copies of components to ensure undo/redo works correctly
    /// Uses encoding/decoding to preserve all properties including IDs
    private func deepCopyComponents(_ components: [UIComponent]) -> [UIComponent] {
        do {
            // Encode components to JSON
            let encoder = JSONEncoder()
            let data = try encoder.encode(components)
            
            // Decode back to create deep copies with preserved IDs
            let decoder = JSONDecoder()
            let copiedComponents = try decoder.decode([UIComponent].self, from: data)
            
            return copiedComponents
        } catch {
            print("⚠️ Failed to deep copy components: \(error)")
            // Fallback: return original components (not ideal but prevents crash)
            return components
        }
    }
    
    func undo() {
        guard !undoStack.isEmpty else { return }
        
        // Don't allow undoing to an empty state if we currently have components
        // This prevents accidentally clearing all components
        if undoStack.count == 1 && !components.isEmpty {
            // Check if the only state in undo stack is empty
            let lastState = undoStack.last!
            if lastState.components.isEmpty {
                // Don't undo to empty state if we have components
                return
            }
        }
        
        let currentState = CanvasState(
            components: deepCopyComponents(components),
            selectedComponentId: selectedComponent?.id
        )
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        restoreState(previousState)
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let currentState = CanvasState(
            components: deepCopyComponents(components),
            selectedComponentId: selectedComponent?.id
        )
        undoStack.append(currentState)
        
        let nextState = redoStack.removeLast()
        restoreState(nextState)
    }
    
    private func restoreState(_ state: CanvasState) {
        print("↩️ restoreState: Restoring state with \(state.components.count) components")
        
        // Cancel any pending debounced saves
        saveStateWorkItem?.cancel()
        saveStateWorkItem = nil
        
        components = deepCopyComponents(state.components)
        // Find selected component in the restored hierarchy
        if let selectedId = state.selectedComponentId {
            selectedComponent = findComponent(by: selectedId)
        } else {
            selectedComponent = nil
        }
        
        // Update lastSavedState to match restored state to prevent duplicate saves
        lastSavedState = CanvasState(
            components: deepCopyComponents(state.components),
            selectedComponentId: state.selectedComponentId
        )
    }
    
    // MARK: - Overlay Management
    func createOverlayFolder(for component: UIComponent) {
        // Create a default overlay component (a simple text badge)
        let overlayComponent = UIComponent(
            type: .text,
            properties: [
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Badge", defaultValue: "Badge"),
                ComponentProperty(key: "fontSize", displayName: "Font Size", type: .font, value: "caption", defaultValue: "caption"),
                ComponentProperty(key: "fontWeight", displayName: "Font Weight", type: .font, value: "bold", defaultValue: "bold"),
                ComponentProperty(key: "foregroundColor", displayName: "Text Color", type: .color, value: Color.white, defaultValue: Color.white)
            ],
            frame: CGRect(x: 0, y: 0, width: 50, height: 20),
            isOverlay: true
        )
        
        component.addOverlayChild(overlayComponent)
        selectedComponent = overlayComponent
        saveState()
    }
    
    // MARK: - Design Management
    func setDesignName(_ name: String) {
        designName = name
    }
    
    // MARK: - Export
    func exportCode() -> String {
        // Clean the design name to make it a valid Swift identifier
        let cleanedName = designName
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "_", with: "")
        let viewName = "\(cleanedName)View"
        
        var code = """
        import SwiftUI

        struct \(viewName): View {
            var body: some View {
        """
        
        if components.isEmpty {
            code += "\n        Text(\"No components added yet\")"
        } else {
            for component in components {
                let componentCode = CodeGenerator.generateCode(for: component, indentLevel: 2)
                code += "\n" + componentCode
            }
        }
        
        code += "\n    }\n}\n\n#Preview {\n    \(viewName)()\n}"
        
        return code
    }
}

// MARK: - Canvas State
struct CanvasState {
    let components: [UIComponent]
    let selectedComponentId: UUID?
}
