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
    private var appLaunchTime: Date?
    private var timerTask: Task<Void, Never>?
    
    private init() {
        // Track app launch time for 30-second timer
        appLaunchTime = Date()
    }
    
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
    
    /// Start the 30-second timer to request review if no interaction has triggered it
    func startTimer() {
        // Cancel any existing timer
        timerTask?.cancel()
        
        // Start new timer
        timerTask = Task { @MainActor in
            // Wait 30 seconds
            try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
            
            // Check if we still haven't requested review
            if !Task.isCancelled && !hasRequestedReviewThisSession {
                requestReviewIfNeeded()
            }
        }
    }
    
    /// Reset for new session (called on app launch)
    func resetForNewSession() {
        hasRequestedReviewThisSession = false
        appLaunchTime = Date()
        timerTask?.cancel()
        timerTask = nil
        // Start the 30-second timer
        startTimer()
    }
}

