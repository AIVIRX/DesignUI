
import SwiftUI
import Combine

@inline(__always)
func debugLog(_ message: @autoclosure () -> String) {
    _ = message
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
    private var layoutTransitionWorkItem: DispatchWorkItem?
    
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
    @Published var lastActionDescription: String = ""
    @Published var lastActionTimestamp: Date = .distantPast
    private var undoStack: [UndoableAction] = []
    private var redoStack: [UndoableAction] = []
    private let maxUndoSteps = 50

    @Published var undoMessage: String? = nil
    private var lastDuplicateTimestamp: Date = .distantPast
    
    private var statusBarCancellable: AnyCancellable?
    private let layoutAnimation = Animation.spring(response: 0.35, dampingFraction: 0.85)
    
    var hasScrollableComponent: Bool {
        return containsComponent(ofType: .scrollView, in: components)
    }
    
    var hasPlatformViewComponent: Bool {
        // ProgressView on macOS can bridge through AppKit and doesn't play well with drawingGroup flattening.
        return containsComponent(ofType: .progressView, in: components)
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

    func addComponent(_ component: UIComponent) {
        registerUndoAction("Added \(component.type.rawValue)")
        beginLayoutTransition(duration: 0.35)
        withAnimation(layoutAnimation) {
            components.append(component)
            selectedComponent = component
        }
    }

    func replaceComponent(_ component: UIComponent, with replacement: UIComponent, registerUndo: Bool = true, undoDescription: String = "AI Edit") {
        if registerUndo {
            registerUndoAction(undoDescription)
        }
        beginLayoutTransition(duration: 0.35)

        replacement.modifierId = component.modifierId
        replacement.modifierType = component.modifierType
        replacement.isOverlay = component.isOverlay

        withAnimation(layoutAnimation) {
            if let parentId = findParentId(of: component.id), let parentComponent = findComponent(by: parentId) {
                if let index = parentComponent.children.firstIndex(where: { $0.id == component.id }) {
                    parentComponent.children[index] = replacement
                } else {
                    parentComponent.addChild(replacement)
                }
            } else if let index = components.firstIndex(where: { $0.id == component.id }) {
                components[index] = replacement
            } else {
                components.append(replacement)
            }
            
            selectedComponent = replacement
            selectedComponentIds = [replacement.id]
        }
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func canAcceptChildren(_ component: UIComponent) -> Bool {
        switch component.type {
        case .scrollView, .stack, .vstack, .hstack, .zstack, .button:
            return true
        default:
            return false
        }
    }
    
    func removeComponent(_ component: UIComponent) {
        debugLog("🗑️ removeComponent: Removing component \(component.id.uuidString.prefix(8)), current count: \(components.count)")
        
        guard let actualComponent = findComponent(by: component.id) else {
            debugLog("⚠️ removeComponent: Component not found in hierarchy")
            return
        }
        
        registerUndoAction("Deleted \(actualComponent.type.rawValue)")
        beginLayoutTransition(duration: 0.35)
        
        if let modifierId = actualComponent.modifierId {
            debugLog("🔗 removeComponent: Component is a modifier child (modifierId: \(modifierId.uuidString.prefix(8)))")
            
            if let parent = findParentComponent(of: actualComponent.id) {
                if let modifierIndex = parent.modifiers.firstIndex(where: { $0.id == modifierId }) {
                    debugLog("🔗 removeComponent: Removing modifier at index \(modifierIndex) from parent")
                    parent.modifiers.remove(at: modifierIndex)
                    
                    DispatchQueue.main.async {
                        self.notifyChange(for: parent)
                    }
                }
            }
        }
        
        var idsToRemove: Set<UUID> = [actualComponent.id]
        collectDescendantIds(from: actualComponent, into: &idsToRemove)
        
        debugLog("🗑️ removeComponent: Removing \(idsToRemove.count) components (including \(idsToRemove.count - 1) children)")
        
        withAnimation(layoutAnimation) {
            removeComponentsRecursively(ids: idsToRemove, from: &components)
            
            if let selectedId = selectedComponent?.id, idsToRemove.contains(selectedId) {
                selectedComponent = nil
            }
        }
        
        debugLog("🗑️ removeComponent: After removal, count: \(components.count)")
    }
    
    private func collectDescendantIds(from component: UIComponent, into ids: inout Set<UUID>) {
        for child in component.children {
            ids.insert(child.id)
            collectDescendantIds(from: child, into: &ids)
        }
    }
    
    private func removeComponentsRecursively(ids: Set<UUID>, from components: inout [UIComponent]) {
        for i in components.indices.reversed() {
            removeComponentsRecursively(ids: ids, from: &components[i].children)
            
            if ids.contains(components[i].id) {
                components.remove(at: i)
            }
        }
    }
    
    func selectComponent(_ component: UIComponent, additive: Bool = false) {
        if additive {
            if selectedComponentIds.contains(component.id) {
                selectedComponentIds.remove(component.id)
                if selectedComponent?.id == component.id {
                    selectedComponent = selectedComponentIds.isEmpty ? nil : findComponent(by: selectedComponentIds.first!)
                }
            } else {
                selectedComponentIds.insert(component.id)
                selectedComponent = component
            }
        } else {
            selectedComponentIds = [component.id]
            selectedComponent = component
        }
    }
    
    func deselectAll() {
        selectedComponent = nil
        selectedComponentIds.removeAll()
    }
    
    func getDesignAsJSON(includeIds: Bool = false) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if !includeIds, let excludeIdsKey = CodingUserInfoKey(rawValue: "excludeIds") {
            encoder.userInfo[excludeIdsKey] = true
        }
        
        let template = DesignTemplate(
            name: self.designName,
            description: "Exported from DesignUI",
            thumbnail: "blank", // Default placeholder
            devicePreset: self.devicePreset.rawValue,
            canvasColorScheme: self.colorScheme == .light ? "light" : (self.colorScheme == .dark ? "dark" : nil),
            statusBarVisible: self.statusBarVisible,
            statusBarTopSafeArea: self.statusBarTopSafeArea,
            components: self.components
        )
        
        if let data = try? encoder.encode(template),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "{}"
    }

    func getSelectedComponentJSON() -> String? {
        guard let selected = selectedComponent else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let excludeIdsKey = CodingUserInfoKey(rawValue: "excludeIds") {
            encoder.userInfo[excludeIdsKey] = true
        }
        if let data = try? encoder.encode(selected),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return nil
    }

    func countComponents(in component: UIComponent) -> Int {
        var count = 1
        for child in component.children {
            count += countComponents(in: child)
        }
        return count
    }
    
    func moveComponentInHierarchy(componentId: UUID, newParentId: UUID?, toIndex: Int) {
        registerUndoAction("Reorder Layer")
        beginLayoutTransition(duration: 0.35)

        withAnimation(layoutAnimation) {
            guard let moved = removeComponentRecursively(id: componentId) else { return }

            if let parentId = newParentId, let parent = findComponent(by: parentId) {
                if canAcceptChildren(parent) {
                    let safeIndex = max(0, min(toIndex, parent.children.count))
                    parent.children.insert(moved, at: safeIndex)
                } else {
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
        }

        NotificationCenter.default.post(name: .designChanged, object: nil)
    }

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
    
    func findParentComponent(of targetId: UUID) -> UIComponent? {
        guard let parentId = findParentId(of: targetId) else { return nil }
        return findComponent(by: parentId)
    }

    func findComponent(by id: UUID) -> UIComponent? {
        if let found = components.first(where: { $0.id == id }) { return found }
        for root in components {
            if let found = findComponentRecursively(in: root, id: id) { return found }
        }
        
        if let statusBar = statusBarComponent, statusBar.id == id {
            return statusBar
        }
        return nil
    }

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
        registerUndoAction("Duplicated \(component.type.rawValue)", coalesceKey: "duplicate-component")

        // Rapid duplicate spam can lag from repeated animations and layout transitions.
        // Keep first duplicate animated, but collapse subsequent rapid duplicates to a direct insert.
        let now = Date()
        let isRapidDuplicate = now.timeIntervalSince(lastDuplicateTimestamp) < 0.12
        lastDuplicateTimestamp = now

        let insertDuplicate = {
            if let parentId = self.findParentId(of: component.id), let parentComponent = self.findComponent(by: parentId) {
                if let originalIndex = parentComponent.children.firstIndex(where: { $0.id == component.id }) {
                    parentComponent.children.insert(duplicatedComponent, at: originalIndex + 1)
                } else {
                    parentComponent.addChild(duplicatedComponent)
                }
            } else {
                if let originalIndex = self.components.firstIndex(where: { $0.id == component.id }) {
                    self.components.insert(duplicatedComponent, at: originalIndex + 1)
                    self.selectedComponent = duplicatedComponent
                } else {
                    self.components.append(duplicatedComponent)
                }
            }
            
            if self.selectedComponent?.id != duplicatedComponent.id {
                self.selectedComponent = duplicatedComponent
            }
        }

        if isRapidDuplicate {
            insertDuplicate()
        } else {
            beginLayoutTransition(duration: 0.35)
            withAnimation(layoutAnimation) {
                insertDuplicate()
            }
        }
    }
    
    func wrapComponent(_ component: UIComponent, in type: ComponentType) {
        guard isWrappableContainerType(type) else { return }
        beginLayoutTransition(duration: 0.35)

        if let parentComponent = parentComponent(for: component.id) {
            wrapComponentAsChild(component, in: type, parentComponent: parentComponent)
            return
        }

        wrapComponentAtRoot(component, in: type)
    }

    private func isWrappableContainerType(_ type: ComponentType) -> Bool {
        switch type {
        case .stack, .vstack, .hstack, .zstack, .scrollView:
            return true
        default:
            return false
        }
    }

    private func parentComponent(for componentId: UUID) -> UIComponent? {
        guard let parentId = findParentId(of: componentId) else { return nil }
        return findComponent(by: parentId)
    }

    private func makeContainer(of type: ComponentType) -> UIComponent {
        UIComponent(
            type: type,
            properties: UIComponent.defaultProperties(for: type),
            children: []
        )
    }

    private func wrapComponentAsChild(_ component: UIComponent, in type: ComponentType, parentComponent: UIComponent) {
        guard let index = parentComponent.children.firstIndex(where: { $0.id == component.id }) else { return }

        let container = makeContainer(of: type)
        withAnimation(layoutAnimation) {
            parentComponent.children.remove(at: index)
            container.addChild(component)
            parentComponent.children.insert(container, at: index)
            selectedComponent = container
        }
    }

    private func wrapComponentAtRoot(_ component: UIComponent, in type: ComponentType) {
        guard let index = components.firstIndex(where: { $0.id == component.id }) else { return }

        let container = makeContainer(of: type)
        withAnimation(layoutAnimation) {
            components.remove(at: index)
            container.addChild(component)
            components.insert(container, at: index)
            selectedComponent = container
        }
    }
    
    private func createDeepCopy(of component: UIComponent) -> UIComponent {
        let duplicatedModifiers = component.modifiers.map { modifier in
            ComponentModifier(
                type: modifier.type,
                properties: deepCopyDictionary(modifier.properties)
            )
        }
        
        let duplicatedChildren = component.children.map { child in
            createDeepCopy(of: child)
        }
        
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
    
    private func deepCopyDictionary(_ dict: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in dict {
            result[key] = deepCopyValue(value)
        }
        return result
    }
    
    private func deepCopyValue(_ value: Any) -> Any {
        if let array = value as? [Any] {
            return array.map { deepCopyValue($0) }
        } else if let dict = value as? [String: Any] {
            return deepCopyDictionary(dict)
        } else {
            return value
        }
    }
    
    func getAbsoluteFrame(for component: UIComponent) -> CGRect {
        var frame = component.frame
        
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
        guard deviceSize.width > 0 && deviceSize.height > 0 else {
            zoomLevel = 1.0
            canvasOffset = .zero
            return
        }
        
        let padding: CGFloat = 100
        let availableWidth = canvasSize.width - padding * 2
        let availableHeight = canvasSize.height - padding * 2
        
        let zoomX = availableWidth / deviceSize.width
        let zoomY = availableHeight / deviceSize.height
        
        let calculatedZoom = min(zoomX, zoomY)
        
        zoomLevel = max(min(calculatedZoom, 2.0), 0.8)
        canvasOffset = .zero
    }
    
    func saveInitialState() {
        isRestoringState = false
        
        undoStack.removeAll()
        redoStack.removeAll()
    }
    
    func registerUndoAction(_ description: String, coalesceKey: String? = nil) {
        guard !isRestoringState else {
            debugLog("🔄 registerUndoAction: Skipping - currently restoring state")
            return
        }
        
        if let key = coalesceKey, let lastAction = undoStack.last,
           lastAction.coalesceKey == key,
           Date().timeIntervalSince(lastAction.timestamp) < 1.0 { // 1.0 second threshold
            debugLog("🔄 registerUndoAction: Coalescing with previous action '\(key)'")
            
            let updatedAction = UndoableAction(
                description: description,
                stateBefore: lastAction.stateBefore,
                timestamp: Date(),
                coalesceKey: key
            )
            undoStack.removeLast()
            undoStack.append(updatedAction)
            lastActionDescription = description
            lastActionTimestamp = Date()
            return
        }
        
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
        
        redoStack.removeAll()
        
        debugLog("💾 registerUndoAction: '\(description)'")
        lastActionDescription = description
        lastActionTimestamp = Date()
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
    
    private func deepCopyComponents(_ components: [UIComponent]) -> [UIComponent] {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(components)
            
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
            return components
        }
    }
    
    private var isRestoringState: Bool = false
    
    func undo() {
        guard let action = undoStack.popLast() else {
            debugLog("↩️ undo: Cannot undo - stack empty")
            return
        }
        
        debugLog("↩️ undo: '\(action.description)' - stack has \(undoStack.count) remaining")
        
        let currentState = currentCanvasState()
        let redoAction = UndoableAction(
            description: action.description,
            stateBefore: currentState,
            timestamp: Date(),
            coalesceKey: action.coalesceKey
        )
        redoStack.append(redoAction)
        
        restoreState(action.stateBefore)
        
        showUndoMessage(prefix: "Undo", description: action.description)
        lastActionDescription = "Undo: \(action.description)"
        lastActionTimestamp = Date()
        undoStackVersion += 1
    }
    
    func redo() {
        guard let action = redoStack.popLast() else {
            debugLog("↪️ redo: Cannot redo - stack empty")
            return
        }
        
        debugLog("↪️ redo: '\(action.description)' - redo stack has \(redoStack.count) remaining")
        
        let currentState = currentCanvasState()
        let undoAction = UndoableAction(
            description: action.description,
            stateBefore: currentState,
            timestamp: Date(),
            coalesceKey: action.coalesceKey
        )
        undoStack.append(undoAction)
        
        restoreState(action.stateBefore)
        
        showUndoMessage(prefix: "Redo", description: action.description)
        lastActionDescription = "Redo: \(action.description)"
        lastActionTimestamp = Date()
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
        
        isRestoringState = true
                
        components = deepCopyComponents(state.components)
        
        self.colorScheme = state.colorScheme
        
        if let savedStatusBar = state.statusBarComponent {
            self.statusBarComponent = savedStatusBar.clone()
            observeStatusBarChanges()
        } else {
            self.statusBarComponent = nil
        }
        
        self.devicePreset = state.devicePreset
        
        if let selectedId = selectedComponent?.id {
            if let restoredComponent = findComponent(by: selectedId) {
                restoredComponent.objectWillChange.send()
                selectedComponent = restoredComponent
                if !selectedComponentIds.contains(selectedId) {
                    selectedComponentIds = [selectedId]
                }
            } else {
                selectedComponent = nil
                selectedComponentIds.removeAll()
            }
        }
        
        isRestoringState = false
        
        objectWillChange.send()
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
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

    func updateModifierContinuous(for component: UIComponent, modifier: ComponentModifier) {
        withActualComponent(component, log: "updateModifierContinuous") { actualComponent in
            actualComponent.updateModifierContinuous(modifier)
            // Continuous drags should stay responsive and avoid full design-change fanout each tick.
            notifyChange(for: actualComponent, postDesignChanged: false)
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

    func updateComponentPropertyContinuous(for component: UIComponent, key: String, value: Any) {
        updateComponentPropertyInternal(
            component,
            key: key,
            value: value,
            registerUndo: false,
            continuous: true
        )
    }

    func updateComponentProperties(
        for component: UIComponent,
        updates: [(key: String, value: Any)],
        description: String,
        coalesceKey: String? = nil
    ) {
        guard !updates.isEmpty else { return }

        withActualComponent(component, log: "updateComponentProperties") { actualComponent in
            registerUndoAction(description, coalesceKey: coalesceKey)

            for update in updates {
                actualComponent.setProperty(key: update.key, value: update.value)
                syncStatusBarFlags(for: actualComponent, key: update.key, value: update.value)
            }

            syncSelectionIfNeeded(actualComponent)
            notifyChange(for: actualComponent, notifyManager: true)
        }
    }

    func updateImageSelection(
        for component: UIComponent,
        imageName: String,
        propertyKey: String = "imageName"
    ) {
        let coalesceKey = "update_image_\(component.id.uuidString)_\(propertyKey)"
        let updates: [(key: String, value: Any)]

        if propertyKey == "imageData" {
            updates = [
                (key: "imageData", value: imageName),
                (key: "imageName", value: "")
            ]
        } else {
            updates = [
                (key: propertyKey, value: imageName),
                (key: "imageData", value: "")
            ]
        }

        updateComponentProperties(
            for: component,
            updates: updates,
            description: "Updated Image",
            coalesceKey: coalesceKey
        )
    }

    func clearImageSelection(
        for component: UIComponent,
        propertyKey: String = "imageName"
    ) {
        let coalesceKey = "clear_image_\(component.id.uuidString)_\(propertyKey)"
        let updates: [(key: String, value: Any)]

        if propertyKey == "imageData" {
            updates = [
                (key: "imageData", value: ""),
                (key: "imageName", value: "")
            ]
        } else {
            updates = [
                (key: propertyKey, value: ""),
                (key: "imageName", value: "")
            ]
        }

        updateComponentProperties(
            for: component,
            updates: updates,
            description: "Cleared Image",
            coalesceKey: coalesceKey
        )
    }

    func createOverlayFolder(for component: UIComponent) {
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
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func setDevicePreset(_ preset: DevicePreset) {
        guard preset != devicePreset else { return }
        
        registerUndoAction("Change Canvas Size")
        self.isLayoutTransitioning = true
        self.devicePreset = preset
        centerCanvasTrigger.toggle()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLayoutTransitioning = false
        }
        
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }

    func setDesignName(_ name: String) {
        designName = name
    }
    
    func exportCode() -> String {
        CodeGenerator.resetImageCounter()
        
        let cleanedName = designName.filter { $0.isLetter || $0.isNumber }
        let viewName = "\(cleanedName.isEmpty ? "Generated" : cleanedName)View"
        
        var imports = ["import SwiftUI"]
        if containsComponent(ofType: .chart, in: components) {
            imports.append("import Charts")
        }
        var code = imports.joined(separator: "\n")
        code += "\n\nstruct \(viewName): View {\n    var body: some View {"
        
        var bodyContent = ""
        
        let showStatusBar = statusBarComponent?.getProperty(key: "showStatusBar") as? Bool ?? true
        let shouldIgnoreSafeArea = !showStatusBar
        
        if components.isEmpty {
            bodyContent = "        Text(\"No components added yet\")"
        } else if shouldIgnoreSafeArea {
            if components.count == 1 {
                let component = components[0]
                var componentCode = CodeGenerator.generateCode(for: component, indentLevel: 2)
                componentCode += "\n            .ignoresSafeArea()"
                bodyContent = componentCode
            } else {
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

    private func notifyChange(
        for component: UIComponent,
        notifyManager: Bool = false,
        postDesignChanged: Bool = true
    ) {
        component.objectWillChange.send()
        if notifyManager { objectWillChange.send() }
        if postDesignChanged {
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }

    private func syncStatusBarFlags(for component: UIComponent, key: String, value: Any) {
        guard component.type == .statusBar else { return }
        if key == "showStatusBar", let boolValue = value as? Bool {
            statusBarVisible = boolValue
        } else if key == "topSafeArea", let boolValue = value as? Bool {
            statusBarTopSafeArea = boolValue
            beginLayoutTransition(duration: 0.35)
        }
    }

    private func beginLayoutTransition(duration: TimeInterval) {
        if Thread.isMainThread {
            isLayoutTransitioning = true
            layoutTransitionWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.isLayoutTransitioning = false
            }
            layoutTransitionWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
        } else {
            DispatchQueue.main.async {
                self.isLayoutTransitioning = true
                self.layoutTransitionWorkItem?.cancel()
                let workItem = DispatchWorkItem { [weak self] in
                    self?.isLayoutTransitioning = false
                }
                self.layoutTransitionWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: workItem)
            }
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
            notifyChange(
                for: actualComponent,
                notifyManager: !continuous,
                postDesignChanged: !continuous
            )
        }
    }
}

struct CanvasState {
    let components: [UIComponent]
    let colorScheme: ColorScheme?
    let devicePreset: DevicePreset
    let statusBarComponent: UIComponent?
}

struct UndoableAction {
    let description: String  // e.g., "Deleted Text component"
    let stateBefore: CanvasState  // State before the action (for undo)
    let timestamp: Date  // When this action occurred (for coalescing)
    let coalesceKey: String? // Key for grouping related actions (e.g. typing)
}
