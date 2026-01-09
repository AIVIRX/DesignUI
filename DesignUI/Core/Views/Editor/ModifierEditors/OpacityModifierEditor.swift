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
    @State private var opacityValue: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Opacity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(opacityValue * 100))%")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                Slider(value: $opacityValue, in: 0...1)
                    .onChange(of: opacityValue) { _, newValue in
                        modifier.properties["opacity"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            opacityValue = modifier.getDouble(key: "opacity", defaultValue: 1.0)
        }
        .onChange(of: modifier) { _, newModifier in
            // Update slider if modifier changes externally
            let currentOpacity = newModifier.getDouble(key: "opacity", defaultValue: 1.0)
            if opacityValue != currentOpacity {
                opacityValue = currentOpacity
            }
        }
    }
}
