//
//  DesignUIApp.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds
import AdSupport
import FirebaseAuth
import FirebaseCore
import RevenueCat
import Firebase
import FirebaseAnalytics
import RevenueCatUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "appl_sXReOOLCUJEKyIWbcoMvhvHVYIt")
        
        requestTrackingAuthorization()
        initializeGoogleMobileAds()
        configureFirebase()
        
        // Add state change listener for Firebase Authentication
            Auth.auth().addStateDidChangeListener { (auth, user) in

                if let uid = user?.uid {

                    // identify Purchases SDK with new Firebase user
                    Purchases.shared.logIn(uid, completion: { (info, created, error) in
                        if let error {
                            print("Sign in error: \(error.localizedDescription)")
                        } else {
                            print("User \(uid) signed in")
                        }
                    })
                }
            }
        // Set the reserved $firebaseAppInstanceId attribute from Firebase Analytics
            let instanceID = Analytics.appInstanceID()
            if let unwrapped = instanceID {
                print("Instance ID -> " + unwrapped)
                print("Setting Attributes")
                Purchases.shared.attribution.setFirebaseAppInstanceID(unwrapped)
            } else {
                print("Instance ID -> NOT FOUND!")
            }
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
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }
    
    private func configureFirebase() {
        FirebaseApp.configure()
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

