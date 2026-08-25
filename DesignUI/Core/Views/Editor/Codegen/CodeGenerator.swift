//
//  CodeGenerator.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import MapKit

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
    
    static func generateCode(for component: UIComponent, indentLevel: Int) -> String {
        let indent = String(repeating: "    ", count: indentLevel)
        let nextIndent = String(repeating: "    ", count: indentLevel + 1)
        
        var baseCode: String
        switch component.type {
        case .text:
            baseCode = generateTextCode(component: component, indent: indent, nextIndent: nextIndent)
        case .image:
            baseCode = generateImageCode(component: component, indent: indent, nextIndent: nextIndent)
        case .stack:
            baseCode = generateStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
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
        case .progressView:
            baseCode = generateProgressViewCode(component: component, indent: indent, nextIndent: nextIndent)
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
        case .map:
            baseCode = generateMapCode(component: component, indent: indent, nextIndent: nextIndent)
            
        default:
            return "\(indent)// \(component.type.rawValue) - Code generation not implemented yet"
        }
        
        // Apply modifiers
        return applyModifiersToCode(baseCode: baseCode, modifiers: component.modifiers, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
    }

    private static func generateStackCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        let stackType = (component.getProperty(key: "stackType") as? String ?? "vertical").lowercased()
        switch stackType {
        case "horizontal":
            return generateHStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case "z":
            return generateZStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        default:
            return generateVStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        }
    }
    
    private static func generateTextCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let text = component.getProperty(key: "text") as? String ?? "Hello World"
        // Escape quotes in text
        let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
        return "\(indent)Text(\"\(escapedText)\")"
    }
    
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
    
    private static func generateSpacerCode(component _: UIComponent, indent: String, nextIndent _: String) -> String {
        return "\(indent)Spacer()"
    }
    
    private static func generateDividerCode(component _: UIComponent, indent: String, nextIndent _: String) -> String {
        return "\(indent)Divider()"
    }
    
    private static func generateRectangleCode(component _: UIComponent, indent: String, nextIndent _: String) -> String {
        return "\(indent)Rectangle()"
    }
    
    private static func generateCircleCode(component _: UIComponent, indent: String, nextIndent _: String) -> String {
        return "\(indent)Circle()"
    }
    
    private static func generateRoundedRectangleCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
        return "\(indent)RoundedRectangle(cornerRadius: \(formatNumber(cornerRadius)))"
    }
    
    private static func generateCapsuleCode(component _: UIComponent, indent: String, nextIndent _: String) -> String {
        return "\(indent)Capsule()"
    }
    
    private static func generateEllipseCode(component _: UIComponent, indent: String, nextIndent _: String) -> String {
        return "\(indent)Ellipse()"
    }
    
    private static func generateShapeCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
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
    
    private static func generateScrollViewCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        let axis = component.getProperty(key: "axis") as? String ?? "vertical"
        let showsIndicators = component.getBoolProperty(key: "showsIndicators", defaultValue: true)
        
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
    
    private static func generateSFSymbolCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let symbolName = component.getProperty(key: "symbolName") as? String ?? "star"
        
        return "\(indent)Image(systemName: \"\(symbolName)\")"
    }

    private static func generateTextFieldCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let text = component.getProperty(key: "text") as? String ?? ""
        let placeholder = component.getProperty(key: "placeholder") as? String ?? "Placeholder"
        // Use constant binding for generated code preview
        return "\(indent)TextField(\"\(placeholder)\", text: .constant(\"\(text)\"))"
    }

    private static func generateMapCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let latitude = doubleProperty(component, key: "latitude", defaultValue: 37.3346)
        let longitude = doubleProperty(component, key: "longitude", defaultValue: -122.0090)
        let latitudeDelta = max(doubleProperty(component, key: "latitudeDelta", defaultValue: 0.018), 0.001)
        let longitudeDelta = max(doubleProperty(component, key: "longitudeDelta", defaultValue: 0.018), 0.001)
        let interactionModes = mapInteractionModesCode(component.getProperty(key: "interactionModes") as? String ?? "all")
        let showsUserLocation = boolProperty(component, key: "showsUserLocation", defaultValue: false)
        let markerComment = mapMarkerSummaryComment(component)

        var code = """
\(indent)Map(coordinateRegion: .constant(
\(indent)    MKCoordinateRegion(
\(indent)        center: CLLocationCoordinate2D(latitude: \(formatNumber(latitude)), longitude: \(formatNumber(longitude))),
\(indent)        span: MKCoordinateSpan(latitudeDelta: \(formatNumber(latitudeDelta)), longitudeDelta: \(formatNumber(longitudeDelta)))
\(indent)    )
\(indent)), interactionModes: \(interactionModes), showsUserLocation: \(showsUserLocation))
"""
        if !markerComment.isEmpty {
            code += "\n\(indent)// Markers: \(markerComment)"
        }
        return code
    }

    private static func boolProperty(_ component: UIComponent, key: String, defaultValue: Bool) -> Bool {
        if let boolValue = component.getProperty(key: key) as? Bool {
            return boolValue
        }
        if let intValue = component.getProperty(key: key) as? Int {
            return intValue != 0
        }
        if let doubleValue = component.getProperty(key: key) as? Double {
            return doubleValue != 0
        }
        if let stringValue = component.getProperty(key: key) as? String {
            switch stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "1", "yes", "y", "on":
                return true
            case "false", "0", "no", "n", "off":
                return false
            default:
                return defaultValue
            }
        }
        return defaultValue
    }

    private static func mapInteractionModesCode(_ rawValue: String) -> String {
        switch rawValue.lowercased().replacingOccurrences(of: " ", with: "") {
        case "none":
            return "[]"
        case "pan":
            return "[.pan]"
        case "zoom":
            return "[.zoom]"
        case "rotate":
            return "[.rotate]"
        case "pitch":
            return "[.pitch]"
        case "pan+zoom":
            return "[.pan, .zoom]"
        case "pan+zoom+rotate":
            return "[.pan, .zoom, .rotate]"
        case "pan+zoom+rotate+pitch":
            return "[.pan, .zoom, .rotate, .pitch]"
        default:
            return ".all"
        }
    }

    private static func mapMarkerSummaryComment(_ component: UIComponent) -> String {
        guard let rawMarkers = component.getProperty(key: "markers") else { return "" }
        if let markerString = rawMarkers as? String {
            let trimmed = markerString.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "" : trimmed
        }
        return "\(rawMarkers)"
    }
    
    private static func generateToggleCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let isOn = component.getProperty(key: "isOn") as? Bool ?? true
        // Generate iOS-style switch without label
        return "\(indent)Toggle(\"\", isOn: .constant(\(isOn)))\n\(nextIndent).labelsHidden()\n\(nextIndent).toggleStyle(.switch)"
    }
    
    private static func generateSliderCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let value = component.getProperty(key: "value") as? Double ?? 0.5
        let min = component.getProperty(key: "min") as? Double ?? 0.0
        let max = component.getProperty(key: "max") as? Double ?? 1.0
        return "\(indent)Slider(value: .constant(\(value)), in: \(min)...\(max))"
    }
    
    private struct GaugeCodeProperties {
        let gaugeType: String
        let value: Double
        let min: Double
        let max: Double
        let showValue: Bool
    }

    private static func generateGaugeCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let properties = gaugeCodeProperties(from: component)

        switch properties.gaugeType {
        case "linear":
            return linearGaugeCode(properties: properties, indent: indent, nextIndent: nextIndent)
        case "circular":
            return circularGaugeCode(properties: properties, indent: indent, nextIndent: nextIndent)
        case "circular range":
            return circularRangeGaugeCode(properties: properties, indent: indent, nextIndent: nextIndent)
        default:
            return defaultGaugeCode(properties: properties, indent: indent, nextIndent: nextIndent)
        }
    }

    private static func gaugeCodeProperties(from component: UIComponent) -> GaugeCodeProperties {
        GaugeCodeProperties(
            gaugeType: component.getProperty(key: "gaugeType") as? String ?? "circular",
            value: doubleProperty(component, key: "value", defaultValue: 50),
            min: doubleProperty(component, key: "min", defaultValue: 0),
            max: doubleProperty(component, key: "max", defaultValue: 100),
            showValue: component.getProperty(key: "showValue") as? Bool ?? true
        )
    }

    private static func doubleProperty(_ component: UIComponent, key: String, defaultValue: Double) -> Double {
        if let doubleValue = component.getProperty(key: key) as? Double {
            return doubleValue
        }
        if let intValue = component.getProperty(key: key) as? Int {
            return Double(intValue)
        }
        return defaultValue
    }

    private static func gaugeHeader(_ properties: GaugeCodeProperties, indent: String) -> String {
        let value = formatNumber(properties.value)
        let min = formatNumber(properties.min)
        let max = formatNumber(properties.max)
        return "\(indent)Gauge(value: \(value), in: \(min)...\(max)) {"
    }

    private static func gaugeValueLabel(_ properties: GaugeCodeProperties, nextIndent: String, emptyWhenHidden: Bool) -> String {
        if properties.showValue {
            return "\(nextIndent)Text(\"\(Int(properties.value))\")"
        }
        return emptyWhenHidden ? "\(nextIndent)EmptyView()" : ""
    }

    private static func linearGaugeCode(properties: GaugeCodeProperties, indent: String, nextIndent: String) -> String {
        var code = gaugeHeader(properties, indent: indent)
        let label = gaugeValueLabel(properties, nextIndent: nextIndent, emptyWhenHidden: false)
        if !label.isEmpty {
            code += "\n\(label)"
        }
        code += "\n\(indent)}"
        code += "\n\(nextIndent).gaugeStyle(.linearCapacity)"
        return code
    }

    private static func circularGaugeCode(properties: GaugeCodeProperties, indent: String, nextIndent: String) -> String {
        var code = gaugeHeader(properties, indent: indent)
        code += "\n\(gaugeValueLabel(properties, nextIndent: nextIndent, emptyWhenHidden: true))"
        code += "\n\(indent)}"
        code += "\n\(nextIndent).gaugeStyle(.accessoryCircularCapacity)"
        return code
    }

    private static func circularRangeGaugeCode(properties: GaugeCodeProperties, indent: String, nextIndent: String) -> String {
        var code = gaugeHeader(properties, indent: indent)
        code += "\n\(nextIndent)EmptyView()"
        code += "\n\(indent)} currentValueLabel: {"
        code += "\n\(gaugeValueLabel(properties, nextIndent: nextIndent, emptyWhenHidden: true))"
        code += "\n\(indent)} minimumValueLabel: {"
        code += "\n\(nextIndent)Text(\"\(Int(properties.min))\")"
        code += "\n\(indent)} maximumValueLabel: {"
        code += "\n\(nextIndent)Text(\"\(Int(properties.max))\")"
        code += "\n\(indent)}"
        code += "\n\(nextIndent).gaugeStyle(.accessoryCircular)"
        return code
    }

    private static func defaultGaugeCode(properties: GaugeCodeProperties, indent: String, nextIndent: String) -> String {
        let value = formatNumber(properties.value)
        let min = formatNumber(properties.min)
        let max = formatNumber(properties.max)
        var code = "\(indent)Gauge(value: \(value), in: \(min)...\(max)) {}"
        code += "\n\(nextIndent).gaugeStyle(.accessoryCircularCapacity)"
        return code
    }
    
    private static func generateProgressViewCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
        let rawValue = component.getProperty(key: "value") as? Double ?? 0.6
        let rawTotal = component.getProperty(key: "total") as? Double ?? 1.0
        
        let total = rawTotal > 0 ? rawTotal : 1.0
        let value = min(max(rawValue, 0), total)
        
        return "\(indent)ProgressView(value: \(formatNumber(value)), total: \(formatNumber(total)))"
    }
    
    private static func generateLinearGradientCode(component: UIComponent, indent: String, nextIndent _: String) -> String {
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
    
    private static func applyModifiersToCode(baseCode: String, modifiers: [ComponentModifier], component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        let code = baseCode.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        var result = code

        for modifier in orderedModifiersForCodegen(modifiers) {
            let modifierCode = generateModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
            if !modifierCode.isEmpty {
                result += "\n" + modifierCode
            }
        }
        
        return result
    }

    private static func orderedModifiersForCodegen(_ modifiers: [ComponentModifier]) -> [ComponentModifier] {
        let effectTypes: Set<ModifierType> = [.opacity, .shadow, .blur, .glassEffect, .clipShape]
        let fillTypes: Set<ModifierType> = [.fill, .foregroundColor, .tint]
        let layoutTypes: Set<ModifierType> = [.frame, .padding, .rotation, .offset]

        return modifiers
            .enumerated()
            .sorted { lhs, rhs in
                let lhsPriority = modifierCodegenPriority(lhs.element.type, fillTypes: fillTypes, layoutTypes: layoutTypes, effectTypes: effectTypes)
                let rhsPriority = modifierCodegenPriority(rhs.element.type, fillTypes: fillTypes, layoutTypes: layoutTypes, effectTypes: effectTypes)
                if lhsPriority == rhsPriority {
                    return lhs.offset < rhs.offset
                }
                return lhsPriority < rhsPriority
            }
            .map(\.element)
    }

    private static func modifierCodegenPriority(
        _ type: ModifierType,
        fillTypes: Set<ModifierType>,
        layoutTypes: Set<ModifierType>,
        effectTypes: Set<ModifierType>
    ) -> Int {
        if fillTypes.contains(type) { return 0 }
        if layoutTypes.contains(type) { return 1 }
        if type == .backgroundColor { return 2 }
        if type == .cornerRadius { return 3 }
        if effectTypes.contains(type) { return 4 }
        return 2
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
        case .offset:
            return generateOffsetModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .blur:
            return generateBlurModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .overlay:
            return generateOverlayModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .border:
            return generateBorderModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .stroke:
            return generateStrokeModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent)
        case .clipShape:
            return generateClipShapeModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .mask:
            return generateMaskModifierCode(modifier: modifier, component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .fill:
            return generateFillModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .tint:
            return generateTintModifierCode(modifier: modifier, indent: indent, nextIndent: nextIndent)
        case .glassEffect:
            return generateGlassEffectModifierCode(modifier: modifier, indent: indent)
        }
    }
    

    private static func generateGlassEffectModifierCode(modifier: ComponentModifier, indent: String) -> String {
        let tintString = (modifier.properties["tint"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let glassStyle = tintString.isEmpty
            ? ".regular.interactive()"
            : ".regular.tint(\(swiftUIColorLiteral(tintString))).interactive()"

        guard let rawShape = (modifier.properties["shape"] as? String) ?? (modifier.properties["shapeType"] as? String),
              !rawShape.isEmpty else {
            return tintString.isEmpty
                ? "\(indent).glassEffect()"
                : "\(indent).glassEffect(\(glassStyle))"
        }

        let shapeName: String
        if rawShape.lowercased() == "roundedrectangle" {
            shapeName = "RoundedRectangle"
        } else {
            shapeName = rawShape.prefix(1).uppercased() + rawShape.dropFirst()
        }

        switch shapeName {
        case "Circle":
            return "\(indent).glassEffect(\(glassStyle), in: Circle())"
        case "Capsule":
            return "\(indent).glassEffect(\(glassStyle), in: Capsule())"
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)
            return "\(indent).glassEffect(\(glassStyle), in: RoundedRectangle(cornerRadius: \(formatNumber(Double(radius)))))"
        case "Ellipse":
            return "\(indent).glassEffect(\(glassStyle), in: Ellipse())"
        case "Rectangle":
            return "\(indent).glassEffect(\(glassStyle), in: Rectangle())"
        default:
            return "\(indent).glassEffect(\(glassStyle))"
        }
    }

    private static func swiftUIColorLiteral(_ colorString: String) -> String {
        let trimmed = colorString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return ".gray.opacity(0.45)" }

        let parts = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
        let colorName = parts.first?.lowercased() ?? "gray"
        let opacity = parts.count > 1 ? (Double(parts[1]) ?? 1.0) : 1.0
        let baseColor: String

        switch colorName {
        case "black": baseColor = "Color.black"
        case "white": baseColor = "Color.white"
        case "gray", "grey": baseColor = "Color.gray"
        case "red": baseColor = "Color.red"
        case "orange": baseColor = "Color.orange"
        case "yellow": baseColor = "Color.yellow"
        case "green": baseColor = "Color.green"
        case "mint": baseColor = "Color.mint"
        case "teal": baseColor = "Color.teal"
        case "cyan", "lightblue": baseColor = "Color.cyan"
        case "blue": baseColor = "Color.blue"
        case "indigo": baseColor = "Color.indigo"
        case "purple": baseColor = "Color.purple"
        case "pink": baseColor = "Color.pink"
        case "brown": baseColor = "Color.brown"
        case "primary": baseColor = "Color.primary"
        case "secondary": baseColor = "Color.secondary"
        case "tertiary": baseColor = "Color.primary.opacity(0.6)"
        case "quaternary": baseColor = "Color.primary.opacity(0.3)"
        case "systembackground": baseColor = "Color(uiColor: .systemBackground)"
        case "secondarysystembackground": baseColor = "Color(uiColor: .secondarySystemBackground)"
        case "tertiarysystembackground": baseColor = "Color(uiColor: .tertiarySystemBackground)"
        case "systemfill": baseColor = "Color(uiColor: .systemFill)"
        case "secondarysystemfill": baseColor = "Color(uiColor: .secondarySystemFill)"
        case "tertiarysystemfill": baseColor = "Color(uiColor: .tertiarySystemFill)"
        case "quaternarysystemfill": baseColor = "Color(uiColor: .quaternarySystemFill)"
        default: baseColor = "Color.gray"
        }

        return "\(baseColor).opacity(\(formatNumber(opacity)))"
    }

    private static func generateFrameModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let validFrameType: (String?) -> String = { raw in
            ["Default", "Full", "Custom"].contains(raw ?? "") ? (raw ?? "Default") : "Default"
        }

        let widthType = validFrameType(modifier.properties["widthType"] as? String)
        let heightType = validFrameType(modifier.properties["heightType"] as? String)
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
            return "\(indent).frame(\(frameParts.joined(separator: ", ")))"
        }
        
        return ""
    }
    
    private static func generatePaddingModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let amount = modifier.getCGFloat(key: "amount", defaultValue: 0)
        let location = modifier.properties["location"] as? String ?? "all"
        
        switch location {
        case "all":
            return "\(indent).padding(\(formatNumber(Double(amount))))"
        case "leading":
            return "\(indent).padding(.leading, \(formatNumber(Double(amount))))"
        case "trailing":
            return "\(indent).padding(.trailing, \(formatNumber(Double(amount))))"
        case "top":
            return "\(indent).padding(.top, \(formatNumber(Double(amount))))"
        case "bottom":
            return "\(indent).padding(.bottom, \(formatNumber(Double(amount))))"
        case "horizontal":
            return "\(indent).padding(.horizontal, \(formatNumber(Double(amount))))"
        case "vertical":
            return "\(indent).padding(.vertical, \(formatNumber(Double(amount))))"
        default:
            return "\(indent).padding(\(formatNumber(Double(amount))))"
        }
    }
    
    private static func generateBackgroundColorModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        // Check for gradient
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(indent).background(\(gradientCode))"
        }
        
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(indent).background(\(colorCode))"
    }
    
    private static func generateBackgroundModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent _: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (background with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let modifierContent = unwrapModifierContainerIfPossible(parentComponent)
            let childCode = generateCode(for: modifierContent, indentLevel: indentLevel + 1)
            return "\(indent).background(\n\(childCode)\n\(indent))"
        }
        
        // Check for gradient
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(indent).background(\(gradientCode))"
        }
        
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(indent).background(\(colorCode))"
    }
    
    private static func generateFillModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        // Check for gradient
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(indent).fill(\(gradientCode))"
        }
        
        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(indent).fill(\(colorCode))"
    }
    
    private static func generateForegroundColorModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        if let gradientCode = generateGradientCode(modifier: modifier) {
            return "\(indent).foregroundStyle(\(gradientCode))"
        }

        // Parse unified "colorname:opacity" format
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(indent).foregroundStyle(\(colorCode))"
    }

    private static func generateTintModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let colorCode = parseColorWithOpacity(modifier: modifier)
        return "\(indent).tint(\(colorCode))"
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
    
    private static func generateFontModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
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
            return "\(indent).font(.system(size: \(size), weight: .\(weight)\(designCode)))"
        }
        
        // Preset size
        // If we have design or non-regular weight, utilize .system(style, design, weight)
        if !designCode.isEmpty || weight != "regular" {
             return "\(indent).font(.system(.\(size)\(designCode), weight: .\(weight)))"
        }
        
        // Simple case: just size (regular weight, default design)
        return "\(indent).font(.\(size))"
    }
    
    private static func generateCornerRadiusModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 8)
        return "\(indent).cornerRadius(\(formatNumber(Double(radius))))"
    }
    
    private static func generateOpacityModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let opacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
        return "\(indent).opacity(\(formatNumber(opacity)))"
    }
    
    private static func generateTextAlignmentModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let alignment = modifier.properties["alignment"] as? String ?? "leading"
        return "\(indent).multilineTextAlignment(.\(alignment))"
    }
    
    private static func generateShadowModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
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
            return "\(indent).shadow(color: \(colorCode), radius: \(formatNumber(Double(radius))), x: \(formatNumber(Double(x))), y: \(formatNumber(Double(y))))"
        } else {
            return "\(indent).shadow(color: \(colorCode), radius: \(formatNumber(Double(radius))))"
        }
    }
    
    private static func generateRotationModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let angle = modifier.getDouble(key: "angle", defaultValue: 0)
        return "\(indent).rotationEffect(.degrees(\(formatNumber(angle))))"
    }
    
    private static func generateOffsetModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
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
        
        return "\(indent).offset(x: \(formatNumber(Double(x))), y: \(formatNumber(Double(y))))"
    }
    
    private static func generateBlurModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let radius = modifier.getCGFloat(key: "radius", defaultValue: 0)
        return "\(indent).blur(radius: \(formatNumber(Double(radius))))"
    }
    
    private static func generateOverlayModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent _: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (overlay with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let alignment = modifier.properties["alignment"] as? String ?? "center"
            let alignmentCode = alignmentFromString(alignment)
            let modifierContent = unwrapModifierContainerIfPossible(parentComponent)
            let childCode = generateCode(for: modifierContent, indentLevel: indentLevel + 1)
            return "\(indent).overlay(\n\(childCode)\n\(indent), alignment: .\(alignmentCode))"
        }
        
        return ""
    }
    
    private static func generateBorderModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
        let width = modifier.getCGFloat(key: "width", defaultValue: 1)
        let color = modifier.properties["color"]
        return "\(indent).border(\(colorToString(color)), width: \(formatNumber(Double(width))))"
    }
    
    private static func generateStrokeModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent: String) -> String {
        let lineWidth = modifier.getCGFloat(key: "lineWidth", defaultValue: 1)
        let color = modifier.properties["color"]
        
        let isShapeComponent: Bool = {
            switch component.type {
            case .shape, .rectangle, .circle, .roundedRectangle, .capsule, .ellipse:
                return true
            default:
                return false
            }
        }()
        
        let hasFillModifier = component.modifiers.contains { $0.type == .fill }
        if isShapeComponent && !hasFillModifier {
            return "\(indent).stroke(\(colorToString(color)), lineWidth: \(formatNumber(Double(lineWidth))))"
        }
        
        let shapeCode = strokeShapeCode(for: component)
        return """
\(indent).overlay(
\(nextIndent)\(shapeCode)
\(nextIndent)    .stroke(\(colorToString(color)), lineWidth: \(formatNumber(Double(lineWidth))))
\(indent))
"""
    }
    
    private static func generateClipShapeModifierCode(modifier: ComponentModifier, indent: String, nextIndent _: String) -> String {
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
            return "\(indent).clipShape(Circle())"
        case "Capsule":
            return "\(indent).clipShape(Capsule())"
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return "\(indent).clipShape(RoundedRectangle(cornerRadius: \(formatNumber(Double(radius)))))"
        case "Ellipse":
            return "\(indent).clipShape(Ellipse())"
        default:
            return "\(indent).clipShape(Rectangle())"
        }
    }
    
    private static func resolvedCornerRadius(for component: UIComponent) -> CGFloat {
        if let radius = component.getProperty(key: "cornerRadius") as? CGFloat {
            return radius
        }
        if let radius = component.getProperty(key: "cornerRadius") as? Double {
            return CGFloat(radius)
        }
        if let radiusModifier = component.modifiers.first(where: { $0.type == .cornerRadius }) {
            return radiusModifier.getCGFloat(key: "radius", defaultValue: 0)
        }
        return 0
    }
    
    private static func strokeShapeCode(for component: UIComponent) -> String {
        if component.type == .shape {
            let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"
            switch shapeType {
            case "Circle":
                return "Circle()"
            case "Capsule":
                return "Capsule()"
            case "Ellipse":
                return "Ellipse()"
            case "Rounded Rectangle":
                let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
                return "RoundedRectangle(cornerRadius: \(formatNumber(radius)))"
            default:
                return "Rectangle()"
            }
        }
        
        switch component.type {
        case .roundedRectangle:
            let radius = component.getProperty(key: "cornerRadius") as? Double ?? 12.0
            return "RoundedRectangle(cornerRadius: \(formatNumber(radius)))"
        case .circle:
            return "Circle()"
        case .capsule:
            return "Capsule()"
        case .ellipse:
            return "Ellipse()"
        case .rectangle:
            return "Rectangle()"
        default:
            let radius = resolvedCornerRadius(for: component)
            if radius > 0 {
                return "RoundedRectangle(cornerRadius: \(formatNumber(Double(radius))))"
            }
            return "Rectangle()"
        }
    }
    
    private static func generateMaskModifierCode(modifier: ComponentModifier, component: UIComponent, indent: String, nextIndent _: String, indentLevel: Int) -> String {
        // Check if there's a parent component for this modifier (mask with children)
        if let parentComponent = component.getParentComponentForModifier(modifier.id) {
            let modifierContent = unwrapModifierContainerIfPossible(parentComponent)
            let childCode = generateCode(for: modifierContent, indentLevel: indentLevel + 1)
            return "\(indent).mask(\n\(childCode)\n\(indent))"
        }
        
        // Fallback to shape mask
        let shapeName = modifier.properties["shape"] as? String ?? "Rectangle"
        switch shapeName {
        case "Circle":
            return "\(indent).mask(Circle())"
        case "Capsule":
            return "\(indent).mask(Capsule())"
        case "RoundedRectangle":
            let radius = modifier.getCGFloat(key: "cornerRadius", defaultValue: 8)
            return "\(indent).mask(RoundedRectangle(cornerRadius: \(radius)))"
        default:
            return "\(indent).mask(Rectangle())"
        }
    }
    
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
    
    /// Overlay/background/mask modifiers store content in a synthetic container.
    /// If the container only has one child, generate the child directly.
    private static func unwrapModifierContainerIfPossible(_ parentComponent: UIComponent) -> UIComponent {
        if parentComponent.modifierType != nil, parentComponent.children.count == 1 {
            return parentComponent.children[0]
        }
        return parentComponent
    }
    
    static func colorToString(_ value: Any?) -> String {
        if let colorString = value as? String {
            return colorStringToString(colorString)
        }

        guard let color = value as? Color else { return ".clear" }
        return swiftUIColorToString(color)
    }

    private static let semanticColorNames: Set<String> = [
        "primary", "secondary", "tertiary", "quaternary", "blue", "red", "green",
        "orange", "yellow", "purple", "pink", "gray", "white", "black", "clear",
        "teal", "indigo", "mint", "cyan", "brown",
    ]

    private static func colorStringToString(_ colorString: String) -> String {
        let cleanString = colorString.hasPrefix("color:") ? String(colorString.dropFirst(6)) : colorString

        let parts = cleanString.split(separator: ":", maxSplits: 1).map(String.init)
        if parts.count == 2, let opacity = Double(parts[1]) {
            let name = parts[0].lowercased()
            if semanticColorNames.contains(name) {
                if opacity >= 0.999 {
                    return ".\(name)"
                }
                return ".\(name).opacity(\(formatNumber(opacity)))"
            }
        }

        let lowercasedName = cleanString.lowercased()
        if semanticColorNames.contains(lowercasedName) {
            return ".\(lowercasedName)"
        }

        // RGB and hex strings can often collapse back to built-in SwiftUI colors.
        if cleanString.hasPrefix("rgb(") || cleanString.hasPrefix("rgba(") || cleanString.hasPrefix("#") {
            let color = ComponentProperty.colorStringToColor(cleanString)
            return swiftUIColorToString(color)
        }

        return "Color(\"\(cleanString)\")"
    }

    private static func swiftUIColorToString(_ color: Color) -> String {
        let rgba = rgbaComponents(from: color)
        let r = rgba.red
        let g = rgba.green
        let b = rgba.blue
        let a = rgba.alpha

        if let standardName = standardColorName(red: r, green: g, blue: b, alpha: a) {
            return standardName
        }

        let cleanR = round(r * 1000) / 1000
        let cleanG = round(g * 1000) / 1000
        let cleanB = round(b * 1000) / 1000

        if a < 0.99 {
            let cleanA = round(a * 100) / 100
            return "Color(red: \(cleanR), green: \(cleanG), blue: \(cleanB), opacity: \(cleanA))"
        }
        return "Color(red: \(cleanR), green: \(cleanG), blue: \(cleanB))"
    }

    private static func rgbaComponents(from color: Color) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        #if os(macOS)
        let nsColor = NSColor(color)
        return nsColor.rgbaComponents
        #else
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
        return (r, g, b, a)
        #endif
    }

    private static func standardColorName(red r: CGFloat, green g: CGFloat, blue b: CGFloat, alpha a: CGFloat) -> String? {
        if matchesColor(r, g, b, targetRed: 1.0, targetGreen: 1.0, targetBlue: 1.0) && a >= 0.99 { return ".white" }
        if matchesColor(r, g, b, targetRed: 0.0, targetGreen: 0.0, targetBlue: 0.0) && a >= 0.99 { return ".black" }
        if a < 0.01 { return ".clear" }

        if matchesColor(r, g, b, targetRed: 0.0, targetGreen: 0.48, targetBlue: 1.0) { return ".blue" }
        if matchesColor(r, g, b, targetRed: 1.0, targetGreen: 0.23, targetBlue: 0.19) { return ".red" }
        if matchesColor(r, g, b, targetRed: 0.20, targetGreen: 0.78, targetBlue: 0.35) { return ".green" }
        if matchesColor(r, g, b, targetRed: 1.0, targetGreen: 0.58, targetBlue: 0.0) { return ".orange" }
        if matchesColor(r, g, b, targetRed: 1.0, targetGreen: 0.80, targetBlue: 0.0) { return ".yellow" }
        if matchesColor(r, g, b, targetRed: 0.69, targetGreen: 0.32, targetBlue: 0.87) { return ".purple" }
        if matchesColor(r, g, b, targetRed: 1.0, targetGreen: 0.18, targetBlue: 0.33) { return ".pink" }
        if matchesColor(r, g, b, targetRed: 0.56, targetGreen: 0.56, targetBlue: 0.58) { return ".gray" }
        if matchesColor(r, g, b, targetRed: 0.19, targetGreen: 0.68, targetBlue: 0.79) { return ".teal" }
        if matchesColor(r, g, b, targetRed: 0.35, targetGreen: 0.34, targetBlue: 0.84) { return ".indigo" }
        if matchesColor(r, g, b, targetRed: 0.0, targetGreen: 0.78, targetBlue: 0.75) { return ".mint" }
        if matchesColor(r, g, b, targetRed: 0.20, targetGreen: 0.68, targetBlue: 0.90) { return ".cyan" }
        if matchesColor(r, g, b, targetRed: 0.61, targetGreen: 0.35, targetBlue: 0.22) { return ".brown" }

        if r < 0.1 && g < 0.1 && b > 0.9 { return ".blue" }
        if r > 0.9 && g < 0.1 && b < 0.1 { return ".red" }
        if r < 0.1 && g > 0.9 && b < 0.1 { return ".green" }

        return nil
    }

    private static func matchesColor(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, targetRed: CGFloat, targetGreen: CGFloat, targetBlue: CGFloat, tolerance: CGFloat = 0.1) -> Bool {
        abs(r - targetRed) < tolerance && abs(g - targetGreen) < tolerance && abs(b - targetBlue) < tolerance
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

#if os(macOS)
extension NSColor {
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        if let rgbColor = self.usingColorSpace(.sRGB) {
            rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        } else {
            red = 0.5
            green = 0.5
            blue = 0.5
            alpha = 1.0
        }
        
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif
