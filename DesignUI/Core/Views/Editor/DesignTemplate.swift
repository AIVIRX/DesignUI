//
//  DesignTemplate.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

struct DesignTemplate: Identifiable, Codable {
    var id: UUID = UUID()
    let name: String
    let description: String
    let thumbnail: String // Image name for image
    let devicePreset: String? // Optional device preset for initial canvas size
    let canvasColorScheme: String? // Optional color scheme preference (light/dark)
    let components: [UIComponent]
    
    enum CodingKeys: String, CodingKey {
        case name, description, thumbnail, devicePreset, canvasColorScheme, components
    }
    
    init(name: String, description: String, thumbnail: String, devicePreset: String?, canvasColorScheme: String? = nil, components: [UIComponent]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.devicePreset = devicePreset
        self.canvasColorScheme = canvasColorScheme
        self.components = components
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.thumbnail = try container.decode(String.self, forKey: .thumbnail)
        self.devicePreset = try container.decodeIfPresent(String.self, forKey: .devicePreset)
        self.canvasColorScheme = try container.decodeIfPresent(String.self, forKey: .canvasColorScheme)
        self.components = try container.decode([UIComponent].self, forKey: .components)
    }
}

class DesignTemplateManager {
    static let shared = DesignTemplateManager()
    
    private var _templates: [DesignTemplate]?
    
    var templates: [DesignTemplate] {
        if let cached = _templates {
            return cached
        }
        let loaded = loadTemplates()
        _templates = loaded
        return loaded
    }
    
    private func loadTemplates() -> [DesignTemplate] {
        var templates: [DesignTemplate] = []
        
        // Load all templates from JSON files
        let templateFiles = [
            "blank",
            "introducing_features",
            "flight_status_widget"
        ]
        
        for filename in templateFiles {
            if let template = loadTemplate(named: filename) {
                templates.append(template)
            } else {
                print("⚠️ Failed to load template: \(filename)")
            }
        }
        
        return templates
    }
    
    private func loadTemplate(named filename: String) -> DesignTemplate? {
        // Try multiple paths since Xcode handles resources differently
        var url: URL?
        
        // Try with subdirectory first (for folder references)
        url = Bundle.main.url(forResource: filename, withExtension: "json", subdirectory: "Templates")
        
        // Try without subdirectory (for flattened resources)
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "json")
        }
        
        // Try finding in Resources/Templates path
        if url == nil {
            url = Bundle.main.url(forResource: "Templates/\(filename)", withExtension: "json")
        }
        
        guard let fileUrl = url else {
            print("⚠️ Template file not found: \(filename).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let template = try JSONDecoder().decode(DesignTemplate.self, from: data)
            print("✅ Loaded template: \(filename)")
            return template
        } catch let DecodingError.keyNotFound(key, context) {
            print("⚠️ Template \(filename): Key '\(key.stringValue)' not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            print("⚠️ Template \(filename): Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch let DecodingError.valueNotFound(type, context) {
            print("⚠️ Template \(filename): Value not found for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch let DecodingError.dataCorrupted(context) {
            print("⚠️ Template \(filename): Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch {
            print("⚠️ Error decoding template \(filename): \(error)")
            return nil
        }
    }
    
    func templates(for category: DesignTemplate) -> [DesignTemplate] {
        return templates
    }
}
