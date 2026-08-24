//
//  Modifier.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation
#if os(macOS)
import AppKit
#endif

enum ModifierType: String, CaseIterable, Identifiable, Codable {
    case frame = "Frame"
    case padding = "Padding"
    case backgroundColor = "Background Color"
    case background = "Background"
    case foregroundColor = "Foreground Color"
    case font = "Font"
    case cornerRadius = "Corner Radius"
    case shadow = "Shadow"
    case opacity = "Opacity"
    case rotation = "Rotation"
    case offset = "Offset"
    case clipShape = "Clip Shape"
    case mask = "Mask"
    case blur = "Blur"
    case overlay = "Overlay"
    case border = "Border"
    case stroke = "Stroke"
    case textAlignment = "Text Alignment"
    case fill = "Fill"
    case tint = "Tint"
    case glassEffect = "Glass Effect"
    
    var id: String { rawValue }
    
    // Custom decoder to handle legacy modifier type names
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Handle legacy names
        switch rawValue {
        case "Font Size", "Font Weight":
            self = .font
        case "Scale":
            // Legacy migration: scale is deprecated; fall back to frame-based sizing.
            self = .frame
        case "Aspect Ratio":
            // Legacy migration: aspect-ratio modifier is deprecated; treat as frame no-op.
            self = .frame
        case "Z Index":
            // Legacy migration: z-index modifier is deprecated; treat as frame no-op.
            self = .frame
        case "Clipped":
            // Legacy migration: clipped modifier is deprecated; treat as frame no-op.
            self = .frame
        default:
            guard let type = ModifierType(rawValue: rawValue) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Cannot initialize ModifierType from invalid String value \(rawValue)"
                    )
                )
            }
            self = type
        }
    }
    
    var description: String {
        switch self {
        case .frame:
            return "Changes width and height"
        case .padding:
            return "Adds padding to one or more sides"
        case .backgroundColor:
            return "Sets background color or gradient"
        case .background:
            return "Adds elements behind the view"
        case .foregroundColor:
            return "Changes text and icon color"
        case .font:
            return "Sets font size and weight"
        case .cornerRadius:
            return "Rounds the corners"
        case .shadow:
            return "Adds shadow effect"
        case .opacity:
            return "Changes transparency"
        case .rotation:
            return "Rotates the view"
        case .offset:
            return "Moves the view"
        case .clipShape:
            return "Clips to a shape"
        case .mask:
            return "Masks the view"
        case .blur:
            return "Blurs the view"
        case .overlay:
            return "Layers a secondary view in front"
        case .border:
            return "Adds a border with color and width"
        case .stroke:
            return "Adds a rounded stroke with color and line width"
        case .textAlignment:
            return "Aligns text content"
        case .fill:
            return "Fills the view with a color"
        case .tint:
            return "Applies tint color to controls"
        case .glassEffect:
            return "Applies Liquid Glass on supported OS versions"
        }
    }
    
    var icon: String {
        switch self {
        case .frame:
            return "rectangle"
        case .padding:
            return "rectangle.inset.filled"
        case .backgroundColor:
            return "paintpalette.fill"
        case .background:
            return "square.stack.3d.down.right"
        case .foregroundColor:
            return "paintbrush"
        case .font:
            return "textformat.size"
        case .cornerRadius:
            return "rectangle.roundedtop"
        case .shadow:
            return "shadow"
        case .opacity:
            return "eye"
        case .rotation:
            return "rotate.right"
        case .offset:
            return "arrow.up.and.down.and.arrow.left.and.right"
        case .clipShape:
            return "scissors"
        case .mask:
            return "theatermasks.fill"
        case .blur:
            return "viewfinder"
        case .overlay:
            return "square.dashed.inset.filled"
        case .border:
            return "square.dashed"
        case .stroke:
            return "square.dashed.inset.filled"
        case .textAlignment:
            return "text.alignleft"
        case .fill:
            return "paintbrush.fill"
        case .tint:
            return "paintpalette"
        case .glassEffect:
            return "drop"
        }
    }
}

struct ComponentModifier: Identifiable, Codable, Equatable {
    let id: UUID
    let type: ModifierType
    var properties: [String: Any]
    
    init(type: ModifierType, properties: [String: Any] = [:]) {
        self.id = UUID()
        self.type = type
        self.properties = properties
    }
    
    // Factory method to create modifier with default properties
    static func createWithDefaults(type: ModifierType) -> ComponentModifier {
        let defaultProperties: [String: Any]
        
        switch type {
        case .padding:
            defaultProperties = [
                "amount": CGFloat(10),
                "location": "all"
            ]
        case .frame:
            defaultProperties = [
                "widthType": "Default",
                "heightType": "Default",
                "width": CGFloat(100),
                "height": CGFloat(100)
            ]
        case .cornerRadius:
            defaultProperties = [
                "radius": CGFloat(8)
            ]
        case .opacity:
            defaultProperties = [
                "opacity": Double(1.0)
            ]
        case .rotation:
            defaultProperties = [
                "angle": Double(0)
            ]
        case .offset:
            defaultProperties = [
                "x": CGFloat(0),
                "y": CGFloat(0)
            ]
        case .shadow:
            defaultProperties = [
                "radius": CGFloat(2),
                "x": CGFloat(0),
                "y": CGFloat(2),
                "color": "black",
                "opacity": Double(0.3)
            ]
        case .blur:
            defaultProperties = [
                "radius": CGFloat(0)
            ]
        case .backgroundColor:
            defaultProperties = [
                "color": "primary:1.0"
            ]
        case .background:
            defaultProperties = [
                "alignment": "center"
                // Component will be added dynamically
            ]
        case .foregroundColor:
            defaultProperties = [
                "color": "primary:1.0"
            ]
        case .font:
            defaultProperties = [
                "fontSize": "body",
                "fontWeight": "regular"
            ]
        case .clipShape:
            defaultProperties = [
                "shape": "Rectangle"
            ]
        case .mask:
            defaultProperties = [
                "opacity": Double(1.0)
            ]
        case .overlay:
            defaultProperties = [
                "alignment": "center"
                // "component" will be added dynamically when creating the overlay
            ]
        case .border:
            defaultProperties = [
                "width": CGFloat(1)
            ]
        case .stroke:
            defaultProperties = [
                "lineWidth": CGFloat(1),
                "color": "color:gray"
            ]
        case .textAlignment:
            defaultProperties = [
                "alignment": "leading"
            ]
        case .fill:
            defaultProperties = [
                "color": "primary:1.0"
            ]
        case .tint:
            defaultProperties = [
                "color": "blue:1.0"
            ]
        case .glassEffect:
            defaultProperties = [
                "shape": "RoundedRectangle",
                "cornerRadius": CGFloat(10),
                "tint": ""
            ]
        }
        
        return ComponentModifier(type: type, properties: defaultProperties)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, properties
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Preserve the original ID to maintain link to modifier children (overlay/mask/background)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.type = try container.decode(ModifierType.self, forKey: .type)
        
        // Decode properties as [String: Any] - Make optional for Lean JSON compatibility
        let propertiesDict = try container.decodeIfPresent([String: AnyCodable].self, forKey: .properties) ?? [:]
        self.properties = propertiesDict.mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Conditionally encode ID based on userInfo
        let excludeIdsKey = CodingUserInfoKey(rawValue: "excludeIds")!
        let shouldExcludeIds = encoder.userInfo[excludeIdsKey] as? Bool ?? false
        
        if !shouldExcludeIds {
            try container.encode(id, forKey: .id)
        }
        
        try container.encode(type, forKey: .type)
        
        // Encode properties as [String: AnyCodable], coercing non-encodable values
        var propertiesDict: [String: AnyCodable] = [:]
        for (key, value) in properties {
            if let color = value as? Color {
                let colorString = ComponentProperty.colorToColorString(color)
                propertiesDict[key] = AnyCodable(colorString)
            } else {
                propertiesDict[key] = AnyCodable(value)
            }
        }
        try container.encode(propertiesDict, forKey: .properties)
    }
    
    static func == (lhs: ComponentModifier, rhs: ComponentModifier) -> Bool {
        // First check ID
        if lhs.id != rhs.id { return false }
        
        // Then check if types match (should if IDs match, but safety first)
        if lhs.type != rhs.type { return false }
        
        // Then check properties count
        if lhs.properties.count != rhs.properties.count { return false }
        
        // Finally check all property values
        for (key, lhsValue) in lhs.properties {
            guard let rhsValue = rhs.properties[key] else { return false }
            
            // Use ComponentProperty's helper for Any comparison
            if !ComponentProperty.valuesAreEqual(lhsValue, rhsValue) {
                return false
            }
        }
        
        return true
    }
    
    /// Safely converts a property value to CGFloat, handling CGFloat, Double, and Int from JSON decoding
    func getCGFloat(key: String, defaultValue: CGFloat = 0) -> CGFloat {
        let value: Any?
        if let direct = properties[key] {
            value = direct
        } else if key == "width", let fallback = properties["lineWidth"] {
            value = fallback
        } else if key == "lineWidth", let fallback = properties["width"] {
            value = fallback
        } else {
            value = nil
        }
        guard let value else { return defaultValue }
        
        if let cgFloat = value as? CGFloat {
            return cgFloat
        } else if let double = value as? Double {
            return CGFloat(double)
        } else if let int = value as? Int {
            return CGFloat(int)
        } else {
            debugLog("⚠️ Could not convert \(key) to CGFloat, value: \(value), type: \(Swift.type(of: value))")
            return defaultValue
        }
    }
    
    /// Safely converts a property value to Double, handling CGFloat, Double, and Int from JSON decoding
    func getDouble(key: String, defaultValue: Double = 0) -> Double {
        let value: Any?
        if let direct = properties[key] {
            value = direct
        } else if key == "width", let fallback = properties["lineWidth"] {
            value = fallback
        } else if key == "lineWidth", let fallback = properties["width"] {
            value = fallback
        } else {
            value = nil
        }
        guard let value else { return defaultValue }
        
        if let double = value as? Double {
            return double
        } else if let cgFloat = value as? CGFloat {
            return Double(cgFloat)
        } else if let int = value as? Int {
            return Double(int)
        } else {
            debugLog("⚠️ Could not convert \(key) to Double, value: \(value), type: \(Swift.type(of: value))")
            return defaultValue
        }
    }
    
    /// Safely gets a Color from properties, handling both Color objects and semantic color strings
    func getColor(key: String, defaultValue: Color = .primary) -> Color {
        guard let value = properties[key] else { return defaultValue }
        
        if let color = value as? Color {
            return color
        } else if let colorString = value as? String {
            // Handle prefix if present
            let cleanString = colorString.hasPrefix("color:") ? String(colorString.dropFirst(6)) : colorString
            return ComponentProperty.colorStringToColor(cleanString)
        }
        
        return defaultValue
    }
    
    func getGradient(key: String) -> LinearGradient? {
        guard let dict = properties[key] as? [String: Any] else { return nil }
        
        let colors = (dict["colors"] as? [Any] ?? []).map { val -> Color in
            if let str = val as? String {
                return ComponentProperty.colorStringToColor(str.hasPrefix("color:") ? String(str.dropFirst(6)) : str)
            }
            return val as? Color ?? .clear
        }
        
        // Ensure we have at least 2 colors for a gradient
        guard colors.count >= 2 else { return nil }
        
        let startPoint = unitPointFromString(dict["startPoint"] as? String ?? "top")
        let endPoint = unitPointFromString(dict["endPoint"] as? String ?? "bottom")
        
        return LinearGradient(gradient: Gradient(colors: colors), startPoint: startPoint, endPoint: endPoint)
    }
    
    private func unitPointFromString(_ str: String) -> UnitPoint {
        switch str.lowercased() {
        case "top": return .top
        case "bottom": return .bottom
        case "leading": return .leading
        case "trailing": return .trailing
        case "topleading": return .topLeading
        case "toptrailing": return .topTrailing
        case "bottomleading": return .bottomLeading
        case "bottomtrailing": return .bottomTrailing
        default: return .center
        }
    }
}
