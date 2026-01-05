//
//  CodePreviewView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI


struct CodePreviewView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView{
            VStack(spacing: 0) {
                // Header with styling matching CodeSnippets
                HStack {
                    Text("Generated Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        copyToClipboard(completeFileCode)
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
                                .fill(Color.gray.opacity(0.2))
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
                        .fill(Color.gray.opacity(0.2))
                )
                
                // Code content with syntax highlighting
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        CompleteFileCode(canvasManager: canvasManager)
                    }
                    .padding(0) // Removed padding as requested
                }
                .background(Color.gray.opacity(0.1))
            }
        }
        .frame(maxWidth: 1000, maxHeight: 800) // Increased default size
        .background(Color.gray.opacity(0.1))
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
    }
    
    private var completeFileCode: String {
        let viewCode = canvasManager.exportCode()
        return """
        //
        //
        //  Generated in DockUI Studio
        //

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
        //
        //
        //  Generated in DockUI Studio
        //

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
            }
            .frame(maxWidth: .infinity)
            .overlay(loadingOverlay)
        }
        .onAppear {
            generateHighlightedText()
        }
        .onChange(of: completeFileCode) { _, _ in
            generateHighlightedText()
        }
        .onChange(of: colorScheme) { _, _ in
            generateHighlightedText()
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
    
    private func performHighlight(_ code: String) async {
        let result = await SyntaxHighlighter.shared.highlight(code, colorScheme: colorScheme)
        
        await MainActor.run {
            self.highlightedText = result
            self.isHighlighting = false
        }
    }
    
    private func generateHighlightedText() {
        // Show loading indicator for large code
        if completeFileCode.count > 1000 {
            isHighlighting = true
        }
        
        // Start highlighting immediately in background
        Task {
            await performHighlight(completeFileCode)
        }
    }
}
