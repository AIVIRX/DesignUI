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
import FirebaseAnalyticsSwift
import AdSupport
import UserNotifications
import FirebaseMessaging
import Supabase
#if os(iOS)
import GoogleMobileAds

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        requestTrackingAuthorization()
        initializeGoogleMobileAds()
        addDynamicQuickActions()
        
        UserDefaults.standard.set(0, forKey: "selectedIndex")
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            
            handleQuickAction(shortcutItem)
            
            func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
                let userDefaults = UserDefaults.standard
                switch shortcutItem.type {
                case QuickAction.explore.rawValue:
                    userDefaults.set(0, forKey: "selectedIndex")
                default:
                    userDefaults.set(0, forKey: "selectedIndex")
                }
            }
        }
        
        // Set up UISceneConfiguration
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = CustomSceneDelegate.self
        
        return sceneConfiguration
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
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    private func configureFirebase() {
        FirebaseApp.configure()
    }
    
    class CustomSceneDelegate: UIResponder, UIWindowSceneDelegate {
        func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
            
            handleQuickAction(shortcutItem)
            
            func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
                let userDefaults = UserDefaults.standard
                switch shortcutItem.type {
                case QuickAction.explore.rawValue:
                    userDefaults.set(0, forKey: "selectedIndex")
                case QuickAction.settings.rawValue:
                    userDefaults.set(1, forKey: "selectedIndex")
                default:
                    userDefaults.set(0, forKey: "selectedIndex")
                }
            }
            completionHandler(true)
        }
    }
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    let client = SupabaseManager.shared.client
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
#endif

#if os(macOS)
@main
struct DesignUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1280, minHeight: 720)
        }
        .windowStyle(DefaultWindowStyle())
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        FirebaseApp.configure()
    }
}
#endif
