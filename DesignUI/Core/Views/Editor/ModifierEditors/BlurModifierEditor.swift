//
//  BlurModifierEditor.swift
//
//  Created by Maicol Cabreja on 2/6/26.
//

import SwiftUI

struct BlurModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var radius: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Blur")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview showing current radius
                    Text("\(Int(radius)) pt")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Radius Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "drop.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider
                        Slider(value: $radius, in: 0...100)
                            .onChange(of: radius) { _, _ in
                                saveRadius()
                            }
                        
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
                        ForEach([0, 2, 5, 10, 20], id: \.self) { preset in
                            PresetBlurRow(
                                value: Double(preset),
                                isSelected: Int(radius) == preset,
                                onSelect: {
                                    radius = Double(preset)
                                    saveRadius()
                                }
                            )
                            
                            if preset != 20 {
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
        radius = modifier.getDouble(key: "radius", defaultValue: 0)
    }
    
    private func saveRadius() {
        var updatedModifier = modifier
        updatedModifier.properties["radius"] = radius
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

struct PresetBlurRow: View {
    let value: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon (visual representation of blur)
                Image(systemName: "drop")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .frame(width: 20, height: 20)
                
                // Label
                Text("\(Int(value)) pt")
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
