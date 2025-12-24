//
//  SimpleUIComponent.swift
//  DesignUI
//
//  Simplified JSON schema for AI editing
//

import SwiftUI
import Foundation

// MARK: - Simple Value Type
/// A simple value that can be encoded/decoded easily
enum SimpleValue: Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode SimpleValue")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .number(let n): try container.encode(n)
        case .bool(let b): try container.encode(b)
        case .null: try container.encodeNil()
        }
    }
    
    // MARK: - Convenience Accessors
    var stringValue: String? {
        if case .string(let s) = self { return s }
        return nil
    }
    
    var numberValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }
    
    var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }
}

// MARK: - Simple UI Component
/// A simplified component model for AI editing
/// Uses flat properties and SwiftUI-like modifier strings
struct SimpleUIComponent: Codable {
    let type: String
    var props: [String: SimpleValue]?
    var modifiers: [String]?
    var children: [SimpleUIComponent]?
    
    // MARK: - Convenience Initializers
    init(type: String, props: [String: SimpleValue]? = nil, modifiers: [String]? = nil, children: [SimpleUIComponent]? = nil) {
        self.type = type
        self.props = props
        self.modifiers = modifiers
        self.children = children
    }
    
    // Custom coding to handle flat properties
    enum CodingKeys: String, CodingKey {
        case type, modifiers, children
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required type
        self.type = try container.decode(String.self, forKey: .type)
        
        // Decode optional modifiers and children
        self.modifiers = try container.decodeIfPresent([String].self, forKey: .modifiers)
        self.children = try container.decodeIfPresent([SimpleUIComponent].self, forKey: .children)
        
        // Decode all other keys as properties
        let dynamicContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
        var props: [String: SimpleValue] = [:]
        
        let reservedKeys = Set(["type", "modifiers", "children"])
        for key in dynamicContainer.allKeys {
            if !reservedKeys.contains(key.stringValue) {
                if let value = try? dynamicContainer.decode(SimpleValue.self, forKey: key) {
                    props[key.stringValue] = value
                }
            }
        }
        
        self.props = props.isEmpty ? nil : props
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode type
        try container.encode(type, forKey: .type)
        
        // Encode modifiers if present
        if let modifiers = modifiers, !modifiers.isEmpty {
            try container.encode(modifiers, forKey: .modifiers)
        }
        
        // Encode children if present
        if let children = children, !children.isEmpty {
            try container.encode(children, forKey: .children)
        }
        
        // Encode props as flat keys
        if let props = props {
            var dynamicContainer = encoder.container(keyedBy: DynamicCodingKey.self)
            for (key, value) in props {
                try dynamicContainer.encode(value, forKey: DynamicCodingKey(stringValue: key))
            }
        }
    }
}

// MARK: - Dynamic Coding Key
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    
    init(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        return nil
    }
}

// MARK: - Simple Design File
/// A simplified design file for AI import/export
struct SimpleDesignFile: Codable {
    let name: String?
    let components: [SimpleUIComponent]
    
    init(name: String? = nil, components: [SimpleUIComponent]) {
        self.name = name
        self.components = components
    }
}

// MARK: - Ultra-Compact UI Component
/// Ultra-minimal JSON format for AI with shortest possible keys
/// Key mappings:
/// - `_` = type (Text, VStack, HStack, etc.)
/// - `v` = main value (text content, symbol name, etc.)
/// - `c` = children array
/// - Style properties are direct keys: color, bg, size, pad, etc.
struct CompactUIComponent: Codable {
    // Required
    let type: String  // "_" in JSON
    
    // Main value (text, symbolName, title, etc.)
    var value: String?  // "v" in JSON
    
    // Children
    var children: [CompactUIComponent]?  // "c" in JSON
    
    // Common style properties (direct, not nested)
    var color: String?        // foreground color
    var bg: String?           // background color
    var size: String?         // font size (title, body, etc.)
    var weight: String?       // font weight
    var pad: Double?          // padding (all sides)
    var padH: Double?         // horizontal padding
    var padV: Double?         // vertical padding
    var corner: Double?       // corner radius
    var opacity: Double?      // opacity
    var spacing: Double?      // stack spacing
    var align: String?        // alignment
    var w: Double?            // width
    var h: Double?            // height
    var shadow: Double?       // shadow radius
    var blur: Double?         // blur radius
    
    enum CodingKeys: String, CodingKey {
        case type = "_"
        case value = "v"
        case children = "c"
        case color, bg, size, weight, pad, padH, padV, corner, opacity, spacing, align, w, h, shadow, blur
    }
    
    init(type: String, value: String? = nil, children: [CompactUIComponent]? = nil) {
        self.type = type
        self.value = value
        self.children = children
    }
}

// MARK: - Compact Schema Converter
struct CompactSchemaConverter {
    
    // Type abbreviations for even shorter JSON
    static let typeAbbreviations: [String: String] = [
        "Text": "T",
        "VStack": "V",
        "HStack": "H",
        "ZStack": "Z",
        "Button": "B",
        "Image": "I",
        "SF Symbol": "SF",
        "Rectangle": "Rect",
        "Circle": "C",
        "RoundedRectangle": "RRect",
        "Capsule": "Cap",
        "Spacer": "Sp",
        "Divider": "Div",
        "ScrollView": "Scroll"
    ]
    
    static let typeExpansions: [String: String] = {
        Dictionary(uniqueKeysWithValues: typeAbbreviations.map { ($1, $0) })
    }()
    
    /// Convert UIComponent to ultra-compact format
    static func toCompact(_ component: UIComponent) -> CompactUIComponent {
        var compact = CompactUIComponent(type: component.type.rawValue)
        
        // Extract main value based on component type
        switch component.type {
        case .text:
            compact.value = component.getProperty(key: "text") as? String
        case .sfSymbol:
            compact.value = component.getProperty(key: "symbolName") as? String
        case .button:
            compact.value = component.getProperty(key: "title") as? String
        default:
            break
        }
        
        // Extract stack properties
        if let spacing = component.getProperty(key: "spacing") as? Double {
            compact.spacing = spacing
        } else if let spacing = component.getProperty(key: "spacing") as? CGFloat {
            compact.spacing = Double(spacing)
        }
        
        if let alignment = component.getProperty(key: "alignment") as? String {
            compact.align = alignment
        }
        
        // Extract modifiers into direct properties
        for modifier in component.modifiers {
            switch modifier.type {
            case .foregroundColor:
                compact.color = getColorString(from: modifier.properties["color"])
            case .background:
                compact.bg = getColorString(from: modifier.properties["color"])
            case .fontSize:
                compact.size = modifier.properties["fontSize"] as? String
            case .font:
                compact.weight = modifier.properties["fontWeight"] as? String
            case .padding:
                let amount = modifier.getCGFloat(key: "amount", defaultValue: 0)
                let location = modifier.properties["location"] as? String ?? "all"
                switch location {
                case "horizontal": compact.padH = Double(amount)
                case "vertical": compact.padV = Double(amount)
                default: compact.pad = Double(amount)
                }
            case .cornerRadius:
                compact.corner = Double(modifier.getCGFloat(key: "radius", defaultValue: 0))
            case .opacity:
                compact.opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            case .frame:
                if modifier.properties["widthType"] as? String == "Fixed" {
                    compact.w = Double(modifier.getCGFloat(key: "width", defaultValue: 0))
                }
                if modifier.properties["heightType"] as? String == "Fixed" {
                    compact.h = Double(modifier.getCGFloat(key: "height", defaultValue: 0))
                }
            case .shadow:
                compact.shadow = Double(modifier.getCGFloat(key: "radius", defaultValue: 0))
            case .blur:
                compact.blur = Double(modifier.getCGFloat(key: "radius", defaultValue: 0))
            default:
                break
            }
        }
        
        // Recursively convert children
        let regularChildren = component.getRegularChildren()
        if !regularChildren.isEmpty {
            compact.children = regularChildren.map { toCompact($0) }
        }
        
        return compact
    }
    
    /// Convert ultra-compact format back to UIComponent
    static func fromCompact(_ compact: CompactUIComponent) -> UIComponent? {
        // Expand type abbreviation if needed
        let typeName = typeExpansions[compact.type] ?? compact.type
        guard let componentType = ComponentType.allCases.first(where: { $0.rawValue == typeName }) else {
            print("⚠️ Unknown type: \(compact.type)")
            return nil
        }
        
        // Build properties
        var properties = UIComponent.defaultProperties(for: componentType)
        
        // Set main value
        if let value = compact.value {
            switch componentType {
            case .text:
                updateProperty(&properties, key: "text", value: value)
            case .sfSymbol:
                updateProperty(&properties, key: "symbolName", value: value)
            case .button:
                updateProperty(&properties, key: "title", value: value)
            default:
                break
            }
        }
        
        // Set stack properties
        if let spacing = compact.spacing {
            updateProperty(&properties, key: "spacing", value: spacing)
        }
        if let align = compact.align {
            updateProperty(&properties, key: "alignment", value: align)
        }
        
        // Build modifiers from style properties
        var modifiers: [ComponentModifier] = []
        
        if let color = compact.color {
            let c = ComponentProperty.colorStringToColor(color)
            modifiers.append(ComponentModifier(type: .foregroundColor, properties: ["color": c]))
        }
        
        if let bg = compact.bg {
            let c = ComponentProperty.colorStringToColor(bg)
            modifiers.append(ComponentModifier(type: .background, properties: ["color": c]))
        }
        
        if let size = compact.size {
            modifiers.append(ComponentModifier(type: .fontSize, properties: ["fontSize": size]))
        }
        
        if let weight = compact.weight {
            modifiers.append(ComponentModifier(type: .font, properties: ["fontWeight": weight]))
        }
        
        if let pad = compact.pad {
            modifiers.append(ComponentModifier(type: .padding, properties: ["amount": CGFloat(pad), "location": "all"]))
        }
        
        if let padH = compact.padH {
            modifiers.append(ComponentModifier(type: .padding, properties: ["amount": CGFloat(padH), "location": "horizontal"]))
        }
        
        if let padV = compact.padV {
            modifiers.append(ComponentModifier(type: .padding, properties: ["amount": CGFloat(padV), "location": "vertical"]))
        }
        
        if let corner = compact.corner {
            modifiers.append(ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(corner)]))
        }
        
        if let opacity = compact.opacity {
            modifiers.append(ComponentModifier(type: .opacity, properties: ["opacity": opacity]))
        }
        
        if compact.w != nil || compact.h != nil {
            var frameProps: [String: Any] = ["widthType": "Default", "heightType": "Default"]
            if let w = compact.w {
                frameProps["widthType"] = "Fixed"
                frameProps["width"] = CGFloat(w)
            }
            if let h = compact.h {
                frameProps["heightType"] = "Fixed"
                frameProps["height"] = CGFloat(h)
            }
            modifiers.append(ComponentModifier(type: .frame, properties: frameProps))
        }
        
        if let shadow = compact.shadow {
            modifiers.append(ComponentModifier(type: .shadow, properties: ["radius": CGFloat(shadow), "x": CGFloat(0), "y": CGFloat(2)]))
        }
        
        if let blur = compact.blur {
            modifiers.append(ComponentModifier(type: .blur, properties: ["radius": CGFloat(blur)]))
        }
        
        // Recursively convert children
        var children: [UIComponent] = []
        if let compactChildren = compact.children {
            for child in compactChildren {
                if let c = fromCompact(child) {
                    children.append(c)
                }
            }
        }
        
        return UIComponent(
            type: componentType,
            properties: properties,
            children: children,
            frame: .zero,
            modifiers: modifiers
        )
    }
    
    // MARK: - Helpers
    
    private static func getColorString(from value: Any?) -> String? {
        if let s = value as? String { return s }
        if let c = value as? Color { return ComponentProperty.colorToColorString(c) }
        return nil
    }
    
    private static func updateProperty(_ properties: inout [ComponentProperty], key: String, value: Any) {
        if let index = properties.firstIndex(where: { $0.key == key }) {
            properties[index].value = value
        }
    }
}

// MARK: - Convenience Extensions

extension UIComponent {
    /// Export to ultra-compact AI format
    func toCompact() -> CompactUIComponent {
        return CompactSchemaConverter.toCompact(self)
    }
    
    /// Create from ultra-compact AI format
    static func fromCompact(_ compact: CompactUIComponent) -> UIComponent? {
        return CompactSchemaConverter.fromCompact(compact)
    }
}

extension Array where Element == UIComponent {
    /// Export to ultra-compact JSON string
    func toCompactJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let compact = self.map { CompactSchemaConverter.toCompact($0) }
        guard let data = try? encoder.encode(compact) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Create from ultra-compact JSON
    static func fromCompactJSON(_ json: String) -> [UIComponent] {
        guard let data = json.data(using: .utf8) else { return [] }
        let decoder = JSONDecoder()
        guard let compact = try? decoder.decode([CompactUIComponent].self, from: data) else { return [] }
        return compact.compactMap { UIComponent.fromCompact($0) }
    }
}
