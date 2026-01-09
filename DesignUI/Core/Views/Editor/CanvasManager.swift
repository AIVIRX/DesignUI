//
//  CanvasManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

enum LayoutAlignment {
    case left, centerHorizontally, right
    case top, centerVertically, bottom
}

enum LayoutDistribution {
    case horizontally, vertically
}

class CanvasManager: ObservableObject {
    @Published var components: [UIComponent] = []
    // Simple flag to track if mouse is hovering over any scrollable component
    @Published var isHoveringScrollable: Bool = false
    
    @Published var selectedComponent: UIComponent? {
        didSet {
            // Ensure consistency with selectedComponentIds for external binding updates
            if let component = selectedComponent {
                // If setting a component that isn't in the set (e.g. from Layers panel or Properties),
                // assume single selection and update the set
                if !selectedComponentIds.contains(component.id) {
                    selectedComponentIds = [component.id]
                }
            } else {
                // If set to nil (deselect), and we aren't handling a toggle operation that managed ids,
                // we should clear ids.
                // Note: DeselectAll sets nil, so this is redundant but safe.
                // Toggle removal sets nil ONLY if ids is empty.
                // So if ids is NOT empty here, implies external deselect.
                if !selectedComponentIds.isEmpty {
                    selectedComponentIds.removeAll()
                }
            }
        }
    }
    @Published var selectedComponentIds: Set<UUID> = [] // Multi-selection support
    @Published var zoomLevel: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    @Published var centerCanvasTrigger: Bool = false // Triggers canvas centering when toggled
    
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
    
    // Clipboard for copy/paste
    private var clipboard: UIComponent?
    var hasClipboardContent: Bool { clipboard != nil }
    
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
        
        // Listen for selection requests
        NotificationCenter.default.addObserver(
            forName: .selectComponent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self, let componentId = notification.object as? UUID else { return }
            self.selectComponent(withId: componentId)
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
        case .scrollView, .vstack, .hstack, .zstack:
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
    
    func selectComponent(_ component: UIComponent, additive: Bool = false) {
        if additive {
            // Cmd+click: toggle selection
            if selectedComponentIds.contains(component.id) {
                selectedComponentIds.remove(component.id)
                // Update primary selection
                if selectedComponent?.id == component.id {
                    selectedComponent = selectedComponentIds.isEmpty ? nil : findComponent(by: selectedComponentIds.first!)
                }
            } else {
                selectedComponentIds.insert(component.id)
                selectedComponent = component
            }
        } else {
            // Normal click: single selection
            selectedComponentIds = [component.id]
            selectedComponent = component
        }
    }
    
    func toggleComponentSelection(_ component: UIComponent) {
        if selectedComponentIds.contains(component.id) {
            selectedComponentIds.remove(component.id)
            if selectedComponent?.id == component.id {
                selectedComponent = selectedComponentIds.isEmpty ? nil : findComponent(by: selectedComponentIds.first!)
            }
        } else {
            selectedComponentIds.insert(component.id)
            selectedComponent = component
        }
    }
    
    func isComponentSelected(_ component: UIComponent) -> Bool {
        return selectedComponentIds.contains(component.id)
    }
    
    func deselectAll() {
        selectedComponent = nil
        selectedComponentIds.removeAll()
    }
    
    // MARK: - Layout Utilities
    
    func alignSelected(_ alignment: LayoutAlignment) {
        let selected = selectedComponentIds.compactMap { findComponent(by: $0) }
        guard selected.count >= 2 else { return }
        
        let frames = selected.map { $0.frame }
        let minX = frames.map { $0.minX }.min() ?? 0
        let maxX = frames.map { $0.maxX }.max() ?? 0
        let minY = frames.map { $0.minY }.min() ?? 0
        let maxY = frames.map { $0.maxY }.max() ?? 0
        let midX = (minX + maxX) / 2
        let midY = (minY + maxY) / 2
        
        saveState(force: true)
        
        for component in selected {
            switch alignment {
            case .left:
                component.frame.origin.x = minX
            case .centerHorizontally:
                component.frame.origin.x = midX - component.frame.width / 2
            case .right:
                component.frame.origin.x = maxX - component.frame.width
            case .top:
                component.frame.origin.y = minY
            case .centerVertically:
                component.frame.origin.y = midY - component.frame.height / 2
            case .bottom:
                component.frame.origin.y = maxY - component.frame.height
            }
        }
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func distributeSelected(_ distribution: LayoutDistribution) {
        let selected = selectedComponentIds.compactMap { findComponent(by: $0) }
        guard selected.count >= 3 else { return }
        
        saveState(force: true)
        
        if distribution == .horizontally {
            let sorted = selected.sorted { $0.frame.minX < $1.frame.minX }
            let first = sorted.first!
            let last = sorted.last!
            
            // Total span between centers or origins? Usually origins or centers.
            // Let's do even spacing between centers.
            let firstCenter = first.frame.midX
            let lastCenter = last.frame.midX
            let totalSpan = lastCenter - firstCenter
            let spacing = totalSpan / CGFloat(sorted.count - 1)
            
            for i in 1..<(sorted.count - 1) {
                sorted[i].frame.origin.x = (firstCenter + CGFloat(i) * spacing) - sorted[i].frame.width / 2
            }
        } else {
            let sorted = selected.sorted { $0.frame.minY < $1.frame.minY }
            let first = sorted.first!
            let last = sorted.last!
            
            let firstCenter = first.frame.midY
            let lastCenter = last.frame.midY
            let totalSpan = lastCenter - firstCenter
            let spacing = totalSpan / CGFloat(sorted.count - 1)
            
            for i in 1..<(sorted.count - 1) {
                sorted[i].frame.origin.y = (firstCenter + CGFloat(i) * spacing) - sorted[i].frame.height / 2
            }
        }
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func groupSelected(into type: ComponentType) {
        let selected = selectedComponentIds.compactMap { findComponent(by: $0) }
        guard !selected.isEmpty else { return }
        
        // Find common parent and insertion index based on the first selected item
        let firstId = selected[0].id
        let parentId = findParentId(of: firstId)
        
        var insertionIndex = 0
        if let pId = parentId, let parent = findComponent(by: pId) {
            insertionIndex = parent.children.firstIndex(where: { $0.id == firstId }) ?? parent.children.count
        } else {
            insertionIndex = components.firstIndex(where: { $0.id == firstId }) ?? components.count
        }
        
        // Calculate bounding box
        let frames = selected.map { $0.frame }
        let minX = frames.map { $0.minX }.min() ?? 0
        let maxX = frames.map { $0.maxX }.max() ?? 0
        let minY = frames.map { $0.minY }.min() ?? 0
        let maxY = frames.map { $0.maxY }.max() ?? 0
        
        let groupFrame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        
        saveState(force: true)
        
        // Create the group component
        let group = UIComponent(
            type: type,
            properties: UIComponent.defaultProperties(for: type),
            frame: groupFrame
        )
        
        // Add children to group and adjust their frames
        for component in selected {
            _ = removeComponentRecursively(id: component.id)
            component.frame.origin.x -= groupFrame.origin.x
            component.frame.origin.y -= groupFrame.origin.y
            group.children.append(component)
        }
        
        // Add group to the original parent at the correct index
        if let pId = parentId, let parent = findComponent(by: pId) {
            let safeIndex = min(insertionIndex, parent.children.count)
            parent.children.insert(group, at: safeIndex)
        } else {
            let safeIndex = min(insertionIndex, components.count)
            components.insert(group, at: safeIndex)
        }
        
        // Select the new group
        selectedComponentIds = [group.id]
        selectedComponent = group
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func replaceDesign(with newComponents: [UIComponent]) {
        saveState(force: true)
        self.components = newComponents
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func updateDesign(with componentsToUpdate: [UIComponent]) {
        saveState(force: true)
        for updated in componentsToUpdate {
            if let existing = findComponent(by: updated.id) {
                // Update properties
                existing.properties = updated.properties
                existing.modifiers = updated.modifiers
                existing.frame = updated.frame
            }
        }
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func getDesignAsJSON() -> String {
        let encoder = JSONEncoder()
        // No pretty print for token saving if needed, but pretty print is better for AI if not too long
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(components),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
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

        // Force save to track layer reorders (same components, different order)
        saveState(force: true)
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

    /// Find a component by id anywhere in the hierarchy
    func selectComponent(withId id: UUID) {
        if let component = findComponent(by: id) {
            self.selectedComponent = component
        }
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
        let duplicatedComponent = createDeepCopy(of: component)
        
        // Check if this component is a child of another component
        if let parentId = findParentId(of: component.id), let parentComponent = findComponent(by: parentId) {
            // Find the index of the original component in its parent
            if let originalIndex = parentComponent.children.firstIndex(where: { $0.id == component.id }) {
                // Insert the duplicate right after the original component
                parentComponent.children.insert(duplicatedComponent, at: originalIndex + 1)
            } else {
                // Fallback: add to end if index not found
                parentComponent.addChild(duplicatedComponent)
            }
        } else {
            // For root components, find the index and insert after
            if let originalIndex = components.firstIndex(where: { $0.id == component.id }) {
                // Cancel any pending debounced saves
                saveStateWorkItem?.cancel()
                saveStateWorkItem = nil
                
                // Save state BEFORE making the change
                saveState(force: true)
                
                components.insert(duplicatedComponent, at: originalIndex + 1)
                selectedComponent = duplicatedComponent
            } else {
                // Fallback: add to end if index not found
                addComponent(duplicatedComponent)
            }
        }
        
        // Select the new component if not already set
        if selectedComponent?.id != duplicatedComponent.id {
            selectedComponent = duplicatedComponent
        }
        
        // Save state after duplication
        saveState()
    }
    
    /// Wraps a component in a container (VStack, HStack, ZStack, ScrollView)
    func wrapComponent(_ component: UIComponent, in type: ComponentType) {
        // Only allow valid container types
        guard type == .vstack || type == .hstack || type == .zstack || type == .scrollView else { return }
        
        let container = UIComponent(type: type, children: [])
        
        // Find parent and index
        if let parentId = findParentId(of: component.id), let parentComponent = findComponent(by: parentId) {
            if let index = parentComponent.children.firstIndex(where: { $0.id == component.id }) {
                // Cancel any pending debounced saves
                saveStateWorkItem?.cancel()
                saveStateWorkItem = nil
                saveState(force: true)
                
                // Remove original from parent
                parentComponent.children.remove(at: index)
                
                // Add original to new container
                container.addChild(component)
                
                // Insert container at original index
                parentComponent.children.insert(container, at: index)
                
                // Select container
                selectedComponent = container
                saveState()
            }
        } else if let index = components.firstIndex(where: { $0.id == component.id }) {
            // Root component
            saveStateWorkItem?.cancel()
            saveStateWorkItem = nil
            saveState(force: true)
            
            components.remove(at: index)
            container.addChild(component)
            components.insert(container, at: index)
            
            selectedComponent = container
            saveState()
        }
    }
    
    private func createDeepCopy(of component: UIComponent) -> UIComponent {
        // Copy modifiers with their properties and order
        let duplicatedModifiers = component.modifiers.map { modifier in
            ComponentModifier(
                type: modifier.type,
                properties: modifier.properties
            )
        }
        
        // Recursively copy children with their modifiers
        let duplicatedChildren = component.children.map { child in
            createDeepCopy(of: child)
        }
        
        let duplicatedComponent = UIComponent(
            type: component.type,
            properties: component.properties,
            children: duplicatedChildren,
            frame: CGRect(
                x: component.frame.origin.x + 20,
                y: component.frame.origin.y + 20,
                width: component.frame.width,
                height: component.frame.height
            ),
            modifiers: duplicatedModifiers,
            isOverlay: component.isOverlay,
            modifierId: component.modifierId,
            modifierType: component.modifierType
        )
        return duplicatedComponent
    }
    
    // MARK: - Copy/Paste/Cut
    
    /// Copy the selected component to clipboard
    func copyComponent(_ component: UIComponent) {
        // Store a deep copy of the component (without offset)
        clipboard = createDeepCopyForClipboard(of: component)
        print("📋 copyComponent: Copied \(component.type.rawValue) to clipboard")
    }
    
    /// Paste component from clipboard
    func pasteComponent() {
        guard let copiedComponent = clipboard else {
            print("📋 pasteComponent: Clipboard is empty")
            return
        }
        
        // Create a new copy with offset so it's visible
        let pastedComponent = createDeepCopy(of: copiedComponent)
        
        // Cancel any pending debounced saves
        saveStateWorkItem?.cancel()
        saveStateWorkItem = nil
        
        // Save state BEFORE making the change
        saveState(force: true)
        
        // Add to canvas
        components.append(pastedComponent)
        selectedComponent = pastedComponent
        
        print("📋 pasteComponent: Pasted \(pastedComponent.type.rawValue) from clipboard")
    }
    
    /// Cut the selected component (copy + delete)
    func cutComponent(_ component: UIComponent) {
        // First copy to clipboard
        copyComponent(component)
        
        // Then remove the component
        removeComponent(component)
        
        print("✂️ cutComponent: Cut \(component.type.rawValue)")
    }
    
    /// Create a deep copy without position offset (for clipboard storage)
    private func createDeepCopyForClipboard(of component: UIComponent) -> UIComponent {
        let duplicatedModifiers = component.modifiers.map { modifier in
            ComponentModifier(
                type: modifier.type,
                properties: modifier.properties
            )
        }
        
        let duplicatedChildren = component.children.map { child in
            createDeepCopyForClipboard(of: child)
        }
        
        let duplicatedComponent = UIComponent(
            type: component.type,
            properties: component.properties,
            children: duplicatedChildren,
            frame: component.frame, // Keep original frame for clipboard
            modifiers: duplicatedModifiers,
            isOverlay: component.isOverlay,
            modifierId: component.modifierId,
            modifierType: component.modifierType
        )
        return duplicatedComponent
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
        // Cancel any pending debounced saves that might have been triggered by component loading
        saveStateWorkItem?.cancel()
        saveStateWorkItem = nil
        justSavedImmediately = false
        
        let state = CanvasState(
            components: deepCopyComponents(components)
        )
        
        // Clear any existing stack and set this as the only state
        undoStack = [state]
        redoStack.removeAll()
        lastSavedState = state
        
        print("💾 saveInitialState: Saved initial state with \(state.components.count) components")
    }
    
    func saveState(force: Bool = false) {
        let state = CanvasState(
            components: deepCopyComponents(components)
        )
        
        // Prevent saving duplicate states
        // But allow forcing a save for structural changes (add/remove components)
        if !force {
            // We removed the ID-based duplicate check because it prevented saving 
            // property/modifier changes where the component structure remained the same.
            // valid changes were being ignored.
            // We now rely on the debounce mechanism and explicit calls to ensure minimal duplicates.
        }
        
        print("💾 saveState: Saving state with \(state.components.count) components, force=\(force)")
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
        
        // Notify of design change to trigger persistence
        // This ensures that deep structural changes (handled by this method) get persisted
        // even if they didn't trigger the @Published components property wrapper.
        NotificationCenter.default.post(name: .designChanged, object: nil)
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
            components: deepCopyComponents(components)
        )
        redoStack.append(currentState)
        
        let previousState = undoStack.removeLast()
        restoreState(previousState)
    }
    
    func redo() {
        guard !redoStack.isEmpty else { return }
        
        let currentState = CanvasState(
            components: deepCopyComponents(components)
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
        
        // Restore components only - preserve current selection
        components = deepCopyComponents(state.components)
        
        // If selected component no longer exists, clear selection
        // Update selectedComponent to point to the new instance in the restored components
        if let selectedId = selectedComponent?.id {
            if let restoredComponent = findComponent(by: selectedId) {
                selectedComponent = restoredComponent
                // Ensure IDs set is consistent
                if !selectedComponentIds.contains(selectedId) {
                    selectedComponentIds = [selectedId]
                }
            } else {
                // Component removed in this state
                selectedComponent = nil
                selectedComponentIds.removeAll()
            }
        }
        
        // Update lastSavedState to match restored state to prevent duplicate saves
        lastSavedState = CanvasState(
            components: deepCopyComponents(state.components)
        )
    }
    
    // MARK: - Overlay Management
    func createOverlayFolder(for component: UIComponent) {
        // Create a default overlay component (a simple text badge)
        let overlayComponent = UIComponent(
            type: .text,
            properties: [
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Badge", defaultValue: "Badge")
            ],
            frame: CGRect(x: 0, y: 0, width: 50, height: 20),
            modifiers: [
                ComponentModifier(type: .font, properties: ["fontSize": "caption", "fontWeight": "bold"])
            ],
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
        // Reset image counter to ensure deterministic variable naming
        CodeGenerator.resetImageCounter()
        
        // Clean the design name to make it a valid Swift identifier
        // Remove all characters that aren't alphanumeric
        let cleanedName = designName.filter { $0.isLetter || $0.isNumber }
        let viewName = "\(cleanedName.isEmpty ? "Generated" : cleanedName)View"
        
        var code = """
        import SwiftUI

        struct \(viewName): View {
            var body: some View {
        """
        
        var bodyContent = ""
        if components.isEmpty {
            bodyContent = "        Text(\"No components added yet\")"
        } else {
            for (index, component) in components.enumerated() {
                let componentCode = CodeGenerator.generateCode(for: component, indentLevel: 2)
                bodyContent += (index > 0 ? "\n" : "") + componentCode
            }
        }
        
        code += "\n" + bodyContent
        

        
        code += "\n    }\n}\n\n#Preview {\n    \(viewName)()\n}"
        
        return code
    }
}

// MARK: - Canvas State
struct CanvasState {
    let components: [UIComponent]
}
