//
//  UIComponent.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

// MARK: - Component Types
enum ComponentType: String, CaseIterable, Identifiable {
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
enum PropertyType {
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
}

// MARK: - Component Property
struct ComponentProperty: Identifiable {
    let id = UUID()
    let key: String
    let type: PropertyType
    var value: Any
    let defaultValue: Any
    let options: [Any]?
    let isRequired: Bool
    
    init(key: String, type: PropertyType, value: Any, defaultValue: Any, options: [Any]? = nil, isRequired: Bool = false) {
        self.key = key
        self.type = type
        self.value = value
        self.defaultValue = defaultValue
        self.options = options
        self.isRequired = isRequired
    }
}

// MARK: - UI Component Model
class UIComponent: ObservableObject, Identifiable {
    let id = UUID()
    let type: ComponentType
    @Published var properties: [ComponentProperty]
    @Published var children: [UIComponent]
    @Published var frame: CGRect
    @Published var isSelected: Bool = false
    @Published var isVisible: Bool = true
    @Published var zIndex: Int = 0
    
    init(type: ComponentType, properties: [ComponentProperty] = [], children: [UIComponent] = [], frame: CGRect = .zero) {
        self.type = type
        self.properties = properties
        self.children = children
        self.frame = frame
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
    
    // MARK: - Code Generation
    func generateSwiftCode() -> String {
        return CodeGenerator.generateCode(for: self)
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
                ComponentProperty(key: "aspectRatio", type: .string, value: "fit", defaultValue: "fit", options: ["fit", "fill", "none"]),
                ComponentProperty(key: "frameWidth", type: .number, value: 100.0, defaultValue: 100.0),
                ComponentProperty(key: "frameHeight", type: .number, value: 100.0, defaultValue: 100.0)
            ]
        case .button:
            return [
                ComponentProperty(key: "title", type: .string, value: "Button", defaultValue: "Button"),
                ComponentProperty(key: "backgroundColor", type: .color, value: Color.blue, defaultValue: Color.blue),
                ComponentProperty(key: "foregroundColor", type: .color, value: Color.white, defaultValue: Color.white),
                ComponentProperty(key: "cornerRadius", type: .cornerRadius, value: 8.0, defaultValue: 8.0),
                ComponentProperty(key: "padding", type: .padding, value: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16), defaultValue: EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            ]
        case .vstack, .hstack, .zstack:
            return [
                ComponentProperty(key: "spacing", type: .spacing, value: 8.0, defaultValue: 8.0),
                ComponentProperty(key: "alignment", type: .alignment, value: "center", defaultValue: "center", options: ["leading", "center", "trailing", "top", "bottom", "firstTextBaseline", "lastTextBaseline"])
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
        default:
            return []
        }
    }
}
