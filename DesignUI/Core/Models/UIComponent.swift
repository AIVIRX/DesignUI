//
//  UIComponent.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

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
    case section = "Section"
    case picker = "Picker"
    case toggle = "Toggle"
    case slider = "Slider"
    case stepper = "Stepper"
    case textField = "TextField"
    case secureField = "SecureField"
    case textEditor = "TextEditor"
    case datePicker = "DatePicker"
    case colorPicker = "ColorPicker"
    case progressView = "ProgressView"
    case loadingIndicator = "LoadingIndicator"
    case card = "Card"
    case alert = "Alert"
    case sheet = "Sheet"
    case fullScreenCover = "FullScreenCover"
    
    var id: String { rawValue }
    
    var category: ComponentCategory {
        switch self {
        case .text, .image, .button:
            return .basic
        case .vstack, .hstack, .zstack, .spacer, .divider:
            return .layout
        case .rectangle, .circle, .roundedRectangle, .capsule, .ellipse:
            return .shapes
        case .list, .scrollView, .navigationView, .tabView, .form, .section:
            return .containers
        case .picker, .toggle, .slider, .stepper, .textField, .secureField, .textEditor, .datePicker, .colorPicker:
            return .controls
        case .progressView, .loadingIndicator:
            return .indicators
        case .card, .alert, .sheet, .fullScreenCover:
            return .overlays
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
        case .roundedRectangle: return "rectangle.roundedtopright"
        case .capsule: return "capsule"
        case .ellipse: return "oval"
        case .list: return "list.bullet"
        case .scrollView: return "scroll"
        case .navigationView: return "navigation"
        case .tabView: return "square.grid.2x2"
        case .form: return "doc.text"
        case .section: return "section"
        case .picker: return "list.bullet.rectangle"
        case .toggle: return "switch.2"
        case .slider: return "slider.horizontal.3"
        case .stepper: return "plusminus"
        case .textField: return "text.cursor"
        case .secureField: return "lock"
        case .textEditor: return "text.alignleft"
        case .datePicker: return "calendar"
        case .colorPicker: return "paintpalette"
        case .progressView: return "chart.bar"
        case .loadingIndicator: return "arrow.clockwise"
        case .card: return "rectangle.stack"
        case .alert: return "exclamationmark.triangle"
        case .sheet: return "rectangle.portrait"
        case .fullScreenCover: return "rectangle.fill"
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
struct ComponentProperty: Identifiable, Codable, Equatable {
    let id: UUID
    let key: String
    let type: PropertyType
    var value: Any
    let defaultValue: Any
    let options: [Any]?
    let isRequired: Bool
    
    init(key: String, type: PropertyType, value: Any, defaultValue: Any, options: [Any]? = nil, isRequired: Bool = false) {
        self.id = UUID()
        self.key = key
        self.type = type
        self.value = value
        self.defaultValue = defaultValue
        self.options = options
        self.isRequired = isRequired
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, key, type, value, defaultValue, options, isRequired
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.key = try container.decode(String.self, forKey: .key)
        self.type = try container.decode(PropertyType.self, forKey: .type)
        self.isRequired = try container.decode(Bool.self, forKey: .isRequired)
        
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
                try container.encode("\(color)", forKey: key)
            } else {
                try container.encode("", forKey: key)
            }
        default:
            try container.encode("\(value)", forKey: key)
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
            // Convert string back to Color (simplified - you might want to improve this)
            return Color.primary // For now, return a default color
        default:
            return try container.decode(String.self, forKey: key)
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
            properties[index].value = value
        }
    }
    
    func getProperty(key: String) -> Any? {
        return properties.first(where: { $0.key == key })?.value
    }
    
    // MARK: - Child Management
    func addChild(_ child: UIComponent) {
        children.append(child)
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
    }
    
    func removeModifier(_ modifier: ComponentModifier) {
        modifiers.removeAll { $0.id == modifier.id }
    }
    
    func removeModifier(at index: Int) {
        guard index < modifiers.count else { return }
        modifiers.remove(at: index)
    }
    
    func updateModifier(_ modifier: ComponentModifier) {
        if let index = modifiers.firstIndex(where: { $0.id == modifier.id }) {
            modifiers[index] = modifier
        }
    }
    
    func moveModifier(from source: IndexSet, to destination: Int) {
        modifiers.move(fromOffsets: source, toOffset: destination)
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
                ComponentProperty(key: "text", type: .string, value: "Hello World", defaultValue: "Hello World"),
                ComponentProperty(key: "fontSize", type: .number, value: 16.0, defaultValue: 16.0),
                ComponentProperty(key: "fontWeight", type: .font, value: "regular", defaultValue: "regular", options: ["regular", "bold", "light", "medium", "semibold", "heavy", "black"]),
                ComponentProperty(key: "foregroundColor", type: .color, value: Color.primary, defaultValue: Color.primary),
                ComponentProperty(key: "multilineTextAlignment", type: .alignment, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"])
            ]
        case .image:
            return [
                ComponentProperty(key: "imageName", type: .string, value: "photo", defaultValue: "photo"),
                ComponentProperty(key: "resizable", type: .boolean, value: true, defaultValue: true),
                ComponentProperty(key: "aspectRatio", type: .dropdown, value: "fit", defaultValue: "fit", options: ["fit", "fill", "none"])
            ]
        case .button:
            return [
                ComponentProperty(key: "title", type: .string, value: "Button", defaultValue: "Button"),
                ComponentProperty(key: "backgroundColor", type: .color, value: Color.blue, defaultValue: Color.blue),
                ComponentProperty(key: "foregroundColor", type: .color, value: Color.white, defaultValue: Color.white),
                ComponentProperty(key: "cornerRadius", type: .cornerRadius, value: 8.0, defaultValue: 8.0)
            ]
        case .vstack:
            return [
                ComponentProperty(key: "alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                ComponentProperty(key: "spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
            ]
        case .hstack:
            return [
                ComponentProperty(key: "alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                ComponentProperty(key: "spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
            ]
        case .zstack:
            return [
                ComponentProperty(key: "alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["topLeading", "top", "topTrailing", "leading", "center", "trailing", "bottomLeading", "bottom", "bottomTrailing"])
            ]
        case .rectangle, .roundedRectangle, .circle, .capsule, .ellipse:
            return [
                ComponentProperty(key: "fill", type: .color, value: Color.gray, defaultValue: Color.gray),
                ComponentProperty(key: "stroke", type: .color, value: Color.clear, defaultValue: Color.clear),
                ComponentProperty(key: "lineWidth", type: .number, value: 1.0, defaultValue: 1.0),
                ComponentProperty(key: "cornerRadius", type: .cornerRadius, value: 8.0, defaultValue: 8.0)
            ]
        case .spacer:
            return [
                ComponentProperty(key: "minLength", type: .number, value: 0.0, defaultValue: 0.0)
            ]
        case .scrollView:
            return [
                ComponentProperty(key: "axis", type: .segmentedControl, value: "vertical", defaultValue: "vertical", options: ["vertical", "horizontal"]),
                ComponentProperty(key: "showsIndicators", type: .boolean, value: true, defaultValue: true)
            ]
        case .list:
            return [
                ComponentProperty(key: "style", type: .dropdown, value: "plain", defaultValue: "plain", options: ["plain", "grouped", "inset", "insetGrouped"]),
                ComponentProperty(key: "separatorStyle", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "none", "singleLine"])
            ]
        case .navigationView:
            return [
                ComponentProperty(key: "style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "stack", "columns"])
            ]
        case .tabView:
            return [
                ComponentProperty(key: "style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "page"])
            ]
        case .form:
            return [
                ComponentProperty(key: "style", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "grouped"])
            ]
        case .section:
            return [
                ComponentProperty(key: "headerStyle", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "prominent"]),
                ComponentProperty(key: "footerStyle", type: .dropdown, value: "automatic", defaultValue: "automatic", options: ["automatic", "prominent"])
            ]
        default:
            return []
        }
    }
}
