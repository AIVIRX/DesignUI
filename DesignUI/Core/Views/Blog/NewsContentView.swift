//
//  NewsContentView.swift
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI

struct NewsContentView: View {
    let blocks: [NewsBlock]
    
    private struct MarkdownLinkMatch {
        let range: NSRange
        let linkText: String
        let url: URL
    }
    
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
        let allMatches = collectMarkdownLinkMatches(in: text)
            .sorted { $0.range.location > $1.range.location }
        
        // Replace matches in reverse order to preserve indices
        for match in allMatches {
            if let fullRange = Range(match.range, in: text),
               let attributedRange = Range(fullRange, in: attributedString) {
                let replacement = makeAttributedLinkText(text: match.linkText, url: match.url)
                attributedString.replaceSubrange(attributedRange, with: replacement)
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
                            .foregroundColor(.accentColor)
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
        let matches = collectMarkdownLinkMatches(in: text)
            .sorted { $0.range.location < $1.range.location }
        
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
    
    private func collectMarkdownLinkMatches(in text: String) -> [MarkdownLinkMatch] {
        var matches: [MarkdownLinkMatch] = []
        let fullRange = NSRange(text.startIndex..., in: text)

        appendMarkdownLinkMatches(
            pattern: #"\[([^\]]+)\]\(([^)]+)\)"#,
            in: text,
            fullRange: fullRange,
            matches: &matches
        )

        appendMarkdownLinkMatches(
            pattern: #"\[([^\]]+)\]\[([^\]]+)\]"#,
            in: text,
            fullRange: fullRange,
            matches: &matches,
            skipDuplicateLocations: true
        )

        return matches
    }
    
    private func appendMarkdownLinkMatches(
        pattern: String,
        in text: String,
        fullRange: NSRange,
        matches: inout [MarkdownLinkMatch],
        skipDuplicateLocations: Bool = false
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
        let regexMatches = regex.matches(in: text, options: [], range: fullRange)

        for match in regexMatches {
            if skipDuplicateLocations && matches.contains(where: { $0.range.location == match.range.location }) {
                continue
            }
            guard match.numberOfRanges >= 3,
                  let linkTextRange = Range(match.range(at: 1), in: text),
                  let urlRange = Range(match.range(at: 2), in: text),
                  let url = URL(string: String(text[urlRange])) else { continue }

            let linkText = String(text[linkTextRange])
            matches.append(MarkdownLinkMatch(range: match.range, linkText: linkText, url: url))
        }
    }
    
    @available(iOS 15.0, macOS 12.0, *)
    private func makeAttributedLinkText(text: String, url: URL) -> AttributedString {
        let length = text.count
        let nsAttributedString = NSMutableAttributedString(string: text)
        nsAttributedString.addAttribute(.link, value: url, range: NSRange(location: 0, length: length))
        #if os(iOS)
        nsAttributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: NSRange(location: 0, length: length))
        #elseif os(macOS)
        nsAttributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: NSRange(location: 0, length: length))
        #endif
        nsAttributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: length))
        return AttributedString(nsAttributedString)
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
                        CachedRemoteImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .cornerRadius(12)
                        } placeholder: {
                                #if os(macOS)
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                                #else
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 300)
                                #endif
                        }
                    }
                case .code:
                    if let code = block.code {
                        VStack {
                            LiveSyntaxHighlightedCode(
                                code: code
                            )
                        }
                        .frame(maxHeight: 300)
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
                                    Text(verbatim: "•")
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
