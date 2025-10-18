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
        
        switch component.type {
        case .text:
            return generateTextCode(component: component, indent: indent, nextIndent: nextIndent)
        case .image:
            return generateImageCode(component: component, indent: indent, nextIndent: nextIndent)
        case .button:
            return generateButtonCode(component: component, indent: indent, nextIndent: nextIndent)
        case .vstack:
            return generateVStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .hstack:
            return generateHStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .zstack:
            return generateZStackCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        case .spacer:
            return generateSpacerCode(component: component, indent: indent, nextIndent: nextIndent)
        case .divider:
            return generateDividerCode(component: component, indent: indent, nextIndent: nextIndent)
        case .rectangle:
            return generateRectangleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .circle:
            return generateCircleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .roundedRectangle:
            return generateRoundedRectangleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .capsule:
            return generateCapsuleCode(component: component, indent: indent, nextIndent: nextIndent)
        case .ellipse:
            return generateEllipseCode(component: component, indent: indent, nextIndent: nextIndent)
        case .scrollView:
            return generateScrollViewCode(component: component, indent: indent, nextIndent: nextIndent, indentLevel: indentLevel)
        default:
            return "\(indent)// \(component.type.rawValue) - Code generation not implemented yet"
        }
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
    private static func generateButtonCode(component: UIComponent, indent: String, nextIndent: String) -> String {
        let title = component.getProperty(key: "title") as? String ?? "Button"
        let backgroundColor = component.getProperty(key: "backgroundColor") as? Color ?? Color.blue
        let foregroundColor = component.getProperty(key: "foregroundColor") as? Color ?? Color.white
        let cornerRadius = component.getProperty(key: "cornerRadius") as? Double ?? 8.0
        let padding = component.getProperty(key: "padding") as? EdgeInsets ?? EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        
        let code = "\(indent)Button(action: {\n\(nextIndent)// Action here\n\(indent)}) {\n\(nextIndent)Text(\"\(title)\")\n\(nextIndent).foregroundColor(\(colorToString(foregroundColor)))\n\(nextIndent).padding(\(edgeInsetsToString(padding)))\n\(indent)}\n\(indent).background(\(colorToString(backgroundColor)))\n\(indent).cornerRadius(\(cornerRadius))"
        
        return code
    }
    
    // MARK: - VStack Code Generation
    private static func generateVStackCode(component: UIComponent, indent: String, nextIndent: String, indentLevel: Int) -> String {
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        var code = "\(indent)VStack(alignment: .\(alignment), spacing: \(spacing)) {"
        
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
        let spacing = component.getProperty(key: "spacing") as? Double ?? 8.0
        let alignment = component.getProperty(key: "alignment") as? String ?? "center"
        
        var code = "\(indent)HStack(alignment: .\(alignment), spacing: \(spacing)) {"
        
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
        var code = "\(indent)VStack(spacing: 8) {"
        
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
