//
//  RootView.swift
//  DesignUI
//
//  Created by AI Assistant on 9/16/25.
//

import SwiftUI

struct RootView: View {
    //@AppStorage("hasSeenOnboarding")
    @State private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        ContentView()
            .onAppear {
                if shouldShowOnboarding() {
                    showOnboarding = true
                }
            }
#if os(iOS)
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                    showOnboarding = false
                })
            }
#else
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(onComplete: {
                    hasSeenOnboarding = true
                    showOnboarding = false
                })
                .frame(minWidth: 600, minHeight: 400)
            }
#endif
    }
    
    private func shouldShowOnboarding() -> Bool {
        // Only show once ever
        return !hasSeenOnboarding
    }
}

#Preview {
    RootView()
}


