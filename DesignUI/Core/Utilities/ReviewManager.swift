//
//  ReviewManager.swift
//  DesignUI
//
//  Created by Assistant on 1/11/25.
//

import SwiftUI
import StoreKit

#if os(iOS)
import UIKit
#endif

@MainActor
class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    private var hasRequestedReviewThisSession = false
    private var timerTask: Task<Void, Never>?
    
    /// Request review if conditions are met (max once per session)
    func requestReviewIfNeeded() {
        // Only request once per session
        guard !hasRequestedReviewThisSession else {
            return
        }
        
        // Check if we're in a suitable context
        // Note: iOS/macOS may still decline to show the review prompt based on system rules
        #if os(iOS)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
        #elseif os(macOS)
        SKStoreReviewController.requestReview()
        #endif
        
        // Mark as requested for this session
        hasRequestedReviewThisSession = true
        
        // Cancel the 30-second timer if it's still running
        timerTask?.cancel()
        timerTask = nil
    }
    
    /// Reset for new session (called on app launch)
    func resetForNewSession() {
        hasRequestedReviewThisSession = false
        timerTask?.cancel()
        timerTask = nil
    }
}

