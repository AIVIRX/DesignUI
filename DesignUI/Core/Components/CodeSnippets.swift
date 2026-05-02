//
//  LiveSyntaxHighlightedCode.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct LiveSyntaxHighlightedCode: View {
    let code: String
    let fontSize: CGFloat
    let maxHeight: CGFloat
    
    @State private var highlightedText: AttributedString = AttributedString()
    @State private var isHighlighting = false
    @State private var highlightCache: [String: AttributedString] = [:]
    @State private var highlightTask: Task<Void, Never>?
    @EnvironmentObject private var toastManager: ToastManager
    @Environment(\.colorScheme) private var colorScheme
        
    init(code: String, fontSize: CGFloat = 16, maxHeight: CGFloat = 500) {
        self.code = code
        self.fontSize = fontSize
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            codeContent
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
        .overlay(borderOverlay)
        .onAppear {
            scheduleHighlight(for: colorScheme)
        }
        .onChange(of: code) { _, _ in
            scheduleHighlight(for: colorScheme)
        }
        .onChange(of: colorScheme) { _, newColorScheme in
            highlightCache.removeAll()
            scheduleHighlight(for: newColorScheme)
        }
        .onDisappear { highlightTask?.cancel() }
    }

    private var header: some View {
        HStack {
            Text("Code Snippet")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()
            copyButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Rectangle().fill(Color.gray.opacity(0.2)))
    }

    private var copyButton: some View {
        Button(action: copyCode) {
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

    private var codeContent: some View {
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

    private func copyCode() {
        copyToClipboard(code)
        toastManager.showCopyToast()
#if os(iOS)
        HapticManager.shared.triggerImpact(style: .soft)
#endif
    }
    
    private func performHighlight(_ code: String, colorScheme: ColorScheme) async {
        // Check cache first
        if let cached = highlightCache[code] {
            await MainActor.run {
                self.highlightedText = cached
                self.isHighlighting = false
            }
            return
        }
        
        let result = await SyntaxHighlighter.shared.highlight(code, colorScheme: colorScheme)
        
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
    }
    
    private func scheduleHighlight(for colorScheme: ColorScheme) {
        highlightTask?.cancel()
        
        // Show loading indicator for large code
        if code.count > 1000 {
            isHighlighting = true
        }
        
        // Start highlighting immediately in background
        highlightTask = Task {
            await performHighlight(code, colorScheme: colorScheme)
        }
    }
}
