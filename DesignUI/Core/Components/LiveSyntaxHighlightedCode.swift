//
//  LiveSyntaxHighlightedCode.swift
//  DesignUI
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
    
    private let highlight = Highlight()
    
    init(code: String, fontSize: CGFloat = 16, maxHeight: CGFloat = 300) {
        self.code = code
        self.fontSize = fontSize
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Modern header with title and copy button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    
                    Text("Code Snippet")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(code)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                        Text("Copy")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
            )
            
            // Code content area
            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(highlightedText)
                        .font(.system(size: fontSize, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: maxHeight)
                
                // Loading overlay
                if isHighlighting {
                    VStack {
                        Spacer()
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Highlighting...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 0.18, green: 0.18, blue: 0.18).opacity(0.9))
                        )
                        Spacer()
                    }
                }
            }
        }
        .background(Color(red: 0.13, green: 0.13, blue: 0.13)) // Dark background like Xcode
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.3, green: 0.3, blue: 0.3), lineWidth: 1)
        )
        .onAppear {
            generateHighlightedText()
        }
        .onChange(of: code) {
            generateHighlightedText()
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
            // Use Xcode's official SwiftUI theme
            let result = try await highlight.attributedText(
                code,
                language: "swift",
                colors: .dark(.xcode)
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
    
    func copyToClipboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
#endif
    }
}


// MARK: - Preview
#Preview {
    LiveSyntaxHighlightedCode(
        code: """
        import SwiftUI

        struct ContentView: View {
            @State private var count = 0
            
            var body: some View {
                VStack {
                    Text("Count: \\(count)")
                        .font(.title)
                    
                    Button("Increment") {
                        count += 1
                    }
                }
            }
        }
        """,
        fontSize: 16,
        maxHeight: 300
    )
    .padding()
}
