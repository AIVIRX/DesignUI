//
//  CodeGenerator.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct CodeGenerator {
    
    /// Formats a number cleanly: removes .0 for whole numbers, keeps decimals when needed
    static func formatNumber(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            // Remove trailing zeros after decimal
            return String(format: "%g", value)
        }
    }
    
    static func generateCode(for component: UIComponent) -> String {
        // Reset counters at the start of each new code generation
        imageCounter = 0
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
        case .textField:
            baseCode = generateTextFieldCode(component: component, indent: indent, nextIndent: nextIndent)
        case .toggle:
            baseCode = generateToggleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .slider:
            baseCode = generateSliderCode(component: component, indent: indent, nextIndent: nextIndent)
        case .button:
            baseCode = generateButtonCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .shape:
            baseCode = generateShapeCode(component: component, indent: indent, nextIndent: nextIndent)
        case .linearGradient:
            baseCode = generateLinearGradientCode(component: component, indent: indent, nextIndent: nextIndent)
        case .chart:
            baseCode = generateChartCode(component: component, indent: indent, nextIndent: nextIndent)
        case .gauge:
            baseCode = generateGaugeCode(component: component, indent: indent, nextIndent: nextIndent)
            
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
    /// Static counter for generating unique image placeholder names
    private static var imageCounter = 0
    
    /// Reset the image counter (call at start of code generation)
    static func resetImageCounter() {
        imageCounter = 0
    }
    
    private static func generateImageCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let imageDataString = component.getProperty(key: "imageData") as? String ?? ""
        let imageName = component.getProperty(key: "imageName") as? String ?? ""
        let resizable = component.getProperty(key: "resizable") as? Bool ?? true
        let aspectRatio = component.getProperty(key: "aspectRatio") as? String ?? "fit"
        
        var code: String
        
        // Generate a clean placeholder name for generated code
        imageCounter += 1
        let placeholderName = "image\(imageCounter)"
        
        if !imageDataString.isEmpty || !imageName.isEmpty {
            // Has an image - generate code with clean placeholder name
            code = "\(indent)Image(\"\(placeholderName)\")"
        } else {
            // Fallback to system placeholder
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
        let buttonStyle = component.getProperty(key: "buttonStyle") as? String ?? "borderedProminent"
        
        // Button always has children in the new container pattern
        var code = "\(indent)Button(action: {\n\(nextIndent)// Action here\n\(indent)}) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for (index, child) in component.children.enumerated() {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
                // Add empty line between siblings (but not after the last one)
                if index < component.children.count - 1 {
                    code += "\n"
                }
            }
        }
        
        code += "\n\(indent)}"
        
        // Apply button style
        code += "\n\(nextIndent).buttonStyle(.\(buttonStyle))"
        
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
        
        var code = "\(indent)VStack(alignment: .\(alignment), spacing: \(formatNumber(spacingValue))) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for (index, child) in component.children.enumerated() {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
                // Add empty line between siblings (but not after the last one)
                if index < component.children.count - 1 {
                    code += "\n"
                }
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
        
        var code = "\(indent)HStack(alignment: .\(alignment), spacing: \(formatNumber(spacingValue))) {"
        
        if component.children.isEmpty {
            code += "\n\(nextIndent)// Add components here"
        } else {
            for (index, child) in component.children.enumerated() {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
                // Add empty line between siblings (but not after the last one)
                if index < component.children.count - 1 {
                    code += "\n"
                }
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
            for (index, child) in component.children.enumerated() {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
                // Add empty line between siblings (but not after the last one)
                if index < component.children.count - 1 {
                    code += "\n"
                }
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
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
        return "\(indent)RoundedRectangle(cornerRadius: \(formatNumber(cornerRadius)))"
    }
    
    private static func generateCapsuleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Capsule()"
    }
    
    private static func generateEllipseCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        return "\(indent)Ellipse()"
    }
    
    // MARK: - Unified Shape Code Generation
    private static func generateShapeCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"
        
        switch shapeType {
        case "Rectangle":
            return "\(indent)Rectangle()"
        case "Circle":
            return "\(indent)Circle()"
        case "Rounded Rectangle":
            let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return "\(indent)RoundedRectangle(cornerRadius: \(formatNumber(cornerRadius)))"
        case "Capsule":
            return "\(indent)Capsule()"
        case "Ellipse":
            return "\(indent)Ellipse()"
        default:
            return "\(indent)Rectangle()"
        }
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
            for (index, child) in component.children.enumerated() {
                code += "\n" + generateCode(for: child, indentLevel: indentLevel + 1)
                // Add empty line between siblings (but not after the last one)
                if index < component.children.count - 1 {
                    code += "\n"
                }
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

    // MARK: - Text Field Code Generation
    private static func generateTextFieldCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let text = component.getProperty(key: "text") as? String ?? ""
        let placeholder = component.getProperty(key: "placeholder") as? String ?? "Placeholder"
        // Use constant binding for generated code preview
        return "\(indent)TextField(\"\(placeholder)\", text: .constant(\"\(text)\"))"
    }
    
    // MARK: - Toggle/Switch Code Generation
    private static func generateToggleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let isOn = component.getProperty(key: "isOn") as? Bool ?? true
        // Generate iOS-style switch without label
        return "\(indent)Toggle(\"\", isOn: .constant(\(isOn)))\n\(nextIndent).labelsHidden()\n\(nextIndent).toggleStyle(.switch)"
    }
    
    // MARK: - Slider Code Generation
    private static func generateSliderCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let value = component.getProperty(key: "value") as? Double ?? 0.5
        let min = component.getProperty(key: "min") as? Double ?? 0.0
        let max = component.getProperty(key: "max") as? Double ?? 1.0
        return "\(indent)Slider(value: .constant(\(value)), in: \(min)...\(max))"
    }
    
    // MARK: - Gauge Code Generation
    private static func generateGaugeCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let gaugeType = component.getProperty(key: "gaugeType") as? String ?? "circular"
        let value = component.getProperty(key: "value") as? Double ?? 50
        let min = component.getProperty(key: "min") as? Double ?? 0
        let max = component.getProperty(key: "max") as? Double ?? 100
        let showValue = component.getProperty(key: "showValue") as? Bool ?? true
        let colorString = component.getProperty(key: "color") as? String ?? "blue"
        
        var code = ""
        
        switch gaugeType {
        case "linear":
            code = "\(indent)Gauge(value: \(formatNumber(value)), in: \(formatNumber(min))...\(formatNumber(max))) {"
            if showValue {
                code += "\n\(nextIndent)Text(\"\(Int(value))\")"
            }
            code += "\n\(indent)}"
            code += "\n\(nextIndent).gaugeStyle(.linearCapacity)"
            
        case "circular":
            code = "\(indent)Gauge(value: \(formatNumber(value)), in: \(formatNumber(min))...\(formatNumber(max))) {"
            if showValue {
                code += "\n\(nextIndent)Text(\"\(Int(value))\")"
            } else {
                code += "\n\(nextIndent)EmptyView()"
            }
            code += "\n\(indent)}"
            code += "\n\(nextIndent).gaugeStyle(.accessoryCircularCapacity)"
            
        case "circular range":
            code = "\(indent)Gauge(value: \(formatNumber(value)), in: \(formatNumber(min))...\(formatNumber(max))) {"
            code += "\n\(nextIndent)EmptyView()"
            code += "\n\(indent)} currentValueLabel: {"
            if showValue {
                code += "\n\(nextIndent)Text(\"\(Int(value))\")"
            } else {
                code += "\n\(nextIndent)EmptyView()"
            }
            code += "\n\(indent)} minimumValueLabel: {"
            code += "\n\(nextIndent)Text(\"\(Int(min))\")"
            code += "\n\(indent)} maximumValueLabel: {"
            code += "\n\(nextIndent)Text(\"\(Int(max))\")"
            code += "\n\(indent)}"
            code += "\n\(nextIndent).gaugeStyle(.accessoryCircular)"
            
        default:
            code = "\(indent)Gauge(value: \(formatNumber(value)), in: \(formatNumber(min))...\(formatNumber(max))) {}"
            code += "\n\(nextIndent).gaugeStyle(.accessoryCircularCapacity)"
        }
        
        // Add color tint
        code += "\n\(nextIndent).tint(\(colorToString(colorString)))"
        
        return code
    }
    
    // MARK: - Linear Gradient Code Generation
    private static func generateLinearGradientCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let colors = component.getProperty(key: "colors") as? [String] ?? ["blue", "green"]
        let startPoint = component.getProperty(key: "startPoint") as? String ?? "top"
        let endPoint = component.getProperty(key: "endPoint") as? String ?? "bottom"

        // Parse "colorname:opacity" format and generate proper SwiftUI code
        let colorStrings = colors.map { colorStr -> String in
            let parts = colorStr.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "blue"
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            
            let baseColor = colorToString(colorName)
            if opacity >= 0.99 {
                return baseColor
            } else {
                let opacityString = String(format: "%.2f", opacity)
                    .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
                return "\(baseColor).opacity(\(opacityString))"
            }
        }
        let colorsList = colorStrings.joined(separator: ", ")

        return "\(indent)LinearGradient(gradient: Gradient(colors: [\(colorsList)]), startPoint: .\(startPoint), endPoint: .\(endPoint))"
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
            // Skip frame modifiers for Spacer and Divider - they should expand naturally
            if component.type == .spacer || component.type == .divider {
                return ""
            }
            return generateFrameModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .padding:
            return generatePaddingModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .backgroundColor:
            return generateBackgroundColorModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .background:
            return generateBackgroundModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .foregroundColor:
            return generateForegroundColorModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .font:
            return generateFontModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
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
        case .aspectRatio:
            return generateAspectRatioModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .zIndex:
            return generateZIndexModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
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
            frameParts.append("width: \(formatNumber(Double(width)))")
        }
        
        if heightType == "Full" {
            frameParts.append("maxHeight: .infinity")
        } else if heightType == "Custom" {
            frameParts.append("height: \(formatNumber(Double(height)))")
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
            return "\(nextIndent).padding(\(formatNumber(Double(amount))))"
        case "leading":
            return "\(nextIndent).padding(.leading, \(formatNumber(Double(amount))))"
        case "trailing":
            return "\(nextIndent).padding(.trailing, \(formatNumber(Double(amount))))"
        case "top":
            return "\(nextIndent).padding(.top, \(formatNumber(Double(amount))))"
        case "bottom":
            return "\(nextIndent).padding(.bottom, \(formatNumber(Double(amount))))"
        case "horizontal":
            return "\(nextIndent).padding(.horizontal, \(formatNumber(Double(amount))))"
        case "vertical":
            return "\(nextIndent).padding(.vertical, \(formatNumber(Double(amount))))"
        default:
            return "\(nextIndent).padding(\(formatNumber(Double(amount))))"
        }
    }
    
    private static func generateBackgroundColorModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        // Check for gradient
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(nextIndent).background(\(gradientCode))"
        }
        
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(nextIndent).background(\(colorCode))"
    }
    
    private static func generateBackgroundModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (background with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let childCode = generateCode(for: parentComponent, indentLevel: indentLevel + 1)
            return "\(nextIndent).background(\n\(childCode)\n\(indent))"
        }
        
        // Check for gradient
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(nextIndent).background(\(gradientCode))"
        }
        
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(nextIndent).background(\(colorCode))"
    }
    
    private static func generateFillModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        // Check for gradient
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(nextIndent).fill(\(gradientCode))"
        }
        
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(nextIndent).fill(\(colorCode))"
    }
    
    private static func generateForegroundColorModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(nextIndent).foregroundStyle(\(colorCode))"
    }
    
    /// Parse "colorname:opacity" format
    private static func parseColorWithOpacity(modifier: ComponentModifier) -> String {
        if let colorData = modifier.properties["color"] as? String {
            let parts = colorData.split(separator: ":")
            let colorName = parts.count >= 1 ? String(parts[0]) : "primary"
            let baseColor = colorToString(colorName)
            let opacity = parts.count >= 2 ? (Double(parts[1]) ?? 1.0) : 1.0
            
            if opacity >= 0.99 {
                return baseColor
            } else {
                let opacityString = String(format: "%.2f", opacity)
                    .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
                return "\(baseColor).opacity(\(opacityString))"
            }
        }
        return ".primary"
    }
    
    /// Converts color value and opacity to a SwiftUI code string like `.red.opacity(0.73)` or just `.red`
    private static func colorWithOpacityToString(_ value: Any?, opacity: Double) -> String {
        let baseColor = colorToString(value)
        
        // If opacity is 1.0 (or very close), don't add opacity modifier
        if opacity >= 0.99 {
            return baseColor
        }
        
        // Format opacity with 2 decimal places, removing trailing zeros
        let opacityString = String(format: "%.2f", opacity)
            .replacingOccurrences(of: "\\.?0+$", with: "", options: .regularExpression)
        
        return "\(baseColor).opacity(\(opacityString))"
    }
    
    private static func generateFontModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let size = modifier.properties["fontSize"] as? String ?? "body"
        let weight = modifier.properties["fontWeight"] as? String ?? "regular"
        let design = modifier.properties["fontDesign"] as? String
        
        var designCode = ""
        if let design = design, design != "default" {
            designCode = ", design: .\(design)"
        }
        
        // Don't generate code if everything is default (body + regular + no design)
        if size == "body" && weight == "regular" && designCode.isEmpty {
            return ""
        }
        
        // Check for custom size (number)
        if let _ = Double(size) {
            return "\(nextIndent).font(.system(size: \(size), weight: .\(weight)\(designCode)))"
        }
        
        // Preset size
        // If we have design or non-regular weight, utilize .system(style, design, weight)
        if !designCode.isEmpty || weight != "regular" {
             return "\(nextIndent).font(.system(.\(size)\(designCode), weight: .\(weight)))"
        }
        
        // Simple case: just size (regular weight, default design)
        return "\(nextIndent).font(.\(size))"
    }
    
    private static func generateCornerRadiusModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 8)
        return "\(nextIndent).cornerRadius(\(formatNumber(Double(radius))))"
    }
    
    private static func generateOpacityModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
        return "\(nextIndent).opacity(\(formatNumber(opacity)))"
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
        
        let colorValue = modifier.properties["color"]
        let colorCode: String
        if let opacity = modifier.properties["opacity"] as? Double, opacity < 1.0 {
            colorCode = "\(colorToString(colorValue)).opacity(\(opacity))"
        } else {
            colorCode = colorToString(colorValue)
        }
        
        // Generate shadow code - note: SwiftUI's standard shadow doesn't support x/y offsets
        // This code requires a custom View extension: func shadow(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)
        if x != 0 || y != 0 {
            return "\(nextIndent).shadow(color: \(colorCode), radius: \(formatNumber(Double(radius))), x: \(formatNumber(Double(x))), y: \(formatNumber(Double(y))))"
        } else {
            return "\(nextIndent).shadow(color: \(colorCode), radius: \(formatNumber(Double(radius))))"
        }
    }
    
    private static func generateRotationModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let angle = modifier.getDouble(key: "angle", defaultValue: 0)
        return "\(nextIndent).rotationEffect(.degrees(\(formatNumber(angle))))"
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
            return "\(nextIndent).scaleEffect(\(formatNumber(x)))"
        } else {
            return "\(nextIndent).scaleEffect(x: \(formatNumber(x)), y: \(formatNumber(y)))"
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
        
        return "\(nextIndent).offset(x: \(formatNumber(Double(x))), y: \(formatNumber(Double(y))))"
    }
    
    private static func generateBlurModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
        return "\(nextIndent).blur(radius: \(formatNumber(Double(radius))))"
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
        let color = modifier.properties["color"]
        return "\(nextIndent).border(\(colorToString(color)), width: \(formatNumber(Double(width))))"
    }
    
    private static func generateClipShapeModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        var shapeName: String = "Rectangle"
        
        if let shape = modifier.properties["shape"] as? String {
            shapeName = shape
        } else if let shapeType = modifier.properties["shapeType"] as? String {
            shapeName = shapeType
        }
        
        // Normalize shape name
        if shapeName.lowercased() == "roundedrectangle" {
            shapeName = "RoundedRectangle"
        } else {
            shapeName = shapeName.prefix(1).uppercased() + shapeName.dropFirst()
        }
        
        switch shapeName {
        case "Circle":
            return "\(nextIndent).clipShape(Circle())"
        case "Capsule":
            return "\(nextIndent).clipShape(Capsule())"
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return "\(nextIndent).clipShape(RoundedRectangle(cornerRadius: \(formatNumber(Double(radius)))))"
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
    
    private static func generateAspectRatioModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let mode = modifier.properties["aspectRatio"] as? String ?? "fit"
        let contentMode = mode == "fill" ? ".fill" : ".fit"
        return "\(nextIndent).aspectRatio(contentMode: \(contentMode))"
    }
    
    private static func generateZIndexModifierCode(modifier: ComponentModifier, indent: String, nextIndent: String) -> String {
        let index = modifier.getDouble(key: "index", defaultValue: 0)
        return "\(nextIndent).zIndex(\(index))"
    }
    
    // MARK: - Helper Functions
    // MARK: - Helper Functions
    private static func generateGradientCode(modifier: ComponentModifier) -> String? {
        guard let dict = modifier.properties["gradient"] as? [String: Any],
              let colors = dict["colors"] as? [Any],
              colors.count >= 2 else {
            return nil
        }
        
        let colorStrings = colors.map { colorToString($0) }
        let colorsList = colorStrings.joined(separator: ", ")
        let startPoint = dict["startPoint"] as? String ?? "top"
        let endPoint = dict["endPoint"] as? String ?? "bottom"
        
        return "LinearGradient(gradient: Gradient(colors: [\(colorsList)]), startPoint: .\(startPoint), endPoint: .\(endPoint))"
    }
    
    static func colorToString(_ value: Any?) -> String {
        // Handle semantic color strings (intent preservation)
        if let colorString = value as? String {
            let cleanString = colorString.hasPrefix("color:") ? String(colorString.dropFirst(6)) : colorString
            
            let semanticColors = ["primary", "secondary", "tertiary", "quaternary", "blue", "red", "green", "orange", "yellow", "purple", "pink", "gray", "white", "black", "clear", "teal", "indigo", "mint", "cyan", "brown"]
            if semanticColors.contains(cleanString.lowercased()) {
                return ".\(cleanString.lowercased())"
            }
            
            // If it's an RGB string or Hex, convert to Color object and let the RGB logic handle it
            // This allows matching against standard colors with tolerance
            if cleanString.hasPrefix("rgb(") || cleanString.hasPrefix("rgba(") || cleanString.hasPrefix("#") {
                let color = ComponentProperty.colorStringToColor(cleanString)
                return colorToString(color) // Recursive call to handle Color object
            }
            
            return "Color(\"\(cleanString)\")"
        }
        
        guard let color = value as? Color else {
            return ".clear"
        }
        
        // Extract RGBA values and match against known colors
        #if os(macOS)
        let nsColor = NSColor(color)
        let rgba = nsColor.rgbaComponents
        let r = rgba.red
        let g = rgba.green
        let b = rgba.blue
        let a = rgba.alpha
        #else
        // For iOS, try to extract components
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        if let cgColor = color.cgColor {
            let components = cgColor.components ?? [0, 0, 0, 1]
            if components.count >= 3 {
                r = components[0]
                g = components[1]
                b = components[2]
                a = components.count >= 4 ? components[3] : 1
            } else if components.count >= 1 {
                // Grayscale
                r = components[0]
                g = components[0]
                b = components[0]
                a = components.count >= 2 ? components[1] : 1
            }
        }
        #endif
        
        // Match against known SwiftUI colors with tolerance
        func matches(_ targetR: CGFloat, _ targetG: CGFloat, _ targetB: CGFloat, tolerance: CGFloat = 0.1) -> Bool {
            return abs(r - targetR) < tolerance && abs(g - targetG) < tolerance && abs(b - targetB) < tolerance
        }
        
        // Standard SwiftUI colors (approximate RGB values)
        if matches(1.0, 1.0, 1.0) && a >= 0.99 { return ".white" }
        if matches(0.0, 0.0, 0.0) && a >= 0.99 { return ".black" }
        if a < 0.01 { return ".clear" }
        
        // Check standard system colors with broad matching
        if matches(0.0, 0.48, 1.0) { return ".blue" } // System Blue
        if matches(1.0, 0.23, 0.19) { return ".red" } // System Red
        if matches(0.20, 0.78, 0.35) { return ".green" } // System Green
        if matches(1.0, 0.58, 0.0) { return ".orange" } // System Orange
        if matches(1.0, 0.80, 0.0) { return ".yellow" } // System Yellow
        if matches(0.69, 0.32, 0.87) { return ".purple" } // System Purple
        if matches(1.0, 0.18, 0.33) { return ".pink" } // System Pink
        if matches(0.56, 0.56, 0.58) { return ".gray" } // System Gray
        if matches(0.19, 0.68, 0.79) { return ".teal" } // System Teal
        if matches(0.35, 0.34, 0.84) { return ".indigo" } // System Indigo
        if matches(0.0, 0.78, 0.75) { return ".mint" } // System Mint
        if matches(0.20, 0.68, 0.90) { return ".cyan" } // System Cyan
        if matches(0.61, 0.35, 0.22) { return ".brown" } // System Brown
        
        // Secondary checks for pure bright colors
        if r < 0.1 && g < 0.1 && b > 0.9 { return ".blue" }
        if r > 0.9 && g < 0.1 && b < 0.1 { return ".red" }
        if r < 0.1 && g > 0.9 && b < 0.1 { return ".green" }
        
        // For truly custom colors, output clean RGB
        let cleanR = round(r * 1000) / 1000
        let cleanG = round(g * 1000) / 1000
        let cleanB = round(b * 1000) / 1000
        
        if a < 0.99 {
            let cleanA = round(a * 100) / 100
            return "Color(red: \(cleanR), green: \(cleanG), blue: \(cleanB), opacity: \(cleanA))"
        }
        return "Color(red: \(cleanR), green: \(cleanG), blue: \(cleanB))"
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
