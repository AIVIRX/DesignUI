//
//  DesignUIApp.swift
//  DockUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import Supabase
import RevenueCat
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
    
    init() {
        // Reset review manager for new session and start 30-second timer
        ReviewManager.shared.resetForNewSession()
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
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
    
    
    init() {
        UserDefaults.standard.set(0, forKey: "selectedIndex")
        
        // Reset review manager for new session and start 30-second timer
        ReviewManager.shared.resetForNewSession()
        
        // Configure RevenueCat for macOS
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_NcISLizYLMfgkTRcyMMCXrbTBFC")
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
        
        // Register custom document type
        registerDocumentType()
    }
    
    private func registerDocumentType() {
        // Verify the document type is registered (it's declared in Info.plist)
        // The type identifier is: com.maicol.dockui.design
        if let dockuiType = UTType("com.maicol.dockui.design") {
            print("✅ Document type registered: \(dockuiType.identifier)")
        } else {
            print("⚠️ Document type not found, but Info.plist should handle it")
        }
    }
    
    var body: some Scene {
        // Main app window - this opens by default
        WindowGroup("DesignUI") {
            ContentView()
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .environmentObject(subscriptionManager)
                .environmentObject(paywallManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .frame(minWidth: 1000, minHeight: 600)
                .onOpenURL { url in
                    handleFileOpening(url: url)
                }
        }
        .windowStyle(DefaultWindowStyle())
        .windowResizability(.automatic)
        .defaultSize(width: 1200, height: 800)
        .commands {
            // Add keyboard shortcuts via Commands API
            CommandGroup(replacing: .undoRedo) {
                // This replaces the default undo/redo with our custom handlers
                // But we'll handle it in the view instead
            }
        }
    }
    
    private func handleFileOpening(url: URL) {
        print("📂 Opening file from URL: \(url.path)")
        
        // Check if file exists and is a .dockui file
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ File does not exist: \(url.path)")
            return
        }
        
        guard url.pathExtension.lowercased() == "dockui" else {
            print("❌ File is not a .dockui file: \(url.pathExtension)")
            return
        }
    }
}
#endif
