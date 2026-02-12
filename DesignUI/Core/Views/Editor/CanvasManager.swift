//
//  CanvasManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Combine

@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    #if DEBUG
    print(message())
    #endif
}

class CanvasManager: ObservableObject {
    @Published var components: [UIComponent] = []
    @Published var isHoveringScrollable: Bool = false
    
    @Published var selectedComponent: UIComponent? {
        didSet {
            if let component = selectedComponent {
                if !selectedComponentIds.contains(component.id) {
                    selectedComponentIds = [component.id]
                }
            } else {
                if !selectedComponentIds.isEmpty {
                    selectedComponentIds.removeAll()
                }
            }
        }
    }
    
    @Published var selectedComponentIds: Set<UUID> = []
    @Published var zoomLevel: CGFloat = 1.0
    @Published var canvasOffset: CGSize = .zero
    @Published var centerCanvasTrigger: Bool = false
    @Published var scrollToSelectionTrigger: Bool = false
    @Published var isTextInputActive: Bool = false
    @Published var isPropertiesSheetPresented: Bool = false
    @Published var didUserDeselect: Bool = false
    @Published var isOverlayPanelOpen: Bool = false
    
    @Published var statusBarComponent: UIComponent?
    
    @Published var isLayoutTransitioning: Bool = false
    
    @Published var designName: String = "GeneratedView"
    
    @Published var colorScheme: ColorScheme? = nil
    @Published var devicePreset: DevicePreset = .iphone16Pro
    
    @Published var statusBarVisible: Bool = true {
        didSet { updateStatusBarComponentFromSettings() }
    }
    @Published var statusBarTopSafeArea: Bool = true {
        didSet { updateStatusBarComponentFromSettings() }
    }
    private var isSyncingStatusBarSettings: Bool = false

    @Published var undoStackVersion: Int = 0 
    private var undoStack: [UndoableAction] = []
    private var redoStack: [UndoableAction] = []
    private let maxUndoSteps = 50

    @Published var undoMessage: String? = nil
    
    private var statusBarCancellable: AnyCancellable?
    
    var hasMapComponent: Bool {
        return false
    }

    var hasScrollableComponent: Bool {
        return containsComponent(ofType: .scrollView, in: components)
    }

    private func containsComponent(ofType type: ComponentType, in components: [UIComponent]) -> Bool {
        for component in components {
            if component.type == type {
                return true
            }
            if containsComponent(ofType: type, in: component.children) {
                return true
            }
        }
        return false
    }
    
    var canUndo: Bool { 
        // Can undo if we have at least one action
        !undoStack.isEmpty
    }
    var canRedo: Bool { !redoStack.isEmpty }
    
    init() {
        components = []
        selectedComponent = nil
        colorScheme = nil
        statusBarComponent = createStatusBarComponent()
        syncStatusBarSettingsFromComponent()
        observeStatusBarChanges()
        
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
            properties: UIComponent.defaultProperties(for: .statusBar),
            frame: CGRect(x: 0, y: 0, width: 393, height: 50) // Default iPhone width
        )
        return statusBarComponent
    }
    
    private func observeStatusBarChanges() {
        statusBarCancellable?.cancel()
        statusBarCancellable = statusBarComponent?.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }
            self.registerUndoAction("Updated Canvas Settings")
        }
    }

    private func syncStatusBarSettingsFromComponent() {
        guard !isSyncingStatusBarSettings else { return }
        isSyncingStatusBarSettings = true
        defer { isSyncingStatusBarSettings = false }
        guard let statusBar = statusBarComponent else { return }
        if let show = boolProperty(from: statusBar, key: "showStatusBar") { statusBarVisible = show }
        if let topSafeArea = boolProperty(from: statusBar, key: "topSafeArea") { statusBarTopSafeArea = topSafeArea }
    }

    private func updateStatusBarComponentFromSettings() {
        guard !isSyncingStatusBarSettings else { return }
        isSyncingStatusBarSettings = true
        defer { isSyncingStatusBarSettings = false }
        guard let statusBar = statusBarComponent else { return }
        updateComponentProperty(for: statusBar, key: "showStatusBar", value: statusBarVisible)
        updateComponentProperty(for: statusBar, key: "topSafeArea", value: statusBarTopSafeArea)
    }

    private func boolProperty(from component: UIComponent, key: String) -> Bool? {
        component.properties.first(where: { $0.key == key })?.value as? Bool
    }
    
    func validateStatusBarProperties() {
        guard let statusBar = statusBarComponent else {
            statusBarComponent = createStatusBarComponent()
            observeStatusBarChanges()
            syncStatusBarSettingsFromComponent()
            return
        }
        
        let defaults = UIComponent.defaultProperties(for: .statusBar)
        let defaultKeys = Set(defaults.map { $0.key })
        
        var currentProps = statusBar.properties
        var changed = false
        
        let filteredProps = currentProps.filter { defaultKeys.contains($0.key) }
        if filteredProps.count != currentProps.count {
            currentProps = filteredProps
            changed = true
        }
        
        for defaultProp in defaults {
            if !currentProps.contains(where: { $0.key == defaultProp.key }) {
                currentProps.append(defaultProp)
                changed = true
            }
        }
        
        if changed {
            statusBar.properties = currentProps
            objectWillChange.send()
        }
        observeStatusBarChanges()
        syncStatusBarSettingsFromComponent()
    }

    // MARK: - Component Management
    func addComponent(_ component: UIComponent) {
        // Register undo action with description BEFORE making the change
        registerUndoAction("Added \(component.type.rawValue)")
        
        components.append(component)
        selectedComponent = component
    }
    
    func canAcceptChildren(_ component: UIComponent) -> Bool {
        switch component.type {
        case .scrollView, .vstack, .hstack, .zstack, .button:
            return true
        default:
            return false
        }
    }
    
    func removeComponent(_ component: UIComponent) {
        debugLog("🗑️ removeComponent: Removing component \(component.id.uuidString.prefix(8)), current count: \(components.count)")
        
        // Find the actual component in the hierarchy to get its full children tree
        guard let actualComponent = findComponent(by: component.id) else {
            debugLog("⚠️ removeComponent: Component not found in hierarchy")
            return
        }
        
        // Register undo action with description BEFORE making the change
        registerUndoAction("Deleted \(actualComponent.type.rawValue)")
        
        // Check if this is a modifier-child (mask/background/overlay parent component)
        // If so, we need to also remove the modifier from the parent component
        if let modifierId = actualComponent.modifierId {
            debugLog("🔗 removeComponent: Component is a modifier child (modifierId: \(modifierId.uuidString.prefix(8)))")
            
            // Find the parent component that owns this modifier
            if let parent = findParentComponent(of: actualComponent.id) {
                // Remove the modifier from the parent
                if let modifierIndex = parent.modifiers.firstIndex(where: { $0.id == modifierId }) {
                    debugLog("🔗 removeComponent: Removing modifier at index \(modifierIndex) from parent")
                    parent.modifiers.remove(at: modifierIndex)
                    
                    // Force parent to notify observers and trigger UI refresh
                    DispatchQueue.main.async {
                        self.notifyChange(for: parent)
                    }
                }
            }
        }
        
        // Collect all descendant IDs (including the component itself and all its children recursively)
        var idsToRemove: Set<UUID> = [actualComponent.id]
        collectDescendantIds(from: actualComponent, into: &idsToRemove)
        
        debugLog("🗑️ removeComponent: Removing \(idsToRemove.count) components (including \(idsToRemove.count - 1) children)")
        
        // Remove from nested children recursively (this handles both top-level and nested components)
        removeComponentsRecursively(ids: idsToRemove, from: &components)
        
        // Clear selection if the selected component or any of its descendants were removed
        if let selectedId = selectedComponent?.id, idsToRemove.contains(selectedId) {
            selectedComponent = nil
        }
        
        debugLog("🗑️ removeComponent: After removal, count: \(components.count)")
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
    
    func deselectAll() {
        selectedComponent = nil
        selectedComponentIds.removeAll()
    }
    
    func getDesignAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let excludeIdsKey = CodingUserInfoKey(rawValue: "excludeIds") {
            encoder.userInfo[excludeIdsKey] = true
        }
        
        // create a temporary DesignTemplate from current state
        let template = DesignTemplate(
            name: self.designName,
            description: "Exported from DesignUI",
            thumbnail: "blank", // Default placeholder
            devicePreset: self.devicePreset.rawValue,
            canvasColorScheme: self.colorScheme == .light ? "light" : (self.colorScheme == .dark ? "dark" : nil),
            components: self.components
        )
        
        if let data = try? encoder.encode(template),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }
    
    // MARK: - Hierarchy Manipulation
    /// Move a component in the hierarchy to a new parent and position
    func moveComponentInHierarchy(componentId: UUID, newParentId: UUID?, toIndex: Int) {
        // Register undo before making changes
        registerUndoAction("Reorder Layer")
        
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
        // designChanged is sufficient for file persistence
        NotificationCenter.default.post(name: .designChanged, object: nil)
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
    
    /// Find the parent component of a given component ID
    func findParentComponent(of targetId: UUID) -> UIComponent? {
        guard let parentId = findParentId(of: targetId) else { return nil }
        return findComponent(by: parentId)
    }

    /// Find a component by id anywhere in the hierarchy
    func findComponent(by id: UUID) -> UIComponent? {
        if let found = components.first(where: { $0.id == id }) { return found }
        for root in components {
            if let found = findComponentRecursively(in: root, id: id) { return found }
        }
        
        // Check status bar component
        if let statusBar = statusBarComponent, statusBar.id == id {
            return statusBar
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
                // Register undo BEFORE making the change
                registerUndoAction("Duplicated \(component.type.rawValue)")
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
                
                // Save state BEFORE making the change
                registerUndoAction("Duplicated \(component.type.rawValue)")
                
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
    }
    
    /// Wraps a component in a container (VStack, HStack, ZStack, ScrollView)
    func wrapComponent(_ component: UIComponent, in type: ComponentType) {
        // Only allow valid container types
        guard type == .vstack || type == .hstack || type == .zstack || type == .scrollView else { return }
        
        let container = UIComponent(
            type: type,
            properties: UIComponent.defaultProperties(for: type),
            children: []
        )
        
        // Find parent and index
        if let parentId = findParentId(of: component.id), let parentComponent = findComponent(by: parentId) {
            if let index = parentComponent.children.firstIndex(where: { $0.id == component.id }) {
                // Cancel any pending debounced saves
                
                // Remove original from parent
                parentComponent.children.remove(at: index)
                
                // Add original to new container
                container.addChild(component)
                
                // Insert container at original index
                parentComponent.children.insert(container, at: index)
                
                // Select container
                selectedComponent = container
            }
        } else if let index = components.firstIndex(where: { $0.id == component.id }) {
            // Root component
            
            components.remove(at: index)
            container.addChild(component)
            components.insert(container, at: index)
            
            selectedComponent = container
        }
    }
    
    private func createDeepCopy(of component: UIComponent) -> UIComponent {
        // Deep copy modifiers with their properties
        let duplicatedModifiers = component.modifiers.map { modifier in
            ComponentModifier(
                type: modifier.type,
                properties: deepCopyDictionary(modifier.properties)
            )
        }
        
        // Recursively deep copy children
        let duplicatedChildren = component.children.map { child in
            createDeepCopy(of: child)
        }
        
        // Deep copy properties array (value can contain reference types like arrays)
        let duplicatedProperties = component.properties.map { prop in
            ComponentProperty(
                key: prop.key,
                displayName: prop.displayName,
                type: prop.type,
                value: deepCopyValue(prop.value),
                defaultValue: deepCopyValue(prop.defaultValue),
                options: prop.options,
            )
        }
        
        // Create new component with NEW UUID (UIComponent init generates new id)
        let duplicatedComponent = UIComponent(
            type: component.type,
            properties: duplicatedProperties,
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
    
    /// Deep copy a dictionary with Any values
    private func deepCopyDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = deepCopyValue(value)
        }
        return result
    }
    
    /// Deep copy any value, handling arrays and dictionaries
    private func deepCopyValue(_ value: Any) -> Any {
        if let array = value as? [Any] {
            return array.map { deepCopyValue($0) }
        } else if let dict = value as? [String: Any] {
            return deepCopyDictionary(dict)
        } else {
            return value
        }
    }
    
    /// Calculate absolute frame of a component including all parent offsets
    func getAbsoluteFrame(for component: UIComponent) -> CGRect {
        // Start with component's own frame
        var frame = component.frame
        
        // Find parent and add its origin recursively
        var current = component
        while let parentId = findParentId(of: current.id), let parent = findComponent(by: parentId) {
            frame.origin.x += parent.frame.origin.x
            frame.origin.y += parent.frame.origin.y
            current = parent
        }
        
        return frame
    }
    
    func setZoomLevel(_ level: CGFloat) {
        zoomLevel = min(max(level, 0.1), 3.0)
    }
    
    func zoomToFitDevice(_ deviceSize: CGSize, canvasSize: CGSize) {
        // Handle content-adaptive (noSize) mode - use a reasonable default zoom
        guard deviceSize.width > 0 && deviceSize.height > 0 else {
            // For noSize mode, just use 1.0 zoom centered
            zoomLevel = 1.0
            canvasOffset = .zero
            return
        }
        
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
    func saveInitialState() {
        isRestoringState = false
        
        // Clear undo/redo stacks for fresh start
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    func registerUndoAction(_ description: String, coalesceKey: String? = nil) {
        // Don't register while we're restoring (undo/redo in progress)
        guard !isRestoringState else {
            debugLog("🔄 registerUndoAction: Skipping - currently restoring state")
            return
        }
        
        // Coalescing logic:
        // If we have a coalesceKey, check if the last action matches it AND is recent (< 0.5s)
        if let key = coalesceKey, let lastAction = undoStack.last,
           lastAction.coalesceKey == key,
           Date().timeIntervalSince(lastAction.timestamp) < 1.0 { // 1.0 second threshold
            debugLog("🔄 registerUndoAction: Coalescing with previous action '\(key)'")
            // We update the description but KEEP the original stateBefore
            // This ensures undo reverts to the state BEFORE the *first* coalesced action
            
            // We need to replace the last action with a new one that has updated timestamp/description
            // but same stateBefore
            let updatedAction = UndoableAction(
                description: description,
                stateBefore: lastAction.stateBefore,
                timestamp: Date(),
                coalesceKey: key
            )
            undoStack.removeLast()
            undoStack.append(updatedAction)
            return
        }
        
        // Capture the current state BEFORE the change
        let stateBefore = currentCanvasState()
        
        let action = UndoableAction(
            description: description,
            stateBefore: stateBefore,
            timestamp: Date(),
            coalesceKey: coalesceKey
        )
        
        undoStack.append(action)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        
        // Clear redo stack when new action is performed
        redoStack.removeAll()
        
        debugLog("💾 registerUndoAction: '\(description)'")
        undoStackVersion += 1
    }

    private func currentCanvasState() -> CanvasState {
        CanvasState(
            components: deepCopyComponents(components),
            colorScheme: colorScheme,
            devicePreset: devicePreset,
            statusBarComponent: statusBarComponent?.clone()
        )
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
            debugLog("⚠️ Failed to deep copy components: \(error)")
            debugLog("⚠️ Error details: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .dataCorrupted(let context):
                    debugLog("⚠️ Data corrupted: \(context.debugDescription)")
                case .keyNotFound(let key, let context):
                    debugLog("⚠️ Key not found: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    debugLog("⚠️ Type mismatch: \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    debugLog("⚠️ Value not found: \(type) - \(context.debugDescription)")
                @unknown default:
                    debugLog("⚠️ Unknown decoding error")
                }
            }
            // Fallback: return original components (not ideal but prevents crash)
            return components
        }
    }
    
    // Track if we're currently restoring state (to avoid saving during undo/redo)
    private var isRestoringState: Bool = false
    
    func undo() {
        guard let action = undoStack.popLast() else {
            debugLog("↩️ undo: Cannot undo - stack empty")
            return
        }
        
        debugLog("↩️ undo: '\(action.description)' - stack has \(undoStack.count) remaining")
        
        // Save current state to redo stack BEFORE restoring (with the same description)
        let currentState = currentCanvasState()
        let redoAction = UndoableAction(
            description: action.description,
            stateBefore: currentState,
            timestamp: Date(),
            coalesceKey: action.coalesceKey
        )
        redoStack.append(redoAction)
        
        // Restore the previous state
        restoreState(action.stateBefore)
        
        // Show toast message
        showUndoMessage(prefix: "Undo", description: action.description)
        undoStackVersion += 1
    }
    
    func redo() {
        guard let action = redoStack.popLast() else {
            debugLog("↪️ redo: Cannot redo - stack empty")
            return
        }
        
        debugLog("↪️ redo: '\(action.description)' - redo stack has \(redoStack.count) remaining")
        
        // Save current state to undo stack BEFORE restoring
        let currentState = currentCanvasState()
        let undoAction = UndoableAction(
            description: action.description,
            stateBefore: currentState,
            timestamp: Date(),
            coalesceKey: action.coalesceKey
        )
        undoStack.append(undoAction)
        
        // Restore the redo state
        restoreState(action.stateBefore)
        
        // Show toast message
        showUndoMessage(prefix: "Redo", description: action.description)
        undoStackVersion += 1
    }

    private func showUndoMessage(prefix: String, description: String) {
        undoMessage = "\(prefix): \(description)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.undoMessage == "\(prefix): \(description)" {
                self?.undoMessage = nil
            }
        }
    }
    
    private func restoreState(_ state: CanvasState) {
        debugLog("↩️ restoreState: Restoring state with \(state.components.count) components")
        
        // Set flag to prevent undo state saving during restore
        isRestoringState = true
                
        // Restore components
        components = deepCopyComponents(state.components)
        
        // Restore color scheme
        self.colorScheme = state.colorScheme
        
        // Restore status bar
        if let savedStatusBar = state.statusBarComponent {
            self.statusBarComponent = savedStatusBar.clone()
            // Make sure we re-observe the new instance
            observeStatusBarChanges()
        } else {
            self.statusBarComponent = nil
        }
        
        // Restore device preset
        self.devicePreset = state.devicePreset
        
        // If selected component no longer exists, clear selection
        if let selectedId = selectedComponent?.id {
            if let restoredComponent = findComponent(by: selectedId) {
                // Force the new component to notify observers
                restoredComponent.objectWillChange.send()
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
        
        // Clear restore flag BEFORE posting notifications
        isRestoringState = false
        
        // Force CanvasManager to notify all observers (triggers UI refresh)
        objectWillChange.send()
        
        // Trigger file persistence
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    // MARK: - Modifier Management
    func addModifier(to component: UIComponent, modifier: ComponentModifier) {
        withActualComponent(component, log: "addModifier") { actualComponent in
            registerUndoAction("Added \(modifier.type.rawValue) modifier")
            actualComponent.addModifier(modifier)
            notifyChange(for: actualComponent)
        }
    }
    
    func removeModifier(from component: UIComponent, modifier: ComponentModifier) {
        withActualComponent(component, log: "removeModifier") { actualComponent in
            registerUndoAction("Deleted \(modifier.type.rawValue) modifier")
            actualComponent.removeModifier(modifier)
            notifyChange(for: actualComponent)
        }
    }
    
    func duplicateModifier(for component: UIComponent, modifier: ComponentModifier) {
        withActualComponent(component, log: "duplicateModifier") { actualComponent in
            guard let index = actualComponent.modifiers.firstIndex(where: { $0.id == modifier.id }) else { return }
            registerUndoAction("Duplicated \(modifier.type.rawValue) modifier")
            let duplicatedModifier = ComponentModifier(type: modifier.type, properties: modifier.properties)
            actualComponent.modifiers.insert(duplicatedModifier, at: index + 1)
            notifyChange(for: actualComponent)
        }
    }
    
    func moveModifier(for component: UIComponent, from source: IndexSet, to destination: Int) {
        withActualComponent(component, log: "moveModifier") { actualComponent in
            registerUndoAction("Reorder Modifiers")
            actualComponent.moveModifier(from: source, to: destination)
            notifyChange(for: actualComponent)
        }
    }
    
    func updateModifier(for component: UIComponent, modifier: ComponentModifier) {
        withActualComponent(component, log: "updateModifier") { actualComponent in
            let coalesceKey = "update_modifier_\(modifier.id.uuidString)"
            registerUndoAction("Updated \(modifier.type.rawValue)", coalesceKey: coalesceKey)
            actualComponent.updateModifier(modifier)
            notifyChange(for: actualComponent)
        }
    }
    
    func updateComponentProperty(for component: UIComponent, key: String, value: Any) {
        updateComponentPropertyInternal(
            component,
            key: key,
            value: value,
            registerUndo: true,
            continuous: false
        )
    }

    /// Update component property without registering undo (for continuous edits like typing)
    func updateComponentPropertyContinuous(for component: UIComponent, key: String, value: Any) {
        updateComponentPropertyInternal(
            component,
            key: key,
            value: value,
            registerUndo: false,
            continuous: true
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
    }
    
    func setColorScheme(_ scheme: ColorScheme?) {
        guard colorScheme != scheme else { return }
        
        registerUndoAction("Changed Color Scheme")
        colorScheme = scheme
        
        // Trigger design changed notification
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    /// Sets the device preset (canvas size) with undo support
    func setDevicePreset(_ preset: DevicePreset) {
        guard preset != devicePreset else { return }
        
        registerUndoAction("Change Canvas Size")
        self.isLayoutTransitioning = true
        self.devicePreset = preset
        centerCanvasTrigger.toggle()
        
        // Reset flag after a short delay to allow animation to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLayoutTransitioning = false
        }
        
        // Notify design changed immediately for this setting
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }

    func setDesignName(_ name: String) {
        designName = name
    }
    
    func exportCode() -> String {
        // Reset image counter to ensure deterministic variable naming
        CodeGenerator.resetImageCounter()
        
        // Clean the design name to make it a valid Swift identifier
        // Remove all characters that aren't alphanumeric
        let cleanedName = designName.filter { $0.isLetter || $0.isNumber }
        let viewName = "\(cleanedName.isEmpty ? "Generated" : cleanedName)View"
        
        var code = "import SwiftUI"
        
        if containsComponent(ofType: .chart, in: components) {
            code += "\nimport Charts"
        }
        
        code += """
        
        struct \(viewName): View {
            var body: some View {
        """
        
        var bodyContent = ""
        
        // Check if we should ignore safe area (when status bar is hidden)
        let showStatusBar = statusBarComponent?.getProperty(key: "showStatusBar") as? Bool ?? true
        let shouldIgnoreSafeArea = !showStatusBar
        
        if components.isEmpty {
            bodyContent = "        Text(\"No components added yet\")"
        } else if shouldIgnoreSafeArea {
            if components.count == 1 {
                // Single component - simple modifier append
                let component = components[0]
                var componentCode = CodeGenerator.generateCode(for: component, indentLevel: 2)
                componentCode += "\n            .ignoresSafeArea()"
                bodyContent = componentCode
            } else {
                // Multiple components - wrap in Group
                bodyContent = "        Group {"
                for component in components {
                    let componentCode = CodeGenerator.generateCode(for: component, indentLevel: 3)
                    bodyContent += "\n" + componentCode
                }
                bodyContent += "\n        }"
                bodyContent += "\n        .ignoresSafeArea()"
            }
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

    private func withActualComponent(_ component: UIComponent, log: String, _ body: (UIComponent) -> Void) {
        guard let actualComponent = findComponent(by: component.id) else {
            debugLog("⚠️ \(log): Component not found in hierarchy")
            return
        }
        body(actualComponent)
    }

    private func notifyChange(for component: UIComponent, notifyManager: Bool = false) {
        component.objectWillChange.send()
        if notifyManager { objectWillChange.send() }
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }

    private func syncStatusBarFlags(for component: UIComponent, key: String, value: Any) {
        guard component.type == .statusBar else { return }
        if key == "showStatusBar", let boolValue = value as? Bool {
            statusBarVisible = boolValue
        } else if key == "topSafeArea", let boolValue = value as? Bool {
            statusBarTopSafeArea = boolValue
        }
    }

    private func syncSelectionIfNeeded(_ component: UIComponent) {
        if selectedComponent?.id == component.id && selectedComponent !== component {
            selectedComponent = component
        }
    }

    private func updateComponentPropertyInternal(
        _ component: UIComponent,
        key: String,
        value: Any,
        registerUndo: Bool,
        continuous: Bool
    ) {
        withActualComponent(component, log: "updateComponentProperty") { actualComponent in
            if registerUndo {
                let coalesceKey = "update_property_\(component.id.uuidString)_\(key)"
                registerUndoAction("Updated \(key)", coalesceKey: coalesceKey)
            }
            if continuous {
                actualComponent.setPropertyContinuous(key: key, value: value)
            } else {
                actualComponent.setProperty(key: key, value: value)
            }
            syncStatusBarFlags(for: actualComponent, key: key, value: value)
            syncSelectionIfNeeded(actualComponent)
            notifyChange(for: actualComponent, notifyManager: true)
        }
    }
}

struct CanvasState {
    let components: [UIComponent]
    let colorScheme: ColorScheme?
    let devicePreset: DevicePreset
    let statusBarComponent: UIComponent?
}

/// Combines a human-readable description with a full state snapshot
struct UndoableAction {
    let description: String  // e.g., "Deleted Text component"
    let stateBefore: CanvasState  // State before the action (for undo)
    let timestamp: Date  // When this action occurred (for coalescing)
    let coalesceKey: String? // Key for grouping related actions (e.g. typing)
}
