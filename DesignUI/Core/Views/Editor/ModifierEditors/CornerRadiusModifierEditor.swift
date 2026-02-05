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
    @ObservedObject var component: UIComponent
    @State private var radius: CGFloat = 8
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Corner Radius")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview showing current radius
                    Text("\(Int(radius))pt")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Radius Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "square.fill.on.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider
                        UndoableSlider(
                            value: Binding(
                                get: { Double(radius) },
                                set: { radius = CGFloat($0) }
                            ),
                            range: 0...100,
                            onValueChanged: { _ in
                                saveRadiusContinuous()
                            },
                            onEditingEnded: { _ in
                                saveRadius()
                            }
                        )
                        
                        // Value label
                        Text("\(Int(radius))")
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
                
                // Quick presets list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach([4, 8, 12, 16, 20, 24], id: \.self) { preset in
                            PresetRadiusRow(
                                value: CGFloat(preset),
                                isSelected: Int(radius) == preset,
                                onSelect: {
                                    radius = CGFloat(preset)
                                    saveRadius()
                                }
                            )
                            
                            if preset != 24 {
                                Divider()
                                    .padding(.leading, 44)
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
        }
        .onAppear {
            loadRadius()
        }
        .onChange(of: modifier) { _, _ in
            loadRadius()
        }
    }
    
    private func loadRadius() {
        radius = modifier.getCGFloat(key: "radius", defaultValue: 8)
    }
    
    private func saveRadius() {
        var updatedModifier = modifier
        updatedModifier.properties["radius"] = radius
        modifier = updatedModifier
    }
    
    private func saveRadiusContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["radius"] = radius
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

// MARK: - Preset Radius Row
struct PresetRadiusRow: View {
    let value: CGFloat
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon (visual representation of radius)
                RoundedRectangle(cornerRadius: value / 4) // Scaled down visual
                    .stroke(isSelected ? Color.blue : Color.primary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .padding(2)
                
                // Label
                Text("\(Int(value))pt")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Checkmark for selected
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
