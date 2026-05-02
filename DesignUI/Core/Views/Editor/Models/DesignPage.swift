//
//  DesignPage.swift
//
//  Created by Maicol Cabreja on 1/18/26.
//

import SwiftUI
import Foundation

/// Represents a single page/screen within a design file.
/// Each page has its own components, device preset, color scheme, and status bar settings.
class DesignPage: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published var name: String
    @Published var components: [UIComponent]
    @Published var thumbnail: Data?  // Screenshot thumbnail for page preview
    
    // Per-page canvas settings
    @Published var devicePreset: String?  // e.g., "iPhone 16 Pro"
    @Published var colorScheme: String?   // "light", "dark", or nil for system
    @Published var statusBarVisible: Bool
    @Published var statusBarTopSafeArea: Bool
    @Published var statusBarComponent: UIComponent? // Persisted Canvas Settings
    
    init(id: UUID = UUID(), name: String = "Page 1", components: [UIComponent] = [], thumbnail: Data? = nil, devicePreset: String? = nil, colorScheme: String? = nil, statusBarVisible: Bool = true, statusBarTopSafeArea: Bool = true, statusBarComponent: UIComponent? = nil) {
        self.id = id
        self.name = name
        self.components = components
        self.thumbnail = thumbnail
        self.devicePreset = devicePreset
        self.colorScheme = colorScheme
        self.statusBarVisible = statusBarVisible
        self.statusBarTopSafeArea = statusBarTopSafeArea
        self.statusBarComponent = statusBarComponent
    }
        
    enum CodingKeys: String, CodingKey {
        case id, name, components, thumbnail, devicePreset, colorScheme, statusBarVisible, statusBarTopSafeArea, statusBarComponent
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        components = try container.decode([UIComponent].self, forKey: .components)
        thumbnail = try container.decodeIfPresent(Data.self, forKey: .thumbnail)
        devicePreset = try container.decodeIfPresent(String.self, forKey: .devicePreset)
        colorScheme = try container.decodeIfPresent(String.self, forKey: .colorScheme)
        statusBarVisible = try container.decodeIfPresent(Bool.self, forKey: .statusBarVisible) ?? true
        statusBarTopSafeArea = try container.decodeIfPresent(Bool.self, forKey: .statusBarTopSafeArea) ?? true
        statusBarComponent = try container.decodeIfPresent(UIComponent.self, forKey: .statusBarComponent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(components, forKey: .components)
        try container.encodeIfPresent(thumbnail, forKey: .thumbnail)
        try container.encodeIfPresent(devicePreset, forKey: .devicePreset)
        try container.encodeIfPresent(colorScheme, forKey: .colorScheme)
        try container.encode(statusBarVisible, forKey: .statusBarVisible)
        try container.encode(statusBarTopSafeArea, forKey: .statusBarTopSafeArea)
        try container.encodeIfPresent(statusBarComponent, forKey: .statusBarComponent)
    }
        
    static func == (lhs: DesignPage, rhs: DesignPage) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.name == rhs.name else { return false }
        guard lhs.components == rhs.components else { return false }
        guard lhs.thumbnail == rhs.thumbnail else { return false }
        guard lhs.devicePreset == rhs.devicePreset else { return false }
        guard lhs.colorScheme == rhs.colorScheme else { return false }
        guard lhs.statusBarVisible == rhs.statusBarVisible else { return false }
        guard lhs.statusBarTopSafeArea == rhs.statusBarTopSafeArea else { return false }
        return statusBarComponentMatches(lhs.statusBarComponent, rhs.statusBarComponent)
    }

    private static func statusBarComponentMatches(_ lhs: UIComponent?, _ rhs: UIComponent?) -> Bool {
        lhs?.id == rhs?.id &&
        lhs?.properties.count == rhs?.properties.count // Shallow check
    }
        
    /// Creates a deep copy of this page with a new ID and optional name suffix
    func clone(withName newName: String? = nil) -> DesignPage {
        // Deep copy components using their clone method
        let clonedComponents = components.map { $0.clone() }
        let clonedStatusBar = statusBarComponent?.clone()
        
        return DesignPage(
            id: UUID(),
            name: newName ?? "\(name) Copy",
            components: clonedComponents,
            thumbnail: thumbnail,
            devicePreset: devicePreset,
            colorScheme: colorScheme,
            statusBarVisible: statusBarVisible,
            statusBarTopSafeArea: statusBarTopSafeArea,
            statusBarComponent: clonedStatusBar
        )
    }
}
