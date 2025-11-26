//
//  JSONToTemplateConverter.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

// MARK: - JSON to Template Converter
class JSONToTemplateConverter {
    
    /// Converts JSON string to UIComponent array
    static func jsonToComponents(jsonString: String) -> [UIComponent]? {
        guard let data = jsonString.data(using: .utf8) else {
            print("❌ Failed to convert JSON string to Data")
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let components = try decoder.decode([UIComponent].self, from: data)
            return components
        } catch {
            print("❌ Failed to decode JSON to components: \(error)")
            print("Error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Generates template code from JSON string
    static func generateTemplateFromJSON(jsonString: String, templateName: String, description: String, thumbnail: String, category: DesignTemplate.TemplateCategory) -> String? {
        guard let components = jsonToComponents(jsonString: jsonString) else {
            return nil
        }
        
        var code = """
        DesignTemplate(
            name: "\(templateName)",
            description: "\(description)",
            thumbnail: "\(thumbnail)",
            components: [
        
        """
        
        // Generate component code for each component
        for (index, component) in components.enumerated() {
            code += generateComponentCode(component: component, indentLevel: 2)
            if index < components.count - 1 {
                code += ",\n"
            }
        }
        
        code += """
        
            ],
            category: .\(category.rawValue.lowercased())
        )
        """
        
        return code
    }
    
    // MARK: - Generate Component Code
    private static func generateComponentCode(component: UIComponent, indentLevel: Int) -> String {
        let indent = String(repeating: "    ", count: indentLevel)
        let nextIndent = String(repeating: "    ", count: indentLevel + 1)
        
        var code = "\(indent)UIComponent(\n"
        
        // Type
        let typeString = component.type.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
        code += "\(nextIndent)type: .\(typeString),\n"
        
        // Properties
        code += "\(nextIndent)properties: [\n"
        for (index, property) in component.properties.enumerated() {
            code += generatePropertyCode(property: property, indentLevel: indentLevel + 2)
            if index < component.properties.count - 1 {
                code += ",\n"
            }
        }
        code += "\n\(nextIndent)],\n"
        
        // Children
        if !component.children.isEmpty {
            code += "\(nextIndent)children: [\n"
            for (index, child) in component.children.enumerated() {
                code += generateComponentCode(component: child, indentLevel: indentLevel + 2)
                if index < component.children.count - 1 {
                    code += ",\n"
                }
            }
            code += "\n\(nextIndent)],\n"
        } else {
            code += "\(nextIndent)children: [],\n"
        }
        
        // Frame
        code += "\(nextIndent)frame: CGRect(x: \(component.frame.origin.x), y: \(component.frame.origin.y), width: \(component.frame.width), height: \(component.frame.height))"
        
        // Modifiers
        if !component.modifiers.isEmpty {
            code += ",\n\(nextIndent)modifiers: [\n"
            for (index, modifier) in component.modifiers.enumerated() {
                code += generateModifierCode(modifier: modifier, indentLevel: indentLevel + 2)
                if index < component.modifiers.count - 1 {
                    code += ",\n"
                }
            }
            code += "\n\(nextIndent)]"
        }
        
        code += "\n\(indent))"
        
        return code
    }
    
    // MARK: - Generate Property Code
    private static func generatePropertyCode(property: ComponentProperty, indentLevel: Int) -> String {
        let indent = String(repeating: "    ", count: indentLevel)
        
        let valueString = formatValue(property.value)
        let defaultValueString = formatValue(property.defaultValue)
        
        var code = "\(indent)ComponentProperty(key: \"\(property.key)\", displayName: \"\(property.displayName)\", type: .\(propertyTypeString(property.type)), value: \(valueString), defaultValue: \(defaultValueString)"
        
        if let options = property.options, !options.isEmpty {
            code += ", options: ["
            for (index, option) in options.enumerated() {
                code += formatValue(option)
                if index < options.count - 1 {
                    code += ", "
                }
            }
            code += "]"
        }
        
        code += ")"
        return code
    }
    
    // MARK: - Generate Modifier Code
    private static func generateModifierCode(modifier: ComponentModifier, indentLevel: Int) -> String {
        let indent = String(repeating: "    ", count: indentLevel)
        
        let modifierTypeString = modifier.type.rawValue.lowercased().replacingOccurrences(of: " ", with: "")
        var code = "\(indent)ComponentModifier(type: .\(modifierTypeString), properties: ["
        
        var propertyStrings: [String] = []
        for (key, value) in modifier.properties.sorted(by: { $0.key < $1.key }) {
            let valueString = formatModifierValue(value)
            propertyStrings.append("\"\(key)\": \(valueString)")
        }
        
        code += propertyStrings.joined(separator: ", ")
        code += "])"
        
        return code
    }
    
    // MARK: - Helper Functions
    private static func formatValue(_ value: Any) -> String {
        if let stringValue = value as? String {
            return "\"\(stringValue.replacingOccurrences(of: "\"", with: "\\\""))\""
        } else if let doubleValue = value as? Double {
            return "\(doubleValue)"
        } else if let intValue = value as? Int {
            return "\(intValue)"
        } else if let boolValue = value as? Bool {
            return "\(boolValue)"
        } else {
            return "\"\(value)\""
        }
    }
    
    private static func formatModifierValue(_ value: Any) -> String {
        if let stringValue = value as? String {
            return "\"\(stringValue.replacingOccurrences(of: "\"", with: "\\\""))\""
        } else if let cgFloatValue = value as? CGFloat {
            return "CGFloat(\(cgFloatValue))"
        } else if let doubleValue = value as? Double {
            return "\(doubleValue)"
        } else if let intValue = value as? Int {
            return "\(intValue)"
        } else if let boolValue = value as? Bool {
            return "\(boolValue)"
        } else if let colorValue = value as? Color {
            return colorToCodeString(colorValue)
        } else if let dict = value as? [String: Any] {
            // Handle color dictionaries
            if let red = dict["red"] as? Double,
               let green = dict["green"] as? Double,
               let blue = dict["blue"] as? Double,
               let alpha = dict["alpha"] as? Double {
                return "Color(red: \(red), green: \(green), blue: \(blue), opacity: \(alpha))"
            }
            return formatValue(value)
        } else {
            return formatValue(value)
        }
    }
    
    private static func propertyTypeString(_ type: PropertyType) -> String {
        switch type {
        case .string: return "string"
        case .number: return "number"
        case .boolean: return "boolean"
        case .color: return "color"
        case .font: return "font"
        case .alignment: return "alignment"
        case .spacing: return "spacing"
        case .cornerRadius: return "cornerRadius"
        case .padding: return "padding"
        case .frame: return "frame"
        case .offset: return "offset"
        case .rotation: return "rotation"
        case .scale: return "scale"
        case .opacity: return "opacity"
        case .shadow: return "shadow"
        case .border: return "border"
        case .gradient: return "gradient"
        case .animation: return "animation"
        case .segmentedControl: return "segmentedControl"
        case .dropdown: return "dropdown"
        }
    }
    
    private static func colorToCodeString(_ color: Color) -> String {
        if color == Color.primary {
            return "Color.primary"
        } else if color == Color.secondary {
            return "Color.secondary"
        } else if color == Color.blue {
            return "Color.blue"
        } else if color == Color.red {
            return "Color.red"
        } else if color == Color.green {
            return "Color.green"
        } else if color == Color.orange {
            return "Color.orange"
        } else if color == Color.purple {
            return "Color.purple"
        } else if color == Color.pink {
            return "Color.pink"
        } else if color == Color.yellow {
            return "Color.yellow"
        } else if color == Color.gray {
            return "Color.gray"
        } else if color == Color.white {
            return "Color.white"
        } else if color == Color.black {
            return "Color.black"
        } else if color == Color.clear {
            return "Color.clear"
        } else {
            #if os(macOS)
            let nsColor = NSColor(color)
            let rgba = nsColor.rgbaComponents
            return "Color(red: \(rgba.red), green: \(rgba.green), blue: \(rgba.blue), opacity: \(rgba.alpha))"
            #else
            return "Color.primary"
            #endif
        }
    }
}

