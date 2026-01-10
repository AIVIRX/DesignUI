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
    @ObservedObject var component: UIComponent
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
                
                // Use UndoableSlider for proper undo handling
                UndoableSlider(
                    value: $opacityValue,
                    range: 0...1,
                    onValueChanged: { _ in
                        // Continuous update during drag - no undo save
                        saveOpacityContinuous()
                    },
                    onEditingEnded: { _ in
                        // Final save when drag ends
                        saveOpacity()
                    }
                )
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
    
    private func saveOpacity() {
        var updatedModifier = modifier
        updatedModifier.properties["opacity"] = opacityValue
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
        }
    }
    
    /// Continuous save during slider drag - no undo state save
    private func saveOpacityContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["opacity"] = opacityValue
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}
