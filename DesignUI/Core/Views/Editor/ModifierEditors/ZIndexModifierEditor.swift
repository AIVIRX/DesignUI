//
//  ZIndexModifierEditor.swift
//
//  Created by Maicol Cabreja on 2/6/26.
//

import SwiftUI

struct ZIndexModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var zIndex: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Z Index")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(zIndex))")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Stepper Control
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "square.3.layers.3d.down.right")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Value and Stepper
                        HStack {
                            Text("\(Int(zIndex))")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .monospacedDigit()
                            
                            Spacer()
                            
                            Stepper("", value: $zIndex, step: 1)
                                .onChange(of: zIndex) { _, _ in
                                    saveIndex()
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Layer Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        PresetZIndexRow(name: "Bring to Front", icon: "arrow.up.to.line.square", value: 10, isSelected: zIndex == 10) {
                            zIndex = 10
                            saveIndex()
                        }
                        
                        Divider().padding(.leading, 44)
                        
                        PresetZIndexRow(name: "Default", icon: "square", value: 0, isSelected: zIndex == 0) {
                            zIndex = 0
                            saveIndex()
                        }
                        
                        Divider().padding(.leading, 44)
                        
                        PresetZIndexRow(name: "Send to Back", icon: "arrow.down.to.line.square", value: -10, isSelected: zIndex == -10) {
                            zIndex = -10
                            saveIndex()
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
        .frame(maxHeight: 350)
        .onAppear {
            loadIndex()
        }
        .onChange(of: modifier) { _, _ in
            loadIndex()
        }
    }
    
    private func loadIndex() {
        zIndex = modifier.getDouble(key: "index", defaultValue: 0)
    }
    
    private func saveIndex() {
        var updatedModifier = modifier
        updatedModifier.properties["index"] = zIndex
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Preset Z Index Row
struct PresetZIndexRow: View {
    let name: String
    let icon: String
    let value: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                // Label
                Text(name)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Value hint
                Text("\(value)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
                // Checkmark
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
