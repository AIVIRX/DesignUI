//
//  AdManager.swift
//  DockUI
//
//  Created by Assistant on 1/11/25.
//
#if os(iOS)
import SwiftUI

import GoogleMobileAds
import UIKit

@MainActor
class AdManager: ObservableObject {
    static let shared = AdManager()
    
    @Published var nativeAds: [String: NativeAd] = [:]
    
    private let adUnitID: String
    private var adLoaders: [String: AdLoader] = [:]
    private var adDelegates: [String: AdLoaderDelegate] = [:] // Keep strong references to delegates
    
    private init() {
        // For testing, you can use: "ca-app-pub-3940256099942544/3986624511"

        self.adUnitID = "ca-app-pub-2043555402127024/3628489512" // TODO: Replace with production ID
    }
    
    func loadNativeAd(for identifier: String) {
        #if os(iOS)
        // Check if ad already loaded for this identifier
        if nativeAds[identifier] != nil {
            return
        }
        
        #if canImport(GoogleMobileAds)
        // Ensure AdMob SDK is initialized before loading ads
        // This prevents the "Failed to change to usage state 2" error
        // Initialize on first use if not already initialized
        // Note: Initialization should ideally be done in AppDelegate
        // This is a fallback initialization
        MobileAds.shared.start(completionHandler: nil)
        
        // Get root view controller using iOS 13+ window scene API
        var rootViewController: UIViewController?
        
        // Try to get key window first
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            rootViewController = window.rootViewController
        }
        
        // Fallback to first window if no key window found
        if rootViewController == nil,
           let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            rootViewController = window.rootViewController
        }
        
        guard let rootViewController = rootViewController else {
            return
        }
        
        // Create or reuse ad loader for this identifier
        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        
        // Create and store delegate to keep it alive
        let delegate = AdLoaderDelegate(identifier: identifier, adManager: self)
        adLoader.delegate = delegate
        adDelegates[identifier] = delegate // Keep strong reference
        adLoaders[identifier] = adLoader
        
        let request = Request()
        adLoader.load(request)
        #endif
        #endif
    }
    
    func getNativeAd(for identifier: String) -> NativeAd? {
        return nativeAds[identifier]
    }
    
    func setNativeAd(_ ad: NativeAd, for identifier: String) {
        nativeAds[identifier] = ad
    }
}

private class AdLoaderDelegate: NSObject, NativeAdLoaderDelegate {
    let identifier: String
    weak var adManager: AdManager?
    
    init(identifier: String, adManager: AdManager) {
        self.identifier = identifier
        self.adManager = adManager
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        // Update on main actor since AdManager is @MainActor
        Task { @MainActor in
            adManager?.setNativeAd(nativeAd, for: identifier)
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("Failed to load native ad for \(identifier): \(error.localizedDescription)")
    }
}
#endif

