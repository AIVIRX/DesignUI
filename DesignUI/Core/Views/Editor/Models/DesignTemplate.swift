//
//  DesignTemplate.swift
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
    let statusBarVisible: Bool? // Optional status bar visibility
    let statusBarTopSafeArea: Bool? // Optional top safe area setting
    let components: [UIComponent]
    
    enum CodingKeys: String, CodingKey {
        case name, description, thumbnail, devicePreset, canvasColorScheme, statusBarVisible, statusBarTopSafeArea, components
    }
    
    init(name: String, description: String, thumbnail: String, devicePreset: String?, canvasColorScheme: String? = nil, statusBarVisible: Bool? = nil, statusBarTopSafeArea: Bool? = nil, components: [UIComponent]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.devicePreset = devicePreset
        self.canvasColorScheme = canvasColorScheme
        self.statusBarVisible = statusBarVisible
        self.statusBarTopSafeArea = statusBarTopSafeArea
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
        self.statusBarVisible = try container.decodeIfPresent(Bool.self, forKey: .statusBarVisible)
        self.statusBarTopSafeArea = try container.decodeIfPresent(Bool.self, forKey: .statusBarTopSafeArea)
        self.components = try container.decode([UIComponent].self, forKey: .components)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(devicePreset, forKey: .devicePreset)
        try container.encodeIfPresent(canvasColorScheme, forKey: .canvasColorScheme)
        try container.encodeIfPresent(statusBarVisible, forKey: .statusBarVisible)
        try container.encodeIfPresent(statusBarTopSafeArea, forKey: .statusBarTopSafeArea)
        try container.encode(components, forKey: .components)
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
            "wallet",
            "introducing_features",
            "flight_status_widget",
            "rideshare",
        ]
        
        for filename in templateFiles {
            if let template = loadTemplate(named: filename) {
                templates.append(template)
            } else {
                debugLog("⚠️ Failed to load template: \(filename)")
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
            debugLog("⚠️ Template file not found: \(filename).json")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileUrl)
            let template = try JSONDecoder().decode(DesignTemplate.self, from: data)
            debugLog("✅ Loaded template: \(filename)")
            return template
        } catch let DecodingError.keyNotFound(key, context) {
            debugLog("⚠️ Template \(filename): Key '\(key.stringValue)' not found at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch let DecodingError.typeMismatch(type, context) {
            debugLog("⚠️ Template \(filename): Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch let DecodingError.valueNotFound(type, context) {
            debugLog("⚠️ Template \(filename): Value not found for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch let DecodingError.dataCorrupted(context) {
            debugLog("⚠️ Template \(filename): Data corrupted at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            return nil
        } catch {
            debugLog("⚠️ Error decoding template \(filename): \(error)")
            return nil
        }
    }
    
}
