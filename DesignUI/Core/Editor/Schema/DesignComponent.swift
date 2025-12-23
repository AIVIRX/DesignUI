import Foundation
import SwiftUI

// MARK: - Component Type Enum
/// All supported SwiftUI component types
enum DesignComponentType: String, Codable, CaseIterable {
    // Basic
    case text = "Text"
    case image = "Image"
    case color = "Color"
    
    // Interactive
    case button = "Button"
    case textField = "TextField"
    case secureField = "SecureField"
    case toggle = "Toggle"
    case slider = "Slider"
    case picker = "Picker"
    case datePicker = "DatePicker"
    case stepper = "Stepper"
    
    // Layout
    case vStack = "VStack"
    case hStack = "HStack"
    case zStack = "ZStack"
    case scrollView = "ScrollView"
    case lazyVStack = "LazyVStack"
    case lazyHStack = "LazyHStack"
    case lazyVGrid = "LazyVGrid"
    case lazyHGrid = "LazyHGrid"
    case spacer = "Spacer"
    case divider = "Divider"
    case geometryReader = "GeometryReader"
    
    // Shapes
    case rectangle = "Rectangle"
    case roundedRectangle = "RoundedRectangle"
    case circle = "Circle"
    case ellipse = "Ellipse"
    case capsule = "Capsule"
    
    // Navigation
    case navigationStack = "NavigationStack"
    case navigationLink = "NavigationLink"
    case tabView = "TabView"
    
    // Container
    case list = "List"
    case form = "Form"
    case group = "Group"
    case section = "Section"
    
    var isContainer: Bool {
        switch self {
        case .vStack, .hStack, .zStack, .scrollView, .lazyVStack, .lazyHStack,
             .lazyVGrid, .lazyHGrid, .geometryReader, .navigationStack, .tabView,
             .list, .form, .group, .section:
            return true
        default:
            return false
        }
    }
    
    var category: String {
        switch self {
        case .text, .image, .color:
            return "Basic"
        case .button, .textField, .secureField, .toggle, .slider, .picker, .datePicker, .stepper:
            return "Interactive"
        case .vStack, .hStack, .zStack, .scrollView, .lazyVStack, .lazyHStack,
             .lazyVGrid, .lazyHGrid, .spacer, .divider, .geometryReader:
            return "Layout"
        case .rectangle, .roundedRectangle, .circle, .ellipse, .capsule:
            return "Shapes"
        case .navigationStack, .navigationLink, .tabView:
            return "Navigation"
        case .list, .form, .group, .section:
            return "Container"
        }
    }
    
    var iconName: String {
        switch self {
        case .text: return "textformat"
        case .image: return "photo"
        case .color: return "paintpalette"
        case .button: return "button.horizontal"
        case .textField: return "character.cursor.ibeam"
        case .secureField: return "lock.fill"
        case .toggle: return "switch.2"
        case .slider: return "slider.horizontal.3"
        case .picker: return "filemenu.and.selection"
        case .datePicker: return "calendar"
        case .stepper: return "plusminus"
        case .vStack: return "square.split.1x2"
        case .hStack: return "square.split.2x1"
        case .zStack: return "square.stack"
        case .scrollView: return "scroll"
        case .lazyVStack: return "square.split.1x2.fill"
        case .lazyHStack: return "square.split.2x1.fill"
        case .lazyVGrid: return "square.grid.3x3"
        case .lazyHGrid: return "square.grid.3x1.below.line.grid.1x2"
        case .spacer: return "arrow.up.and.down"
        case .divider: return "minus"
        case .geometryReader: return "aspectratio"
        case .rectangle: return "rectangle"
        case .roundedRectangle: return "rectangle.inset.filled"
        case .circle: return "circle"
        case .ellipse: return "oval"
        case .capsule: return "capsule"
        case .navigationStack: return "square.stack.3d.up"
        case .navigationLink: return "arrow.right.square"
        case .tabView: return "square.grid.4x3.fill"
        case .list: return "list.bullet"
        case .form: return "doc.plaintext"
        case .group: return "folder"
        case .section: return "rectangle.split.3x1"
        }
    }
}

// MARK: - Component Properties
/// Dynamic properties container for any component
struct DesignComponentProperties: Codable, Equatable {
    // Text Properties
    var text: String?
    var fontName: String?
    var fontWeight: String?
    var fontSize: CGFloat?
    var fontDesign: String?
    var textAlignment: String?
    var lineLimit: Int?
    var truncationMode: String?
    var kerning: CGFloat?
    var tracking: CGFloat?
    var baselineOffset: CGFloat?
    
    // Image Properties
    var imageSource: ImageSource?
    var systemName: String?
    var assetName: String?
    var imageURL: String?
    var resizable: Bool?
    var contentMode: String?
    var renderingMode: String?
    
    // Button Properties
    var buttonLabel: String?
    var buttonRole: String?
    var action: DesignAction?
    
    // TextField Properties
    var placeholder: String?
    var textFieldStyle: String?
    var keyboardType: String?
    var autocapitalization: String?
    var autocorrection: Bool?
    
    // Toggle Properties
    var isOn: Bool?
    var toggleStyle: String?
    
    // Slider Properties
    var sliderValue: Double?
    var sliderMin: Double?
    var sliderMax: Double?
    var sliderStep: Double?
    
    // Stack Properties
    var alignment: String?
    var spacing: CGFloat?
    
    // ScrollView Properties
    var scrollAxes: String?
    var showsIndicators: Bool?
    
    // Grid Properties
    var columns: [GridColumnConfig]?
    var pinnedViews: [String]?
    
    // Shape Properties
    var cornerRadius: CGFloat?
    var cornerStyle: String?
    
    // Spacer Properties
    var minLength: CGFloat?
    
    // Color Properties
    var colorValue: String?
    
    // Generic Properties
    var label: String?
    var title: String?
    var systemImage: String?
    
    static let `default` = DesignComponentProperties()
}

// MARK: - Supporting Types
enum ImageSource: String, Codable, Equatable {
    case system
    case asset
    case url
}

struct GridColumnConfig: Codable, Equatable {
    var type: String // "fixed", "flexible", "adaptive"
    var size: CGFloat?
    var minimum: CGFloat?
    var maximum: CGFloat?
    var spacing: CGFloat?
    var alignment: String?
}

struct DesignAction: Codable, Equatable {
    var type: String // "navigate", "dismiss", "custom", "sheet", "alert"
    var destination: String?
    var parameters: [String: AnyCodable]?
}

// MARK: - Design Component
/// Main component model for the editor
struct DesignComponent: Identifiable, Codable, Equatable {
    let id: String
    var type: DesignComponentType
    var name: String
    var parentId: String?
    var childrenIds: [String]
    var zIndex: Int
    var properties: DesignComponentProperties
    var modifiers: [DesignModifier]
    
    init(
        id: String = UUID().uuidString,
        type: DesignComponentType,
        name: String? = nil,
        parentId: String? = nil,
        childrenIds: [String] = [],
        zIndex: Int = 0,
        properties: DesignComponentProperties = .default,
        modifiers: [DesignModifier] = []
    ) {
        self.id = id
        self.type = type
        self.name = name ?? type.rawValue
        self.parentId = parentId
        self.childrenIds = childrenIds
        self.zIndex = zIndex
        self.properties = properties
        self.modifiers = modifiers
    }
    
    // Factory methods for quick creation with defaults
    static func text(_ content: String, id: String = UUID().uuidString) -> DesignComponent {
        var props = DesignComponentProperties()
        props.text = content
        props.fontSize = 17
        props.fontWeight = "regular"
        return DesignComponent(id: id, type: .text, properties: props)
    }
    
    static func image(systemName: String, id: String = UUID().uuidString) -> DesignComponent {
        var props = DesignComponentProperties()
        props.imageSource = .system
        props.systemName = systemName
        props.resizable = true
        props.contentMode = "fit"
        return DesignComponent(id: id, type: .image, properties: props)
    }
    
    static func button(_ label: String, id: String = UUID().uuidString) -> DesignComponent {
        var props = DesignComponentProperties()
        props.buttonLabel = label
        props.buttonRole = "none"
        return DesignComponent(id: id, type: .button, properties: props)
    }
    
    static func vStack(
        alignment: String = "center",
        spacing: CGFloat = 8,
        id: String = UUID().uuidString
    ) -> DesignComponent {
        var props = DesignComponentProperties()
        props.alignment = alignment
        props.spacing = spacing
        return DesignComponent(id: id, type: .vStack, properties: props)
    }
    
    static func hStack(
        alignment: String = "center",
        spacing: CGFloat = 8,
        id: String = UUID().uuidString
    ) -> DesignComponent {
        var props = DesignComponentProperties()
        props.alignment = alignment
        props.spacing = spacing
        return DesignComponent(id: id, type: .hStack, properties: props)
    }
    
    static func zStack(
        alignment: String = "center",
        id: String = UUID().uuidString
    ) -> DesignComponent {
        var props = DesignComponentProperties()
        props.alignment = alignment
        return DesignComponent(id: id, type: .zStack, properties: props)
    }
    
    static func spacer(minLength: CGFloat? = nil, id: String = UUID().uuidString) -> DesignComponent {
        var props = DesignComponentProperties()
        props.minLength = minLength
        return DesignComponent(id: id, type: .spacer, properties: props)
    }
    
    static func rectangle(id: String = UUID().uuidString) -> DesignComponent {
        DesignComponent(id: id, type: .rectangle)
    }
    
    static func circle(id: String = UUID().uuidString) -> DesignComponent {
        DesignComponent(id: id, type: .circle)
    }
}

// MARK: - Component Type Registry
/// Registry for component type metadata and defaults
struct ComponentTypeRegistry {
    static let shared = ComponentTypeRegistry()
    
    func defaultProperties(for type: DesignComponentType) -> DesignComponentProperties {
        var props = DesignComponentProperties()
        
        switch type {
        case .text:
            props.text = "Text"
            props.fontSize = 17
            props.fontWeight = "regular"
            props.fontDesign = "default"
            props.textAlignment = "leading"
            
        case .image:
            props.imageSource = .system
            props.systemName = "photo"
            props.resizable = true
            props.contentMode = "fit"
            props.renderingMode = "original"
            
        case .button:
            props.buttonLabel = "Button"
            props.buttonRole = "none"
            
        case .textField:
            props.placeholder = "Enter text..."
            props.text = ""
            props.textFieldStyle = "plain"
            props.keyboardType = "default"
            props.autocapitalization = "sentences"
            props.autocorrection = true
            
        case .toggle:
            props.label = "Toggle"
            props.isOn = false
            props.toggleStyle = "switch"
            
        case .slider:
            props.sliderValue = 0.5
            props.sliderMin = 0
            props.sliderMax = 1
            
        case .vStack, .lazyVStack:
            props.alignment = "center"
            props.spacing = 8
            
        case .hStack, .lazyHStack:
            props.alignment = "center"
            props.spacing = 8
            
        case .zStack:
            props.alignment = "center"
            
        case .scrollView:
            props.scrollAxes = "vertical"
            props.showsIndicators = true
            
        case .spacer:
            props.minLength = nil
            
        case .roundedRectangle:
            props.cornerRadius = 10
            props.cornerStyle = "continuous"
            
        case .capsule:
            props.cornerStyle = "continuous"
            
        case .color:
            props.colorValue = "#007AFF"
            
        default:
            break
        }
        
        return props
    }
    
    func createComponent(type: DesignComponentType, id: String = UUID().uuidString) -> DesignComponent {
        DesignComponent(
            id: id,
            type: type,
            name: type.rawValue,
            properties: defaultProperties(for: type)
        )
    }
}
