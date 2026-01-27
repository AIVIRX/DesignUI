//
//  TransformModifierEditors.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Rotation Modifier Editor
struct RotationModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var angle: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Rotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview showing current angle
                    Text("\(Int(angle))°")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Rotation Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                            .rotationEffect(.degrees(angle))
                        
                        // Slider
                        // Slider
                        UndoableSlider(
                            value: $angle,
                            range: 0...360,
                            onValueChanged: { _ in saveAngleContinuous() },
                            onEditingEnded: { _ in saveAngle() }
                        )
                        
                        // Value label
                        Text("\(Int(angle))°")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
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
                        ForEach([0, 45, 90, 135, 180, 225, 270, 315], id: \.self) { preset in
                            PresetRotationRow(
                                value: Double(preset),
                                isSelected: Int(angle) == preset,
                                onSelect: {
                                    angle = Double(preset)
                                    saveAngle()
                                }
                            )
                            
                            if preset != 315 {
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
        .frame(maxHeight: 400)
        .onAppear {
            loadAngle()
        }
        .onChange(of: modifier) { _, _ in
            loadAngle()
        }
    }
    
    private func loadAngle() {
        angle = modifier.getDouble(key: "angle", defaultValue: 0)
    }
    
    private func saveAngle() {
        var updatedModifier = modifier
        updatedModifier.properties["angle"] = angle
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    private func saveAngleContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["angle"] = angle
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

// MARK: - Preset Rotation Row
struct PresetRotationRow: View {
    let value: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon (visual representation of angle)
                Image(systemName: "arrow.up")
                    .rotationEffect(.degrees(value))
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                // Label
                Text("\(Int(value))°")
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


// MARK: - Scale Modifier Editor
// MARK: - Scale Modifier Editor
// MARK: - Scale Modifier Editor
struct ScaleModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var scale: Double = 1.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Scale")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview showing current scale
                    Text("\(String(format: "%.1fx", scale))")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Slider
                VStack(spacing: 4) {
                    HStack {
                        Text("Factor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        UndoableSlider(
                            value: $scale,
                            range: 0.5...8.0,
                            step: 0.5,
                            onValueChanged: { _ in saveScaleContinuous() },
                            onEditingEnded: { _ in saveScale() }
                        )
                        
                        Text("\(String(format: "%.1f", scale))")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                
                // Quick presets list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach([0.5, 1.0, 1.5, 2.0, 3.0], id: \.self) { preset in
                            PresetScaleRow(
                                value: preset,
                                isSelected: abs(scale - preset) < 0.1,
                                onSelect: {
                                    scale = preset
                                    saveScale()
                                }
                            )
                            
                            if preset != 3.0 {
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
        .frame(maxHeight: 400)
        .onAppear {
            loadScale()
        }
        .onChange(of: modifier) { _, _ in
            loadScale()
        }
    }
    
    private func loadScale() {
        // Since we are enforcing uniform scale, just read X
        scale = modifier.getDouble(key: "x", defaultValue: 1.0)
    }
    
    private func saveScale() {
        var updatedModifier = modifier
        updatedModifier.properties["x"] = scale
        updatedModifier.properties["y"] = scale
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    private func saveScaleContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["x"] = scale
        updatedModifier.properties["y"] = scale
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

// MARK: - Preset Scale Row
struct PresetScaleRow: View {
    let value: Double
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon (visual representation)
                Image(systemName: "square.dashed")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .scaleEffect(CGFloat(min(max(value, 0.5), 1.2))) // Clamp visual scale
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                // Label
                Text("\(String(format: "%.2fx", value))")
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

// MARK: - Offset Modifier Editor
// MARK: - Offset Modifier Editor
struct OffsetModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var offsetX: Double = 0
    @State private var offsetY: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Offset")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview showing current offset
                    Text("x: \(Int(offsetX)), y: \(Int(offsetY))")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Fields
                VStack(spacing: 12) {
                    // X Offset
                    HStack {
                        Text("X")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        TextField("", value: $offsetX, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: offsetX) { _, _ in saveOffset() }
                            .onSubmit { saveOffset() }
                    }
                    
                    // Y Offset
                    HStack {
                        Text("Y")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 20, alignment: .leading)
                        
                        TextField("", value: $offsetY, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: offsetY) { _, _ in saveOffset() }
                            .onSubmit { saveOffset() }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                
                // Quick presets list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(presets, id: \.name) { preset in
                            PresetOffsetRow(
                                name: preset.name,
                                icon: preset.icon,
                                value: preset.value,
                                isSelected: abs(offsetX - preset.value.x) < 0.1 && abs(offsetY - preset.value.y) < 0.1,
                                onSelect: {
                                    offsetX = preset.value.x
                                    offsetY = preset.value.y
                                    saveOffset()
                                }
                            )
                            
                            if preset.name != "Shadow" {
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
            loadOffset()
        }
        .onChange(of: modifier) { _, _ in
            loadOffset()
        }
    }
    
    private let presets: [(name: String, icon: String, value: (x: Double, y: Double))] = [
        ("Reset", "circle.slash", (0, 0)),
        ("Right", "arrow.right", (10, 0)),
        ("Left", "arrow.left", (-10, 0)),
        ("Down", "arrow.down", (0, 10)),
        ("Up", "arrow.up", (0, -10)),
        ("Shadow", "square.on.square", (4, 4))
    ]
    
    private func loadOffset() {
        offsetX = modifier.getDouble(key: "x", defaultValue: 0)
        offsetY = modifier.getDouble(key: "y", defaultValue: 0)
    }
    
    private func saveOffset() {
        var updatedModifier = modifier
        updatedModifier.properties["x"] = offsetX
        updatedModifier.properties["y"] = offsetY
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Preset Offset Row
struct PresetOffsetRow: View {
    let name: String
    let icon: String
    let value: (x: Double, y: Double)
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
                
                // Values
                Text("(\(Int(value.x)), \(Int(value.y)))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                
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
