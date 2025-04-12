//
//  highlightSwiftCode.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 4/5/25.
//

import SwiftUI

func highlightSwiftCode(_ code: String) -> AttributedString {
    var result = AttributedString(code)

    let rules: [(pattern: String, color: Color)] = [
        // MARK: - Keywords
        ("\\b(import|func||var|if|else|for|while|return|struct|class|enum|extension|protocol|init|deinit|switch|case|default|break|continue|fallthrough|guard|in|repeat|do|try|catch|throws|throw|await|async|yield|where)\\b", .pink),
        
        // MARK: - Access Control
        ("\\b(public|private|fileprivate|internal|open|static|final|lazy|mutating|nonmutating)\\b", .indigo),
        
        // MARK: - Types
        ("\\b(String|Int|Double|Float|Bool|Void|Any|Optional|Array|Dictionary|Set|Result|Error)\\b", .purple),
        
        // MARK: - String Literals
        ("\"(\\\\.|[^\"\\\\])*\"", .orange),
        
        // MARK: - Numbers
        ("\\b\\d+(\\.\\d+)?\\b", .orange),
        
        // MARK: - Comments
        ("//.*", .gray),                           // Single-line
        ("/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/", .gray), // Multiline (basic)
        
        // MARK: - Attributes
        ("@\\w+", .pink),
        
        // MARK: - Operators
        ("[=\\+\\-\\*/<>!\\|&\\^~%]+", .red),
        
        // MARK: - Function Names (basic)
        ("\\bfunc\\s+(\\w+)", .mint),
        
        // MARK: - Property access (self., object.property)
        ("\\bself\\b(\\.[a-zA-Z_][a-zA-Z0-9_]*)?", .cyan)
    ]

    for (pattern, color) in rules {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else { continue }
        let nsRange = NSRange(code.startIndex..., in: code)
        let matches = regex.matches(in: code, range: nsRange)

        for match in matches {
            guard let range = Range(match.range, in: code),
                  let attrRange = Range(range, in: result) else { continue }
            result[attrRange].foregroundColor = color
        }
    }

    return result
}
