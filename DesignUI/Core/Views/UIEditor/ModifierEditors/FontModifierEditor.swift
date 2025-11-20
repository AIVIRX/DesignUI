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
    @State private var fontName: String = "body"
    @State private var fontSizeText: String = ""
    @State private var fontWeight: String = "regular"
    
    private let fontNames = [
        ("body", "Body"),
        ("title", "Title"),
        ("headline", "Headline"),
        ("subheadline", "Subheadline"),
        ("caption", "Caption"),
        ("footnote", "Footnote"),
        ("largeTitle", "Large Title")
    ]
    
    private let fontWeights = [
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Font")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Font Name
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Font Name", selection: $fontName) {
                    ForEach(fontNames, id: \.0) { font in
                        Text(font.1).tag(font.0)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: fontName) { _, newValue in
                    modifier.properties["fontName"] = newValue
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
            }
            
            // Font Size
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Size")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("17", text: $fontSizeText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: fontSizeText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["fontSize"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if fontSizeText.isEmpty || Double(fontSizeText) == nil {
                            fontSizeText = String(format: "%.0f", modifier.getCGFloat(key: "fontSize", defaultValue: 17))
                        }
                    }
            }
            
            // Font Weight
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Weight")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Font Weight", selection: $fontWeight) {
                    ForEach(fontWeights, id: \.0) { weight in
                        Text(weight.1).tag(weight.0)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: fontWeight) { _, newValue in
                    modifier.properties["fontWeight"] = newValue
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
            }
        }
        .onAppear {
            fontName = modifier.properties["fontName"] as? String ?? "body"
            fontSizeText = String(format: "%.0f", modifier.getCGFloat(key: "fontSize", defaultValue: 17))
            fontWeight = modifier.properties["fontWeight"] as? String ?? "regular"
        }
        .onChange(of: modifier) { _, _ in
            let currentFontSize = modifier.getCGFloat(key: "fontSize", defaultValue: 17)
            if Double(fontSizeText) != Double(currentFontSize) {
                fontSizeText = String(format: "%.0f", currentFontSize)
            }
        }
    }
}
