//
//  SyntaxHighlighter.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import SwiftSyntax
import SwiftSyntaxParser

struct SyntaxHighlight {
    let text: String
    let type: HighlightType
    let range: Range<String.Index>
}

enum HighlightType {
    case keyword
    case string
    case comment
    case attribute
    case identifier
    case operator
    case number
    case type
    case propertyWrapper
    case modifier
    case punctuation
    case `default`
    
    var color: Color {
        switch self {
        case .keyword:
            return .purple
        case .string:
            return .green
        case .comment:
            return .gray
        case .attribute:
            return .blue
        case .identifier:
            return .primary
        case .operator:
            return .orange
        case .number:
            return .red
        case .type:
            return .blue
        case .propertyWrapper:
            return .cyan
        case .modifier:
            return .indigo
        case .punctuation:
            return .secondary
        case .default:
            return .primary
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .keyword, .type, .propertyWrapper:
            return .semibold
        case .modifier:
            return .medium
        default:
            return .regular
        }
    }
}

class SyntaxHighlighter: ObservableObject {
    @Published var highlightedSegments: [SyntaxHighlight] = []
    
    func highlightCode(_ code: String) {
        do {
            let sourceFile = try SyntaxParser.parse(source: code)
            var segments: [SyntaxHighlight] = []
            
            // Walk through the syntax tree to extract tokens
            let visitor = TokenVisitor { token in
                let text = String(describing: token.text)
                let range = token.position..<token.endPosition
                let highlightType = self.classifyToken(token)
                
                segments.append(SyntaxHighlight(
                    text: text,
                    type: highlightType,
                    range: range
                ))
            }
            
            visitor.walk(sourceFile)
            self.highlightedSegments = segments
        } catch {
            // If parsing fails, treat as plain text
            self.highlightedSegments = [SyntaxHighlight(
                text: code,
                type: .default,
                range: code.startIndex..<code.endIndex
            )]
        }
    }
    
    private func classifyToken(_ token: TokenSyntax) -> HighlightType {
        switch token.tokenKind {
        // Keywords
        case .structKeyword, .classKeyword, .funcKeyword, .varKeyword, .letKeyword,
             .ifKeyword, .elseKeyword, .forKeyword, .whileKeyword, .doKeyword,
             .tryKeyword, .catchKeyword, .throwKeyword, .returnKeyword,
             .importKeyword, .publicKeyword, .privateKeyword, .internalKeyword,
             .staticKeyword, .finalKeyword, .overrideKeyword, .requiredKeyword,
             .convenienceKeyword, .initKeyword, .deinitKeyword, .extensionKeyword,
             .protocolKeyword, .enumKeyword, .caseKeyword, .defaultKeyword,
             .switchKeyword, .whereKeyword, .guardKeyword, .deferKeyword,
             .inoutKeyword, .mutatingKeyword, .nonmutatingKeyword, .subscriptKeyword,
             .precedencegroupKeyword, .infixKeyword, .prefixKeyword, .postfixKeyword,
             .operatorKeyword, .associativityKeyword, .leftKeyword, .rightKeyword,
             .noneKeyword, .trueKeyword, .falseKeyword, .nilKeyword, .selfKeyword,
             .superKeyword, .unownedKeyword, .weakKeyword, .someKeyword, .anyKeyword,
             .asKeyword, .isKeyword, .inKeyword, .repeatKeyword, .breakKeyword,
             .continueKeyword, .fallthroughKeyword, .typealiasKeyword, .associatedtypeKeyword:
            return .keyword
            
        // Property wrappers and attributes
        case .atSign:
            return .attribute
            
        // String literals
        case .stringLiteral, .multilineStringLiteral:
            return .string
            
        // Comments
        case .lineComment, .blockComment, .docLineComment, .docBlockComment:
            return .comment
            
        // Numbers
        case .integerLiteral, .floatingLiteral:
            return .number
            
        // Operators
        case .spacedBinaryOperator, .unspacedBinaryOperator, .prefixOperator, .postfixOperator:
            return .operator
            
        // Punctuation
        case .leftParen, .rightParen, .leftBrace, .rightBrace, .leftBracket, .rightBracket,
             .comma, .period, .semicolon, .colon, .arrow, .backslash, .backtick,
             .exclamationMark, .questionMark, .dollarSign, .equal, .minus, .plus,
             .asterisk, .slash, .percent, .ampersand, .pipe, .lessThan, .greaterThan,
             .caret, .tilde, .backslash, .backtick, .exclamationMark, .questionMark:
            return .punctuation
            
        // Identifiers
        case .identifier:
            let text = String(describing: token.text)
            
            // Check for SwiftUI-specific types
            if isSwiftUIType(text) {
                return .type
            }
            
            // Check for property wrappers
            if isPropertyWrapper(text) {
                return .propertyWrapper
            }
            
            // Check for common SwiftUI modifiers
            if isSwiftUIModifier(text) {
                return .modifier
            }
            
            return .identifier
            
        default:
            return .default
        }
    }
    
    private func isSwiftUIType(_ text: String) -> Bool {
        let swiftUITypes = [
            "View", "Text", "Image", "Button", "VStack", "HStack", "ZStack",
            "List", "ScrollView", "NavigationView", "TabView", "Form", "Group",
            "ForEach", "LazyVStack", "LazyHStack", "LazyVGrid", "LazyHGrid",
            "Color", "LinearGradient", "RadialGradient", "AngularGradient",
            "Rectangle", "Circle", "RoundedRectangle", "Capsule", "Ellipse",
            "Path", "Shape", "GeometryReader", "Spacer", "Divider"
        ]
        return swiftUITypes.contains(text)
    }
    
    private func isPropertyWrapper(_ text: String) -> Bool {
        let propertyWrappers = [
            "@State", "@Binding", "@ObservedObject", "@StateObject", "@EnvironmentObject",
            "@Environment", "@Published", "@AppStorage", "@SceneStorage", "@FocusState",
            "@GestureState", "@ScaledMetric", "@FetchRequest", "@SectionedFetchRequest"
        ]
        return propertyWrappers.contains(text)
    }
    
    private func isSwiftUIModifier(_ text: String) -> Bool {
        let modifiers = [
            "frame", "padding", "background", "foregroundColor", "font", "cornerRadius",
            "shadow", "opacity", "scaleEffect", "rotationEffect", "offset", "clipShape",
            "mask", "blendMode", "compositingGroup", "drawingGroup", "animation",
            "transition", "onAppear", "onDisappear", "onTapGesture", "onLongPressGesture",
            "gesture", "disabled", "hidden", "accessibility", "navigationTitle",
            "navigationBarTitleDisplayMode", "toolbar", "navigationBarBackButtonHidden"
        ]
        return modifiers.contains(text)
    }
}

// Visitor to walk through syntax tree and extract tokens
private class TokenVisitor: SyntaxVisitor {
    private let tokenHandler: (TokenSyntax) -> Void
    
    init(tokenHandler: @escaping (TokenSyntax) -> Void) {
        self.tokenHandler = tokenHandler
        super.init(viewMode: .sourceAccurate)
    }
    
    override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        tokenHandler(node)
        return .visitChildren
    }
}
