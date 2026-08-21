//
//  ContentView.swift
//
//  Created by Maicol Cabreja on 8/18/24.
//

import SwiftUI
import Foundation
import RevenueCat
import RevenueCatUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @EnvironmentObject private var designManager: DesignManager
    @State private var selectedTab: Tabs = .home
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    enum Tabs: Hashable {
        case home
        case news
        case symbols
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

            Tab("SF Symbols", systemImage: "sparkles", value: .symbols) {
                SFIconsView()
            }
            
            Tab("Account", systemImage: "person", value: .profile) {
                ProfileContainerView()
            }
        }
        .toast($toastManager.currentToast)
#if os(iOS)
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    UIDevice.current.userInterfaceIdiom == .phone && !hasSeenOnboarding
                },
                set: { newValue in
                    if !newValue { hasSeenOnboarding = true }
                }
            )
        ) {
            OnboardingFlowView(
                title: "Welcome to DockUI",
                description: "Build interfaces faster with smart components and real-time previews.",
                logo: "AppLogo",
                carousel: [
                    .init(text: "Design", image: "AppLogo"),
                    .init(text: "Preview", image: "AppLogo"),
                    .init(text: "Ship", image: "AppLogo"),
                    .init(text: "Export", image: "AppLogo"),
                    .init(text: "Iterate", image: "AppLogo"),
                ],
                form: [
                    FormStep(
                        icon: "wand.and.stars",
                        title: "Create Faster",
                        description: "Generate UI ideas quickly with reusable components.",
                        type: .button(title: "Continue", icon: "arrow.right"),
                        gradient: (.indigo, .indigo, .indigo),
                        onSubmit: { _ in }
                    ),
                    FormStep(
                        icon: "square.grid.2x2",
                        title: "Build Screens",
                        description: "Compose layouts with drag-and-drop layers.",
                        type: .button(title: "Continue", icon: "arrow.right"),
                        gradient: (.cyan, .cyan, .cyan),
                        onSubmit: { _ in }
                    ),
                    FormStep(
                        icon: "square.and.arrow.up",
                        title: "Export Quickly",
                        description: "Save screenshots and copy code when your design is ready.",
                        type: .button(title: "Continue", icon: "arrow.right"),
                        gradient: (.green, .green, .green),
                        onSubmit: { _ in }
                    ),
                ],
                completion: CompletionStep(
                    title: "Setting things up",
                    description: "Finalizing your workspace.",
                    completionTitle: "All set",
                    completionDescription: "You are ready to design.",
                    onSubmit: {
                        try? await Task.sleep(nanoseconds: 400_000_000)
                    },
                    onComplete: {
                        hasSeenOnboarding = true
                        DispatchQueue.main.async {
                            paywallManager.present()
                        }
                    }
                )
            )
        }
        .fullScreenCover(isPresented: Binding(
            get: { designManager.currentDesign != nil },
            set: { if !$0 { designManager.closeCurrentDesign() } }
        )) {
            if let currentDesign = designManager.currentDesign {
                EditorLoadingView(designFile: currentDesign)
                    .environmentObject(designManager)
            }
        }
#endif
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
