//
//  CodeGenerator.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct CodeGenerator {
    static func generateCode(for component: UIComponent) -> String {
        return generateCode(for: component, indentLevel: 0)
    }
    
    static func generateCode(for component: UIComponent, indentLevel: Int) -> String {
        let indent = String(repeating: "    ", count: indentLevel)
        let nextIndent = String(repeating: "    ", count: indentLevel + 1)
        
        var baseCode: String
        switch component.type {
        case .text:
            baseCode = generateTextCode(component: component, indent: indent, nextIndent: nextIndent)
        case .image:
            baseCode = generateImageCode(component: component, indent: indent, nextIndent: nextIndent)
        case .button:
            baseCode = generateButtonCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .vstack:
            baseCode = generateVStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .hstack:
            baseCode = generateHStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .zstack:
            baseCode = generateZStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .spacer:
            baseCode = generateSpacerCode(component: component, indent: indent, nextIndent: nextIndent)
        case .divider:
            baseCode = generateDividerCode(component: component, indent: indent, nextIndent: nextIndent)
        case .rectangle:
            baseCode = generateRectangleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .circle:
            baseCode = generateCircleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .roundedRectangle:
            baseCode = generateRoundedRectangleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .capsule:
            baseCode = generateCapsuleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .ellipse:
            baseCode = generateEllipseCode(component: component, indent: indent, nextIndent: nextIndent)
        case .scrollView:
            baseCode = generateScrollViewCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .sfSymbol:
            baseCode = generateSFSymbolCode(component: component, indent: indent, nextIndent: nextIndent)
        default:
            return "\(indent)// \(component.type.rawValue) - Code generation not implemented yet"
        }
        
        // Apply modifiers
        return applyModifiersToCode(baseCode: baseCode, modifiers: component.modifiers, indent: indent, nextIndent: nextIndent)
    }
    
    // MARK: - Text Code Generation
    private static func generateTextCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        let fontSize = component.getProperty(key: "fontSize") as? String ?? "body"
        let fontWeight = component.getProperty(key: "fontWeight") as? String ?? "regular"
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.primary
        
        var code = "\(indent)Text(\"\(text)\")"
        
        // Font
        let fontStyle: String
        switch fontSize {
        case "largeTitle": fontStyle = ".largeTitle"
        case "title": fontStyle = ".title"
        case "title2": fontStyle = ".title2"
        case "title3": fontStyle = ".title3"
        case "headline": fontStyle = ".headline"
        case "body": fontStyle = ".body"
        case "callout": fontStyle = ".callout"
        case "subheadline": fontStyle = ".subheadline"
        case "footnote": fontStyle = ".footnote"
        case "caption": fontStyle = ".caption"
        case "caption2": fontStyle = ".caption2"
        default: fontStyle = ".body"
        }
        
        if fontWeight != "regular" {
            code += "\n\(nextIndent).font(\(fontStyle).weight(.\(fontWeight)))"
        } else {
            code += "\n\(nextIndent).font(\(fontStyle))"
        }
        
        // Foreground color
        if foregroundColor != Color.primary {
            code += "\n\(nextIndent).foregroundColor(\(colorToString(foregroundColor)))"
        }
        
        return code
    }
    
    // MARK: - Image Code Generation
    private static func generateImageCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let imageName = component.getProperty(key: "imageName") as? String ?? "photo"
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        let frameWidth = component.getProperty(key: "frameWidth") as? Double ?? 100.0
        let frameHeight = component.getProperty(key: "frameHeight") as? Double ?? 100.0
        
        var code = "\(indent)Image(\"\(imageName)\")"
        
        if resizable {
            code += "\n\(nextIndent).resizable()"
        }
        
        if aspectRatio != "none" {
            code += "\n\(nextIndent).aspectRatio(contentMode: .\(aspectRatio))"
        }
        
        code += "\n\(nextIndent).frame(width: \(frameWidth), height: \(frameHeight))"
        
        return code
    }
    
    // MARK: - Button Code Generation
    private static func generateButtonCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // If button has children, use container approach
        if !component.children.isEmpty {
            var code = "\(indent)Button(action: {\n\(nextIndent)// Action here\n\(indent)}) {"
            for child in component.children {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
            }
            code += "\n\(indent)}"
            code += "\n\(indent).buttonStyle(PlainButtonStyle())"
            return code
        }
        
        // No children: Use default SwiftUI button with label-based initializer and apply properties
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.blue
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.white
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        
        var code = "\(indent)Button(\"\(title)\") {}"
        code += "\n\(nextIndent).foregroundColor(\(colorToString(foregroundColor)))"
        code += "\n\(nextIndent).padding(.horizontal, 16)"
        code += "\n\(nextIndent).padding(.vertical, 8)"
        code += "\n\(nextIndent).background(\(colorToString(backgroundColor)))"
        code += "\n\(nextIndent).cornerRadius(\(cornerRadius))"
        return code
    }
    
    // MARK: - VStack Code Generation
    private static func generateVStackCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // Get spacing as Double (defaults to 8.0 if not set or invalid)
        let spacingValue: Double
        if let spacing = component.getProperty(key: "spacing") as? Double {
            spacingValue = spacing
        } else if let spacingString = component.getProperty(key: "spacing") as? String, spacingString != "default" {
            spacingValue = Double(spacingString) ?? 8.0
        } else {
            spacingValue = 8.0
        }
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        var code = "\(indent)VStack(alignment: .\(alignment), spacing: \(spacingValue)) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for child in component.children {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
            }
        }
        
        code += "\n\(indent)}"
        
        return code
    }
    
    // MARK: - HStack Code Generation
    private static func generateHStackCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // Get spacing as Double (defaults to 8.0 if not set or invalid)
        let spacingValue: Double
        if let spacing = component.getProperty(key: "spacing") as? Double {
            spacingValue = spacing
        } else if let spacingString = component.getProperty(key: "spacing") as? String, spacingString != "default" {
            spacingValue = Double(spacingString) ?? 8.0
        } else {
            spacingValue = 8.0
        }
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        var code = "\(indent)HStack(alignment: .\(alignment), spacing: \(spacingValue)) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for child in component.children {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
            }
        }
        
        code += "\n\(indent)}"
        
        return code
    }
    
    // MARK: - ZStack Code Generation
    private static func generateZStackCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        var code = "\(indent)ZStack(alignment: .\(alignment)) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for child in component.children {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
            }
        }
        
        code += "\n\(indent)}"
        
        return code
    }
    
    // MARK: - Spacer Code Generation
    private static func generateSpacerCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let minLength = component.getProperty(key: "minLength") as? Double ?? 0.0
        
        if minLength > 0 {
            return "\(indent)Spacer(minLength: \(minLength))"
        } else {
            return "\(indent)Spacer()"
        }
    }
    
    // MARK: - Divider Code Generation
    private static func generateDividerCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Divider()"
    }
    
    // MARK: - Shape Code Generation
    private static func generateRectangleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        var code = "\(indent)Rectangle()"
        
        if stroke != Color.clear {
            code += "\n\(nextIndent).stroke(\(colorToString(stroke)), lineWidth: \(lineWidth))"
        } else {
            code += "\n\(nextIndent).fill(\(colorToString(fill)))"
        }
        
        return code
    }
    
    private static func generateCircleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        var code = "\(indent)Circle()"
        
        if stroke != Color.clear {
            code += "\n\(nextIndent).stroke(\(colorToString(stroke)), lineWidth: \(lineWidth))"
        } else {
            code += "\n\(nextIndent).fill(\(colorToString(fill)))"
        }
        
        return code
    }
    
    private static func generateRoundedRectangleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        
        var code = "\(indent)RoundedRectangle(cornerRadius: \(cornerRadius))"
        
        if stroke != Color.clear {
            code += "\n\(nextIndent).stroke(\(colorToString(stroke)), lineWidth: \(lineWidth))"
        } else {
            code += "\n\(nextIndent).fill(\(colorToString(fill)))"
        }
        
        return code
    }
    
    private static func generateCapsuleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        var code = "\(indent)Capsule()"
        
        if stroke != Color.clear {
            code += "\n\(nextIndent).stroke(\(colorToString(stroke)), lineWidth: \(lineWidth))"
        } else {
            code += "\n\(nextIndent).fill(\(colorToString(fill)))"
        }
        
        return code
    }
    
    private static func generateEllipseCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let fill = component.getProperty(key: "fill") as? Color ?? Color.gray
        let stroke = component.getProperty(key: "stroke") as? Color ?? Color.clear
        let lineWidth = component.getProperty(key: "lineWidth") as? Double ?? 1.0
        
        var code = "\(indent)Ellipse()"
        
        if stroke != Color.clear {
            code += "\n\(nextIndent).stroke(\(colorToString(stroke)), lineWidth: \(lineWidth))"
        } else {
            code += "\n\(nextIndent).fill(\(colorToString(fill)))"
        }
        
        return code
    }
    
    // MARK: - ScrollView Code Generation
    private static func generateScrollViewCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        let axis = component.getProperty(key: "axis") as? String ?? "vertical"
        let showsIndicators = component.getProperty(key: "showsIndicators") as? Bool ?? true
        
        let scrollAxis: String = axis == "horizontal" ? ".horizontal" : ".vertical"
        let showsIndicatorsString = showsIndicators ? "true" : "false"
        
        var code = "\(indent)ScrollView(\(scrollAxis), showsIndicators: \(showsIndicatorsString)) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for child in component.children {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
            }
        }
        
        code += "\n\(indent)}"
        
        return code
    }
    
    // MARK: - Modifier Code Generation
    private static func applyModifiersToCode(baseCode: String, modifiers: [ComponentModifier], indent: String, nextIndent: String) -> String {
        var code = baseCode
        
        for modifier in modifiers {
            code += "\n" + generateModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        }
        
        return code
    }
    
    private static func generateSFSymbolCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let symbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.primary
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.clear
        let fontSize = component.getProperty(key: "fontSize") as? String ?? "largeTitle"
        
        let fontString: String = {
            switch fontSize {
            case "largeTitle": return ".largeTitle"
            case "title": return ".title"
            case "title2": return ".title2"
            case "title3": return ".title3"
            case "headline": return ".headline"
            case "body": return ".body"
            case "callout": return ".callout"
            case "subheadline": return ".subheadline"
            case "footnote": return ".footnote"
            case "caption": return ".caption"
            case "caption2": return ".caption2"
            default: return ".largeTitle"
            }
        }()
        
        var code = "\(indent)Image(systemName: \"\(symbolName)\")"
        code += "\n\(nextIndent).font(\(fontString))"
        
        // Foreground color
        if foregroundColor != Color.primary {
            code += "\n\(nextIndent).foregroundColor(\(colorToString(foregroundColor)))"
        }
        
        // Background color
        if backgroundColor != Color.clear {
            code += "\n\(nextIndent).background(\(colorToString(backgroundColor)))"
        }
        
        code += "\n\(nextIndent).symbolRenderingMode(.hierarchical)"
        
        return code
    }
    
    private static func generateModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        switch modifier.type {
        case .frame:
            return generateFrameModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .padding:
            return generatePaddingModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .background:
            return generateBackgroundModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .foregroundColor:
            return generateForegroundColorModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .cornerRadius:
            return generateCornerRadiusModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .opacity:
            return generateOpacityModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .textAlignment:
            return generateTextAlignmentModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        default:
            return "\(indent)// \(modifier.type.rawValue) modifier - Code generation not implemented yet"
        }
    }
    
    private static func generateFrameModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let widthType = modifier.properties["widthType"] as? String ?? "Default"
        let heightType = modifier.properties["heightType"] as? String ?? "Default"
        let width = modifier.getCGFloat(key: "width", defaultValue: 100)
        let height = modifier.getCGFloat(key: "height", defaultValue: 100)
        
        // Generate frame code based on type
        if widthType == "Default" && heightType == "Default" {
            return "" // No frame modifier applied
        }
        
        var frameParts: [String] = []
        
        // Handle width
        if widthType == "Full" {
            frameParts.append("maxWidth: .infinity")
        } else if widthType == "Custom" {
            frameParts.append("width: \(width)")
        }
        // If widthType == "Default", don't add anything
        
        // Handle height
        if heightType == "Full" {
            frameParts.append("maxHeight: .infinity")
        } else if heightType == "Custom" {
            frameParts.append("height: \(height)")
        }
        // If heightType == "Default", don't add anything
        
        // Only generate frame if we have at least one dimension
        if !frameParts.isEmpty {
            return "\(nextIndent).frame(\(frameParts.joined(separator: ", ")))"
        } else {
            return "" // No frame modifier applied
        }
    }
    
    private static func generatePaddingModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let amount = modifier.getCGFloat(key: "amount", defaultValue: 0)
        let location = modifier.properties["location"] as? String ?? "all"
        
        switch location {
        case "all":
            return "\(nextIndent).padding(\(amount))"
        case "leading":
            return "\(nextIndent).padding(.leading, \(amount))"
        case "trailing":
            return "\(nextIndent).padding(.trailing, \(amount))"
        case "top":
            return "\(nextIndent).padding(.top, \(amount))"
        case "bottom":
            return "\(nextIndent).padding(.bottom, \(amount))"
        case "horizontal":
            return "\(nextIndent).padding(.horizontal, \(amount))"
        case "vertical":
            return "\(nextIndent).padding(.vertical, \(amount))"
        default:
            return "\(nextIndent).padding(\(amount))"
        }
    }
    
    private static func generateBackgroundModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let color = modifier.properties["color"] as? Color ?? Color.clear
        return "\(nextIndent).background(\(colorToString(color)))"
    }
    
    private static func generateForegroundColorModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let color = modifier.properties["color"] as? Color ?? Color.primary
        return "\(nextIndent).foregroundColor(\(colorToString(color)))"
    }
    
    private static func generateCornerRadiusModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 8)
        return "\(nextIndent).cornerRadius(\(radius))"
    }
    
    private static func generateOpacityModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
        return "\(nextIndent).opacity(\(opacity))"
    }
    
    private static func generateTextAlignmentModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let alignment = modifier.properties["alignment"] as? String ?? "leading"
        return "\(nextIndent).multilineTextAlignment(.\(alignment))"
    }
    
    // MARK: - Helper Functions
    private static func colorToString(_ color: Color) -> String {
        // This is a simplified color conversion
        // In a real implementation, you'd want to store the actual color values
        if color == Color.primary {
            return "Color.primary"
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
        } else {
            return "Color.primary"
        }
    }
    
    private static func edgeInsetsToString(_ insets: EdgeInsets) -> String {
        return "EdgeInsets(top: \(insets.top), leading: \(insets.leading), bottom: \(insets.bottom), trailing: \(insets.trailing))"
    }
}
