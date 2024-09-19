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
import FirebaseAuth
import FirebaseAnalytics
import AdSupport
import UserNotifications
import FirebaseMessaging
#if os(iOS)
import GoogleMobileAds
#endif

#if os(iOS)
enum DeepLink: Equatable {
    case post(id: String)
    case profile(id: String)
    case explore
    case upload
    case activity
    
    static func == (lhs: DeepLink, rhs: DeepLink) -> Bool {
        switch (lhs, rhs) {
        case (.post(let id1), .post(let id2)):
            return id1 == id2
        case (.profile(let id1), .profile(let id2)):
            return id1 == id2
        case (.explore, .explore),
             (.upload, .upload),
             (.activity, .activity):
            return true
        default:
            return false
        }
    }
}


extension View {
    func applyColorSchemeForiPad() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return self.preferredColorScheme(.dark) // Set to .dark for dark mode
        } else {
            return self.preferredColorScheme(nil) // Use the system setting for non-iPad devices
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureFirebase()
        requestTrackingAuthorization()
        initializeGoogleMobileAds()
        
        // Handle Quick Actions
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            handleQuickAction(shortcutItem)
        }
        
        return true
    }
    
    private func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) -> Bool {
        handleQuickAction(shortcutItem)
        return true
    }
    
    private func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) {
            guard let rootViewController = window?.rootViewController as? UIHostingController<ContentView> else {
                return
            }

            let contentView = rootViewController.rootView
            
            switch shortcutItem.type {
            case "com.Maicol.Dockui.Home":
                contentView.selectedTab = 0
            case "com.Maicol.Dockui.Explore":
                contentView.selectedTab = 1
            case "com.Maicol.Dockui.Upload":
                contentView.selectedTab = 2
            case "com.Maicol.Dockui.Activity":
                contentView.selectedTab = 3
            case "com.Maicol.Dockui.Profile":
                contentView.selectedTab = 4
            default:
                break
            }
        }
    
    // Handle incoming notifications while the app is in the foreground
    class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    // Handle device token registration for Firebase Messaging
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
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
        Messaging.messaging().delegate = self
    }
    
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    @StateObject private var userStore = UserStore()
    @State private var selectedTab: Int = 0
    @State private var deepLink: DeepLink?
    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .environmentObject(store)
                .environmentObject(userStore)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }
    
    func handleDeepLink(url: URL) {
        if url.pathComponents.contains("post") {
            selectedTab = 0 // Switch to Home tab
        } else if url.pathComponents.contains("explore") {
            selectedTab = 1 // Switch to Explore tab
        } else if url.pathComponents.contains("upload") {
            selectedTab = 2 // Switch to Upload tab
        } else if url.pathComponents.contains("activity") {
            selectedTab = 3 // Switch to Activity tab
        } else if url.pathComponents.contains("profile") {
            selectedTab = 4 // Switch to Profile tab
        }
    }
}


#endif

#if os(macOS)
@main
struct DesignUIApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var store = Store()
    @StateObject private var userStore = UserStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(userStore)
                .frame(minWidth: 1280, minHeight: 720)
        }
        .windowStyle(DefaultWindowStyle())
                .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        FirebaseApp.configure()

        // Request notification authorization
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    NSApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }

        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Set Firebase Messaging delegate
        Messaging.messaging().delegate = self
    }

    // MARK: - MessagingDelegate
    
    

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // Optionally, send the FCM token to your server here.
    }

    func fetchFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                // Handle the token, e.g., send it to your server.
            }
        }
    }


    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}
#endif
