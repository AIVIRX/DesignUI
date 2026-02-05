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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
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
                
                // Slider Block
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider
                        UndoableSlider(
                            value: $opacityValue,
                            range: 0...1,
                            onValueChanged: { _ in
                                saveOpacityContinuous()
                            },
                            onEditingEnded: { _ in
                                saveOpacity()
                            }
                        )
                        
                        // Value label
                        Text("\(Int(opacityValue * 100))")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Presets Block
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { preset in
                                Button(action: {
                                    opacityValue = preset
                                    saveOpacity()
                                }) {
                                    Text("\(Int(preset * 100))%")
                                        .font(.caption)
                                        .fontWeight(abs(opacityValue - preset) < 0.01 ? .semibold : .regular)
                                        .foregroundColor(abs(opacityValue - preset) < 0.01 ? .white : .primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(abs(opacityValue - preset) < 0.01 ? Color.blue : Color.secondary.opacity(0.1))
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding()
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
    }
    
    /// Continuous save during slider drag - no undo state save
    private func saveOpacityContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["opacity"] = opacityValue
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}
