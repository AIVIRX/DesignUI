//
//  DesignUIApp.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import AppTrackingTransparency
import Firebase
import FirebaseCore
import FirebaseAnalytics
import AdSupport
import Supabase

#if os(iOS)
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        requestTrackingAuthorization()
        initializeGoogleMobileAds()
        
        //        UserDefaults.standard.set(0, forKey: "selectedIndex")

        return true
    }
    
    private func requestTrackingAuthorization() {
        if #available(iOS 14, *) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("TRACKING ENABLED \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)")
                    case .denied:
                        print("TRACKING DISABLED \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)")
                    default:
                        print("DEFAULT TRACKING \(ASIdentifierManager.shared().advertisingIdentifier.uuidString)")
                    }
                }
            }
        } else {
            print("iOS version is below 14.0, no tracking authorization needed.")
        }
    }
    
    private func initializeGoogleMobileAds() {
        MobileAds.shared.start(completionHandler: nil)
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
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    init() {
        hasRequestedReview = false // Reset at the start of every app session
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(colorSchemeManager)
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
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    init() {
        hasRequestedReview = false // Reset at the start of every app session
        UserDefaults.standard.set(0, forKey: "selectedIndex")

    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(colorSchemeManager)
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
