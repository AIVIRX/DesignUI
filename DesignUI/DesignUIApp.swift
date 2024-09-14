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
extension View {
    func applyColorSchemeForiPad() -> some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return self.preferredColorScheme(.dark) // Set to .dark for dark mode
        } else {
            return self.preferredColorScheme(nil) // Use the system setting for non-iPad devices
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        requestNotif()
        requestTrackingAuthorization()
        initializeGoogleMobileAds()
        configureFirebase()
        
        return true
    }
    
    private func requestNotif() {
        // Set UNUserNotificationCenter delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification authorization
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
        }
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

extension AppDelegate {
    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        // Optionally, send the FCM token to your server here.
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    @StateObject private var userStore = UserStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(userStore)
            
        }
    }

}

#endif

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
        }
        .windowStyle(DefaultWindowStyle())
                .windowResizability(.contentSize)
    }
}



class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
                    // Set minimum and maximum window sizes
                    window.minSize = NSSize(width: 800, height: 600)  // Example minimum size
                    window.maxSize = NSSize(width: 1280, height: 1280) // Example maximum size
                }
        
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
