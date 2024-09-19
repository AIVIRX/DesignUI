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
    case home = "com.Maicol.Dockui.Home"
    case search = "com.Maicol.Dockui.Search"
    case profile = "com.Maicol.Dockui.Profile"
}

func addDynamicQuickActions() {
    // Quick action info for feedback
    var homeInfo: [String: NSSecureCoding] {
        return ["name": "home" as NSSecureCoding]
    }
    
    var searchInfo: [String: NSSecureCoding] {
        return ["name": "search" as NSSecureCoding]
    }
    
    // Quick action info for rating
    var profileInfo: [String: NSSecureCoding] {
        return ["name": "profile" as NSSecureCoding]
    }
    
    // Define the shortcut items with relevant information.
    UIApplication.shared.shortcutItems = [
        UIApplicationShortcutItem(
            type: QuickAction.home.rawValue,
            localizedTitle: "Home",
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "house"),
            userInfo: homeInfo
        ),
        UIApplicationShortcutItem(
            type: QuickAction.search.rawValue,
            localizedTitle: "Search",
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "magnifyingglass"),
            userInfo: searchInfo
        ),
        UIApplicationShortcutItem(
            type: QuickAction.profile.rawValue,
            localizedTitle: "Profile",
            localizedSubtitle: "",
            icon: UIApplicationShortcutIcon(systemImageName: "person"),
            userInfo: profileInfo
        )
    ]
}
#endif
