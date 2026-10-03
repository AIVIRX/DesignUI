// Minimal editor data adapters; compile alongside the production generators.
import SwiftUI

enum ComponentType: String, CaseIterable {
    case text = "Text", image = "Image", sfSymbol = "SF Symbol", stack = "Stack"
    case vstack = "VStack", hstack = "HStack", zstack = "ZStack", spacer = "Spacer"
    case divider = "Divider", rectangle = "Rectangle", circle = "Circle"
    case roundedRectangle = "RoundedRectangle", capsule = "Capsule", ellipse = "Ellipse"
    case linearGradient = "Linear Gradient", scrollView = "ScrollView", statusBar = "Status Bar"
    case textField = "Text Field", toggle = "Switch", slider = "Slider"
    case progressView = "Progress View", chart = "Chart", shape = "Shape", button = "Button"
    case gauge = "Gauge", map = "Map"
}
enum ModifierType: String, CaseIterable {
    case frame = "Frame", padding = "Padding", backgroundColor = "Background Color"
    case background = "Background", foregroundColor = "Foreground Color", font = "Font"
    case cornerRadius = "Corner Radius", shadow = "Shadow", opacity = "Opacity"
    case rotation = "Rotation", offset = "Offset", clipShape = "Clip Shape", mask = "Mask"
    case blur = "Blur", overlay = "Overlay", border = "Border", stroke = "Stroke"
    case textAlignment = "Text Alignment", fill = "Fill", tint = "Tint", glassEffect = "Glass Effect"
}
struct ComponentModifier {
    var id = UUID()
    var type: ModifierType
    var properties: [String: Any] = [:]
    func getDouble(key: String, defaultValue: Double) -> Double { properties[key] as? Double ?? defaultValue }
    func getCGFloat(key: String, defaultValue: CGFloat) -> CGFloat {
        CGFloat(properties[key] as? Double ?? Double(defaultValue))
    }
}
final class UIComponent {
    var type: ComponentType
    var properties: [String: Any]
    var modifiers: [ComponentModifier]
    var children: [UIComponent]
    var modifierType: ModifierType? = nil
    var modifierId: UUID? = nil
    var modifierContent: [UUID: UIComponent] = [:]
    init(_ type: ComponentType, _ properties: [String: Any] = [:], modifiers: [ComponentModifier] = [], children: [UIComponent] = []) {
        self.type = type; self.properties = properties; self.modifiers = modifiers; self.children = children
    }
    func getProperty(key: String) -> Any? { properties[key] }
    func getBoolProperty(key: String, defaultValue: Bool) -> Bool { properties[key] as? Bool ?? defaultValue }
    func getParentComponentForModifier(_ id: UUID) -> UIComponent? { modifierContent[id] }
}
enum ComponentProperty {
    // The compiler tests use production color token export, not this RGB fallback.
    static func colorStringToColor(_ token: String) -> Color { .blue }
}

@main
struct CodegenRegression {
    static func decode(_ json: [String: Any]) -> UIComponent {
        guard let raw = json["type"] as? String, let type = ComponentType(rawValue: raw) else {
            fatalError("Unrecognized component in fixture: \(json)")
        }
        let modifiers = (json["modifiers"] as? [[String: Any]] ?? []).map { item -> ComponentModifier in
            guard let type = ModifierType(rawValue: item["type"] as? String ?? "") else { fatalError("Unknown modifier") }
            return ComponentModifier(type: type, properties: item["properties"] as? [String: Any] ?? [:])
        }
        return UIComponent(type, json["properties"] as? [String: Any] ?? [:], modifiers: modifiers,
                           children: (json["children"] as? [[String: Any]] ?? []).map(decode))
    }
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        var cases = ComponentType.allCases.map { UIComponent($0) }
        let tricky = "Line one\n\"quoted\" \\path \\(literal) 😄"
        cases += [UIComponent(.text, ["text": tricky]), UIComponent(.textField, ["placeholder": tricky, "text": tricky])]
        cases.append(UIComponent(.image, ["imageName": "https://example.com/photo.jpg", "aspectRatio": "fill"]))
        for size in ["24", "title", "body"] {
            cases.append(UIComponent(.text, modifiers: [ComponentModifier(type: .font, properties: ["fontSize": size, "fontDesign": "rounded", "fontWeight": "bold"])]))
        }
        for type in [ModifierType.background, .overlay, .mask] {
            let modifier = ComponentModifier(type: type)
            let child = UIComponent(.text, ["text": "Unique modifier child"])
            child.modifierId = modifier.id
            let parent = UIComponent(.vstack, modifiers: [modifier], children: [UIComponent(.text), child])
            parent.modifierContent[modifier.id] = child
            let source = CodeGenerator.generateCode(for: parent, indentLevel: 0)
            precondition(source.components(separatedBy: "Unique modifier child").count == 2, "Modifier content exported more than once")
            cases.append(parent)
        }
        for width in ["Default", "Full", "Custom"] {
            for height in ["Default", "Full", "Custom"] {
                cases.append(UIComponent(.rectangle, modifiers: [
                    ComponentModifier(type: .frame, properties: ["widthType": width, "heightType": height, "width": 40.0, "height": 60.0]),
                    ComponentModifier(type: .stroke, properties: ["color": "#123456:0.4"])
                ]))
            }
        }
        for token in ["#123456", "#12345678:0.4", "systemBackground:1", "tertiary:0.5", "blue:0.4"] {
            cases.append(UIComponent(.text, modifiers: [ComponentModifier(type: .foregroundColor, properties: ["color": token])]))
            cases.append(UIComponent(.chart, ["chartStyle": "Bar"], modifiers: [ComponentModifier(type: .fill, properties: ["color": token])]))
        }
        for style in ["Line", "Area", "Line + Area", "Bar", "Stacked Bar", "Donut", "Sparkline"] {
            cases.append(UIComponent(.chart, ["chartStyle": style, "showGoal": true, "showGrid": true]))
        }
        for modifier in ModifierType.allCases {
            cases.append(UIComponent(.rectangle, modifiers: [ComponentModifier(type: modifier)]))
        }
        let map = UIComponent(.map, [
            "markers": "[{\"latitude\":40.8447,\"longitude\":-73.9143,\"title\":\"Pickup\",\"tint\":\"white:1.0\"}]",
            "mapStyle": "hybrid", "showsTraffic": true, "showsCompass": true,
            "showsScale": true, "showsPitchToggle": true, "showsUserLocation": true, "showsUserLocationButton": true
        ])
        let mapCode = CodeGenerator.generateCode(for: map, indentLevel: 0)
        precondition(mapCode.contains("Marker(\"Pickup\"") && mapCode.contains("UserAnnotation()") && !mapCode.contains("// Markers"))
        cases.append(map)
        precondition(CodeGenerator.generateCode(for: UIComponent(.text, ["text": tricky]), indentLevel: 0) == "Text(\(String(reflecting: tricky)))")
        let fixtureDirectory = URL(fileURLWithPath: "tests/visual/fixtures")
        for file in try FileManager.default.contentsOfDirectory(at: fixtureDirectory, includingPropertiesForKeys: nil) where file.pathExtension == "json" {
            let json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
            cases += (json["components"] as? [[String: Any]] ?? []).map(decode)
        }
        for (index, component) in cases.enumerated() {
            let source = "import SwiftUI\nimport Charts\nimport MapKit\nstruct Export\(index): View {\nvar body: some View {\n\(CodeGenerator.generateCode(for: component, indentLevel: 1))\n}\n}\n"
            try source.write(to: output.appendingPathComponent("Export\(index).swift"), atomically: true, encoding: .utf8)
        }
        print("Generated \(cases.count) regression exports using the production code generator.")
    }
}
