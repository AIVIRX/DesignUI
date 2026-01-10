//
//  FontModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Font Modifier Editor
struct FontModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var fontSize: String = "body"
    @State private var fontWeight: String = "regular"
    
    private let fontSizes: [(name: String, displayName: String)] = [
        ("largeTitle", "Large Title"),
        ("title", "Title"),
        ("title2", "Title 2"),
        ("title3", "Title 3"),
        ("headline", "Headline"),
        ("body", "Body"),
        ("callout", "Callout"),
        ("subheadline", "Subheadline"),
        ("footnote", "Footnote"),
        ("caption", "Caption"),
        ("caption2", "Caption 2")
    ]
    
    private let fontWeights: [(name: String, displayName: String)] = [
        ("ultraLight", "Ultra Light"),
        ("thin", "Thin"),
        ("light", "Light"),
        ("regular", "Regular"),
        ("medium", "Medium"),
        ("semibold", "Semibold"),
        ("bold", "Bold"),
        ("heavy", "Heavy"),
        ("black", "Black")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Size List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Size")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(fontSizes, id: \.name) { sizeInfo in
                            FontOptionRow(
                                name: sizeInfo.name,
                                displayName: sizeInfo.displayName,
                                isSelected: fontSize == sizeInfo.name,
                                font: getFont(for: sizeInfo.name),
                                weight: .regular,
                                onSelect: {
                                    fontSize = sizeInfo.name
                                    saveFont()
                                }
                            )
                            
                            if sizeInfo.name != fontSizes.last?.name {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Weight List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(fontWeights, id: \.name) { weightInfo in
                            FontOptionRow(
                                name: weightInfo.name,
                                displayName: weightInfo.displayName,
                                isSelected: fontWeight == weightInfo.name,
                                font: .body,
                                weight: getWeight(for: weightInfo.name),
                                onSelect: {
                                    fontWeight = weightInfo.name
                                    saveFont()
                                }
                            )
                            
                            if weightInfo.name != fontWeights.last?.name {
                                Divider()
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .frame(maxHeight: 400)
        .onAppear {
            loadFont()
        }
        .onChange(of: modifier) { _, _ in
            loadFont()
        }
    }
    
    private var previewFont: Font {
        getFont(for: fontSize)
    }
    
    private var previewWeight: Font.Weight {
        getWeight(for: fontWeight)
    }
    
    private func getFont(for name: String) -> Font {
        switch name {
        case "largeTitle": return .largeTitle
        case "title": return .title
        case "title2": return .title2
        case "title3": return .title3
        case "headline": return .headline
        case "callout": return .callout
        case "subheadline": return .subheadline
        case "footnote": return .footnote
        case "caption": return .caption
        case "caption2": return .caption2
        default: return .body
        }
    }

    private func getWeight(for name: String) -> Font.Weight {
        switch name {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .regular
        }
    }
    
    private func loadFont() {
        fontSize = modifier.properties["fontSize"] as? String ?? "body"
        fontWeight = modifier.properties["fontWeight"] as? String ?? "regular"
    }
    
    private func saveFont() {
        var updatedModifier = modifier
        updatedModifier.properties["fontSize"] = fontSize
        updatedModifier.properties["fontWeight"] = fontWeight
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Font Option Row
struct FontOptionRow: View {
    let name: String
    let displayName: String
    let isSelected: Bool
    var font: Font = .body
    var weight: Font.Weight = .regular
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(displayName)
                    .font(font)
                    .fontWeight(weight)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isHovered ? Color.gray.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
