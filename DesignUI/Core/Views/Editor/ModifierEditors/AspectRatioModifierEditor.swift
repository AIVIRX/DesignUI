//
//  AspectRatioModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/6/26.
//

import SwiftUI

struct AspectRatioModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var selectedRatioName: String = "Original"
    
    private let presets: [(name: String, icon: String, ratio: Double?)] = [
        ("Original", "photo", nil),
        ("Square (1:1)", "square", 1.0),
        ("16:9", "rectangle.ratio.16.to.9", 16.0/9.0),
        ("4:3", "rectangle.ratio.4.to.3", 4.0/3.0),
        ("3:2", "rectangle.ratio.3.to.2", 3.0/2.0),
        ("2:1", "rectangle", 2.0/1.0)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Aspect Ratio")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(selectedRatioName)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Presets List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(presets, id: \.name) { preset in
                            PresetRatioRow(
                                name: preset.name,
                                icon: preset.icon,
                                isSelected: selectedRatioName == preset.name,
                                onSelect: {
                                    selectedRatioName = preset.name
                                    saveRatio(preset.ratio)
                                }
                            )
                            
                            if preset.name != presets.last?.name {
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
        .frame(maxHeight: 450)
        .onAppear {
            loadRatio()
        }
        .onChange(of: modifier) { _, _ in
            loadRatio()
        }
    }
    
    private func loadRatio() {
        if let ratio = modifier.properties["ratio"] as? Double {
            // Find matching preset or default to Custom (though we don't have custom yet, maybe add later?)
            // efficient match
            if let match = presets.first(where: {
                guard let r = $0.ratio else { return false }
                return abs(r - ratio) < 0.01
            }) {
                selectedRatioName = match.name
            } else {
                selectedRatioName = "Custom"
            }
        } else {
            selectedRatioName = "Original"
        }
    }
    
    private func saveRatio(_ ratio: Double?) {
        var updatedModifier = modifier
        if let r = ratio {
            updatedModifier.properties["ratio"] = r
            updatedModifier.properties["aspectRatio"] = "fit" // Ensure consistent mode
        } else {
            updatedModifier.properties.removeValue(forKey: "ratio")
            updatedModifier.properties["aspectRatio"] = "fit" // Reset to default mode logic
        }
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

struct PresetRatioRow: View {
    let name: String
    let icon: String
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
