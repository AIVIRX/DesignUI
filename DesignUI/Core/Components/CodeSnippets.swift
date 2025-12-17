//
//  LiveSyntaxHighlightedCode.swift
//  DockUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import HighlightSwift

struct LiveSyntaxHighlightedCode: View {
    let code: String
    let fontSize: CGFloat
    let maxHeight: CGFloat
    
    @State private var highlightedText: AttributedString = AttributedString()
    @State private var isHighlighting = false
    @State private var highlightCache: [String: AttributedString] = [:]
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.colorScheme) private var colorScheme
    
    private let highlight = Highlight()
    
    init(code: String, fontSize: CGFloat = 16, maxHeight: CGFloat = 500) {
        self.code = code
        self.fontSize = fontSize
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Modern header with title and copy button
            HStack {
                Text("Code Snippet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(code)
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
                            .fill(Color.gray.opacity(0.2))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            )
            
            // Code content area
            ScrollView(.vertical, showsIndicators: true) {
                Text(highlightedText)
                    .font(.system(size: fontSize, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: maxHeight)
            .overlay(loadingOverlay)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .overlay(borderOverlay)
        .onAppear {
            generateHighlightedText()
        }
        .onChange(of: code) {
            generateHighlightedText()
        }
        .onChange(of: colorScheme) {
            highlightCache.removeAll()
            generateHighlightedText()
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                colorScheme == .dark
                    ? Color(red: 0.3, green: 0.3, blue: 0.3)
                    : Color(red: 0.8, green: 0.8, blue: 0.8),
                lineWidth: 1
            )
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
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.2))
                    )
                    Spacer()
                }
            }
        }
    }
    
    private func performHighlight(_ code: String) async {
        // Check cache first
        if let cached = highlightCache[code] {
            await MainActor.run {
                self.highlightedText = cached
                self.isHighlighting = false
            }
            return
        }
        
        do {
            // Use appropriate theme based on color scheme
            let result = try await highlight.attributedText(
                code,
                language: "swift",
                colors: colorScheme == .dark ? .dark(.github) : .light(.github)
            )
            
            // Cache the result
            highlightCache[code] = result
            
            // Limit cache size
            if highlightCache.count > 50 {
                let firstKey = highlightCache.keys.first!
                highlightCache.removeValue(forKey: firstKey)
            }
            
            await MainActor.run {
                self.highlightedText = result
                self.isHighlighting = false
            }
        } catch {
            // Fallback to plain text
            await MainActor.run {
                var fallbackText = AttributedString(code)
                fallbackText.font = .system(size: fontSize, design: .monospaced)
                fallbackText.foregroundColor = Color(red: 0.9, green: 0.9, blue: 0.9)
                self.highlightedText = fallbackText
                self.isHighlighting = false
            }
        }
    }
    
    private func generateHighlightedText() {
        // Show loading indicator for large code
        if code.count > 1000 {
            isHighlighting = true
        }
        
        // Start highlighting immediately in background
        Task {
            await performHighlight(code)
        }
    }
}

