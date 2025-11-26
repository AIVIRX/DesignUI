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
    case background = "Background"
    case foregroundColor = "Foreground Color"
    case font = "Font Weight"
    case fontSize = "Font Size"
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
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .frame:
            return "Changes width and height"
        case .padding:
            return "Adds padding to one or more sides"
        case .background:
            return "Adds elements behind"
        case .foregroundColor:
            return "Changes text and icon color"
        case .font:
            return "Adjusts font weight"
        case .fontSize:
            return "Changes text size"
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
        }
    }
    
    var icon: String {
        switch self {
        case .frame:
            return "rectangle"
        case .padding:
            return "rectangle.inset.filled"
        case .background:
            return "square.stack.3d.down.right"
        case .foregroundColor:
            return "paintbrush"
        case .font:
            return "textformat"
        case .fontSize:
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
        case .background:
            defaultProperties = [
                "color": Color.clear
            ]
        case .foregroundColor:
            defaultProperties = [
                "color": Color.primary
            ]
        case .font:
            defaultProperties = [
                "fontWeight": "regular"
            ]
        case .fontSize:
            defaultProperties = [
                "fontSize": "body"
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
                "color": Color.blue
            ]
        }
        
        return ComponentModifier(type: type, properties: defaultProperties)
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case type, properties
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID() // Generate new ID for decoded instances
        self.type = try container.decode(ModifierType.self, forKey: .type)
        
        print("🔧 ComponentModifier decoding type: \(type)")
        
        // Decode properties as [String: Any]
        let propertiesDict = try container.decode([String: AnyCodable].self, forKey: .properties)
        self.properties = propertiesDict.mapValues { $0.value }
        
        print("🔧 ComponentModifier decoded properties: \(properties)")
        print("🔧 ComponentModifier decoded properties types: \(properties.mapValues { Swift.type(of: $0) })")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        print("🔧 ComponentModifier encoding type: \(type) with properties: \(properties)")
        
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
}

// Helper for encoding/decoding Any values
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        print("🔧 AnyCodable decoding from container")
        
        if let bool = try? container.decode(Bool.self) {
            print("🔧 Decoded Bool: \(bool)")
            value = bool
        } else if let int = try? container.decode(Int.self) {
            print("🔧 Decoded Int: \(int)")
            value = int
        } else if let double = try? container.decode(Double.self) {
            print("🔧 Decoded Double: \(double), converting to CGFloat")
            // Convert Double back to CGFloat for consistency
            value = CGFloat(double)
        } else if let colorDict = try? container.decode([String: Double].self) {
            print("🔧 Decoded Color dict: \(colorDict)")
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
            print("🔧 Decoded String: \(string)")
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            print("🔧 Decoded Array")
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            print("🔧 Decoded Dictionary")
            value = dict.mapValues { $0.value }
        } else {
            // Try to decode as UIComponent if possible (recursive structure)
            // Note: We can't directly decode UIComponent here easily without circular dependency issues or complex type erasure.
            // Instead, we rely on the dictionary decoding above to handle nested structures if they are encoded as dictionaries.
            // If UIComponent encodes itself as a container of properties, it might be caught by the dictionary case.
            
            print("❌ AnyCodable decoding failed - unsupported type")
            throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        print("🔧 AnyCodable encoding value: \(value) of type: \(Swift.type(of: value))")
        
        if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let cgFloat = value as? CGFloat {
            try container.encode(Double(cgFloat))
        } else if let color = value as? Color {
            // Encode Color as a dictionary with RGBA values
            #if os(macOS)
            let uiColor = NSColor(color)
            let rgba = uiColor.rgbaComponents
            try container.encode([
                "red": Double(rgba.red),
                "green": Double(rgba.green),
                "blue": Double(rgba.blue),
                "alpha": Double(rgba.alpha)
            ])
            #else
            // Fallback for non-macOS platforms
            try container.encode([
                "red": Double(0.0),
                "green": Double(0.0),
                "blue": Double(0.0),
                "alpha": Double(1.0)
            ])
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
