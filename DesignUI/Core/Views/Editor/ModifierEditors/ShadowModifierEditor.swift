//
//  ShadowModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Shadow Modifier Editor
struct ShadowModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var radius: CGFloat = 4
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 2
    @State private var opacity: Double = 0.3
    @State private var selectedColorName: String = "black"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Shadow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(currentColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                    
                    Text("\(Int(radius))pt")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Color Section (re-use universal picker)
                UniversalColorPickerView(
                    selectedColorName: $selectedColorName,
                    opacityValue: $opacity,
                    title: "Color",
                    onColorChanged: { saveShadowContinuous() },
                    onColorConfirmed: { saveShadow() }
                )
                
                // Radius Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Radius")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(radius))")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        UndoableSlider(
                            value: Binding(
                                get: { Double(radius) },
                                set: { radius = CGFloat($0) }
                            ),
                            range: 0...50,
                            step: 1.0,
                            onValueChanged: { _ in saveShadowContinuous() },
                            onEditingEnded: { _ in saveShadow() }
                        )
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                
                // Offset Sliders
                VStack(spacing: 16) {
                    // X Offset
                    VStack(spacing: 8) {
                        HStack {
                            Text("Offset X")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(offsetX))")
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        UndoableSlider(
                            value: Binding(
                                get: { Double(offsetX) },
                                set: { offsetX = CGFloat($0) }
                            ),
                            range: -50...50,
                            step: 1.0,
                            onValueChanged: { _ in saveShadowContinuous() },
                            onEditingEnded: { _ in saveShadow() }
                        )
                    }
                    
                    // Y Offset
                    VStack(spacing: 8) {
                        HStack {
                            Text("Offset Y")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(offsetY))")
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        UndoableSlider(
                            value: Binding(
                                get: { Double(offsetY) },
                                set: { offsetY = CGFloat($0) }
                            ),
                            range: -50...50,
                            step: 1.0,
                            onValueChanged: { _ in saveShadowContinuous() },
                            onEditingEnded: { _ in saveShadow() }
                        )
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
            }
            .padding()
        }
        .frame(maxHeight: 500)
        .onAppear {
            loadShadow()
        }
        .onChange(of: modifier) { _, _ in
            loadShadow()
        }
    }

    private var currentColor: Color {
        UniversalColorPickerView.swiftUIColors.first(where: { $0.name == selectedColorName })?.color ?? .black
    }
    
    private func loadShadow() {
        radius = modifier.getCGFloat(key: "radius", defaultValue: 4)
        opacity = modifier.getDouble(key: "opacity", defaultValue: 0.3)
        
        // Load offset
        if let x = modifier.properties["x"] as? CGFloat { offsetX = x }
        else if let x = modifier.properties["offsetX"] as? CGFloat { offsetX = x }
        
        if let y = modifier.properties["y"] as? CGFloat { offsetY = y }
        else if let y = modifier.properties["offsetY"] as? CGFloat { offsetY = y }
        
        // Load color
        if let colorString = modifier.properties["colorString"] as? String {
            let parts = colorString.split(separator: ":")
            selectedColorName = String(parts.first ?? "black").lowercased()
            if parts.count >= 2, let parsedOpacity = Double(parts[1]) {
                opacity = parsedOpacity
            }
        } else if let colorValue = modifier.properties["color"] as? String {
            let parts = colorValue.split(separator: ":")
            selectedColorName = String(parts.first ?? "black").lowercased()
            if parts.count >= 2, let parsedOpacity = Double(parts[1]) {
                opacity = parsedOpacity
            }
        } else {
            selectedColorName = "black"
        }
    }
    
    private func saveShadow() {
        var updatedModifier = modifier
        radius = CGFloat(radius.rounded())
        offsetX = CGFloat(offsetX.rounded())
        offsetY = CGFloat(offsetY.rounded())
        updatedModifier.properties["radius"] = radius
        updatedModifier.properties["opacity"] = opacity
        updatedModifier.properties["x"] = offsetX
        updatedModifier.properties["y"] = offsetY
        
        // Save the color name as string for better consistency
        let colorName = selectedColorName.lowercased()
        updatedModifier.properties["colorString"] = "\(colorName):\(opacity)"
        updatedModifier.properties["color"] = colorName
        
        modifier = updatedModifier
    }
    
    private func saveShadowContinuous() {
        var updatedModifier = modifier
        radius = CGFloat(radius.rounded())
        offsetX = CGFloat(offsetX.rounded())
        offsetY = CGFloat(offsetY.rounded())
        updatedModifier.properties["radius"] = radius
        updatedModifier.properties["opacity"] = opacity
        updatedModifier.properties["x"] = offsetX
        updatedModifier.properties["y"] = offsetY
        
        // Save the color name as string for better consistency
        let colorName = selectedColorName.lowercased()
        updatedModifier.properties["colorString"] = "\(colorName):\(opacity)"
        updatedModifier.properties["color"] = colorName
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}
