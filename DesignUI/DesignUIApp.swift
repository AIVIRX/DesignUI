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
    
    init() {
        // Reset review manager for new session and start 30-second timer
        ReviewManager.shared.resetForNewSession()
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
        
        // Configure SDWebImage cache limits to prevent memory issues
        // Limit memory cache to 20MB (aggressive limit)
        SDImageCache.shared.config.maxMemoryCost = 20 * 1024 * 1024 // 20MB
        // Limit memory cache to 30 images max (very aggressive)
        SDImageCache.shared.config.maxMemoryCount = 30
        // Enable auto-cleanup when memory warning
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        // Set disk cache limit to 100MB
        SDImageCache.shared.config.maxDiskAge = 3600 * 24 * 3 // 3 days
        SDImageCache.shared.config.maxDiskSize = 100 * 1024 * 1024 // 100MB
        
        // Configure image decoder to use lower memory footprint
        SDImageCodersManager.shared.addCoder(SDImageIOCoder.shared)
        
        // Set default options for all image loads
        SDWebImageManager.shared.optionsProcessor = SDWebImageOptionsProcessor { url, options, context in
            var mutableOptions = options
            // Decode images on background thread to reduce main thread memory pressure
            mutableOptions.insert(.decodeFirstFrameOnly)
            // Scale down large images
            mutableOptions.insert(.scaleDownLargeImages)
            return SDWebImageOptionsResult(options: mutableOptions, context: context)
        }
        
        // Listen for memory warnings and clear cache aggressively
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Clear memory cache immediately on memory warning
            SDImageCache.shared.clearMemory()
            // Also clean up expired disk cache
            SDImageCache.shared.deleteOldFiles { _ in }
        }
        
        // More aggressive periodic cleanup every 30 seconds
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            // Clear memory cache more frequently to prevent gradual growth
            SDImageCache.shared.clearMemory()
        }
        #endif
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
        
        // Note: macOS doesn't have memory warning notifications like iOS
        // Add more aggressive periodic cleanup to prevent gradual memory growth
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            // Clear memory cache more frequently to prevent gradual growth
            SDImageCache.shared.clearMemory()
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
