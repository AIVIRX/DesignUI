//
//  UIComponent.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - ComponentAnyCodable Helper
struct ComponentAnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            throw DecodingError.typeMismatch(AnyCodable.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let string = value as? String {
            try container.encode(string)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - Component Types
enum ComponentType: String, CaseIterable, Identifiable, Codable {
    case text = "Text"
    case image = "Image"
    case sfSymbol = "SF Symbol"
    case vstack = "VStack"
    case hstack = "HStack"
    case zstack = "ZStack"
    case spacer = "Spacer"
    case divider = "Divider"
    case rectangle = "Rectangle"
    case circle = "Circle"
    case roundedRectangle = "RoundedRectangle"
    case capsule = "Capsule"
    case ellipse = "Ellipse"
    case linearGradient = "Linear Gradient"
    case scrollView = "ScrollView"

    case statusBar = "Status Bar"
    case textField = "Text Field"
    case toggle = "Switch"
    case slider = "Slider"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .text: return "textformat"
        case .image: return "photo"
        case .vstack: return "square.split.1x2.fill"
        case .hstack: return "square.split.2x1.fill"
        case .zstack: return "square.2.layers.3d.top.filled"
        case .spacer: return "space"
        case .divider: return "minus"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .roundedRectangle: return "rectangle.ratio.4.to.3.fill"
        case .capsule: return "capsule"
        case .ellipse: return "oval"
        case .linearGradient: return "square.fill.text.grid.1x2"
        case .scrollView: return "scroll"
        case .sfSymbol: return "star"
        case .statusBar: return "iphone"
        case .textField: return "text.cursor"
        case .toggle: return "switch.2"
        case .slider: return "slider.horizontal.3"
        }
    }
}

// MARK: - Property Types
enum PropertyType: Codable {
    case string
    case number
    case boolean
    case color
    case font
    case alignment
    case spacing
    case cornerRadius
    case padding
    case frame
    case offset
    case rotation
    case scale
    case opacity
    case shadow
    case border
    case gradient
    case animation
    case segmentedControl
    case dropdown
    case colorArray
    case unitPoint
}

// MARK: - Component Property
struct ComponentProperty: Identifiable, Equatable {
    let id: UUID
    let key: String
    let displayName: String
    let type: PropertyType
    var value: Any
    let defaultValue: Any
    let options: [Any]?
    let isRequired: Bool
    
    init(key: String, displayName: String, type: PropertyType, value: Any, defaultValue: Any, options: [Any]? = nil, isRequired: Bool = false) {
        self.id = UUID()
        self.key = key
        self.displayName = displayName
        self.type = type
        self.value = value
        self.defaultValue = defaultValue
        self.options = options
        self.isRequired = isRequired
    }
    
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, key, displayName, type, value, defaultValue, options, isRequired
    }
}

// MARK: - Codable Extension
extension ComponentProperty: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle backward compatibility for missing fields
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.key = try container.decode(String.self, forKey: .key)
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? Self.properDisplayName(for: self.key)
        self.type = try container.decode(PropertyType.self, forKey: .type)
        self.isRequired = try container.decodeIfPresent(Bool.self, forKey: .isRequired) ?? false
        
        // Decode value based on type
        self.value = try Self.decodeAnyValue(from: container, forKey: .value, type: type)
        self.defaultValue = try Self.decodeAnyValue(from: container, forKey: .defaultValue, type: type)
        
        // Decode options if present
        if let optionsStrings = try container.decodeIfPresent([String].self, forKey: .options) {
            self.options = optionsStrings
        } else {
            self.options = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encode(type, forKey: .type)
        try container.encode(isRequired, forKey: .isRequired)
        
        // Encode value based on type
        try Self.encodeAnyValue(value, to: &container, forKey: .value, type: type)
        try Self.encodeAnyValue(defaultValue, to: &container, forKey: .defaultValue, type: type)
        
        // Encode options if present
        if let options = options {
            let optionsStrings = options.map { "\($0)" }
            try container.encode(optionsStrings, forKey: .options)
        }
    }
    
    // Helper methods for encoding/decoding Any values
    private static func encodeAnyValue(_ value: Any, to container: inout KeyedEncodingContainer<CodingKeys>, forKey key: CodingKeys, type: PropertyType) throws {
        switch type {
        case .string:
            try container.encode(value as? String ?? "", forKey: key)
        case .number:
            try container.encode(value as? Double ?? 0.0, forKey: key)
        case .boolean:
            try container.encode(value as? Bool ?? false, forKey: key)
        case .color:
            // Convert Color to string representation, or use string value if already a string
            if let color = value as? Color {
                let colorString = colorToColorString(color)
                try container.encode(colorString, forKey: key)
            } else if let colorString = value as? String {
                // Already a string (from setProperty conversion), encode it directly
                try container.encode(colorString, forKey: key)
            } else {
                try container.encode("primary", forKey: key)
            }
        case .font, .alignment, .segmentedControl, .dropdown:
            try container.encode(value as? String ?? "", forKey: key)
        case .spacing, .cornerRadius, .padding, .frame, .offset, .rotation, .scale, .opacity, .shadow, .border, .gradient, .animation:
            // For numeric properties, try to encode as Double
            if let doubleValue = value as? Double {
                try container.encode(doubleValue, forKey: key)
            } else if let intValue = value as? Int {
                try container.encode(Double(intValue), forKey: key)
            } else {
                try container.encode("\(value)", forKey: key)
            }
        case .colorArray:
             // Encode array of color strings
             if let colorStrings = value as? [String] {
                 try container.encode(colorStrings, forKey: key)
             } else if let colors = value as? [Color] {
                 let colorStrings = colors.map { colorToColorString($0) }
                 try container.encode(colorStrings, forKey: key)
             } else {
                 try container.encode([String](), forKey: key)
             }
         case .unitPoint:
             // Encode as string representation (e.g. "top", "bottomLeading")
             if let unitPointString = value as? String {
                 try container.encode(unitPointString, forKey: key)
             } else {
                 try container.encode("center", forKey: key) // Fallback
             }
        }
    }
    
    private static func decodeAnyValue(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys, type: PropertyType) throws -> Any {
        switch type {
        case .string:
            return try container.decode(String.self, forKey: key)
        case .number:
            return try container.decode(Double.self, forKey: key)
        case .boolean:
            return try container.decode(Bool.self, forKey: key)
        case .color:
            let colorString = try container.decode(String.self, forKey: key)
            // Convert stored string back to Color
            return colorStringToColor(colorString)
        case .font, .alignment, .segmentedControl, .dropdown:
            return try container.decode(String.self, forKey: key)
        case .spacing, .cornerRadius, .padding, .frame, .offset, .rotation, .scale, .opacity, .shadow, .border, .gradient, .animation:
            // Try to decode as Double first, fallback to String
            if let doubleValue = try? container.decode(Double.self, forKey: key) {
                return doubleValue
            } else {
                return try container.decode(String.self, forKey: key)
            }
        case .colorArray:
            return try container.decode([String].self, forKey: key)
        case .unitPoint:
            return try container.decode(String.self, forKey: key)
        }
    }
    
    // Helper to convert Color to string representation (make it accessible)
    static func colorToColorString(_ color: Color) -> String {
        // Compare with known SwiftUI colors
        if color == .primary { return "primary" }
        if color == .secondary { return "secondary" }
        if color == .primary.opacity(0.6) { return "tertiary" }
        if color == .primary.opacity(0.3) { return "quaternary" }
        if color == .black { return "black" }
        if color == .white { return "white" }
        if color == .red { return "red" }
        if color == .orange { return "orange" }
        if color == .yellow { return "yellow" }
        if color == .green { return "green" }
        if color == .mint { return "mint" }
        if color == .teal { return "teal" }
        if color == .cyan { return "cyan" }
        if color == .blue { return "blue" }
        if color == .indigo { return "indigo" }
        if color == .purple { return "purple" }
        if color == .pink { return "pink" }
        if color == .brown { return "brown" }
        if color == .gray { return "gray" }
        if color == .clear { return "clear" }
        
        // For custom colors, extract RGB values
        #if os(macOS)
        let nsColor = NSColor(color)
        let rgbColor = nsColor.usingColorSpace(.sRGB) ?? nsColor
        let r = Double(rgbColor.redComponent)
        let g = Double(rgbColor.greenComponent)
        let b = Double(rgbColor.blueComponent)
        let a = Double(rgbColor.alphaComponent)
        if a < 1.0 {
            return String(format: "rgba(%.3f,%.3f,%.3f,%.3f)", r, g, b, a)
        } else {
            return String(format: "rgb(%.3f,%.3f,%.3f)", r, g, b)
        }
        #else
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        if a < 1.0 {
            return String(format: "rgba(%.3f,%.3f,%.3f,%.3f)", Double(r), Double(g), Double(b), Double(a))
        } else {
            return String(format: "rgb(%.3f,%.3f,%.3f)", Double(r), Double(g), Double(b))
        }
        #endif
    }
    
    // Helper to convert color string back to Color (make it accessible)
    static func colorStringToColor(_ colorString: String) -> Color {
        // Handle common SwiftUI colors
        switch colorString {
        case "primary": return .primary
        case "secondary": return .secondary
        case "tertiary": return .primary.opacity(0.6)
        case "quaternary": return .primary.opacity(0.3)
        case "black": return .black
        case "white": return .white
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "mint": return .mint
        case "teal": return .teal
        case "cyan": return .cyan
        case "blue": return .blue
        case "indigo": return .indigo
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        case "clear": return .clear
        default:
            // Try to parse RGB/RGBA format
            if colorString.hasPrefix("rgb(") || colorString.hasPrefix("rgba(") {
                let cleaned = colorString
                    .replacingOccurrences(of: "rgb(", with: "")
                    .replacingOccurrences(of: "rgba(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                let components = cleaned.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                if components.count >= 3 {
                    let r = components[0]
                    let g = components[1]
                    let b = components[2]
                    let a = components.count >= 4 ? components[3] : 1.0
                    return Color(red: r, green: g, blue: b, opacity: a)
                }
            }
            return .primary // Fallback
        }
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: ComponentProperty, rhs: ComponentProperty) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Display Name Helper
    static func properDisplayName(for key: String) -> String {
        switch key {
        case "fontSize": return "Font Size"
        case "foregroundColor": return "Text Color"
        case "backgroundColor": return "Background Color"
        case "text": return "Text"
        case "title": return "Title"
        case "resizable": return "Resizable"
        case "aspectRatio": return "Aspect Ratio"
        case "cornerRadius": return "Corner Radius"
        case "alignment": return "Alignment"
        case "spacing": return "Spacing"
        case "symbolName": return "Symbol Name"
        case "size": return "Size"
        case "color": return "Color"
        default: return key.capitalized
        }
    }
}

// MARK: - UI Component Model
class UIComponent: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published private(set) var type: ComponentType
    @Published var properties: [ComponentProperty]
    @Published var children: [UIComponent]
    private var _frame: CGRect = .zero
    var frame: CGRect {
        get { _frame }
        set {
            _frame = newValue
            objectWillChange.send()
            // Post notification to trigger design file saving
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    @Published var isSelected: Bool = false
    @Published var isVisible: Bool = true
    @Published var zIndex: Int = 0
    @Published var modifiers: [ComponentModifier]
    @Published var isOverlay: Bool = false // Marks this component as an overlay child
    @Published var modifierId: UUID? // ID of the modifier this child belongs to (for overlay, mask, background)
    @Published var modifierType: ModifierType? // Type of modifier this parent component belongs to
    
    init(type: ComponentType, properties: [ComponentProperty] = [], children: [UIComponent] = [], frame: CGRect = .zero, modifiers: [ComponentModifier] = [], isOverlay: Bool = false, modifierId: UUID? = nil, modifierType: ModifierType? = nil) {
        self.id = UUID()
        self.type = type
        self.properties = properties
        self.children = children
        self._frame = frame
        self.modifiers = modifiers
        self.isOverlay = isOverlay
        self.modifierId = modifierId
        self.modifierType = modifierType
    }
    
    // MARK: - Property Management
    func setProperty(key: String, value: Any) {
        print("🔑 setProperty called - key: '\(key)', value: '\(value)'")
        
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        // Ensure UI updates happen on main thread
        let updateUI = {
            self.objectWillChange.send()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        
        if let index = properties.firstIndex(where: { $0.key == key }) {
            print("🔑 Found existing property at index \(index)")
            let property = properties[index]
            
            // For color properties, convert Color objects to strings to preserve semantic colors
            var finalValue = value
            if property.type == .color, let color = value as? Color {
                let colorString = ComponentProperty.colorToColorString(color)
                finalValue = colorString
            }
            
            properties[index].value = finalValue
            print("🔑 Updated property '\(key)' to '\(finalValue)'")
            
            if Thread.isMainThread {
                updateUI()
            } else {
                DispatchQueue.main.async { updateUI() }
            }
        } else {
            print("🔑 Property '\(key)' doesn't exist, adding it")
            // Property doesn't exist, add it
            
            // Determine property type - check if it's a color property by key name
            let propertyType: PropertyType = {
                if key.contains("color") || key.contains("Color") || key.contains("fill") || key.contains("stroke") || key.contains("background") || key.contains("foreground") {
                    return .color
                }
                return .string // Default to string type
            }()
            
            // For color properties, convert Color objects to strings
            var finalValue = value
            if propertyType == .color, let color = value as? Color {
                let colorString = ComponentProperty.colorToColorString(color)
                finalValue = colorString
            }
            
            let newProperty = ComponentProperty(
                key: key,
                displayName: ComponentProperty.properDisplayName(for: key),
                type: propertyType,
                value: finalValue,
                defaultValue: finalValue
            )
            properties.append(newProperty)
            
            if Thread.isMainThread {
                updateUI()
            } else {
                DispatchQueue.main.async { updateUI() }
            }
        }
    }
    
    /// Set property during continuous editing (sliders) - does NOT save undo state
    /// Call `setProperty` when editing ends to properly save the final state
    func setPropertyContinuous(key: String, value: Any) {
        // Ensure UI updates happen on main thread
        let updateUI = {
            self.objectWillChange.send()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        
        if let index = properties.firstIndex(where: { $0.key == key }) {
            let property = properties[index]
            
            // For color properties, convert Color objects to strings
            var finalValue = value
            if property.type == .color, let color = value as? Color {
                let colorString = ComponentProperty.colorToColorString(color)
                finalValue = colorString
            }
            
            properties[index].value = finalValue
            
            if Thread.isMainThread {
                updateUI()
            } else {
                DispatchQueue.main.async { updateUI() }
            }
        }
    }
    // MARK: - Frame Management
    func updateFrame(_ newFrame: CGRect) {
        // The frame setter automatically handles objectWillChange and save notification
        frame = newFrame
    }
    
    func getProperty(key: String) -> Any? {
        guard let property = properties.first(where: { $0.key == key }) else {
            return nil
        }
        
        // For color properties, ensure semantic colors are preserved
        if property.type == .color {
            // If stored as string, convert to Color (semantic colors will adapt)
            if let colorString = property.value as? String {
                return ComponentProperty.colorStringToColor(colorString)
            }
            // If stored as Color, check if it's a semantic color and preserve it
            if let color = property.value as? Color {
                // Check if it matches semantic colors - if so, return the semantic color
                let colorString = ComponentProperty.colorToColorString(color)
                if colorString == "primary" || colorString == "secondary" || 
                   colorString == "tertiary" || colorString == "quaternary" {
                    return ComponentProperty.colorStringToColor(colorString)
                }
                // Otherwise return the color as-is
                return color
            }
        }
        
        return property.value
    }
    
    // MARK: - Child Management
    func addChild(_ child: UIComponent) {
        // Prevent adding the same component multiple times
        if !children.contains(where: { $0.id == child.id }) {
            children.append(child)
        }
    }
    
    func addOverlayChild(_ child: UIComponent) {
        // Mark as overlay and add to children
        child.isOverlay = true
        addChild(child)
    }
    
    func getOverlayChildren() -> [UIComponent] {
        return children.filter { $0.isOverlay }
    }
    
    func getRegularChildren() -> [UIComponent] {
        return children.filter { !$0.isOverlay && $0.modifierId == nil }
    }
    
    func getChildrenForModifier(_ modifierId: UUID) -> [UIComponent] {
        return children.filter { $0.modifierId == modifierId }
    }
    
    func getParentComponentForModifier(_ modifierId: UUID) -> UIComponent? {
        // The parent component is the one directly linked to the modifier
        // It should be the first child with this modifierId (there should only be one)
        return children.first { $0.modifierId == modifierId }
    }
    
    func addModifierChild(_ child: UIComponent, modifierId: UUID) {
        child.modifierId = modifierId
        addChild(child)
    }
    
    func removeChild(_ child: UIComponent) {
        children.removeAll { $0.id == child.id }
    }
    
    func removeChild(at index: Int) {
        guard index < children.count else { return }
        children.remove(at: index)
    }
    
    // MARK: - Modifier Management
    func addModifier(_ modifier: ComponentModifier) {
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        var newModifier = modifier
        
        // For overlay, mask, and background modifiers, create a parent component
        if modifier.type == .overlay || modifier.type == .mask || modifier.type == .background {
            let parentComponent = UIComponent(
                type: .vstack, // Use vstack as container type
                properties: [],
                children: [],
                frame: .zero,
                modifiers: [],
                isOverlay: false,
                modifierId: modifier.id,
                modifierType: modifier.type
            )
            // Store parent component ID in modifier
            newModifier.properties["parentComponentId"] = parentComponent.id.uuidString
            
            // Create a default child based on modifier type
            let defaultChild: UIComponent
            if modifier.type == .mask {
                defaultChild = UIComponent(type: .circle, properties: [], modifiers: [])
            } else if modifier.type == .overlay {
                defaultChild = UIComponent(
                    type: .text, 
                    properties: [
                        ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Text", defaultValue: "Text")
                    ],
                    modifiers: []
                )
            } else {
                // Default handling (background) - Rounded Rectangle
                defaultChild = UIComponent(
                    type: .roundedRectangle,
                    properties: [
                        ComponentProperty(
                            key: "cornerRadius",
                            displayName: "Corner Radius",
                            type: .cornerRadius,
                            value: 8.0,
                            defaultValue: 0.0
                        )
                    ],
                    modifiers: []
                )
            }
            
            // Add the default child to the container
            parentComponent.addChild(defaultChild)
            
            // Add parent component as child to the main component
            addModifierChild(parentComponent, modifierId: modifier.id)
            
            // Auto-select the new default child so user can immediately edit it
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .selectComponent, object: defaultChild.id)
            }
        }
        
        modifiers.append(newModifier)
        objectWillChange.send()
        print("🔄 Modifier added: \(newModifier.type.rawValue)")
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func removeModifier(_ modifier: ComponentModifier) {
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        // For overlay, mask, and background modifiers, remove the parent component
        if modifier.type == .overlay || modifier.type == .mask || modifier.type == .background {
            let modifierChildren = getChildrenForModifier(modifier.id)
            for child in modifierChildren {
                removeChild(child)
            }
            // Trigger UI update after removing children
            objectWillChange.send()
        }
        
        modifiers.removeAll { $0.id == modifier.id }
        objectWillChange.send()
        print("🔄 Modifier removed: \(modifier.type.rawValue)")
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    func removeModifier(at index: Int) {
        guard index < modifiers.count else { return }
        
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        let removedModifier = modifiers[index]
        
        // For overlay, mask, and background modifiers, remove the parent component
        if removedModifier.type == .overlay || removedModifier.type == .mask || removedModifier.type == .background {
            let modifierChildren = getChildrenForModifier(removedModifier.id)
            for child in modifierChildren {
                removeChild(child)
            }
            // Trigger UI update after removing children
            objectWillChange.send()
        }
        
        modifiers.remove(at: index)
        objectWillChange.send()
        print("🔄 Modifier removed at index \(index): \(removedModifier.type.rawValue)")
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    /// Update modifier and save undo state - use for discrete changes or when editing ends
    func updateModifier(_ modifier: ComponentModifier) {
        if let index = modifiers.firstIndex(where: { $0.id == modifier.id }) {
            // Save state for undo BEFORE making changes
            NotificationCenter.default.post(name: .designWillChange, object: nil)
            
            modifiers[index] = modifier
            print("🔄 Modifier updated: \(modifier.type.rawValue) with properties: \(modifier.properties)")
            
            // Defer state changes to avoid publishing during view updates
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
                // Post notification to trigger design file saving
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        } else {
            print("⚠️ Modifier not found for update: \(modifier.id)")
        }
    }
    
    /// Update modifier during continuous editing (sliders) - does NOT save undo state
    /// Call `updateModifier` when editing ends to properly save the final state
    func updateModifierContinuous(_ modifier: ComponentModifier) {
        if let index = modifiers.firstIndex(where: { $0.id == modifier.id }) {
            // NO undo state save - this is for continuous slider updates
            modifiers[index] = modifier
            
            // Still update UI and persist to file
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        }
    }
    
    func moveModifier(from source: IndexSet, to destination: Int) {
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        modifiers.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
        print("🔄 Modifiers reordered")
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    // MARK: - Cloning
    func clone() -> UIComponent {
        // Deep copy children recursively
        let clonedChildren = children.map { $0.clone() }
        
        // Properties and modifiers are structs, so they are value types and copied automatically
        // However, we need to ensure any reference types inside them (if any) are handled
        // Currently Property and Modifier only contain value types or immutable standard types
        
        return UIComponent(
            type: type,
            properties: properties,
            children: clonedChildren,
            frame: frame,
            modifiers: modifiers,
            isOverlay: isOverlay,
            modifierId: modifierId,
            modifierType: modifierType
        )
    }
    
    // MARK: - Type Conversion
    func convertType(to newType: ComponentType) {
        // Only allow conversion between similar component categories
        let containers: Set<ComponentType> = [.vstack, .hstack, .zstack, .scrollView]
        let shapes: Set<ComponentType> = [.rectangle, .circle, .roundedRectangle, .capsule, .ellipse]
        
        let currentCategory: String
        if containers.contains(type) {
            currentCategory = "container"
        } else if shapes.contains(type) {
            currentCategory = "shape"
        } else {
            currentCategory = "other"
        }
        
        let newCategory: String
        if containers.contains(newType) {
            newCategory = "container"
        } else if shapes.contains(newType) {
            newCategory = "shape"
        } else {
            newCategory = "other"
        }
        
        // Only convert within same category
        guard currentCategory == newCategory else {
            print("⚠️ Cannot convert between different component categories")
            return
        }
        
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        // Update the type
        self.type = newType
        
        // Get new default properties for the target type
        let newDefaultProperties = UIComponent.defaultProperties(for: newType)
        
        // For containers, update alignment options if needed
        if containers.contains(newType) {
            // Update alignment property based on new container type
            if newType == .vstack {
                // VStack uses horizontal alignment: leading, center, trailing
                if let alignmentIndex = properties.firstIndex(where: { $0.key == "alignment" }) {
                    let currentAlignment = properties[alignmentIndex].value as? String ?? "center"
                    // Map alignment if needed
                    let mapped: String
                    switch currentAlignment {
                    case "top", "bottom", "firstTextBaseline", "lastTextBaseline":
                        mapped = "center"
                    default:
                        mapped = currentAlignment
                    }
                    properties[alignmentIndex].value = mapped
                }
            } else if newType == .hstack {
                // HStack uses vertical alignment: top, center, bottom, firstTextBaseline, lastTextBaseline
                if let alignmentIndex = properties.firstIndex(where: { $0.key == "alignment" }) {
                    let currentAlignment = properties[alignmentIndex].value as? String ?? "center"
                    // Map alignment if needed
                    let mapped: String
                    switch currentAlignment {
                    case "leading", "trailing":
                        mapped = "center"
                    default:
                        mapped = currentAlignment
                    }
                    properties[alignmentIndex].value = mapped
                }
            }
        }
        
        // Add any missing properties from the new type
        for newProp in newDefaultProperties {
            if !properties.contains(where: { $0.key == newProp.key }) {
                properties.append(newProp)
            }
        }
        
        objectWillChange.send()
        print("🔄 Component converted to \(newType.rawValue)")
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    // MARK: - Code Generation
    func generateSwiftCode() -> String {
        return CodeGenerator.generateCode(for: self)
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, type, properties, children, frame, isSelected, isVisible, zIndex, modifiers, isOverlay, modifierId, modifierType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(ComponentType.self, forKey: .type)
        self.properties = try container.decode([ComponentProperty].self, forKey: .properties)
        self.children = try container.decode([UIComponent].self, forKey: .children)
        
        // Handle frame decoding - support both array format [[x, y], [width, height]] and dictionary format
        if let frameArray = try? container.decode([[Double]].self, forKey: .frame),
           frameArray.count == 2,
           frameArray[0].count == 2,
           frameArray[1].count == 2 {
            // Array format: [[x, y], [width, height]]
            let x = frameArray[0][0]
            let y = frameArray[0][1]
            let width = frameArray[1][0]
            let height = frameArray[1][1]
            self._frame = CGRect(x: x, y: y, width: width, height: height)
        } else {
            // Dictionary format (standard CGRect Codable)
        self._frame = try container.decode(CGRect.self, forKey: .frame)
        }
        self.isSelected = try container.decodeIfPresent(Bool.self, forKey: .isSelected) ?? false
        self.isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        self.zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        self.modifiers = try container.decodeIfPresent([ComponentModifier].self, forKey: .modifiers) ?? []
        self.isOverlay = try container.decodeIfPresent(Bool.self, forKey: .isOverlay) ?? false
        self.modifierId = try container.decodeIfPresent(UUID.self, forKey: .modifierId)
        self.modifierType = try container.decodeIfPresent(ModifierType.self, forKey: .modifierType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(properties, forKey: .properties)
        try container.encode(children, forKey: .children)
        try container.encode(frame, forKey: .frame)
        try container.encode(isSelected, forKey: .isSelected)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(zIndex, forKey: .zIndex)
        try container.encode(modifiers, forKey: .modifiers)
        try container.encode(isOverlay, forKey: .isOverlay)
        try container.encodeIfPresent(modifierId, forKey: .modifierId)
        try container.encodeIfPresent(modifierType, forKey: .modifierType)
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: UIComponent, rhs: UIComponent) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Default Properties Factory
extension UIComponent {
    static func defaultProperties(for type: ComponentType) -> [ComponentProperty] {
        switch type {
        case .text:
            return [
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Hello World", defaultValue: "Hello World")
            ]
        case .image:
            return [
                ComponentProperty(key: "imageName", displayName: "Image Name", type: .string, value: "", defaultValue: ""),
                ComponentProperty(key: "imageData", displayName: "Image Data", type: .string, value: "", defaultValue: ""),
                ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: true),
                ComponentProperty(key: "aspectRatio", displayName: "Aspect Ratio", type: .dropdown, value: "fit", defaultValue: "fit", options: ["fit", "fill", "none"])
            ]
        case .vstack:
            return [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
            ]
        case .hstack:
            return [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
            ]
        case .zstack:
            return [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["topLeading", "top", "topTrailing", "leading", "center", "trailing", "bottomLeading", "bottom", "bottomTrailing"])
            ]
        case .linearGradient:
            return [
                ComponentProperty(key: "colors", displayName: "Colors", type: .colorArray, value: ["blue", "green"], defaultValue: ["blue", "green"]),
                ComponentProperty(key: "startPoint", displayName: "Start Point", type: .unitPoint, value: "top", defaultValue: "top", options: ["top", "bottom", "leading", "trailing", "center", "topLeading", "topTrailing", "bottomLeading", "bottomTrailing"]),
                ComponentProperty(key: "endPoint", displayName: "End Point", type: .unitPoint, value: "bottom", defaultValue: "bottom", options: ["top", "bottom", "leading", "trailing", "center", "topLeading", "topTrailing", "bottomLeading", "bottomTrailing"])
            ]
        case .rectangle, .circle, .capsule, .ellipse:
            return []
        case .roundedRectangle:
            return [
                ComponentProperty(key: "cornerRadius", displayName: "Corner Radius", type: .number, value: 12.0, defaultValue: 12.0)
            ]
        case .spacer:
            return []
        case .scrollView:
            return [
                ComponentProperty(key: "axis", displayName: "Axis", type: .segmentedControl, value: "vertical", defaultValue: "vertical", options: ["vertical", "horizontal"]),
                ComponentProperty(key: "showsIndicators", displayName: "Shows Indicators", type: .boolean, value: true, defaultValue: true)
            ]
        case .sfSymbol:
            return [
                ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "star", defaultValue: "star"),
                ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: false, defaultValue: false)
            ]
        case .statusBar:
            return [
                // Status bar only has isVisible property
            ]
        case .textField:
            return [
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Text Value", defaultValue: "Text Value"),
                ComponentProperty(key: "placeholder", displayName: "Placeholder", type: .string, value: "Placeholder", defaultValue: "Placeholder")
            ]
        case .toggle:
            return [
                ComponentProperty(key: "isOn", displayName: "Is On", type: .boolean, value: true, defaultValue: true)
            ]
        case .slider:
            return [
                ComponentProperty(key: "value", displayName: "Value", type: .number, value: 0.5, defaultValue: 0.5),
                ComponentProperty(key: "min", displayName: "Minimum", type: .number, value: 0.0, defaultValue: 0.0),
                ComponentProperty(key: "max", displayName: "Maximum", type: .number, value: 1.0, defaultValue: 1.0)
            ]
        default:
            return []
        }
    }
}
