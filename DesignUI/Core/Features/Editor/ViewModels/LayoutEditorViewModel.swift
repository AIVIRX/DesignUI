import SwiftUI
import Combine

class LayoutEditorViewModel: ObservableObject {
    @Published var rootComponent: UIComponent
    
    init(rootComponent: UIComponent? = nil) {
        self.rootComponent = rootComponent ?? UIComponent(
            type: .vstack,
            size: CGSize(width: 400, height: 600),
            children: []
        )
    }
    
    func saveToJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(rootComponent)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    func loadFromJSON(_ jsonString: String) throws {
        let decoder = JSONDecoder()
        let data = jsonString.data(using: .utf8)!
        rootComponent = try decoder.decode(UIComponent.self, from: data)
    }
    
    // Example layout for testing
    static var exampleLayout: UIComponent {
        UIComponent(
            type: .vstack,
            position: CGPoint(x: 200, y: 300),
            size: CGSize(width: 400, height: 600),
            children: [
                UIComponent(
                    type: .text,
                    position: .zero,
                    size: CGSize(width: 200, height: 50),
                    textContent: "Hello, Layout Editor!",
                    style: StyleProperties(
                        foregroundColor: .blue,
                        padding: 8,
                        alignment: .center
                    )
                ),
                UIComponent(
                    type: .rectangle,
                    position: .zero,
                    size: CGSize(width: 200, height: 100),
                    style: StyleProperties(
                        backgroundColor: .red,
                        cornerRadius: 8,
                        padding: 16
                    )
                )
            ],
            style: StyleProperties(
                backgroundColor: .gray.opacity(0.1),
                padding: 16,
                spacing: 20
            )
        )
    }
} 