//
//  SchemaConverter.swift
//  DesignUI
//
//  Converts between SimpleUIComponent and UIComponent
//

import SwiftUI
import Foundation

// MARK: - Schema Converter
struct SchemaConverter {
    
    // MARK: - Convert UIComponent to Simple Format
    static func toSimple(_ component: UIComponent) -> SimpleUIComponent {
        // Extract properties as flat dictionary
        var props: [String: SimpleValue] = [:]
        
        for property in component.properties {
            switch property.type {
            case .string, .font, .alignment, .segmentedControl, .dropdown:
                if let s = property.value as? String {
                    props[property.key] = .string(s)
                }
            case .number, .spacing, .cornerRadius, .padding, .frame, .offset, .rotation, .scale, .opacity, .shadow, .border, .gradient, .animation:
                if let n = property.value as? Double {
                    props[property.key] = .number(n)
                } else if let n = property.value as? CGFloat {
                    props[property.key] = .number(Double(n))
                } else if let n = property.value as? Int {
                    props[property.key] = .number(Double(n))
                }
            case .boolean:
                if let b = property.value as? Bool {
                    props[property.key] = .bool(b)
                }
            case .color:
                // Convert color to string representation
                if let colorString = property.value as? String {
                    props[property.key] = .string(colorString)
                } else if let color = property.value as? Color {
                    props[property.key] = .string(ComponentProperty.colorToColorString(color))
                }
            }
        }
        
        // Convert modifiers to string format
        let modifierStrings = component.modifiers.map { modifierToString($0) }
        
        // Recursively convert children (excluding overlay/modifier children for simplicity)
        let childComponents = component.getRegularChildren().map { toSimple($0) }
        
        return SimpleUIComponent(
            type: component.type.rawValue,
            props: props.isEmpty ? nil : props,
            modifiers: modifierStrings.isEmpty ? nil : modifierStrings,
            children: childComponents.isEmpty ? nil : childComponents
        )
    }
    
    // MARK: - Convert Simple Format to UIComponent
    static func fromSimple(_ simple: SimpleUIComponent) -> UIComponent? {
        // Parse type
        guard let componentType = ComponentType.allCases.first(where: { $0.rawValue == simple.type }) else {
            print("⚠️ Unknown component type: \(simple.type)")
            return nil
        }
        
        // Build properties from props
        var properties = UIComponent.defaultProperties(for: componentType)
        
        if let props = simple.props {
            for (key, value) in props {
                // Update existing property or add new one
                if let index = properties.firstIndex(where: { $0.key == key }) {
                    switch value {
                    case .string(let s):
                        properties[index].value = s
                    case .number(let n):
                        properties[index].value = n
                    case .bool(let b):
                        properties[index].value = b
                    case .null:
                        break
                    }
                } else {
                    // Add new property
                    let propertyType = inferPropertyType(key: key, value: value)
                    let newProperty = ComponentProperty(
                        key: key,
                        displayName: ComponentProperty.properDisplayName(for: key),
                        type: propertyType,
                        value: extractValue(value),
                        defaultValue: extractValue(value)
                    )
                    properties.append(newProperty)
                }
            }
        }
        
        // Parse modifiers
        var modifiers: [ComponentModifier] = []
        if let modifierStrings = simple.modifiers {
            for modString in modifierStrings {
                if let modifier = parseModifier(modString) {
                    modifiers.append(modifier)
                }
            }
        }
        
        // Recursively convert children
        var children: [UIComponent] = []
        if let simpleChildren = simple.children {
            for simpleChild in simpleChildren {
                if let child = fromSimple(simpleChild) {
                    children.append(child)
                }
            }
        }
        
        let component = UIComponent(
            type: componentType,
            properties: properties,
            children: children,
            frame: .zero,
            modifiers: modifiers
        )
        
        return component
    }
    
    // MARK: - Modifier String Conversion
    
    /// Convert ComponentModifier to SwiftUI-like string
    static func modifierToString(_ modifier: ComponentModifier) -> String {
        switch modifier.type {
        case .foregroundColor:
            let color = getColorName(from: modifier.properties["color"])
            return ".foregroundColor(\(color))"
            
        case .backgroundColor:
            if let _ = modifier.properties["gradient"] {
                return ".background(LinearGradient(...))"
            }
            let color = getColorName(from: modifier.properties["color"])
            return ".background(\(color))"
            
        case .background:
            let color = getColorName(from: modifier.properties["color"])
            return ".background(\(color))"
            
        case .font:
            let weight = modifier.properties["fontWeight"] as? String ?? "regular"
            return ".fontWeight(.\(weight))"
            
        case .fontSize:
            let size = modifier.properties["fontSize"] as? String ?? "body"
            return ".font(.\(size))"
            
        case .padding:
            let amount = modifier.getCGFloat(key: "amount", defaultValue: 10)
            let location = modifier.properties["location"] as? String ?? "all"
            if location == "all" {
                return ".padding(\(Int(amount)))"
            } else {
                return ".padding(.\(location), \(Int(amount)))"
            }
            
        case .frame:
            let widthType = modifier.properties["widthType"] as? String ?? "Default"
            let heightType = modifier.properties["heightType"] as? String ?? "Default"
            var parts: [String] = []
            
            if widthType == "Fixed" {
                let w = modifier.getCGFloat(key: "width", defaultValue: 100)
                parts.append("width: \(Int(w))")
            } else if widthType == "Infinity" {
                parts.append("maxWidth: .infinity")
            }
            
            if heightType == "Fixed" {
                let h = modifier.getCGFloat(key: "height", defaultValue: 100)
                parts.append("height: \(Int(h))")
            } else if heightType == "Infinity" {
                parts.append("maxHeight: .infinity")
            }
            
            if parts.isEmpty {
                return ".frame()"
            }
            return ".frame(\(parts.joined(separator: ", ")))"
            
        case .cornerRadius:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 8)
            return ".cornerRadius(\(Int(radius)))"
            
        case .opacity:
            let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            return ".opacity(\(opacity))"
            
        case .shadow:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 2)
            let x = modifier.getCGFloat(key: "x", defaultValue: 0)
            let y = modifier.getCGFloat(key: "y", defaultValue: 2)
            return ".shadow(radius: \(Int(radius)), x: \(Int(x)), y: \(Int(y)))"
            
        case .rotation:
            let angle = modifier.getDouble(key: "angle", defaultValue: 0)
            return ".rotationEffect(.degrees(\(angle)))"
            
        case .scale:
            let scaleX = modifier.getDouble(key: "x", defaultValue: 1.0)
            let scaleY = modifier.getDouble(key: "y", defaultValue: 1.0)
            if scaleX == scaleY {
                return ".scaleEffect(\(scaleX))"
            }
            return ".scaleEffect(x: \(scaleX), y: \(scaleY))"
            
        case .offset:
            let x = modifier.getCGFloat(key: "x", defaultValue: 0)
            let y = modifier.getCGFloat(key: "y", defaultValue: 0)
            return ".offset(x: \(Int(x)), y: \(Int(y)))"
            
        case .blur:
            let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            return ".blur(radius: \(Int(radius)))"
            
        case .clipShape:
            let shape = modifier.properties["shape"] as? String ?? "Rectangle"
            return ".clipShape(\(shape)())"
            
        case .border:
            let width = modifier.getCGFloat(key: "width", defaultValue: 1)
            let color = getColorName(from: modifier.properties["color"])
            return ".border(\(color), width: \(Int(width)))"
            
        case .fill:
            let color = getColorName(from: modifier.properties["color"])
            return ".fill(\(color))"
            
        case .textAlignment:
            let alignment = modifier.properties["alignment"] as? String ?? "leading"
            return ".multilineTextAlignment(.\(alignment))"
            
        case .overlay, .mask:
            // These have child components, simplified representation
            return ".\(modifier.type.rawValue.lowercased())()"
            
        case .aspectRatio:
            let mode = modifier.properties["aspectRatio"] as? String ?? "fit"
            return ".aspectRatio(contentMode: .\(mode))"
            
        case .zIndex:
            let index = modifier.getDouble(key: "index", defaultValue: 0)
            return ".zIndex(\(index))"
        }
    }
    
    /// Parse SwiftUI-like modifier string to ComponentModifier
    static func parseModifier(_ string: String) -> ComponentModifier? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix(".") else { return nil }
        
        let content = String(trimmed.dropFirst())
        
        // Parse modifier name and arguments
        guard let parenStart = content.firstIndex(of: "(") else {
            // No arguments modifier
            return parseSimpleModifier(content)
        }
        
        let name = String(content[..<parenStart])
        let argsStart = content.index(after: parenStart)
        guard let parenEnd = content.lastIndex(of: ")") else { return nil }
        let argsString = String(content[argsStart..<parenEnd])
        
        return parseModifierWithArgs(name: name, args: argsString)
    }
    
    // MARK: - Private Helpers
    
    private static func parseSimpleModifier(_ name: String) -> ComponentModifier? {
        // Handle modifiers without arguments
        return nil
    }
    
    private static func parseModifierWithArgs(name: String, args: String) -> ComponentModifier? {
        switch name {
        case "foregroundColor":
            let color = parseColorArg(args)
            return ComponentModifier(type: .foregroundColor, properties: ["color": color])
            
        case "background":
            // Parse as backgroundColor since .background(Color) is for colors
            let color = parseColorArg(args)
            return ComponentModifier(type: .backgroundColor, properties: ["color": color])
            
        case "font":
            // Parse .font(.title) or .font(.system(size: 16))
            let fontSize = parseFontArg(args)
            return ComponentModifier(type: .fontSize, properties: ["fontSize": fontSize])
            
        case "fontWeight":
            let weight = args.replacingOccurrences(of: ".", with: "")
            return ComponentModifier(type: .font, properties: ["fontWeight": weight])
            
        case "padding":
            return parsePaddingModifier(args)
            
        case "frame":
            return parseFrameModifier(args)
            
        case "cornerRadius":
            let radius = CGFloat(Double(args) ?? 8)
            return ComponentModifier(type: .cornerRadius, properties: ["radius": radius])
            
        case "opacity":
            let opacity = Double(args) ?? 1.0
            return ComponentModifier(type: .opacity, properties: ["opacity": opacity])
            
        case "shadow":
            return parseShadowModifier(args)
            
        case "rotationEffect":
            // Parse .degrees(45)
            let angle = parseDegreesArg(args)
            return ComponentModifier(type: .rotation, properties: ["angle": angle])
            
        case "scaleEffect":
            return parseScaleModifier(args)
            
        case "offset":
            return parseOffsetModifier(args)
            
        case "blur":
            return parseBlurModifier(args)
            
        case "clipShape":
            let shape = args.replacingOccurrences(of: "()", with: "")
            return ComponentModifier(type: .clipShape, properties: ["shape": shape])
            
        case "border":
            return parseBorderModifier(args)
            
        case "fill":
            let color = parseColorArg(args)
            return ComponentModifier(type: .fill, properties: ["color": color])
            
        case "multilineTextAlignment":
            let alignment = args.replacingOccurrences(of: ".", with: "")
            return ComponentModifier(type: .textAlignment, properties: ["alignment": alignment])
            
        default:
            print("⚠️ Unknown modifier: \(name)")
            return nil
        }
    }
    
    private static func parseColorArg(_ arg: String) -> Color {
        let colorName = arg.replacingOccurrences(of: ".", with: "").lowercased()
        return ComponentProperty.colorStringToColor(colorName)
    }
    
    private static func parseFontArg(_ arg: String) -> String {
        // Handle .title, .body, .headline, etc.
        return arg.replacingOccurrences(of: ".", with: "")
    }
    
    private static func parseDegreesArg(_ arg: String) -> Double {
        // Parse .degrees(45)
        if arg.hasPrefix(".degrees(") && arg.hasSuffix(")") {
            let valueStr = arg.dropFirst(9).dropLast()
            return Double(valueStr) ?? 0
        }
        return Double(arg) ?? 0
    }
    
    private static func parsePaddingModifier(_ args: String) -> ComponentModifier {
        // Parse: 16 or .horizontal, 12
        if let amount = Double(args) {
            return ComponentModifier(type: .padding, properties: [
                "amount": CGFloat(amount),
                "location": "all"
            ])
        }
        
        // Parse edge-specific padding
        let parts = args.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        if parts.count == 2 {
            let location = parts[0].replacingOccurrences(of: ".", with: "")
            let amount = CGFloat(Double(parts[1]) ?? 10)
            return ComponentModifier(type: .padding, properties: [
                "amount": amount,
                "location": location
            ])
        }
        
        return ComponentModifier.createWithDefaults(type: .padding)
    }
    
    private static func parseFrameModifier(_ args: String) -> ComponentModifier {
        var properties: [String: Any] = [
            "widthType": "Default",
            "heightType": "Default",
            "width": CGFloat(100),
            "height": CGFloat(100)
        ]
        
        // Parse width: 100, height: 50, maxWidth: .infinity, etc.
        let pairs = args.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for pair in pairs {
            let keyValue = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard keyValue.count == 2 else { continue }
            
            let key = keyValue[0]
            let value = keyValue[1]
            
            switch key {
            case "width":
                properties["widthType"] = "Fixed"
                properties["width"] = CGFloat(Double(value) ?? 100)
            case "height":
                properties["heightType"] = "Fixed"
                properties["height"] = CGFloat(Double(value) ?? 100)
            case "maxWidth":
                if value == ".infinity" {
                    properties["widthType"] = "Infinity"
                }
            case "maxHeight":
                if value == ".infinity" {
                    properties["heightType"] = "Infinity"
                }
            default:
                break
            }
        }
        
        return ComponentModifier(type: .frame, properties: properties)
    }
    
    private static func parseShadowModifier(_ args: String) -> ComponentModifier {
        var properties: [String: Any] = [
            "radius": CGFloat(2),
            "x": CGFloat(0),
            "y": CGFloat(2),
            "color": Color.black
        ]
        
        let pairs = args.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for pair in pairs {
            let keyValue = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard keyValue.count == 2 else { continue }
            
            let key = keyValue[0]
            let value = CGFloat(Double(keyValue[1]) ?? 0)
            
            switch key {
            case "radius": properties["radius"] = value
            case "x": properties["x"] = value
            case "y": properties["y"] = value
            default: break
            }
        }
        
        return ComponentModifier(type: .shadow, properties: properties)
    }
    
    private static func parseScaleModifier(_ args: String) -> ComponentModifier {
        // Parse single value or x:, y: format
        if let scale = Double(args) {
            return ComponentModifier(type: .scale, properties: ["x": scale, "y": scale])
        }
        
        var scaleX = 1.0
        var scaleY = 1.0
        
        let pairs = args.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for pair in pairs {
            let keyValue = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard keyValue.count == 2 else { continue }
            
            if keyValue[0] == "x" { scaleX = Double(keyValue[1]) ?? 1.0 }
            if keyValue[0] == "y" { scaleY = Double(keyValue[1]) ?? 1.0 }
        }
        
        return ComponentModifier(type: .scale, properties: ["x": scaleX, "y": scaleY])
    }
    
    private static func parseOffsetModifier(_ args: String) -> ComponentModifier {
        var x: CGFloat = 0
        var y: CGFloat = 0
        
        let pairs = args.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for pair in pairs {
            let keyValue = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard keyValue.count == 2 else { continue }
            
            if keyValue[0] == "x" { x = CGFloat(Double(keyValue[1]) ?? 0) }
            if keyValue[0] == "y" { y = CGFloat(Double(keyValue[1]) ?? 0) }
        }
        
        return ComponentModifier(type: .offset, properties: ["x": x, "y": y])
    }
    
    private static func parseBlurModifier(_ args: String) -> ComponentModifier {
        // Parse radius: 5
        let pairs = args.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
        if pairs.count == 2 && pairs[0] == "radius" {
            let radius = CGFloat(Double(pairs[1]) ?? 0)
            return ComponentModifier(type: .blur, properties: ["radius": radius])
        }
        return ComponentModifier.createWithDefaults(type: .blur)
    }
    
    private static func parseBorderModifier(_ args: String) -> ComponentModifier {
        // Parse .red, width: 2
        let parts = args.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        var color = Color.black
        var width: CGFloat = 1
        
        if !parts.isEmpty {
            color = parseColorArg(parts[0])
        }
        
        if parts.count > 1 {
            let widthPart = parts[1].split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if widthPart.count == 2 {
                width = CGFloat(Double(widthPart[1]) ?? 1)
            }
        }
        
        return ComponentModifier(type: .border, properties: ["color": color, "width": width])
    }
    
    private static func getColorName(from value: Any?) -> String {
        if let colorString = value as? String {
            return ".\(colorString)"
        }
        if let color = value as? Color {
            let name = ComponentProperty.colorToColorString(color)
            return ".\(name)"
        }
        return ".primary"
    }
    
    private static func inferPropertyType(key: String, value: SimpleValue) -> PropertyType {
        // Infer based on key name
        if key.lowercased().contains("color") { return .color }
        if key == "text" || key == "title" || key == "symbolName" { return .string }
        if key == "spacing" { return .spacing }
        if key == "alignment" { return .alignment }
        
        // Infer based on value type
        switch value {
        case .string: return .string
        case .number: return .number
        case .bool: return .boolean
        case .null: return .string
        }
    }
    
    private static func extractValue(_ value: SimpleValue) -> Any {
        switch value {
        case .string(let s): return s
        case .number(let n): return n
        case .bool(let b): return b
        case .null: return ""
        }
    }
}

// MARK: - Convenience Extensions

extension UIComponent {
    /// Export to simplified AI-friendly format
    func toSimple() -> SimpleUIComponent {
        return SchemaConverter.toSimple(self)
    }
    
    /// Create from simplified AI format
    static func fromSimple(_ simple: SimpleUIComponent) -> UIComponent? {
        return SchemaConverter.fromSimple(simple)
    }
}

extension Array where Element == UIComponent {
    /// Export all components to simplified format
    func toSimple() -> [SimpleUIComponent] {
        return self.map { SchemaConverter.toSimple($0) }
    }
    
    /// Export to JSON string for AI
    func toAIJSON() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let simpleComponents = self.toSimple()
        guard let data = try? encoder.encode(simpleComponents) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
