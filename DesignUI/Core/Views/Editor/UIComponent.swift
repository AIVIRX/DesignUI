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
    case chart = "Chart"
    case shape = "Shape"
    case button = "Button"
    case gauge = "Gauge"
    
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
        case .roundedRectangle: return "rectangle.ratio.4.to.3"
        case .capsule: return "capsule"
        case .ellipse: return "oval"
        case .linearGradient: return "square.fill.text.grid.1x2"
        case .scrollView: return "scroll"
        case .sfSymbol: return "star"
        case .statusBar: return "iphone"
        case .textField: return "text.cursor"
        case .toggle: return "switch.2"
        case .slider: return "slider.horizontal.3"
        case .chart: return "chart.bar.fill"
        case .shape: return "square.on.circle"
        case .button: return "button.programmable"
        case .gauge: return "gauge.medium"
        }
    }
    
    var assetName: String {
        return "component_\(String(describing: self).lowercased())"
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
    case slider
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

    
    init(key: String, displayName: String, type: PropertyType, value: Any, defaultValue: Any, options: [Any]? = nil) {
        self.id = UUID()
        self.key = key
        self.displayName = displayName
        self.type = type
        self.value = value
        self.defaultValue = defaultValue
        self.options = options
    }
    
    // MARK: - Value Comparison for Diff-Only Saving
    static func valuesAreEqual(_ lhs: Any, _ rhs: Any) -> Bool {
        // Compare by type
        if let l = lhs as? String, let r = rhs as? String { return l == r }
        if let l = lhs as? Double, let r = rhs as? Double { return l == r }
        if let l = lhs as? Int, let r = rhs as? Int { return l == r }
        if let l = lhs as? Bool, let r = rhs as? Bool { return l == r }
        if let l = lhs as? Color, let r = rhs as? Color { return colorToColorString(l) == colorToColorString(r) }
        // For other types, convert to string and compare
        return "\(lhs)" == "\(rhs)"
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case key, value
    }
}

// MARK: - Codable Extension
extension ComponentProperty: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle backward compatibility for missing fields
        self.id = UUID() // Always generate new ID for property on load
        self.key = try container.decode(String.self, forKey: .key)
        self.displayName = Self.properDisplayName(for: self.key) // Derive display name from key
        
        // Type is no longer encoded - infer generic type from value
        // The authoritative type will be restored in UIComponent.init(from:)
        let (inferredValue, inferredType) = try Self.decodeValueAndInferType(from: container, forKey: .value)
        
        self.value = inferredValue
        self.type = inferredType
        
        // defaultValue and options are no longer encoded/decoded
        // They are restored from code in UIComponent.init(from:)
        self.defaultValue = self.value // Temporary placeholder
        self.options = nil // Temporary placeholder
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // id and displayName are not encoded - derived on load
        try container.encode(key, forKey: .key)
        // type removed
        
        // Encode value based on type
        // Since we don't store type, we just encode the value directly as primitive
        try Self.encodeAnyValue(value, to: &container, forKey: .value, type: type)
        
        // defaultValue and options are NOT encoded anymore
    }
    
    // Helper to decode value and infer a provisional type
    private static func decodeValueAndInferType(from container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) throws -> (Any, PropertyType) {
        if let boolVal = try? container.decode(Bool.self, forKey: key) {
            return (boolVal, .boolean)
        } else if let intVal = try? container.decode(Int.self, forKey: key) {
             return (Double(intVal), .number) 
        } else if let doubleVal = try? container.decode(Double.self, forKey: key) {
            return (doubleVal, .number)
        } else if let stringVal = try? container.decode(String.self, forKey: key) {
            return (stringVal, .string) // Default to string, will be refined to .color/etc later
        } else if let arrayVal = try? container.decode([String].self, forKey: key) {
            return (arrayVal, .string) // Provisional - technically valid for colorArray logic
        } else {
             // Fallback for empty/null - usually string
             return ("", .string)
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
        case .spacing, .cornerRadius, .padding, .frame, .offset, .rotation, .scale, .opacity, .shadow, .border, .gradient, .animation, .slider:
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
        // getRed returns bool indicating success
        if uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) {
            if a < 1.0 {
                return String(format: "rgba(%.3f,%.3f,%.3f,%.3f)", Double(r), Double(g), Double(b), Double(a))
            } else {
                return String(format: "rgb(%.3f,%.3f,%.3f)", Double(r), Double(g), Double(b))
            }
        } else {
            // Fallback for semantic colors that cannot be converted (e.g. some system patterns)
            return "primary" 
        }
        #endif
    }
    
    // Helper to convert color string back to Color (make it accessible)
    static func colorStringToColor(_ colorString: String) -> Color {
        // Handle transparency suffix (e.g. "blue:0.5" or "primary:0.3")
        if colorString.contains(":") && !colorString.hasPrefix("rgb") {
            let components = colorString.split(separator: ":")
            if components.count == 2 {
                let baseColorString = String(components[0])
                if let opacity = Double(components[1]) {
                    return colorStringToColor(baseColorString).opacity(opacity)
                }
            }
        }
        
        // Handle common SwiftUI colors
        switch colorString {
        case "primary": return .primary
        case "secondary": return .secondary
        case "tertiary": return .primary.opacity(0.6)
        case "quaternary": return .primary.opacity(0.3)
        case "black": return .black
        case "white": return .white
        case "gray": return .gray
        
        // Semantic / Dark Mode Adaptable
        case "systemBackground": 
            #if os(macOS)
            return Color(nsColor: .windowBackgroundColor)
            #else
            return Color(uiColor: .systemBackground)
            #endif
        case "secondarySystemBackground":
             #if os(macOS)
             return Color(nsColor: .controlBackgroundColor)
             #else
             return Color(uiColor: .secondarySystemBackground)
             #endif
        case "label":
            #if os(macOS)
            return Color(nsColor: .labelColor)
            #else
            return Color(uiColor: .label)
            #endif
        case "secondaryLabel":
             #if os(macOS)
             return Color(nsColor: .secondaryLabelColor)
             #else
             return Color(uiColor: .secondaryLabel)
             #endif
             
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
        case "clear": return .clear
        default:
            // Check for Hex (standard #RRGGBB or #RRGGBBAA)
            if colorString.hasPrefix("#") {
                let hex = colorString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                var int: UInt64 = 0
                Scanner(string: hex).scanHexInt64(&int)
                let a, r, g, b: UInt64
                
                switch hex.count {
                case 3: // RGB (12-bit)
                    (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
                case 6: // RGB (24-bit)
                    (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
                case 8: // ARGB (32-bit)
                    (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
                default:
                    (a, r, g, b) = (255, 0, 0, 0)
                }
                
                return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
            }
            
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
        
        // Save state for undo BEFORE making changes
        NotificationCenter.default.post(name: .designWillChange, object: nil)
        
        // Ensure UI updates happen on main thread
        let updateUI = {
            self.objectWillChange.send()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        
        if let index = properties.firstIndex(where: { $0.key == key }) {
            let property = properties[index]
            
            // For color properties, convert Color objects to strings to preserve semantic colors
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
        } else {
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
    func getProperty(key: String) -> Any? {
        guard let property = properties.first(where: { $0.key == key }) else {
            return nil
        }
        
        // For color properties, ensure semantic colors are preserved
        if property.type == .color {
            // If stored as string, return as string (Editor expects String binding)
            if let colorString = property.value as? String {
                return colorString
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
        
        // For number properties, ensure we always return Double (JSON can decode as Int)
        if property.type == .number {
            if let intVal = property.value as? Int {
                return Double(intVal)
            }
            // Already Double or other - return as-is
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
        
        Task { @MainActor in
            objectWillChange.send()
            // Post notification to trigger design file saving
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    func removeModifier(_ modifier: ComponentModifier) {
        // Save state for undo BEFORE making changes
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .designWillChange, object: nil)
        }
        
        // For overlay, mask, and background modifiers, remove the parent component
        if modifier.type == .overlay || modifier.type == .mask || modifier.type == .background {
            let modifierChildren = getChildrenForModifier(modifier.id)
            for child in modifierChildren {
                removeChild(child)
            }
            // Trigger UI update after removing children
            Task { @MainActor in objectWillChange.send() }
        }
        
        modifiers.removeAll { $0.id == modifier.id }
        
        Task { @MainActor in
            objectWillChange.send()
            // Post notification to trigger design file saving
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    /// Update modifier and save undo state - use for discrete changes or when editing ends
    func updateModifier(_ modifier: ComponentModifier) {
        if let index = modifiers.firstIndex(where: { $0.id == modifier.id }) {
            // Save state for undo BEFORE making changes
            NotificationCenter.default.post(name: .designWillChange, object: nil)
            
            modifiers[index] = modifier
            
            // Defer state changes to avoid publishing during view updates
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
                // Post notification to trigger design file saving
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        } else {
            debugLog("⚠️ Modifier not found for update: \(modifier.id)")
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
        // Note: Undo state should be saved by the caller (CanvasManager)
        
        modifiers.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    // MARK: - Cloning
    func clone() -> UIComponent {
        // Deep copy children recursively
        let clonedChildren = children.map { $0.clone() }
        
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
        let shapes: Set<ComponentType> = [.rectangle, .circle, .roundedRectangle, .capsule, .ellipse, .shape]
        
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
            debugLog("⚠️ Cannot convert between different component categories")
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
        
        // Post notification to trigger design file saving
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, type, properties, children, frame, isVisible, zIndex, modifiers, isOverlay, modifierId, modifierType
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.type = try container.decode(ComponentType.self, forKey: .type)
        
        // DICTIONARY PROPERTIES FORMAT: { "key": value }
        if let propsDict = try? container.decode([String: AnyCodable].self, forKey: .properties) {
            self.properties = propsDict.map { key, anyValue in
                ComponentProperty(
                    key: key,
                    displayName: ComponentProperty.properDisplayName(for: key),
                    type: .string, // Provisional type, restored from defaults later
                    value: anyValue.value,
                    defaultValue: anyValue.value, // Placeholder
                    options: nil
                )
            }
        } else {
            self.properties = []
        }
        
        self.children = try container.decodeIfPresent([UIComponent].self, forKey: .children) ?? []
        
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
            // Dictionary format (standard CGRect Codable) - default to .zero if missing
            self._frame = try container.decodeIfPresent(CGRect.self, forKey: .frame) ?? .zero
        }
        self.isVisible = try container.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        self.zIndex = try container.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        self.modifiers = try container.decodeIfPresent([ComponentModifier].self, forKey: .modifiers) ?? []
        self.isOverlay = try container.decodeIfPresent(Bool.self, forKey: .isOverlay) ?? false
        self.modifierId = try container.decodeIfPresent(UUID.self, forKey: .modifierId)
        self.modifierType = try container.decodeIfPresent(ModifierType.self, forKey: .modifierType)

        let defaultProps = UIComponent.defaultProperties(for: self.type)
        var restoredProperties: [ComponentProperty] = []
        
        for defaultProp in defaultProps {
            // Check if this property was saved in JSON
            if let savedProp = self.properties.first(where: { $0.key == defaultProp.key }) {
                // Property exists in JSON - use saved value with restored metadata
                var correctValue = savedProp.value
                
                if defaultProp.type == .number {
                    // JSON numbers can decode as Int or Double, normalize to Double
                    if let intVal = correctValue as? Int {
                        correctValue = Double(intVal)
                    } else if let stringVal = correctValue as? String, let doubleVal = Double(stringVal) {
                        correctValue = doubleVal
                    }
                }
                
                restoredProperties.append(ComponentProperty(
                    key: defaultProp.key,
                    displayName: defaultProp.displayName,
                    type: defaultProp.type,
                    value: correctValue,
                    defaultValue: defaultProp.defaultValue,
                    options: defaultProp.options
                ))
            } else {
                // Property NOT in JSON - use default value from code
                restoredProperties.append(defaultProp)
            }
        }
        
        // Also add any custom properties that aren't in defaults (shouldn't happen often)
        for savedProp in self.properties {
            if !restoredProperties.contains(where: { $0.key == savedProp.key }) {
                restoredProperties.append(savedProp)
            }
        }
        
        self.properties = restoredProperties

        // Fix orphaned modifier children when modifier IDs are missing in JSON
        reconcileModifierChildren()
    }

    // MARK: - Modifier Child Reconciliation (import fix)
    private func reconcileModifierChildren() {
        let modifierIds = Set(modifiers.map { $0.id })
        let modifierTypes: [ModifierType] = [.background, .overlay, .mask]
        
        for type in modifierTypes {
            let modifiersOfType = modifiers.enumerated().filter { $0.element.type == type }
            if modifiersOfType.isEmpty { continue }
            
            let childrenOfType = children.enumerated().filter { $0.element.modifierType == type }
            if childrenOfType.isEmpty { continue }
            
            // Reassign orphaned children to modifiers in order
            let orphanChildren = childrenOfType.filter { (_, child) in
                guard let id = child.modifierId else { return true }
                return !modifierIds.contains(id)
            }
            
            if orphanChildren.isEmpty { continue }
            
            for (idx, (childIndex, child)) in orphanChildren.enumerated() {
                let targetModifier = modifiersOfType[min(idx, modifiersOfType.count - 1)]
                children[childIndex].modifierId = targetModifier.element.id
                
                // Keep parentComponentId in sync if present/needed
                if modifiers[targetModifier.offset].properties["parentComponentId"] as? String != child.id.uuidString {
                    modifiers[targetModifier.offset].properties["parentComponentId"] = child.id.uuidString
                }
            }
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Conditionally encode ID based on userInfo (for cleaner template exports)
        let excludeIdsKey = CodingUserInfoKey(rawValue: "excludeIds")!
        let shouldExcludeIds = encoder.userInfo[excludeIdsKey] as? Bool ?? false
        
        if !shouldExcludeIds {
            try container.encode(id, forKey: .id)
        }

        try container.encode(type, forKey: .type)
        // DIFF-ONLY PROPERTY SAVING: Only encode properties that differ from defaults
        let defaultProps = UIComponent.defaultProperties(for: self.type)
        var propsDict: [String: AnyCodable] = [:]
        for prop in properties {
            // Find the default property for this key
            let defaultProp = defaultProps.first { $0.key == prop.key }
            
            // Only encode if value differs from default
            if let defProp = defaultProp {
                if !ComponentProperty.valuesAreEqual(prop.value, defProp.defaultValue) {
                    propsDict[prop.key] = AnyCodable(prop.value)
                }
            } else {
                // No default found, always encode (custom property)
                propsDict[prop.key] = AnyCodable(prop.value)
            }
        }
        if !propsDict.isEmpty {
            try container.encode(propsDict, forKey: .properties)
        }
        
        if !children.isEmpty {
            try container.encode(children, forKey: .children)
        }
        
        // Only encode values that differ from defaults to keep JSON clean
        if frame != .zero {
            try container.encode(frame, forKey: .frame)
        }
        
        if !isVisible { // Default is true
            try container.encode(isVisible, forKey: .isVisible)
        }
        
        if zIndex != 0 {
            try container.encode(zIndex, forKey: .zIndex)
        }
        
        if !modifiers.isEmpty {
            try container.encode(modifiers, forKey: .modifiers)
        }
        
        if isOverlay { // Default is false
            try container.encode(isOverlay, forKey: .isOverlay)
        }
        
        try container.encodeIfPresent(modifierId, forKey: .modifierId)
        try container.encodeIfPresent(modifierType, forKey: .modifierType)
    }
    
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
        case .shape:
            return [
                ComponentProperty(key: "shapeType", displayName: "Shape Type", type: .dropdown, value: "Rectangle", defaultValue: "Rectangle", options: ["Rectangle", "Circle", "Rounded Rectangle", "Capsule", "Ellipse"]),
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
                ComponentProperty(key: "symbolName", displayName: "Symbol", type: .string, value: "star", defaultValue: "star")
            ]
        case .statusBar:
            return [
                ComponentProperty(key: "showStatusBar", displayName: "Show Status Bar", type: .boolean, value: true, defaultValue: true),
                ComponentProperty(key: "topSafeArea", displayName: "Top Safe Area", type: .boolean, value: true, defaultValue: true)
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
        case .chart:
            return [
                ComponentProperty(key: "chartStyle", displayName: "Chart Style", type: .dropdown, value: "Line + Area", defaultValue: "Line + Area", options: ["Line + Area", "Line", "Area", "Bar"]),
                ComponentProperty(key: "dataPreset", displayName: "Data Pattern", type: .dropdown, value: "Increasing", defaultValue: "Increasing", options: ["Increasing", "Decreasing", "Stable", "Volatile"]),

                ComponentProperty(key: "pointCount", displayName: "Point Count", type: .slider, value: 20.0, defaultValue: 20.0, options: [5.0, 30.0]),

                ComponentProperty(key: "color", displayName: "Color", type: .color, value: "blue", defaultValue: "blue"),
                ComponentProperty(key: "showXAxis", displayName: "Show X Axis", type: .boolean, value: true, defaultValue: true),
                ComponentProperty(key: "showYAxis", displayName: "Show Y Axis", type: .boolean, value: true, defaultValue: true)
            ]
        case .button:
            return [
                ComponentProperty(key: "buttonStyle", displayName: "Button Style", type: .dropdown, value: "borderedProminent", defaultValue: "borderedProminent", options: ["bordered", "borderedProminent", "borderless", "plain"])
            ]
        
        case .gauge:
            return [
                ComponentProperty(key: "gaugeType", displayName: "Gauge Type", type: .dropdown, value: "circular", defaultValue: "circular", options: ["linear", "circular", "circular range"]),
                ComponentProperty(key: "value", displayName: "Value", type: .number, value: 50.0, defaultValue: 50.0),
                ComponentProperty(key: "min", displayName: "Min", type: .number, value: 0.0, defaultValue: 0.0),
                ComponentProperty(key: "max", displayName: "Max", type: .number, value: 100.0, defaultValue: 100.0),
                ComponentProperty(key: "showValue", displayName: "Show Value", type: .boolean, value: true, defaultValue: true),
                ComponentProperty(key: "color", displayName: "Color", type: .color, value: "blue", defaultValue: "blue")
            ]

        default:
            return []
        }
    }
}
