import Foundation
import SwiftUI

// MARK: - Design Canvas
/// The main canvas configuration matching phone screen dimensions
struct DesignCanvas: Codable, Equatable {
    var id: String
    var name: String
    var width: CGFloat
    var height: CGFloat
    var backgroundColor: String
    var safeAreaInsets: SafeAreaInsets
    var gridEnabled: Bool
    var gridSize: CGFloat
    var snapToGrid: Bool
    var zoom: CGFloat
    var panOffset: CGPoint
    
    init(
        id: String = UUID().uuidString,
        name: String = "iPhone 14 Pro",
        width: CGFloat = 390,
        height: CGFloat = 844,
        backgroundColor: String = "#FFFFFF",
        safeAreaInsets: SafeAreaInsets = .iPhone14Pro,
        gridEnabled: Bool = false,
        gridSize: CGFloat = 8,
        snapToGrid: Bool = true,
        zoom: CGFloat = 1.0,
        panOffset: CGPoint = .zero
    ) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.backgroundColor = backgroundColor
        self.safeAreaInsets = safeAreaInsets
        self.gridEnabled = gridEnabled
        self.gridSize = gridSize
        self.snapToGrid = snapToGrid
        self.zoom = zoom
        self.panOffset = panOffset
    }
    
    // Preset device configurations
    static let iPhone14Pro = DesignCanvas(name: "iPhone 14 Pro", width: 390, height: 844)
    static let iPhone14ProMax = DesignCanvas(name: "iPhone 14 Pro Max", width: 430, height: 932)
    static let iPhoneSE = DesignCanvas(name: "iPhone SE", width: 375, height: 667, safeAreaInsets: .iPhoneSE)
    static let iPadPro11 = DesignCanvas(name: "iPad Pro 11\"", width: 834, height: 1194, safeAreaInsets: .iPadPro)
    static let iPadPro12_9 = DesignCanvas(name: "iPad Pro 12.9\"", width: 1024, height: 1366, safeAreaInsets: .iPadPro)
}

struct SafeAreaInsets: Codable, Equatable {
    var top: CGFloat
    var bottom: CGFloat
    var leading: CGFloat
    var trailing: CGFloat
    
    static let none = SafeAreaInsets(top: 0, bottom: 0, leading: 0, trailing: 0)
    static let iPhone14Pro = SafeAreaInsets(top: 59, bottom: 34, leading: 0, trailing: 0)
    static let iPhoneSE = SafeAreaInsets(top: 20, bottom: 0, leading: 0, trailing: 0)
    static let iPadPro = SafeAreaInsets(top: 24, bottom: 20, leading: 0, trailing: 0)
}

// MARK: - Layer Management
/// Manages z-index ordering and visibility state
struct LayerManager: Codable, Equatable {
    /// Ordered list of component IDs (bottom to top)
    var order: [String]
    /// Visibility state per component
    var visibility: [String: Bool]
    /// Lock state per component
    var locked: [String: Bool]
    /// Collapsed state in hierarchy view
    var collapsed: [String: Bool]
    
    init(
        order: [String] = [],
        visibility: [String: Bool] = [:],
        locked: [String: Bool] = [:],
        collapsed: [String: Bool] = [:]
    ) {
        self.order = order
        self.visibility = visibility
        self.locked = locked
        self.collapsed = collapsed
    }
    
    // MARK: - Layer Operations
    
    mutating func addLayer(_ componentId: String, at index: Int? = nil) {
        if let index = index, index < order.count {
            order.insert(componentId, at: index)
        } else {
            order.append(componentId)
        }
        visibility[componentId] = true
        locked[componentId] = false
        collapsed[componentId] = false
    }
    
    mutating func removeLayer(_ componentId: String) {
        order.removeAll { $0 == componentId }
        visibility.removeValue(forKey: componentId)
        locked.removeValue(forKey: componentId)
        collapsed.removeValue(forKey: componentId)
    }
    
    mutating func moveLayer(_ componentId: String, to newIndex: Int) {
        guard let currentIndex = order.firstIndex(of: componentId) else { return }
        order.remove(at: currentIndex)
        let targetIndex = min(newIndex, order.count)
        order.insert(componentId, at: targetIndex)
    }
    
    mutating func toggleVisibility(_ componentId: String) {
        visibility[componentId]?.toggle()
    }
    
    mutating func toggleLocked(_ componentId: String) {
        locked[componentId]?.toggle()
    }
    
    mutating func toggleCollapsed(_ componentId: String) {
        collapsed[componentId]?.toggle()
    }
    
    func isVisible(_ componentId: String) -> Bool {
        visibility[componentId] ?? true
    }
    
    func isLocked(_ componentId: String) -> Bool {
        locked[componentId] ?? false
    }
    
    func isCollapsed(_ componentId: String) -> Bool {
        collapsed[componentId] ?? false
    }
    
    func zIndex(for componentId: String) -> Int {
        order.firstIndex(of: componentId) ?? 0
    }
}

// MARK: - Selection State
/// Manages component selection in the editor
struct SelectionState: Codable, Equatable {
    var selectedIds: [String]
    var multiSelect: Bool
    var selectionBounds: CGRect?
    
    init(
        selectedIds: [String] = [],
        multiSelect: Bool = false,
        selectionBounds: CGRect? = nil
    ) {
        self.selectedIds = selectedIds
        self.multiSelect = multiSelect
        self.selectionBounds = selectionBounds
    }
    
    var isEmpty: Bool { selectedIds.isEmpty }
    var isSingleSelection: Bool { selectedIds.count == 1 }
    var isMultiSelection: Bool { selectedIds.count > 1 }
    
    mutating func select(_ componentId: String, append: Bool = false) {
        if append && multiSelect {
            if !selectedIds.contains(componentId) {
                selectedIds.append(componentId)
            }
        } else {
            selectedIds = [componentId]
        }
    }
    
    mutating func deselect(_ componentId: String) {
        selectedIds.removeAll { $0 == componentId }
    }
    
    mutating func toggleSelection(_ componentId: String) {
        if selectedIds.contains(componentId) {
            deselect(componentId)
        } else {
            select(componentId, append: multiSelect)
        }
    }
    
    mutating func clearSelection() {
        selectedIds.removeAll()
        selectionBounds = nil
    }
    
    func isSelected(_ componentId: String) -> Bool {
        selectedIds.contains(componentId)
    }
}

// MARK: - CGPoint/CGRect Codable Extensions
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

extension CGRect: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y, width, height
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(x: x, y: y, width: width, height: height)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin.x, forKey: .x)
        try container.encode(origin.y, forKey: .y)
        try container.encode(size.width, forKey: .width)
        try container.encode(size.height, forKey: .height)
    }
}
