//
//  ContentView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 8/18/24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

struct ContentView: View {
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @StateObject private var authViewModel = AuthViewModel()
    @State private var selectedTab: Tabs = .home
    let client = SupabaseManager.shared.client
    
    enum Tabs: Hashable {
        case home
        case news
        case profile
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: .home) {
                DesignBrowserView()
            }
            
            Tab("News", systemImage: "newspaper", value: .news) {
                NewsListView()
            }
            
            Tab("Account", systemImage: "person", value: .profile) {
                ProfileContainerView()
            }
        }
        .toast($toastManager.currentToast)
        .sheet(isPresented: $paywallManager.isPresenting) {
            CustomPaywallView()
#if os(macOS)
                .frame(minWidth: 760, minHeight: 560)
#endif
                .onDisappear {
                    subscriptionManager.checkSubscriptionStatus()
                }
        }
    }
}
