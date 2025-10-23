//
//  UIComponent.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

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
    case button = "Button"
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
    case list = "List"
    case scrollView = "ScrollView"
    case navigationView = "NavigationView"
    case tabView = "TabView"
    case form = "Form"
    case picker = "Picker"
    case toggle = "Toggle"
    case slider = "Slider"
    case textEditor = "TextEditor"
    case sfSymbol = "SF Symbol"
    
    var id: String { rawValue }
    
    var category: ComponentCategory {
        switch self {
        case .text, .image, .button, .sfSymbol:
            return .basic
        case .vstack, .hstack, .zstack, .spacer, .divider:
            return .layout
        case .rectangle, .circle, .roundedRectangle, .capsule, .ellipse:
            return .shapes
        case .list, .scrollView, .navigationView, .tabView, .form:
            return .containers
        case .picker, .toggle, .slider, .textEditor:
            return .controls
        }
    }
    
    var icon: String {
        switch self {
        case .text: return "textformat"
        case .image: return "photo"
        case .button: return "button.programmable"
        case .vstack: return "rectangle.stack"
        case .hstack: return "rectangle.stack"
        case .zstack: return "square.stack.3d.up"
        case .spacer: return "space"
        case .divider: return "minus"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .roundedRectangle: return "rectangle.ratio.4.to.3.fill"
        case .capsule: return "capsule"
        case .ellipse: return "oval"
        case .list: return "list.bullet"
        case .scrollView: return "scroll"
        case .navigationView: return "navigation"
        case .tabView: return "square.grid.2x2"
        case .form: return "doc.text"
        case .picker: return "list.bullet.rectangle"
        case .toggle: return "switch.2"
        case .slider: return "slider.horizontal.3"
        case .textEditor: return "text.alignleft"
        case .sfSymbol: return "star"
        }
    }
}

enum ComponentCategory: String, CaseIterable {
    case basic = "Basic"
    case layout = "Layout"
    case shapes = "Shapes"
    case containers = "Containers"
    case controls = "Controls"
    case indicators = "Indicators"
    case overlays = "Overlays"
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
        self.displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? self.key
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
            // Convert Color to string representation
            if let color = value as? Color {
                let colorString = colorToColorString(color)
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
        }
    }
    
    // Helper to convert Color to string representation
    private static func colorToColorString(_ color: Color) -> String {
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
        if color == Color(red: 0.99, green: 0.99, blue: 0.99) { return "gray2" }
        if color == Color(red: 0.95, green: 0.95, blue: 0.97) { return "gray3" }
        if color == Color(red: 0.90, green: 0.90, blue: 0.92) { return "gray4" }
        if color == Color(red: 0.85, green: 0.85, blue: 0.87) { return "gray5" }
        if color == Color(red: 0.78, green: 0.78, blue: 0.80) { return "gray6" }
        if color == .clear { return "clear" }
        return "primary" // Fallback
    }
    
    // Helper to convert color string back to Color
    private static func colorStringToColor(_ colorString: String) -> Color {
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
        case "gray2": return Color(red: 0.99, green: 0.99, blue: 0.99)
        case "gray3": return Color(red: 0.95, green: 0.95, blue: 0.97)
        case "gray4": return Color(red: 0.90, green: 0.90, blue: 0.92)
        case "gray5": return Color(red: 0.85, green: 0.85, blue: 0.87)
        case "gray6": return Color(red: 0.78, green: 0.78, blue: 0.80)
        case "clear": return .clear
        default: return .primary // Fallback
        }
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: ComponentProperty, rhs: ComponentProperty) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - UI Component Model
class UIComponent: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    let type: ComponentType
    @Published var properties: [ComponentProperty]
    @Published var children: [UIComponent]
    @Published var frame: CGRect
    @Published var isSelected: Bool = false
    @Published var isVisible: Bool = true
    @Published var zIndex: Int = 0
    @Published var modifiers: [ComponentModifier]
    
    init(type: ComponentType, properties: [ComponentProperty] = [], children: [UIComponent] = [], frame: CGRect = .zero, modifiers: [ComponentModifier] = []) {
        self.id = UUID()
        self.type = type
        self.properties = properties
        self.children = children
        self.frame = frame
        self.modifiers = modifiers
    }
    
    // MARK: - Property Management
    func setProperty(key: String, value: Any) {
        if let index = properties.firstIndex(where: { $0.key == key }) {
            let oldValue = properties[index].value
            properties[index].value = value
            objectWillChange.send()
            
            print("🔄 Property changed: \(key) from '\(oldValue)' to '\(value)'")
            
            // Post notification to trigger design file saving
            NotificationCenter.default.post(name: .designChanged, object: nil)
        } else {
            print("⚠️ Property not found: \(key)")
        }
    }
    
    func getProperty(key: String) -> Any? {
        return properties.first(where: { $0.key == key })?.value
    }
    
    // MARK: - Child Management
    func addChild(_ child: UIComponent) {
        // Prevent adding the same component multiple times
        if !children.contains(where: { $0.id == child.id }) {
            children.append(child)
        }
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
        modifiers.append(modifier)
        objectWillChange.send()
        print("🔄 Modifier added: \(modifier.type.rawValue)")
    }
    
    func removeModifier(_ modifier: ComponentModifier) {
        modifiers.removeAll { $0.id == modifier.id }
        objectWillChange.send()
        print("🔄 Modifier removed: \(modifier.type.rawValue)")
    }
    
    func removeModifier(at index: Int) {
        guard index < modifiers.count else { return }
        let removedModifier = modifiers[index]
        modifiers.remove(at: index)
        objectWillChange.send()
        print("🔄 Modifier removed at index \(index): \(removedModifier.type.rawValue)")
    }
    
    func updateModifier(_ modifier: ComponentModifier) {
        if let index = modifiers.firstIndex(where: { $0.id == modifier.id }) {
            modifiers[index] = modifier
            objectWillChange.send()
            print("🔄 Modifier updated: \(modifier.type.rawValue)")
        }
    }
    
    func moveModifier(from source: IndexSet, to destination: Int) {
        modifiers.move(fromOffsets: source, toOffset: destination)
        objectWillChange.send()
        print("🔄 Modifiers reordered")
    }
    
    // MARK: - Code Generation
    func generateSwiftCode() -> String {
        return CodeGenerator.generateCode(for: self)
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, type, properties, children, frame, isSelected, isVisible, zIndex, modifiers
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.type = try container.decode(ComponentType.self, forKey: .type)
        self.properties = try container.decode([ComponentProperty].self, forKey: .properties)
        self.children = try container.decode([UIComponent].self, forKey: .children)
        self.frame = try container.decode(CGRect.self, forKey: .frame)
        self.isSelected = try container.decode(Bool.self, forKey: .isSelected)
        self.isVisible = try container.decode(Bool.self, forKey: .isVisible)
        self.zIndex = try container.decode(Int.self, forKey: .zIndex)
        self.modifiers = try container.decode([ComponentModifier].self, forKey: .modifiers)
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
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Hello World", defaultValue: "Hello World"),
                ComponentProperty(key: "fontSize", displayName: "Font Size", type: .font, value: "body", defaultValue: "body", options: ["largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"]),
                ComponentProperty(key: "fontWeight", displayName: "Font Weight", type: .font, value: "regular", defaultValue: "regular", options: ["regular", "bold", "light", "medium", "semibold", "heavy", "black"]),
                ComponentProperty(key: "foregroundColor", displayName: "Text Color", type: .color, value: Color.primary, defaultValue: Color.primary),
            ]
        case .image:
            return [
                ComponentProperty(key: "imageName", displayName: "Image Name", type: .string, value: "photo", defaultValue: "photo"),
                ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: true),
                ComponentProperty(key: "aspectRatio", displayName: "Aspect Ratio", type: .dropdown, value: "fit", defaultValue: "fit", options: ["fit", "fill", "none"])
            ]
        case .button:
            return [
                ComponentProperty(key: "title", displayName: "Title", type: .string, value: "Button", defaultValue: "Button"),
                ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: Color.blue, defaultValue: Color.blue),
                ComponentProperty(key: "foregroundColor", displayName: "Text Color", type: .color, value: Color.white, defaultValue: Color.white),
                ComponentProperty(key: "cornerRadius", displayName: "Corner Radius", type: .cornerRadius, value: 8.0, defaultValue: 8.0)
            ]
        case .vstack:
            return [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"]),
                ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: Color.clear, defaultValue: Color.clear)
            ]
        case .hstack:
            return [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"]),
                ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: Color.clear, defaultValue: Color.clear)
            ]
        case .zstack:
            return [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["topLeading", "top", "topTrailing", "leading", "center", "trailing", "bottomLeading", "bottom", "bottomTrailing"]),
                ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: Color.clear, defaultValue: Color.clear)
            ]
        case .rectangle, .roundedRectangle, .circle, .capsule, .ellipse:
            return [
                ComponentProperty(key: "cornerRadius", displayName: "Corner Radius", type: .cornerRadius, value: 8.0, defaultValue: 8.0),
                ComponentProperty(key: "fill", displayName: "Fill Color", type: .color, value: Color.gray, defaultValue: Color.gray)
            ]
        case .spacer:
            return [
                ComponentProperty(key: "minLength", displayName: "Min Length", type: .number, value: 0.0, defaultValue: 0.0)
            ]
        case .scrollView:
            return [
                ComponentProperty(key: "axis", displayName: "Axis", type: .segmentedControl, value: "vertical", defaultValue: "vertical", options: ["vertical", "horizontal"]),
                ComponentProperty(key: "showsIndicators", displayName: "Shows Indicators", type: .boolean, value: true, defaultValue: true)
            ]
        case .list:
            return [
                ComponentProperty(key: "style", displayName: "Style", type: .dropdown, value: "plain", defaultValue: "plain", options: ["plain", "grouped", "inset", "insetGrouped"]),
                ComponentProperty(key: "separatorStyle", displayName: "Separator Style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "none", "singleLine"])
            ]
        case .navigationView:
            return [
                ComponentProperty(key: "style", displayName: "Style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "stack", "columns"])
            ]
        case .tabView:
            return [
                ComponentProperty(key: "style", displayName: "Style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "page"])
            ]
        case .form:
            return [
                ComponentProperty(key: "style", displayName: "Style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "grouped"])
            ]
        case .sfSymbol:
            return [
                ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "star", defaultValue: "star"),
                ComponentProperty(key: "foregroundColor", displayName: "Color", type: .color, value: Color.primary, defaultValue: Color.primary),
                ComponentProperty(key: "fontSize", displayName: "Size", type: .font, value: "largeTitle", defaultValue: "largeTitle", options: ["largeTitle", "title", "title2", "title3", "headline", "body", "callout", "subheadline", "footnote", "caption", "caption2"]),
                ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: Color.clear, defaultValue: Color.clear)
            ]
        default:
            return []
        }
    }
}
