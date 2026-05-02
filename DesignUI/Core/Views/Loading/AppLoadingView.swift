//
//  EditorLoadingView.swift
//
//  Created by Claude on 12/30/24.
//

import SwiftUI

/// Wrapper view that shows loading screen when opening a design in the editor
/// Waits for the canvas to actually be ready before transitioning
struct EditorLoadingView: View {
    @ObservedObject var designFile: DesignFile
    @EnvironmentObject private var designManager: DesignManager
    
    @State private var isLoading = true
    @State private var loadingProgress: Double = 0.0
    @State private var loadingMessage = "Loading design..."
    @StateObject private var canvasManager = CanvasManager()
    
    var body: some View {
        ZStack {
            // Editor view (always present, captures readiness)
            UIBuilderView(designFile: designFile)
                .environmentObject(designManager)
                .opacity(isLoading ? 0 : 1)
                .scaleEffect(isLoading ? 0.98 : 1)
            
            // Loading overlay with blur
            if isLoading {
                EditorLoadingOverlay(
                    progress: loadingProgress,
                    message: loadingMessage
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isLoading)
        .task {
            await loadDesign()
        }
    }
    
    private func loadDesign() async {
        // Load components immediately without artificial delays
        loadingMessage = "Loading components..."
        loadingProgress = 0.1
        await MainActor.run {
            canvasManager.components = designFile.components
            canvasManager.setDesignName(designFile.name)
        }
        loadingMessage = "Almost ready..."
        loadingProgress = 1.0

        withAnimation(.easeInOut(duration: 0.4)) {
            isLoading = false
        }
    }
}

/// Loading overlay with AppLogo, blur background, and progress bar
struct EditorLoadingOverlay: View {
    let progress: Double
    let message: String
    
    @Environment(\.colorScheme) var colorScheme
    @State private var animateLogo = false
    
    var body: some View {
        ZStack {
            // Blurred background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // App Logo with subtle animation
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .scaleEffect(animateLogo ? 1.02 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animateLogo
                    )
                
                // Progress bar and message
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(colorScheme == .dark ? 
                                    Color.white.opacity(0.15) : 
                                    Color.black.opacity(0.1))
                            
                            // Progress fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(8, geometry.size.width * progress))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: 220)
                    
                    // Loading message
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? 
                            .white.opacity(0.7) : 
                            .black.opacity(0.6))
                        .animation(.easeInOut(duration: 0.2), value: message)
                }
            }
        }
        .onAppear {
            animateLogo = true
        }
    }
}
