import Foundation

struct DesignPatternTemplate: Decodable, Identifiable {
    let id: String
    let name: String
    let component: UIComponent
}

enum DesignPatternCatalog {
    static let templates: [DesignPatternTemplate] = {
        guard let url = Bundle.main.url(forResource: "design-patterns", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode([DesignPatternTemplate].self, from: data) else { return [] }
        return templates
    }()
}
