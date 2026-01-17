//
//  Modifier.swift
//  DesignUI
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
    case scale = "Scale"
    case offset = "Offset"
    case clipShape = "Clip Shape"
    case mask = "Mask"
    case blur = "Blur"
    case overlay = "Overlay"
    case border = "Border"
    case textAlignment = "Text Alignment"
    case fill = "Fill"
    case aspectRatio = "Aspect Ratio"
    case zIndex = "Z Index"
    
    var id: String { rawValue }
    
    // Custom decoder to handle legacy modifier type names
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Handle legacy names
        switch rawValue {
        case "Font Size", "Font Weight":
            self = .font
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
        case .scale:
            return "Scales the view"
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
        case .textAlignment:
            return "Aligns text content"
        case .fill:
            return "Fills the view with a color"
        case .aspectRatio:
            return "Constrains the aspect ratio"
        case .zIndex:
            return "Controls stacking order"
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
        case .scale:
            return "arrow.up.left.and.arrow.down.right"
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
        case .textAlignment:
            return "text.alignleft"
        case .fill:
            return "paintbrush.fill"
        case .aspectRatio:
            return "aspectratio"
        case .zIndex:
            return "square.3.layers.3d.down.right"
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
        case .scale:
            defaultProperties = [
                "x": Double(1.0),
                "y": Double(1.0)
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
                "color": Color.black
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
        case .textAlignment:
            defaultProperties = [
                "alignment": "leading"
            ]
        case .fill:
            defaultProperties = [
                "color": "blue:1.0"
            ]
        case .aspectRatio:
            defaultProperties = [
                "aspectRatio": "fit"
            ]
        case .zIndex:
            defaultProperties = [
                "index": Double(1.0)
            ]
        }
        
        return ComponentModifier(type: type, properties: defaultProperties)
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, type, properties
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Preserve the original ID to maintain link to modifier children (overlay/mask/background)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.type = try container.decode(ModifierType.self, forKey: .type)
        
        // Decode properties as [String: Any]
        let propertiesDict = try container.decode([String: AnyCodable].self, forKey: .properties)
        self.properties = propertiesDict.mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        
        // Encode properties as [String: AnyCodable]
        let propertiesDict = properties.mapValues { AnyCodable($0) }
        try container.encode(propertiesDict, forKey: .properties)
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: ComponentModifier, rhs: ComponentModifier) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Helper Methods for Safe Type Conversion
    /// Safely converts a property value to CGFloat, handling CGFloat, Double, and Int from JSON decoding
    func getCGFloat(key: String, defaultValue: CGFloat = 0) -> CGFloat {
        guard let value = properties[key] else { return defaultValue }
        
        if let cgFloat = value as? CGFloat {
            return cgFloat
        } else if let double = value as? Double {
            return CGFloat(double)
        } else if let int = value as? Int {
            return CGFloat(int)
        } else {
            print("⚠️ Could not convert \(key) to CGFloat, value: \(value), type: \(Swift.type(of: value))")
            return defaultValue
        }
    }
    
    /// Safely converts a property value to Double, handling CGFloat, Double, and Int from JSON decoding
    func getDouble(key: String, defaultValue: Double = 0) -> Double {
        guard let value = properties[key] else { return defaultValue }
        
        if let double = value as? Double {
            return double
        } else if let cgFloat = value as? CGFloat {
            return Double(cgFloat)
        } else if let int = value as? Int {
            return Double(int)
        } else {
            print("⚠️ Could not convert \(key) to Double, value: \(value), type: \(Swift.type(of: value))")
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

// Helper for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            // Convert Double back to CGFloat for consistency
            value = CGFloat(double)
        } else if let colorDict = try? container.decode([String: Double].self) {
            // Decode Color from RGBA dictionary
            if let red = colorDict["red"],
               let green = colorDict["green"],
               let blue = colorDict["blue"],
               let alpha = colorDict["alpha"] {
                value = Color(red: red, green: green, blue: blue, opacity: alpha)
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid color data"))
            }
        } else if let string = try? container.decode(String.self) {
            // Preserve the string (including color: prefix if present)
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let cgFloat = value as? CGFloat {
            try container.encode(Double(cgFloat))
        } else if let color = value as? Color {
            // First, try to identify semantic colors and store as named strings
            let colorName = ComponentProperty.colorToColorString(color)
            if colorName != "primary" { // colorToColorString returns "primary" for unknown colors too
                // Check if it's a known semantic color by converting back
                let testColor = ComponentProperty.colorStringToColor(colorName)
                #if os(macOS)
                let originalRGBA = NSColor(color).rgbaComponents
                let testRGBA = NSColor(testColor).rgbaComponents
                // If the round-trip produces similar results, use the name
                if abs(originalRGBA.red - testRGBA.red) < 0.01 &&
                   abs(originalRGBA.green - testRGBA.green) < 0.01 &&
                   abs(originalRGBA.blue - testRGBA.blue) < 0.01 {
                    try container.encode("color:\(colorName)")
                    return
                }
                #endif
            }
            
            // Also check for semantic colors that can't be converted to RGB
            // Store these by name
            #if os(macOS)
            let uiColor = NSColor(color)
            if uiColor.usingColorSpace(.sRGB) == nil {
                // Can't convert to sRGB - likely a semantic color
                // Use the color name from colorToColorString
                try container.encode("color:\(colorName)")
                return
            }
            
            // Fallback: Encode as RGBA dictionary
            let rgba = uiColor.rgbaComponents
            try container.encode([
                "red": Double(rgba.red),
                "green": Double(rgba.green),
                "blue": Double(rgba.blue),
                "alpha": Double(rgba.alpha)
            ])
            #else
            // Fallback for non-macOS platforms
            try container.encode("color:\(colorName)")
            #endif
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else if value is UIComponent {
            // Special handling for UIComponent
            // We can't directly encode UIComponent here if AnyCodable is used inside UIComponent (circular).
            // But UIComponent is Codable, so we can try to encode it.
            // However, AnyCodable is a wrapper.
            // Let's encode it as a wrapper that uses the component's encoding.
            // Actually, simpler: Encode it as a dictionary if possible, or just let it fail if we can't easily wrap it.
            // Better approach: UIComponent conforms to Codable, so we can just encode it directly if the container supports it?
            // No, AnyCodable needs to know how to encode it.
            // Let's try to encode it using a nested encoder?
            // For now, let's assume we store components as dictionaries in properties when using AnyCodable.
            // If we pass a UIComponent instance, we might need to convert it to a dictionary first or handle it here.
            
            // Attempt to encode UIComponent by creating a new encoder? No.
            // Let's just throw for now and ensure we convert UIComponent to a dictionary before storing in properties if needed,
            // OR implement a specific case if we can.
            
            // Actually, we can try to encode it if we cast it to Encodable, but AnyCodable holds Any.
            // Let's try to check if it's UIComponent (which we did) and then encode it.
            // But we need to encode it into the container.
            // Since UIComponent is a class, we might need to wrap it.
            
            // Workaround: Encode as a dictionary representation
            // This is complex. Let's stick to storing simple types in properties for now.
            // For overlay, we might need to store the component data as a dictionary.
            
            print("⚠️ AnyCodable: UIComponent encoding not fully supported directly. Convert to dictionary first.")
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "UIComponent direct encoding not supported in AnyCodable yet"))
            
        } else {
            print("❌ AnyCodable encoding failed for unsupported type: \(Swift.type(of: value))")
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

// MARK: - NSColor Extension for RGBA Components
#if os(macOS)
extension NSColor {
    var rgbaComponents: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        // Convert to RGB color space first to avoid color space issues
        if let rgbColor = self.usingColorSpace(.sRGB) {
            rgbColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        } else {
            // Fallback for colors that can't be converted to RGB
            // Use a default color (gray) to avoid crashes
            red = 0.5
            green = 0.5
            blue = 0.5
            alpha = 1.0
        }
        
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif
