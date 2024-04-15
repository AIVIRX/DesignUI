//
//  DesignUIApp.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 4/13/24.
//

import SwiftUI
import FirebaseCore
import Firebase
import AppTrackingTransparency


class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("TRACKING ENABLED")
                    case .denied:
                        print("TRACKING DISABLED")
                    default:
                        print("DEFAULT TRACKING")
                    }
                }
            }
            else{
                
            }
        })
        FirebaseApp.configure()
        return true
    }
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
