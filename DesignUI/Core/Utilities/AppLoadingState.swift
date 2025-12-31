//
//  AppLoadingState.swift
//  DesignUI
//
//  Created by Claude on 12/30/24.
//

import SwiftUI

/// Observable class to manage app-wide loading state
/// Used for Figma-style loading screen before main UI is shown
class AppLoadingState: ObservableObject {
    static let shared = AppLoadingState()
    
    /// Whether the app is currently in loading state
    @Published var isLoading: Bool = true
    
    /// Loading progress from 0.0 to 1.0
    @Published var loadingProgress: Double = 0.0
    
    /// Current loading status message
    @Published var loadingMessage: String = "Starting up..."
    
    /// Number of items that have been loaded
    @Published var completedItems: Int = 0
    
    /// Total number of items to load
    @Published var totalItems: Int = 0
    
    private init() {}
    
    /// Update progress with item counts
    func updateProgress(completed: Int, total: Int, message: String) {
        DispatchQueue.main.async {
            self.completedItems = completed
            self.totalItems = total
            self.loadingProgress = total > 0 ? Double(completed) / Double(total) : 0.0
            self.loadingMessage = message
        }
    }
    
    /// Mark loading as complete
    func finishLoading() {
        DispatchQueue.main.async {
            self.loadingProgress = 1.0
            self.loadingMessage = "Ready!"
            
            // Brief delay to show completion before transitioning
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Reset loading state (useful for testing or re-triggering load)
    func reset() {
        isLoading = true
        loadingProgress = 0.0
        loadingMessage = "Starting up..."
        completedItems = 0
        totalItems = 0
    }
}
