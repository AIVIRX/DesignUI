//
//  QuickActionHelper.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/19/24.
//

#if os(iOS)
import SwiftUI

var shortcutItemToProcess: UIApplicationShortcutItem?

enum QuickAction: String {
    case explore = "com.Maicol.Dockui.Explore"
    case settings = "com.Maicol.Dockui.Settings"
}

func addDynamicQuickActions() {
    // Quick action info for feedback
    var homeInfo: [String: NSSecureCoding] {
        return ["name": "explore" as NSSecureCoding]
    }
    var settingsInfo: [String: NSSecureCoding] {
        return ["name": "settings" as NSSecureCoding]
    }
    
    // Define the shortcut items with relevant information.
    UIApplication.shared.shortcutItems = [
        UIApplicationShortcutItem(
            type: QuickAction.explore.rawValue,
            localizedTitle: "Explore",
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass"),
            userInfo: homeInfo
        ),
        UIApplicationShortcutItem(
            type: QuickAction.settings.rawValue,
            localizedTitle: "Settings",
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "gear"),
            userInfo: settingsInfo
        ),
    ]
}
#endif
