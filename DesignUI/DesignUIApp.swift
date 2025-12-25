//
//  DesignUIApp.swift
//  DockUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import Supabase
import RevenueCat
import SDWebImage
#if os(iOS)
import AppTrackingTransparency
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                    if #available(iOS 14, *) {
                        ATTrackingManager.requestTrackingAuthorization { status in
                            switch status {
                            case .authorized:
                                MobileAds.shared.start(completionHandler: nil)
                            case .denied:
                                MobileAds.shared.start(completionHandler: nil)
                            default:
                                MobileAds.shared.start(completionHandler: nil)
                            }
                        }
                    } else {
                        MobileAds.shared.start(completionHandler: nil)
                    }
                })
        
        UserDefaults.standard.set(0, forKey: "selectedIndex")
        
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_NcISLizYLMfgkTRcyMMCXrbTBFC")
        
        return true
    }
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let client = SupabaseManager.shared.client
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var paywallManager = PaywallManager.shared
    @StateObject private var designManager = DesignManager.shared
    
    init() {
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
        
        // Configure SDWebImage cache limits to prevent memory issues
        // Limit memory cache to 30MB (default is unlimited)
        SDImageCache.shared.config.maxMemoryCost = 30 * 1024 * 1024 // 30MB
        // Limit memory cache to 50 images max
        SDImageCache.shared.config.maxMemoryCount = 50
        // Enable auto-cleanup when memory warning
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        // Set disk cache limit to 200MB
        SDImageCache.shared.config.maxDiskAge = 3600 * 24 * 7 // 7 days
        SDImageCache.shared.config.maxDiskSize = 200 * 1024 * 1024 // 200MB
        
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            SDImageCache.shared.clearMemory()
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
                .environmentObject(designManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .onAppear {
                    print("App launched with color scheme: \(colorSchemeManager.currentScheme.displayName)")
                }
        }
    }
}
#endif

#if os(macOS)
import UniformTypeIdentifiers
import AppKit

@main
struct DesignUIApp: App {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var paywallManager = PaywallManager.shared
    @StateObject private var designManager = DesignManager.shared

    init() {
        UserDefaults.standard.set(0, forKey: "selectedIndex")
                
        // Configure RevenueCat for macOS
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_NcISLizYLMfgkTRcyMMCXrbTBFC")
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
        
        // Configure SDWebImage cache limits to prevent memory issues
        // Limit memory cache to 30MB (default is unlimited)
        SDImageCache.shared.config.maxMemoryCost = 30 * 1024 * 1024 // 30MB
        // Limit memory cache to 50 images max
        SDImageCache.shared.config.maxMemoryCount = 50
        // Enable auto-cleanup when memory warning
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        // Set disk cache limit to 200MB
        SDImageCache.shared.config.maxDiskAge = 3600 * 24 * 7 // 7 days
        SDImageCache.shared.config.maxDiskSize = 200 * 1024 * 1024 // 200MB
        
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            SDImageCache.shared.clearMemory()
        }
    }

    
    var body: some Scene {
        // Main app window - this opens by default
        WindowGroup {
            ContentView()
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
                .environmentObject(designManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .frame(minWidth: 1000, minHeight: 600)
        }
        .windowStyle(DefaultWindowStyle())
        .windowResizability(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Standard Edit menu (Cut, Copy, Paste, Select All, etc.)
            TextEditingCommands()
        }
    }
}
#endif
