//
//  OpacityModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Opacity Modifier Editor
struct OpacityModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var opacityText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opacity")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", text: $opacityText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: opacityText) { _, newValue in
                        // Allow empty string while typing
                        if newValue.isEmpty {
                            return
                        }
                        // Try to parse the value
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["opacity"] = value
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        // When user finishes editing, ensure we have a valid value
                        if opacityText.isEmpty || Double(opacityText) == nil {
                            opacityText = String(format: "%.1f", modifier.getDouble(key: "opacity", defaultValue: 1.0))
                        }
                    }
            }
        }
        .onAppear {
            opacityText = String(format: "%.1f", modifier.getDouble(key: "opacity", defaultValue: 1.0))
        }
        .onChange(of: modifier) { _, _ in
            // Update text field if modifier changes externally
            let currentOpacity = modifier.getDouble(key: "opacity", defaultValue: 1.0)
            if Double(opacityText) != currentOpacity {
                opacityText = String(format: "%.1f", currentOpacity)
            }
        }
    }
}
