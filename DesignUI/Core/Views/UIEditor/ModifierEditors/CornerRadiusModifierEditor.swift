//
//  CornerRadiusModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Corner Radius Modifier Editor
struct CornerRadiusModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var radiusText: String = ""
    
    var body: some View {
        HStack {
            Text("Radius")
            
            Spacer()
            
            TextField("8", text: $radiusText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .onChange(of: radiusText) { _, newValue in
                    // Allow empty string while typing
                    if newValue.isEmpty {
                        return
                    }
                    // Try to parse the value
                    if let value = Double(newValue) {
                        var updatedModifier = modifier
                        updatedModifier.properties["radius"] = CGFloat(value)
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                }
                .onSubmit {
                    // When user finishes editing, ensure we have a valid value
                    if radiusText.isEmpty || Double(radiusText) == nil {
                        radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 8))
                    }
                }
        }
        .onAppear {
            radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 8))
        }
        .onChange(of: modifier) { _, _ in
            // Update text field if modifier changes externally
            let currentRadius = modifier.getCGFloat(key: "radius", defaultValue: 8)
            if Double(radiusText) != Double(currentRadius) {
                radiusText = String(format: "%.0f", currentRadius)
            }
        }
    }
}
