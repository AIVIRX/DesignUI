//
//  SyntaxHighlighter.swift
//
//  Created by Maicol Cabreja on 1/4/25.
//

import SwiftUI

class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()

    private static let highlightPattern = [
        "(?<comment>//.*)",
        "(?<string>\".*?\")",
        "(?<defBlock>(?<defKeyword>\\b(?:struct|class|enum|protocol|actor|extension)\\b)\\s+(?<defName>\\w+))",
        "(?<importBlock>(?<importKeyword>\\bimport\\b)\\s+(?<importName>\\w+))",
        "(?<keyword>\\b(?:import|class|struct|enum|protocol|actor|extension|func|var|let|if|else|guard|switch|case|default|return|init|deinit|self|super|try|catch|do|throw|throws|async|await|public|private|fileprivate|internal|open|static|weak|unowned|inout|defer|break|continue|fallthrough|for|in|while|repeat|where|as|is|nil|this|true|false)\\b)",
        "(?<attribute>@\\w+)",
        "(?<number>\\b\\d+\\.?\\d*\\b)",
        "(?<type>\\b[A-Z][a-zA-Z0-9_]*\\b)"
    ].joined(separator: "|")

    private static let highlightRegex = try? NSRegularExpression(pattern: highlightPattern, options: [])
    
    func highlight(_ code: String, colorScheme: ColorScheme) async -> AttributedString {
        // Run on detached task with lower priority to allow UI/Network to finish first
        let task: Task<AttributedString, Never> = Task.detached(priority: .utility) {
            Self.highlightSync(code: code, colorScheme: colorScheme)
        }
        return await task.value
    }

    private static func highlightSync(code: String, colorScheme: ColorScheme) -> AttributedString {
        var attributedString = AttributedString(code)
        guard let regex = highlightRegex else { return attributedString }

        let isDark = colorScheme == .dark
        let defaultC = isDark
            ? Color(red: 0.82, green: 0.70, blue: 0.96)
            : Color(red: 0.5, green: 0.0, blue: 0.5)
        let numberC = isDark
            ? Color(red: 0.82, green: 0.76, blue: 0.47)
            : Color(red: 0.6, green: 0.5, blue: 0.0)
        let stringC = isDark
            ? Color(red: 0.97, green: 0.49, blue: 0.42)
            : Color(red: 0.8, green: 0.2, blue: 0.1)
        let keywordC = isDark
            ? Color(red: 1.0, green: 0.4, blue: 0.7)
            : Color(red: 0.8, green: 0.0, blue: 0.4)
        let defNameC = isDark ? Color.cyan : Color(red: 0.0, green: 0.6, blue: 0.8)
        let importNameC = isDark ? Color.white : Color.black
        let commentC = Color.gray

        attributedString.font = .system(size: 14, design: .monospaced)
        attributedString.foregroundColor = defaultC

        let fullRange = NSRange(location: 0, length: (code as NSString).length)
        regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
            guard let match else { return }
            guard let attrRange = Range(match.range, in: attributedString) else { return }

            if match.range(withName: "comment").location != NSNotFound {
                attributedString[attrRange].foregroundColor = commentC
            } else if match.range(withName: "string").location != NSNotFound {
                attributedString[attrRange].foregroundColor = stringC
            } else if match.range(withName: "defBlock").location != NSNotFound {
                if let keyRange = Range(match.range(withName: "defKeyword"), in: attributedString) {
                    attributedString[keyRange].foregroundColor = keywordC
                }
                if let nameRange = Range(match.range(withName: "defName"), in: attributedString) {
                    attributedString[nameRange].foregroundColor = defNameC
                }
            } else if match.range(withName: "importBlock").location != NSNotFound {
                if let keyRange = Range(match.range(withName: "importKeyword"), in: attributedString) {
                    attributedString[keyRange].foregroundColor = keywordC
                }
                if let nameRange = Range(match.range(withName: "importName"), in: attributedString) {
                    attributedString[nameRange].foregroundColor = importNameC
                }
            } else if match.range(withName: "keyword").location != NSNotFound
                || match.range(withName: "attribute").location != NSNotFound {
                attributedString[attrRange].foregroundColor = keywordC
            } else if match.range(withName: "number").location != NSNotFound {
                attributedString[attrRange].foregroundColor = numberC
            } else if match.range(withName: "type").location != NSNotFound {
                attributedString[attrRange].foregroundColor = defaultC
            }
        }

        return attributedString
    }
}
