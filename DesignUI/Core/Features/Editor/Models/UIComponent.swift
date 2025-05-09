import SwiftUI

// Make CGPoint and CGSize Codable
extension CGPoint: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(Double.self, forKey: .x)
        let y = try container.decode(Double.self, forKey: .y)
        self.init(x: x, y: y)
    }
    
    private enum CodingKeys: String, CodingKey {
        case x, y
    }
}

extension CGSize: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(Double.self, forKey: .width)
        let height = try container.decode(Double.self, forKey: .height)
        self.init(width: width, height: height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case width, height
    }
}

// Component Type Enum
enum ComponentType: String, Codable {
    case text
    case rectangle
    case vstack
    case hstack
    case zstack
}

// Alignment Type
enum ComponentAlignment: String, Codable {
    case leading, center, trailing
    
    var swiftUIAlignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// Style Properties
struct StyleProperties: Codable {
    var backgroundColor: Color?
    var foregroundColor: Color?
    var cornerRadius: CGFloat?
    var padding: CGFloat?
    var alignment: ComponentAlignment?
    var spacing: CGFloat?
    
    enum CodingKeys: String, CodingKey {
        case backgroundColor, foregroundColor, cornerRadius, padding, alignment, spacing
    }
    
    // Custom coding for Color
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        backgroundColor = try container.decodeIfPresent(Color.self, forKey: .backgroundColor)
        foregroundColor = try container.decodeIfPresent(Color.self, forKey: .foregroundColor)
        cornerRadius = try container.decodeIfPresent(CGFloat.self, forKey: .cornerRadius)
        padding = try container.decodeIfPresent(CGFloat.self, forKey: .padding)
        alignment = try container.decodeIfPresent(ComponentAlignment.self, forKey: .alignment)
        spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
    }
}

// Main UIComponent struct
struct UIComponent: Identifiable, Codable {
    let id: String
    let type: ComponentType
    var position: CGPoint
    var size: CGSize
    var children: [UIComponent]?
    var textContent: String?
    var style: StyleProperties?
    
    init(
        id: String = UUID().uuidString,
        type: ComponentType,
        position: CGPoint = .zero,
        size: CGSize = .zero,
        children: [UIComponent]? = nil,
        textContent: String? = nil,
        style: StyleProperties? = nil
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        self.children = children
        self.textContent = textContent
        self.style = style
    }
} 