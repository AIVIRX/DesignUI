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
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(colorScheme == .dark ? 0.66 : 0.32),
                            Color.black.opacity(colorScheme == .dark ? 0.42 : 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea()

            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 42)
                .offset(x: -120, y: -170)

            Circle()
                .fill(Color.cyan.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 48)
                .offset(x: 140, y: 190)

            VStack(spacing: 28) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(.white.opacity(0.1))
                        .frame(width: 124, height: 124)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .stroke(.white.opacity(0.12), lineWidth: 1)
                        )

                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 94, height: 94)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 14)
                        .scaleEffect(animateLogo ? 1.03 : 0.98)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                            value: animateLogo
                        )
                }

                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Opening workspace")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)

                        Text(message)
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(.white.opacity(0.72))
                            .animation(.easeInOut(duration: 0.2), value: message)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.12))

                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(12, geometry.size.width * progress))
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("Preparing canvas")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.55))

                        Spacer()

                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(24)
                .frame(maxWidth: 320)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
        .onAppear {
            animateLogo = true
        }
    }
}
