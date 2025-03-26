//
//  EntitlementManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/14/25.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    // Conditional app group ID depending on the platform
       static let userDefaults: UserDefaults = {
           #if os(macOS)
           // macOS app group ID (without "group." prefix)
           return UserDefaults(suiteName: "5C778DVBP3.Maicol.dockui")!
           #else
           // iOS app group ID (with "group." prefix)
           return UserDefaults(suiteName: "group.5C778DVBP3.Maicol.dockui")!
           #endif
       }()
    
    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false
    
    @AppStorage("activeSubscriptionID", store: userDefaults)
    var activeSubscriptionID: String?
}

