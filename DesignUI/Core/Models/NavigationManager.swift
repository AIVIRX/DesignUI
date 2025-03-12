//
//  NavigationManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/3/25.
//

import SwiftUI

class NavigationManager: ObservableObject {
    @Published var selectedTab: Int = 0
    
    func navigateToSignIn() {
        selectedTab = 1  // Or whatever index represents your sign-in view
        // Additional macOS-specific navigation logic if needed
    }
}
