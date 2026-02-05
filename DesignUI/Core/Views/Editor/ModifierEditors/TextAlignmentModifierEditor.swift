//
//  TextAlignmentModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Text Alignment Modifier Editor
// MARK: - Text Alignment Modifier Editor
struct TextAlignmentModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var alignment: String = "leading"
    @State private var sliderValue: Double = 0
    
    private let alignments: [(name: String, value: String, icon: String)] = [
        ("Leading", "leading", "text.alignleft"),
        ("Center", "center", "text.aligncenter"),
        ("Trailing", "trailing", "text.alignright")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Text Alignment")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(alignment.capitalized)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Alignment Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: getCurrentIcon())
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider (0 = Leading, 1 = Center, 2 = Trailing)
                        UndoableSlider(
                            value: $sliderValue,
                            range: 0...2,
                            step: 1,
                            onValueChanged: { newValue in
                                updateAlignmentFromSlider(value: newValue)
                            },
                            onEditingEnded: { _ in
                                saveAlignment()
                            }
                        )
                        
                        // Value label (Hidden or descriptive?)
                        // Using text representation instead of number
                        Text(alignment.capitalized.prefix(1))
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
                
                // Presets List
                VStack(alignment: .leading, spacing: 16) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(alignments, id: \.value) { item in
                            AlignmentOptionRow(
                                displayName: item.name,
                                icon: item.icon,
                                isSelected: alignment == item.value,
                                onSelect: {
                                    alignment = item.value
                                    updateSliderFromAlignment()
                                    saveAlignment()
                                }
                            )
                            
                            if item.value != alignments.last?.value {
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
        .frame(maxHeight: 500)
        .onAppear {
            loadAlignment()
        }
        .onChange(of: modifier) { _, _ in
            loadAlignment()
        }
    }
    
    private func getCurrentIcon() -> String {
        alignments.first(where: { $0.value == alignment })?.icon ?? "text.alignleft"
    }
    
    private func loadAlignment() {
        alignment = modifier.properties["alignment"] as? String ?? "leading"
        updateSliderFromAlignment()
    }
    
    private func updateSliderFromAlignment() {
        switch alignment {
        case "center": sliderValue = 1
        case "trailing": sliderValue = 2
        default: sliderValue = 0
        }
    }
    
    private func updateAlignmentFromSlider(value: Double) {
        let intValue = Int(round(value))
        switch intValue {
        case 1: alignment = "center"
        case 2: alignment = "trailing"
        default: alignment = "leading"
        }
        // Continuous update
        saveAlignmentContinuous()
    }
    
    private func saveAlignment() {
        var updatedModifier = modifier
        updatedModifier.properties["alignment"] = alignment
        modifier = updatedModifier
    }
    
    private func saveAlignmentContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["alignment"] = alignment
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

struct AlignmentOptionRow: View {
    let displayName: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24, height: 24)
                
                // Label
                Text(displayName)
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
