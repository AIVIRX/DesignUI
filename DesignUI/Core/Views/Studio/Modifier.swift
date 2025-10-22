//
//  Modifier.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

enum ModifierType: String, CaseIterable, Identifiable, Codable {
    case frame = "Frame"
    case padding = "Padding"
    case background = "Background"
    case overlay = "Overlay"
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
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .frame:
            return "Changes width and height"
        case .padding:
            return "Adds padding to one or more sides"
        case .background:
            return "Adds elements behind"
        case .overlay:
            return "Adds elements on top"
        case .foregroundColor:
            return "Changes text and icon color"
        case .font:
            return "Changes text font and size"
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
        case .overlay:
            return "square.stack.3d.up"
        case .foregroundColor:
            return "paintbrush"
        case .font:
            return "textformat"
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
            return "theatermasks"
        case .blur:
            return "viewfinder"
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
                "style": "body",
                "size": CGFloat(16),
                "weight": "regular"
            ]
        case .overlay:
            defaultProperties = [
                "type": "color",
                "color": Color.clear,
                "text": "Overlay",
                "position": "topTrailing",
                "iconName": "star.fill"
            ]
        case .clipShape:
            defaultProperties = [
                "shape": "Rectangle"
            ]
        case .mask:
            defaultProperties = [
                "opacity": Double(1.0)
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
        
        // Decode properties as [String: Any]
        let propertiesDict = try container.decode([String: AnyCodable].self, forKey: .properties)
        self.properties = propertiesDict.mapValues { $0.value }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        
        // Encode properties as [String: AnyCodable]
        let propertiesDict = properties.mapValues { AnyCodable($0) }
        try container.encode(propertiesDict, forKey: .properties)
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: ComponentModifier, rhs: ComponentModifier) -> Bool {
        return lhs.id == rhs.id
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
            // Encode Color as a dictionary with RGBA values
            let uiColor = NSColor(color)
            let rgba = uiColor.rgbaComponents
            try container.encode([
                "red": Double(rgba.red),
                "green": Double(rgba.green),
                "blue": Double(rgba.blue),
                "alpha": Double(rgba.alpha)
            ])
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
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
        
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red: red, green: green, blue: blue, alpha: alpha)
    }
}
#endif
