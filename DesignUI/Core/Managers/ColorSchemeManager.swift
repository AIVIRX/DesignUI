//
//  ColorSchemeManager.swift
//
//  Created by Maicol Cabreja on 8/18/24.
//

import SwiftUI

enum AppColorScheme: String, CaseIterable {
    case system = "Auto"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system:
            return "Auto"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

class ColorSchemeManager: ObservableObject {
    @Published var currentScheme: AppColorScheme {
        didSet {
            UserDefaults.standard.set(currentScheme.rawValue, forKey: "appColorScheme")
            // Force a UI update when scheme changes
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    
    init() {
        let savedScheme = UserDefaults.standard.string(forKey: "appColorScheme") ?? AppColorScheme.system.rawValue
        self.currentScheme = AppColorScheme(rawValue: savedScheme) ?? .system
    }
}
