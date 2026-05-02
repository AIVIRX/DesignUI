//
//  CodePreviewView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct CodePreviewView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var toastManager: ToastManager

    private var systemBackgroundColor: Color {
#if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
#else
        return Color(uiColor: .systemBackground)
#endif
    }

    private var secondaryBackgroundColor: Color {
#if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
#else
        return Color(uiColor: .secondarySystemBackground)
#endif
    }
    
    var body: some View {
        let content = VStack(spacing: 0) {
            codePreviewContent
        }
        
        #if os(macOS)
        return content
            .frame(minWidth: 1000, idealWidth: 1400, minHeight: 600, idealHeight: 900)
            .background(systemBackgroundColor)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        colorScheme == .dark
                            ? Color(red: 0.3, green: 0.3, blue: 0.3)
                            : Color(red: 0.8, green: 0.8, blue: 0.8),
                        lineWidth: 1
                    )
            )
        #else
        return content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(systemBackgroundColor)
            .ignoresSafeArea(.container, edges: .bottom)
        #endif
    }
    
    @ViewBuilder
    private var codePreviewContent: some View {
        // Header with styling matching CodeSnippets
        HStack {
            Text("Generated Code")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: {
                copyToClipboard(completeFileCode)
                toastManager.showCopyToast()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                    Text("Copy code")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(secondaryBackgroundColor)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(secondaryBackgroundColor)
        )
        
        // Code content with syntax highlighting
        // Code content with syntax highlighting
        VStack(alignment: .leading, spacing: 0) {
            CompleteFileCode(canvasManager: canvasManager)
        }
        .background(systemBackgroundColor)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var completeFileCode: String {
        let viewCode = canvasManager.exportCode()
        return """

        \(viewCode)

        """
    }
}

struct CompleteFileCode: View {
    @ObservedObject var canvasManager: CanvasManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var highlightedText: AttributedString = AttributedString()
    @State private var isHighlighting = false
        
    private var completeFileCode: String {
        let viewCode = canvasManager.exportCode()
        return """

        \(viewCode)

        """
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Code content area with syntax highlighting - horizontal scroll to prevent wrapping
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Text(highlightedText)
                    .font(.system(size: 14, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(20) // Added inline padding
                    .coordinateSpace(name: "codeScroll") // Give coordinate space a name if needed
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure it fills available space
            .overlay(loadingOverlay)
        }
        .onAppear {
            generateHighlightedText(for: colorScheme)
        }
        .onChange(of: completeFileCode) { _, _ in
            generateHighlightedText(for: colorScheme)
        }
        .onChange(of: colorScheme) { _, newColorScheme in
            generateHighlightedText(for: newColorScheme)
        }
    }
    
    private var loadingOverlay: some View {
        Group {
            if isHighlighting {
                VStack {
                    Spacer()
                    HStack {
                        #if os(macOS)
                        Color.clear
                            .frame(width: 24, height: 24)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                        #else
                        ProgressView()
                            .scaleEffect(0.8)
                        #endif
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    
                    Spacer()
                }
            }
        }
    }
    
    private func performHighlight(_ code: String, colorScheme: ColorScheme) async {
        let result = await SyntaxHighlighter.shared.highlight(code, colorScheme: colorScheme)
        
        await MainActor.run {
            self.highlightedText = result
            self.isHighlighting = false
        }
    }
    
    private func generateHighlightedText(for colorScheme: ColorScheme) {
        // Show loading indicator for large code
        if completeFileCode.count > 1000 {
            isHighlighting = true
        }
        
        // Start highlighting immediately in background
        Task {
            await performHighlight(completeFileCode, colorScheme: colorScheme)
        }
    }
}
