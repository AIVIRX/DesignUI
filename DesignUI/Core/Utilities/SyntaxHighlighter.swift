//
//  SyntaxHighlighter.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/4/25.
//

import SwiftUI

class SyntaxHighlighter {
    static let shared = SyntaxHighlighter()
    

    
    func highlight(_ code: String, colorScheme: ColorScheme) async -> AttributedString {
        // Run on detached task with lower priority to allow UI/Network to finish first
        return await Task.detached(priority: .utility) {
            var attributedString = AttributedString(code)
            
            // Define Colors based on ColorScheme
            let isDark = colorScheme == .dark
            
            // Palette
            // Dark Mode (Pastels) / Light Mode (Darker/Saturated)
            let defaultC = isDark 
                ? Color(red: 0.82, green: 0.70, blue: 0.96) // #d2b2f4 (Light Purple)
                : Color(red: 0.5, green: 0.0, blue: 0.5)    // Dark Purple
            
            let numberC = isDark
                ? Color(red: 0.82, green: 0.76, blue: 0.47) // #d2c278 (Mustard)
                : Color(red: 0.6, green: 0.5, blue: 0.0)    // Dark Mustard
                
            let stringC = isDark
                ? Color(red: 0.97, green: 0.49, blue: 0.42) // #f87d6c (Salmon)
                : Color(red: 0.8, green: 0.2, blue: 0.1)    // Dark Red
            
            let keywordC = isDark
                ? Color(red: 1.0, green: 0.4, blue: 0.7)    // Pink
                : Color(red: 0.8, green: 0.0, blue: 0.4)    // Magenta
            
            let defNameC = isDark ? Color.cyan : Color(red: 0.0, green: 0.6, blue: 0.8) // Cyan for dark, darker cyan for light
            let importNameC = isDark ? Color.white : Color.black // White vs Black for text
            let commentC = Color.gray // Gray works for both usually
            
            // Set default font and color
            attributedString.font = .system(size: 14, design: .monospaced)
            attributedString.foregroundColor = defaultC
            
            // Combined Regex Pattern (O(N) single pass)
            let pattern = [
                "(?<comment>//.*)",
                "(?<string>\".*?\")",
                "(?<defBlock>(?<defKeyword>\\b(?:struct|class|enum|protocol|actor|extension)\\b)\\s+(?<defName>\\w+))",
                "(?<importBlock>(?<importKeyword>\\bimport\\b)\\s+(?<importName>\\w+))",
                "(?<keyword>\\b(?:import|class|struct|enum|protocol|actor|extension|func|var|let|if|else|guard|switch|case|default|return|init|deinit|self|super|try|catch|do|throw|throws|async|await|public|private|fileprivate|internal|open|static|weak|unowned|inout|defer|break|continue|fallthrough|for|in|while|repeat|where|as|is|nil|this|true|false)\\b)",
                "(?<attribute>@\\w+)",
                "(?<number>\\b\\d+\\.?\\d*\\b)",
                "(?<type>\\b[A-Z][a-zA-Z0-9_]*\\b)"
            ].joined(separator: "|")
            
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return attributedString }
            
            let nsString = code as NSString
            let fullRange = NSRange(location: 0, length: nsString.length)
            
            regex.enumerateMatches(in: code, options: [], range: fullRange) { match, _, _ in
                guard let match = match else { return }
                
                let range = match.range
                guard let attrRange = Range(range, in: attributedString) else { return }
                
                // Determine which group matched - check specific subgroups first
                if match.range(withName: "comment").location != NSNotFound {
                    attributedString[attrRange].foregroundColor = commentC
                } else if match.range(withName: "string").location != NSNotFound {
                    attributedString[attrRange].foregroundColor = stringC
                } else if match.range(withName: "defBlock").location != NSNotFound {
                    // Handle definition block: Keyword + Name
                    if let keyRange = Range(match.range(withName: "defKeyword"), in: attributedString) {
                         attributedString[keyRange].foregroundColor = keywordC
                    }
                    if let nameRange = Range(match.range(withName: "defName"), in: attributedString) {
                         attributedString[nameRange].foregroundColor = defNameC
                    }
                } else if match.range(withName: "importBlock").location != NSNotFound {
                    // Handle import block: Keyword + Name
                    if let keyRange = Range(match.range(withName: "importKeyword"), in: attributedString) {
                         attributedString[keyRange].foregroundColor = keywordC
                    }
                    if let nameRange = Range(match.range(withName: "importName"), in: attributedString) {
                         attributedString[nameRange].foregroundColor = importNameC
                    }
                } else if match.range(withName: "keyword").location != NSNotFound {
                    attributedString[attrRange].foregroundColor = keywordC
                } else if match.range(withName: "attribute").location != NSNotFound {
                    attributedString[attrRange].foregroundColor = keywordC
                } else if match.range(withName: "number").location != NSNotFound {
                    attributedString[attrRange].foregroundColor = numberC
                } else if match.range(withName: "type").location != NSNotFound {
                    // "Remove darker purple" -> Use default color for types now
                    attributedString[attrRange].foregroundColor = defaultC 
                }
            }
            
            return attributedString
        }.value
    }
}
