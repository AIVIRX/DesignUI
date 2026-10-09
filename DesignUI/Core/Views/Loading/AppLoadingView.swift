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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isLoading = true
    @State private var isEditorMounted = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingMessage = "Loading design..."
    
    var body: some View {
        ZStack {
            // Mount the expensive editor only after the loading state has rendered.
            // This lets the new window present immediately for complex projects.
            if isEditorMounted {
                UIBuilderView(designFile: designFile, onInitialRender: finishLoading)
                    .environmentObject(designManager)
                    .opacity(isLoading ? 0 : 1)
                    .scaleEffect(isLoading && !reduceMotion ? 0.98 : 1)
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
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: isLoading)
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
    }

    private func finishLoading() {
        guard isLoading else { return }
        loadingProgress = 1

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.4)) {
            isLoading = false
        }
    }
}

/// Lightweight loading state that adapts to the current appearance and accessibility settings.
struct EditorLoadingOverlay: View {
    let progress: Double
    let message: String

    var body: some View {
        ZStack {
            Color.platformWindowBackground
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .accessibilityHidden(true)

                VStack(spacing: 12) {
                    Text("Opening project")
                        .font(.headline)

                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 240)
                        .accessibilityLabel("Opening project")
                        .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(32)
        }
    }
}

private extension Color {
    static var platformWindowBackground: Color {
#if os(macOS)
        Color(nsColor: .windowBackgroundColor)
#else
        Color(uiColor: .systemBackground)
#endif
    }
}
