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
}

func addDynamicQuickActions() {
    // Quick action info for feedback
    var homeInfo: [String: NSSecureCoding] {
        return ["name": "explore" as NSSecureCoding]
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
    ]
}
#endif
