import Foundation

// MARK: - Editor Action
/// All possible actions that can be performed in the editor (supports undo/redo)
enum EditorAction: Codable, Equatable {
    // Component Actions
    case addComponent(AddComponentPayload)
    case removeComponent(componentId: String, removeChildren: Bool)
    case duplicateComponent(componentId: String, insertAfter: Bool)
    case moveComponent(componentId: String, newParentId: String?, insertIndex: Int?)
    case groupComponents(componentIds: [String], containerType: DesignComponentType)
    case ungroupComponent(componentId: String)
    case renameComponent(componentId: String, name: String)
    
    // Property Actions
    case updateProperty(componentId: String, propertyName: String, value: AnyCodable)
    case updateProperties(componentId: String, properties: DesignComponentProperties)
    
    // Modifier Actions
    case addModifier(componentId: String, modifier: DesignModifier, insertIndex: Int?)
    case updateModifier(componentId: String, modifierId: String, modifier: DesignModifier)
    case removeModifier(componentId: String, modifierId: String)
    case reorderModifiers(componentId: String, modifierIds: [String])
    
    // Layer Actions
    case reorderLayers(layerOrder: [String])
    case setLayerVisibility(componentId: String, visible: Bool)
    case setLayerLock(componentId: String, locked: Bool)
    
    // Selection Actions
    case setSelection(componentIds: [String], multiSelect: Bool)
    case clearSelection
    
    // Canvas Actions
    case updateCanvas(settings: CanvasSettings)
    
    // History Actions
    case undo
    case redo
    
    // Project Actions
    case saveProject(name: String?, description: String?)
    case loadProject(projectId: String)
    
    var displayName: String {
        switch self {
        case .addComponent: return "Add Component"
        case .removeComponent: return "Remove Component"
        case .duplicateComponent: return "Duplicate Component"
        case .moveComponent: return "Move Component"
        case .groupComponents: return "Group Components"
        case .ungroupComponent: return "Ungroup Component"
        case .renameComponent: return "Rename Component"
        case .updateProperty: return "Update Property"
        case .updateProperties: return "Update Properties"
        case .addModifier: return "Add Modifier"
        case .updateModifier: return "Update Modifier"
        case .removeModifier: return "Remove Modifier"
        case .reorderModifiers: return "Reorder Modifiers"
        case .reorderLayers: return "Reorder Layers"
        case .setLayerVisibility: return "Set Layer Visibility"
        case .setLayerLock: return "Set Layer Lock"
        case .setSelection: return "Set Selection"
        case .clearSelection: return "Clear Selection"
        case .updateCanvas: return "Update Canvas"
        case .undo: return "Undo"
        case .redo: return "Redo"
        case .saveProject: return "Save Project"
        case .loadProject: return "Load Project"
        }
    }
    
    var isUndoable: Bool {
        switch self {
        case .undo, .redo, .saveProject, .loadProject, .setSelection, .clearSelection:
            return false
        default:
            return true
        }
    }
}

// MARK: - Action Payloads
struct AddComponentPayload: Codable, Equatable {
    var componentType: DesignComponentType
    var parentId: String?
    var insertIndex: Int?
    var initialProperties: DesignComponentProperties?
    var initialModifiers: [DesignModifier]?
    var name: String?
}

struct CanvasSettings: Codable, Equatable {
    var name: String?
    var backgroundColor: String?
    var gridEnabled: Bool?
    var gridSize: CGFloat?
    var snapToGrid: Bool?
    var zoom: CGFloat?
}

// MARK: - Action History
/// Manages undo/redo stacks
struct ActionHistory: Codable {
    var undoStack: [EditorAction]
    var redoStack: [EditorAction]
    var maxHistorySize: Int
    
    init(maxHistorySize: Int = 50) {
        self.undoStack = []
        self.redoStack = []
        self.maxHistorySize = maxHistorySize
    }
    
    mutating func push(_ action: EditorAction) {
        guard action.isUndoable else { return }
        undoStack.append(action)
        redoStack.removeAll() // Clear redo stack on new action
        
        // Trim history if needed
        if undoStack.count > maxHistorySize {
            undoStack.removeFirst(undoStack.count - maxHistorySize)
        }
    }
    
    mutating func undo() -> EditorAction? {
        guard let action = undoStack.popLast() else { return nil }
        redoStack.append(action)
        return action
    }
    
    mutating func redo() -> EditorAction? {
        guard let action = redoStack.popLast() else { return nil }
        undoStack.append(action)
        return action
    }
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    mutating func clear() {
        undoStack.removeAll()
        redoStack.removeAll()
    }
}

// MARK: - Action System State
struct ActionSystem: Codable {
    var pendingActions: [EditorAction]
    var history: ActionHistory
    
    init() {
        self.pendingActions = []
        self.history = ActionHistory()
    }
    
    mutating func dispatch(_ action: EditorAction) {
        pendingActions.append(action)
        history.push(action)
    }
    
    mutating func processPendingActions() -> [EditorAction] {
        let actions = pendingActions
        pendingActions.removeAll()
        return actions
    }
}

// MARK: - AnyCodable Helper
/// Type-erased Codable wrapper for dynamic property values
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            self.value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map(AnyCodable.init))
        case let dict as [String: Any]:
            try container.encode(dict.mapValues(AnyCodable.init))
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unable to encode value"))
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (is NSNull, is NSNull):
            return true
        case let (l as Bool, r as Bool):
            return l == r
        case let (l as Int, r as Int):
            return l == r
        case let (l as Double, r as Double):
            return l == r
        case let (l as String, r as String):
            return l == r
        default:
            return false
        }
    }
}
