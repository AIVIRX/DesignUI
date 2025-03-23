//
//  EntitlementManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/14/25.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "group.Maicol.Dockui")!

    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false
}
