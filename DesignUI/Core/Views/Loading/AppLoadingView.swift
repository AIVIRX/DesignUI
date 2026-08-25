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
    @State private var isEditorMounted = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingMessage = "Loading design..."
    
    var body: some View {
        ZStack {
            // Mount the expensive editor only after the loading state has rendered.
            // This lets the new window present immediately for complex projects.
            if isEditorMounted {
                UIBuilderView(designFile: designFile)
                    .environmentObject(designManager)
                    .opacity(isLoading ? 0 : 1)
                    .scaleEffect(isLoading ? 0.98 : 1)
            }
            
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
        loadingMessage = "Loading components..."
        loadingProgress = 0.1

        // Give SwiftUI a presentation pass before constructing the full canvas tree.
        await Task.yield()
        isEditorMounted = true

        loadingMessage = "Almost ready..."
        loadingProgress = 0.75
        try? await Task.sleep(nanoseconds: 150_000_000)
        loadingProgress = 1

        withAnimation(.easeInOut(duration: 0.4)) {
            isLoading = false
        }
    }
}

/// Loading overlay with AppLogo, blur background, and progress bar
struct EditorLoadingOverlay: View {
    let progress: Double
    let message: String
    
    @State private var animateLogo = false
    
    var body: some View {
        VStack(spacing: 28) {
            logoMark
            progressCard
        }
        .onAppear {
            animateLogo = true
        }
    }

    private var logoMark: some View {
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
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            loadingHeader
            progressTrack
            progressStatus
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

    private var loadingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Opening project")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var progressTrack: some View {
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
    }

    private var progressStatus: some View {
        HStack {
            Text("Preparing canvas")
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))

            Spacer()

            Text(verbatim: "\(Int((progress * 100).rounded()))%")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
