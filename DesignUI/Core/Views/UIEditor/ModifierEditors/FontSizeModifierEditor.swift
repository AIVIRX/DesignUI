//
//  FontSizeModifierEditor.swift
//  DesignUI
//
//  Created by ChatGPT on 11/25/25.
//

import SwiftUI

struct FontSizeModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var fontSize: String = "body"
    
    private let fontSizes = [
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Font Size")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Font Size", selection: $fontSize) {
                    ForEach(fontSizes, id: \.0) { size in
                        Text(size.1).tag(size.0)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: fontSize) { _, newValue in
                    var updatedModifier = modifier
                    updatedModifier.properties["fontSize"] = newValue
                    modifier = updatedModifier
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
            }
        }
        .onAppear {
            fontSize = modifier.properties["fontSize"] as? String ?? "body"
        }
    }
}

