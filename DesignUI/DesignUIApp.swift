//
//  DesignUIApp.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 4/13/24.
//

import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds
import AdSupport

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    switch status {
                    case .authorized:
                        print("TRACKING ENABLED")
                        GADMobileAds.sharedInstance().start(completionHandler: nil)
                        print(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
                    case .denied:
                        print("TRACKING DISABLED")
                        GADMobileAds.sharedInstance().start(completionHandler: nil)
                        print(ASIdentifierManager.shared().advertisingIdentifier.uuidString)
                    default:
                        print("DEFAULT TRACKING")
                    }
                }
            }
            else{
                GADMobileAds.sharedInstance().start(completionHandler: nil)
            }
        })
        return true
    }
}

@main
struct CryptoProfitCalculatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = Store()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
