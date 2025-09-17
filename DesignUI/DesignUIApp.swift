//
//  DesignUIApp.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import Firebase
import FirebaseCore
import FirebaseAnalytics
import AdSupport
import Supabase

#if os(iOS)

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        
        //        UserDefaults.standard.set(0, forKey: "selectedIndex")

        return true
    }
        
    private func configureFirebase() {
        FirebaseApp.configure()
    }
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let client = SupabaseManager.shared.client
    @StateObject private var store = Store()
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager.shared
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    init() {
        hasRequestedReview = false // Reset at the start of every app session
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .onAppear {
                    print("App launched with color scheme: \(colorSchemeManager.currentScheme.displayName)")
                }
        }
    }
}
#endif

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
    }
}

@main
struct DesignUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager.shared
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    init() {
        hasRequestedReview = false // Reset at the start of every app session
        UserDefaults.standard.set(0, forKey: "selectedIndex")

    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .frame(minWidth: 1000, minHeight: 600)
                .onAppear {
                    print("App launched with color scheme: \(colorSchemeManager.currentScheme.displayName)")
                }
        }
        .windowStyle(DefaultWindowStyle())
        .windowResizability(.automatic)

    }
}
#endif
