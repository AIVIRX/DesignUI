//
//  DesignUIApp.swift
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import Supabase
import RevenueCat
import SDWebImage

#if os(iOS)
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Purchases.configure(withAPIKey: "appl_NcISLizYLMfgkTRcyMMCXrbTBFC")
        
        return true
    }
}

#if !DESIGNUI_VISUAL_TEST
@main
#endif
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var paywallManager = PaywallManager.shared
    @StateObject private var designManager = DesignManager.shared
    
    init() {
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
        SDImageCache.shared.config.maxMemoryCost = 15 * 1024 * 1024 // 15MB Limit memory cache to 15MB for lower memory footprint
        SDImageCache.shared.config.maxMemoryCount = 30 // Limit memory cache to 30 images max (keeps recent images, evicts old ones)
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true // Enable auto-cleanup when memory warning
        SDImageCache.shared.config.maxDiskAge = 3600 * 24 * 7 // 7 days
        SDImageCache.shared.config.maxDiskSize = 200 * 1024 * 1024 // Set disk cache limit to 200MB
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
                .onOpenURL { url in
                    // Handle custom URL scheme (app open)
                    if url.scheme == "dockui" {
                        return
                    }
                    guard url.isFileURL else { return }
                    
                    let success = url.startAccessingSecurityScopedResource()
                    guard success else {
                        print("❌ Failed to access security scoped resource")
                        return
                    }
                    
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    
                    print("📂 Opening file: \(url.path)")

                    designManager.handleOpenURL(url) { design in
                        DispatchQueue.main.async {
                            if let design = design {
                                toastManager.showToast(ToastData(title: "Opened", icon: "checkmark.circle.fill"))
                                designManager.openDesign(design)
                            } else {
                                toastManager.showToast(ToastData(title: "Failed", icon: "xmark.circle.fill"))
                            }
                        }
                    }
                }
        }
    }
}
#endif

#if os(macOS)
import UniformTypeIdentifiers
import Foundation

#if !DESIGNUI_VISUAL_TEST
@main
#endif
struct DesignUIApp: App {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @StateObject private var paywallManager = PaywallManager.shared
    @StateObject private var designManager = DesignManager.shared
    
    init() {
        // Configure RevenueCat for macOS
        //Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_NcISLizYLMfgkTRcyMMCXrbTBFC")
        // Ensure paywall is not shown on launch
        PaywallManager.shared.isPresenting = false
        
        // Configure SDWebImage cache limits to prevent memory issues
        // Limit memory cache to 15MB for lower memory footprint
        SDImageCache.shared.config.maxMemoryCost = 15 * 1024 * 1024 // 15MB
        // Limit memory cache to 30 images max (keeps recent images, evicts old ones)
        SDImageCache.shared.config.maxMemoryCount = 30
        // Enable auto-cleanup when memory warning
        SDImageCache.shared.config.shouldUseWeakMemoryCache = true
        // Set disk cache limit to 200MB
        SDImageCache.shared.config.maxDiskAge = 3600 * 24 * 3 // 3 days
        SDImageCache.shared.config.maxDiskSize = 200 * 1024 * 1024 // 200MB
    }
    
    var body: some Scene {
        // Main app window
            // Main app window
            WindowGroup {
                WindowToastContainer {
                    MainWindow()
                        .environmentObject(colorSchemeManager)
                        .environmentObject(subscriptionManager)
                        .environmentObject(paywallManager)
                        .environmentObject(designManager)
                        .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                        .frame(minWidth: 1200, minHeight: 750)
                }
            }
            .windowResizability(.automatic)
            .windowStyle(.hiddenTitleBar)
            .defaultSize(width: 1200, height: 750)
            .commands {
                TextEditingCommands()
            }
            
            // Editor Window Group
            WindowGroup(for: DesignFile.ID.self) { $designId in
                WindowToastContainer {
                    if let id = $designId.wrappedValue,
                       let design = designManager.designFiles.first(where: { $0.id == id }) {
                        EditorLoadingView(designFile: design)
                            .environmentObject(colorSchemeManager)
                            .environmentObject(subscriptionManager)
                            .environmentObject(paywallManager)
                            .environmentObject(designManager)
                            .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                            .frame(minWidth: 1200, minHeight: 750)
                    } else {
                        Text("Design not found")
                            .frame(width: 300, height: 200)
                    }
                }
            }
            .windowResizability(.automatic)
            .windowStyle(.hiddenTitleBar)
            .defaultSize(width: 1200, height: 750)
            .restorationBehavior(.disabled)
            .commands {
                TextEditingCommands()
            }
        }
    }

struct MainWindow: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var designManager: DesignManager
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        ContentView()
            .onOpenURL { url in
                // Handle custom URL scheme (app open)
                if url.scheme == "dockui" {
                    return
                }
                // Handle file import
                guard url.isFileURL else { return }
                
                    _ = (url as NSURL).startAccessingSecurityScopedResource()
                    defer { url.stopAccessingSecurityScopedResource() }
                
                print("📂 Opening file: \(url.path)")
                
                // Import or open the file
                designManager.handleOpenURL(url) { design in
                    if let design = design {
                        toastManager.showToast(ToastData(title: "Opened", icon: "checkmark.circle.fill"))
                        openWindow(value: design.id)
                        
                        // Close the main window after opening the editor
                        // giving a small delay to ensure the new window is registering
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    } else {
                        toastManager.showToast(ToastData(title: "Failed", icon: "xmark.circle.fill"))
                    }
                }
            }
    }
}

private struct WindowToastContainer<Content: View>: View {
    @StateObject private var toastManager = ToastManager()
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content.environmentObject(toastManager)
    }
}
#endif
