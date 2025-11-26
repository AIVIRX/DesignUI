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
    @StateObject private var designManager = DesignManager.shared

    
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
                .environmentObject(designManager)
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
            
            // Add Open File command
            CommandGroup(after: .newItem) {
                Button("Open Design File...") {
                    openDesignFile()
                }
                .keyboardShortcut("o", modifiers: .command)
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
        
        // Load the design file
        if let designFile = DesignFile.load(from: url) {
            print("✅ Successfully loaded design file: \(designFile.name)")
            
            // Check if file is already in the design manager's list
            if let existingFile = designManager.designFiles.first(where: { $0.fileURL == url }) {
                // File already exists in list, just open it
                designManager.openDesign(existingFile)
            } else {
                // File is new (opened from outside), add it to the list and open it
                DispatchQueue.main.async {
                    designManager.designFiles.append(designFile)
                    designManager.designFiles.sort { $0.lastModified > $1.lastModified }
                    designManager.openDesign(designFile)
                }
            }
        } else {
            print("❌ Failed to load design file from: \(url.path)")
        }
    }
    
    private func openDesignFile() {
        #if os(macOS)
        let panel = NSOpenPanel()
        // Use the registered UTType or fallback to filename extension
        if let dockuiType = UTType("com.maicol.dockui.design") {
            panel.allowedContentTypes = [dockuiType]
        } else if let dockuiType = UTType(filenameExtension: "dockui") {
            panel.allowedContentTypes = [dockuiType]
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "Open Design File"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                handleFileOpening(url: url)
            }
        }
        #endif
    }
}
#endif
