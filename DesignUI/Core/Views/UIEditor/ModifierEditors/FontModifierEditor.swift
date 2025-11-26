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
    @State private var fontWeight: String = "regular"
    
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
            fontWeight = modifier.properties["fontWeight"] as? String ?? "regular"
        }
    }
}
