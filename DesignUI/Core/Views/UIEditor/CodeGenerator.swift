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
        return applyModifiersToCode(baseCode: baseCode, modifiers: component.modifiers, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
    }
    
    // MARK: - Text Code Generation
    private static func generateTextCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        // Escape quotes in text
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        return "\(indent)Text(\"\(escapedText)\")"
    }
    
    // MARK: - Image Code Generation
    private static func generateImageCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let imageDataString = component.getProperty(key: "imageData") as? String ?? ""
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        
        var code: String
        if !imageDataString.isEmpty {
            // Generate code to load image from base64 data
            #if os(macOS)
            code = "\(indent)(Data(base64Encoded: \"\(imageDataString)\")).flatMap { NSImage(data: $0) }.map { Image(nsImage: $0) } ?? Image(systemName: \"photo\")"
            #else
            code = "\(indent)(Data(base64Encoded: \"\(imageDataString)\")).flatMap { UIImage(data: $0) }.map { Image(uiImage: $0) } ?? Image(systemName: \"photo\")"
            #endif
        } else {
            // Fallback to placeholder
            code = "\(indent)Image(systemName: \"photo\")"
        }
        
        if resizable {
            code += "\n\(nextIndent).resizable()"
        }
        
        if aspectRatio != "none" {
            if aspectRatio == "fit" {
                code += "\n\(nextIndent).aspectRatio(contentMode: .fit)"
            } else if aspectRatio == "fill" {
                code += "\n\(nextIndent).aspectRatio(contentMode: .fill)"
            }
        }
        
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
            return code
        }
        
        // No children: Use default SwiftUI button with title
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? String ?? "blue"
        let escapedTitle = title.replacingOccurrences(of: "\"", with: "\\\"")
        
        var code = "\(indent)Button(\"\(escapedTitle)\") {}"
        
        // Apply background color if specified
        if let bgColor = colorFromString(backgroundColor) {
            code += "\n\(nextIndent).background(\(colorToString(bgColor)))"
        }
        
        return code
    }
    
    // MARK: - VStack Code Generation
    private static func generateVStackCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
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
        return "\(indent)Spacer()"
    }
    
    // MARK: - Divider Code Generation
    private static func generateDividerCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Divider()"
    }
    
    // MARK: - Shape Code Generation
    private static func generateRectangleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Rectangle()"
    }
    
    private static func generateCircleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Circle()"
    }
    
    private static func generateRoundedRectangleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)RoundedRectangle(cornerRadius: 12)"
    }
    
    private static func generateCapsuleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Capsule()"
    }
    
    private static func generateEllipseCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Ellipse()"
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
    
    // MARK: - SF Symbol Code Generation
    private static func generateSFSymbolCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let symbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        return "\(indent)Image(systemName: \"\(symbolName)\")"
    }
    
    // MARK: - Modifier Code Generation
    private static func applyModifiersToCode(baseCode: String, modifiers: [ComponentModifier], component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        var code = baseCode
        
        for modifier in modifiers {
            let modifierCode = generateModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
            if !modifierCode.isEmpty {
                code += "\n" + modifierCode
            }
        }
        
        return code
    }
    
    private static func generateModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        switch modifier.type {
        case .frame:
            return generateFrameModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .padding:
            return generatePaddingModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .background:
            return generateBackgroundModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .foregroundColor:
            return generateForegroundColorModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .font:
            return generateFontModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .fontSize:
            return generateFontSizeModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .cornerRadius:
            return generateCornerRadiusModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .opacity:
            return generateOpacityModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .textAlignment:
            return generateTextAlignmentModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .shadow:
            return generateShadowModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .rotation:
            return generateRotationModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .scale:
            return generateScaleModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .offset:
            return generateOffsetModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .blur:
            return generateBlurModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .overlay:
            return generateOverlayModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .border:
            return generateBorderModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .clipShape:
            return generateClipShapeModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .mask:
            return generateMaskModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .fill:
            return generateFillModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        }
    }
    
    private static func generateFrameModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let widthType = modifier.properties["widthType"] as? String ?? "Default"
        let heightType = modifier.properties["heightType"] as? String ?? "Default"
        let width = modifier.getCGFloat(key: "width", defaultValue: 100)
        let height = modifier.getCGFloat(key: "height", defaultValue: 100)
        
        if widthType == "Default" && heightType == "Default" {
            return ""
        }
        
        var frameParts: [String] = []
        
        if widthType == "Full" {
            frameParts.append("maxWidth: .infinity")
        } else if widthType == "Custom" {
            frameParts.append("width: \(width)")
        }
        
        if heightType == "Full" {
            frameParts.append("maxHeight: .infinity")
        } else if heightType == "Custom" {
            frameParts.append("height: \(height)")
        }
        
        if !frameParts.isEmpty {
            return "\(nextIndent).frame(\(frameParts.joined(separator: ", ")))"
        }
        
        return ""
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
    
    private static func generateBackgroundModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (background with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let childCode = generateCode(for: parentComponent, indentLevel: indentLevel + 1)
            return "\(nextIndent).background(\n\(childCode)\n\(indent))"
        }
        
        // Fallback to color background
        let color = modifier.properties["color"] as? Color ?? Color.clear
        return "\(nextIndent).background(\(colorToString(color)))"
    }
    
    private static func generateForegroundColorModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let color = modifier.properties["color"] as? Color ?? Color.primary
        return "\(nextIndent).foregroundColor(\(colorToString(color)))"
    }
    
    private static func generateFontModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let weight = modifier.properties["fontWeight"] as? String ?? "regular"
        return "\(nextIndent).fontWeight(.\(weight))"
    }
    
    private static func generateFontSizeModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let size = modifier.properties["fontSize"] as? String ?? "body"
        let fontStyle = fontStyleString(for: size)
        return "\(nextIndent).font(\(fontStyle))"
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
    
    private static func generateShadowModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 2)
        
        let x: CGFloat
        if let offsetX = modifier.properties["offsetX"] as? CGFloat {
            x = offsetX
        } else if let offsetX = modifier.properties["offsetX"] as? Double {
            x = CGFloat(offsetX)
        } else {
            x = modifier.getCGFloat(key: "x", defaultValue: 0)
        }
        
        let y: CGFloat
        if let offsetY = modifier.properties["offsetY"] as? CGFloat {
            y = offsetY
        } else if let offsetY = modifier.properties["offsetY"] as? Double {
            y = CGFloat(offsetY)
        } else {
            y = modifier.getCGFloat(key: "y", defaultValue: 2)
        }
        
        var color = modifier.properties["color"] as? Color ?? Color.black
        if let opacity = modifier.properties["opacity"] as? Double {
            color = color.opacity(opacity)
        }
        
        // Generate shadow code - note: SwiftUI's standard shadow doesn't support x/y offsets
        // This code requires a custom View extension: func shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        if x != 0 || y != 0 {
            return "\(nextIndent).shadow(color: \(colorToString(color)), radius: \(radius), x: \(x), y: \(y))"
        } else {
            return "\(nextIndent).shadow(color: \(colorToString(color)), radius: \(radius))"
        }
    }
    
    private static func generateRotationModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let angle = modifier.getDouble(key: "angle", defaultValue: 0)
        return "\(nextIndent).rotationEffect(.degrees(\(angle)))"
    }
    
    private static func generateScaleModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let x: Double
        if let scaleX = modifier.properties["scaleX"] as? Double {
            x = scaleX
        } else {
            x = modifier.getDouble(key: "x", defaultValue: 1.0)
        }
        
        let y: Double
        if let scaleY = modifier.properties["scaleY"] as? Double {
            y = scaleY
        } else {
            y = modifier.getDouble(key: "y", defaultValue: 1.0)
        }
        
        if x == y {
            return "\(nextIndent).scaleEffect(\(x))"
        } else {
            return "\(nextIndent).scaleEffect(x: \(x), y: \(y))"
        }
    }
    
    private static func generateOffsetModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let x: CGFloat
        if let offsetX = modifier.properties["offsetX"] as? CGFloat {
            x = offsetX
        } else if let offsetX = modifier.properties["offsetX"] as? Double {
            x = CGFloat(offsetX)
        } else {
            x = modifier.getCGFloat(key: "x", defaultValue: 0)
        }
        
        let y: CGFloat
        if let offsetY = modifier.properties["offsetY"] as? CGFloat {
            y = offsetY
        } else if let offsetY = modifier.properties["offsetY"] as? Double {
            y = CGFloat(offsetY)
        } else {
            y = modifier.getCGFloat(key: "y", defaultValue: 0)
        }
        
        return "\(nextIndent).offset(x: \(x), y: \(y))"
    }
    
    private static func generateBlurModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
        return "\(nextIndent).blur(radius: \(radius))"
    }
    
    private static func generateOverlayModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (overlay with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let alignment = modifier.properties["alignment"] as? String ?? "center"
            let alignmentCode = alignmentFromString(alignment)
            let childCode = generateCode(for: parentComponent, indentLevel: indentLevel + 1)
            return "\(nextIndent).overlay(\n\(childCode)\n\(indent), alignment: .\(alignmentCode))"
        }
        
        return ""
    }
    
    private static func generateBorderModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let width = modifier.getCGFloat(key: "width", defaultValue: 1)
        // Border uses Color.primary by default (no color property)
        return "\(nextIndent).border(Color.primary, width: \(width))"
    }
    
    private static func generateClipShapeModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        var shapeName: String
        if let shape = modifier.properties["shape"] as? String {
            shapeName = shape
        } else if let shapeType = modifier.properties["shapeType"] as? String {
            let capitalized = shapeType.capitalized
            shapeName = capitalized == "Roundedrectangle" ? "RoundedRectangle" : capitalized
        } else {
            shapeName = "Rectangle"
        }
        
        switch shapeName {
        case "Circle":
            return "\(nextIndent).clipShape(Circle())"
        case "Capsule":
            return "\(nextIndent).clipShape(Capsule())"
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return "\(nextIndent).clipShape(RoundedRectangle(cornerRadius: \(radius)))"
        case "Ellipse":
            return "\(nextIndent).clipShape(Ellipse())"
        default:
            return "\(nextIndent).clipShape(Rectangle())"
        }
    }
    
    private static func generateMaskModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (mask with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let childCode = generateCode(for: parentComponent, indentLevel: indentLevel + 1)
            return "\(nextIndent).mask(\n\(childCode)\n\(indent))"
        }
        
        // Fallback to shape mask
        let shapeName = modifier.properties["shape"] as? String ?? "Rectangle"
        switch shapeName {
        case "Circle":
            return "\(nextIndent).mask(Circle())"
        case "Capsule":
            return "\(nextIndent).mask(Capsule())"
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return "\(nextIndent).mask(RoundedRectangle(cornerRadius: \(radius)))"
        default:
            return "\(nextIndent).mask(Rectangle())"
        }
    }
    
    private static func generateFillModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let color = modifier.properties["color"] as? Color ?? Color.blue
        return "\(nextIndent).background(\(colorToString(color)))"
    }
    
    // MARK: - Helper Functions
    private static func colorToString(_ color: Color) -> String {
        // Try to match semantic colors first
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
            // For custom colors, try to extract RGBA values
            #if os(macOS)
            let nsColor = NSColor(color)
            let rgba = nsColor.rgbaComponents
            return "Color(red: \(rgba.red), green: \(rgba.green), blue: \(rgba.blue), opacity: \(rgba.alpha))"
            #else
            // For iOS, we can't easily extract RGBA, so fallback to primary
            return "Color.primary"
            #endif
        }
    }
    
    private static func colorFromString(_ colorString: String) -> Color? {
        switch colorString.lowercased() {
        case "primary": return Color.primary
        case "secondary": return Color.secondary
        case "blue": return Color.blue
        case "red": return Color.red
        case "green": return Color.green
        case "orange": return Color.orange
        case "purple": return Color.purple
        case "pink": return Color.pink
        case "yellow": return Color.yellow
        case "gray", "grey": return Color.gray
        case "white": return Color.white
        case "black": return Color.black
        case "clear": return Color.clear
        default: return nil
        }
    }
    
    private static func fontStyleString(for size: String) -> String {
        switch size {
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
        default: return ".body"
        }
    }
    
    private static func alignmentFromString(_ alignment: String) -> String {
        switch alignment {
        case "topLeading": return "topLeading"
        case "top": return "top"
        case "topTrailing": return "topTrailing"
        case "leading": return "leading"
        case "center": return "center"
        case "trailing": return "trailing"
        case "bottomLeading": return "bottomLeading"
        case "bottom": return "bottom"
        case "bottomTrailing": return "bottomTrailing"
        default: return "center"
        }
    }
}
