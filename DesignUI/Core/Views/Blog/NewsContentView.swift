//
//  NewsContentView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import HighlightSwift
import SDWebImage
import SDWebImageSwiftUI

struct NewsContentView: View {
    let blocks: [NewsBlock]
    
    // Parse markdown links in text and render them as clickable links
    @ViewBuilder
    private func parseMarkdownLinks(text: String) -> some View {
        if #available(iOS 15.0, macOS 12.0, *) {
            Text(parseMarkdownLinksAttributed(text: text))
        } else {
            // Fallback for older versions - create a view with parsed links
            parseMarkdownLinksLegacy(text: text)
        }
    }
    
    @available(iOS 15.0, macOS 12.0, *)
    private func parseMarkdownLinksAttributed(text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        var allMatches: [(range: NSRange, linkText: String, url: URL)] = []
        
        // Find all matches from both patterns
        // Pattern 1: [text](url)
        let pattern1 = #"\[([^\]]+)\]\(([^)]+)\)"#
        if let regex1 = try? NSRegularExpression(pattern: pattern1, options: []) {
            let matches = regex1.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            for match in matches {
                if match.numberOfRanges >= 3,
                   let linkTextRange = Range(match.range(at: 1), in: text),
                   let urlRange = Range(match.range(at: 2), in: text),
                   let url = URL(string: String(text[urlRange])) {
                    let linkText = String(text[linkTextRange])
                    allMatches.append((match.range, linkText, url))
                }
            }
        }
        
        // Pattern 2: [text][url]
        let pattern2 = #"\[([^\]]+)\]\[([^\]]+)\]"#
        if let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) {
            let matches = regex2.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            for match in matches {
                // Only add if not already matched by pattern1
                let isDuplicate = allMatches.contains { $0.range.location == match.range.location }
                if !isDuplicate,
                   match.numberOfRanges >= 3,
                   let linkTextRange = Range(match.range(at: 1), in: text),
                   let urlRange = Range(match.range(at: 2), in: text),
                   let url = URL(string: String(text[urlRange])) {
                    let linkText = String(text[linkTextRange])
                    allMatches.append((match.range, linkText, url))
                }
            }
        }
        
        // Sort matches by position (reverse order for replacement)
        allMatches.sort { $0.range.location > $1.range.location }
        
        // Replace matches in reverse order to preserve indices
        for match in allMatches {
            if let fullRange = Range(match.range, in: text),
               let attributedRange = Range(fullRange, in: attributedString) {
                // Create NSAttributedString with attributes, then convert to AttributedString
                let nsAttributedString = NSMutableAttributedString(string: match.linkText)
                nsAttributedString.addAttribute(.link, value: match.url, range: NSRange(location: 0, length: match.linkText.count))
                #if os(iOS)
                nsAttributedString.addAttribute(.foregroundColor, value: UIColor.white, range: NSRange(location: 0, length: match.linkText.count))
                #elseif os(macOS)
                nsAttributedString.addAttribute(.foregroundColor, value: NSColor.white, range: NSRange(location: 0, length: match.linkText.count))
                #endif
                nsAttributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: match.linkText.count))
                
                var linkText = AttributedString(nsAttributedString)
                attributedString.replaceSubrange(attributedRange, with: linkText)
            }
        }
        
        return attributedString
    }
    
    @ViewBuilder
    private func parseMarkdownLinksLegacy(text: String) -> some View {
        // For older iOS versions, create a view with parsed links
        let parts = parseMarkdownLinksIntoParts(text)
        
        if parts.count == 1 {
            // No links found, return plain text
            Text(parts[0].text)
        } else {
            // Build inline text with links using HStack
            HStack(spacing: 0) {
                ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                    if let url = part.url {
                        Link(part.text, destination: url)
                            .foregroundColor(.white)
                            .underline()
                    } else {
                        Text(part.text)
                    }
                }
            }
        }
    }
    
    private struct TextPart {
        let text: String
        let url: URL?
    }
    
    private func parseMarkdownLinksIntoParts(_ text: String) -> [TextPart] {
        var parts: [TextPart] = []
        var matches: [(range: NSRange, linkText: String, url: URL, pattern: Int)] = []
        
        // Find all matches from both patterns
        // Pattern 1: [text](url)
        let pattern1 = #"\[([^\]]+)\]\(([^)]+)\)"#
        if let regex1 = try? NSRegularExpression(pattern: pattern1, options: []) {
            let regexMatches = regex1.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            for match in regexMatches {
                if match.numberOfRanges >= 3,
                   let linkTextRange = Range(match.range(at: 1), in: text),
                   let urlRange = Range(match.range(at: 2), in: text),
                   let url = URL(string: String(text[urlRange])) {
                    let linkText = String(text[linkTextRange])
                    matches.append((match.range, linkText, url, 1))
                }
            }
        }
        
        // Pattern 2: [text][url]
        let pattern2 = #"\[([^\]]+)\]\[([^\]]+)\]"#
        if let regex2 = try? NSRegularExpression(pattern: pattern2, options: []) {
            let regexMatches = regex2.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            for match in regexMatches {
                if match.numberOfRanges >= 3,
                   let linkTextRange = Range(match.range(at: 1), in: text),
                   let urlRange = Range(match.range(at: 2), in: text),
                   let url = URL(string: String(text[urlRange])) {
                    let linkText = String(text[linkTextRange])
                    // Only add if not already matched by pattern1 (avoid duplicates)
                    let isDuplicate = matches.contains { $0.range.location == match.range.location }
                    if !isDuplicate {
                        matches.append((match.range, linkText, url, 2))
                    }
                }
            }
        }
        
        // Sort matches by position
        matches.sort { $0.range.location < $1.range.location }
        
        // Build parts
        var currentLocation = 0
        let nsString = text as NSString
        
        for match in matches {
            // Add text before the match
            if match.range.location > currentLocation {
                let beforeText = nsString.substring(with: NSRange(location: currentLocation, length: match.range.location - currentLocation))
                if !beforeText.isEmpty {
                    parts.append(TextPart(text: beforeText, url: nil))
                }
            }
            
            // Add the link
            parts.append(TextPart(text: match.linkText, url: match.url))
            
            currentLocation = match.range.location + match.range.length
        }
        
        // Add remaining text
        if currentLocation < nsString.length {
            let remainingText = nsString.substring(from: currentLocation)
            if !remainingText.isEmpty {
                parts.append(TextPart(text: remainingText, url: nil))
            }
        }
        
        return parts.isEmpty ? [TextPart(text: text, url: nil)] : parts
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(blocks) { block in
                switch block.type {
                case .heading:
                    if let text = block.text {
                        Text(text)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .padding(.top)
                    }
                case .paragraph:
                    if let text = block.text {
                        parseMarkdownLinks(text: text)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                case .image:
                    if let urlString = block.url, let url = URL(string: urlString) {
                        WebImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                #if os(macOS)
                                Color.clear
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    )
                                #else
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                #endif
                            case .success(let image):
                                image.resizable()
                                    .scaledToFill()
                                    .cornerRadius(12)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                    .foregroundColor(.gray.opacity(0.5))
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            @unknown default:
                                Color.gray.opacity(0.2)
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                    .cornerRadius(12)
                            }
                        }
                    }
                case .code:
                    if let code = block.code {
                        VStack {
                            LiveSyntaxHighlightedCode(
                                code: code
                            )
                        }
                        .frame(maxWidth: 700, maxHeight: 300)
                        .clipped()
                    }
                case .link:
                    if let text = block.text, let urlString = block.url, let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack {
                                Text(text)
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                case .bulletedList:
                    if let items = block.items {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(items, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Text("•")
                                    Text(item)
                                }
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}
