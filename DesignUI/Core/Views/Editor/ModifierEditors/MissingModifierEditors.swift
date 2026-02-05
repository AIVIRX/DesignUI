//
//  MissingModifierEditors.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/23/24.
//

import SwiftUI

// MARK: - Blur Modifier Editor
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

// MARK: - Preset Blur Row
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

// MARK: - ClipShape Modifier Editor
struct ClipShapeModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var selectedShape: String = "Rectangle"
    @State private var cornerRadius: Double = 10
    
    private let shapes: [(name: String, icon: String, id: String)] = [
        ("Rectangle", "rectangle", "Rectangle"),
        ("Rounded Rectangle", "rectangle.roundedtop", "RoundedRectangle"),
        ("Circle", "circle", "Circle"),
        ("Capsule", "capsule", "Capsule"),
        ("Ellipse", "oval", "Ellipse")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Clip Shape")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(selectedShape)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Corner Radius (only for RoundedRectangle)
                if selectedShape == "RoundedRectangle" {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Corner Radius")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(cornerRadius))")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        
                        Slider(value: $cornerRadius, in: 0...100)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                            .onChange(of: cornerRadius) { _, _ in
                                saveShape()
                            }
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                }
                
                // Shapes List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shapes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(shapes, id: \.id) { shape in
                            PresetShapeRow(
                                name: shape.name,
                                icon: shape.icon,
                                isSelected: selectedShape == shape.id,
                                onSelect: {
                                    selectedShape = shape.id
                                    saveShape()
                                }
                            )
                            
                            if shape.id != "Ellipse" {
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
            loadShape()
        }
        .onChange(of: modifier) { _, _ in
            loadShape()
        }
    }
    
    private func loadShape() {
        selectedShape = modifier.properties["shape"] as? String ?? "Rectangle"
        cornerRadius = modifier.getDouble(key: "cornerRadius", defaultValue: 10)
    }
    
    private func saveShape() {
        var updatedModifier = modifier
        updatedModifier.properties["shape"] = selectedShape
        if selectedShape == "RoundedRectangle" {
            updatedModifier.properties["cornerRadius"] = cornerRadius
        } else {
            updatedModifier.properties.removeValue(forKey: "cornerRadius")
        }
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Preset Shape Row
struct PresetShapeRow: View {
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

// MARK: - Mask Modifier Editor
struct MaskModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @FocusState private var isCornerRadiusFocused: Bool
    
    private let maskTypes = ["rectangle", "roundedRectangle", "circle", "capsule", "linearGradient"]
    
    private var selectedMask: String {
        modifier.properties["shape"] as? String ?? "rectangle"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mask Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { selectedMask },
                    set: { newValue in
                        var updatedModifier = modifier
                        updatedModifier.properties["shape"] = newValue
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                )) {
                    ForEach(maskTypes, id: \.self) { mask in
                        Text(mask.capitalized).tag(mask)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if selectedMask == "roundedRectangle" {
                cornerRadiusField
            }
        }
    }
    
    private var cornerRadiusField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Corner Radius")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let radiusBinding = Binding<String>(
                get: { String(format: "%.0f", modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)) },
                set: { newValue in
                    if let value = Double(newValue) {
                        var updatedModifier = modifier
                        updatedModifier.properties["cornerRadius"] = CGFloat(value)
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                }
            )
            
            TextField("10", text: radiusBinding)
                .textFieldStyle(.roundedBorder)
                .focused($isCornerRadiusFocused)
                .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                    isCornerRadiusFocused = false
                }
                .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                    isCornerRadiusFocused = false
                }
        }
    }
}

// MARK: - Border Modifier Editor
// MARK: - Border Modifier Editor
struct BorderModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var width: Double = 1
    @State private var selectedColorName: String = "Black"
    @State private var isColorExpanded: Bool = false
    
    private let colors: [(name: String, color: Color)] = [
        ("Black", .black),
        ("White", .white),
        ("Gray", .gray),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Primary", .primary),
        ("Secondary", .secondary)
    ]
    
    // Helper to get current color
    private var currentColor: Color {
        colors.first { $0.name == selectedColorName }?.color ?? .black
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Border")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(currentColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                    
                    Text("\(Int(width)) pt")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Color Section
                VStack(alignment: .leading, spacing: 8) {
                    Button(action: { withAnimation { isColorExpanded.toggle() } }) {
                        HStack {
                            Text("Color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(currentColor)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                                
                                Text(selectedColorName)
                                    .font(.system(size: 13))
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .rotationEffect(.degrees(isColorExpanded ? 90 : 0))
                            }
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if isColorExpanded {
                        VStack(spacing: 0) {
                            ForEach(colors, id: \.name) { colorOption in
                                BorderColorRow(
                                    name: colorOption.name,
                                    color: colorOption.color,
                                    isSelected: selectedColorName == colorOption.name,
                                    onSelect: {
                                        selectedColorName = colorOption.name
                                        saveBorder()
                                        withAnimation { isColorExpanded = false }
                                    }
                                )
                                
                                if colorOption.name != colors.last?.name {
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
                
                // Width Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "lineweight")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider
                        Slider(value: $width, in: 0...20)
                            .onChange(of: width) { _, _ in
                                saveBorder()
                            }
                        
                        // Value label
                        Text("\(Int(width))")
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
                
                // Quick Width Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Width Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach([1, 2, 4, 8], id: \.self) { preset in
                            Button(action: {
                                width = Double(preset)
                                saveBorder()
                            }) {
                                Text("\(preset)pt")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Int(width) == preset ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
                                    .foregroundColor(Int(width) == preset ? .blue : .primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxHeight: 450)
        .onAppear {
            loadBorder()
        }
        .onChange(of: modifier) { _, _ in
            loadBorder()
        }
    }
    
    private func loadBorder() {
        width = modifier.getDouble(key: "width", defaultValue: 1)
        // Load color logic - simplified for now as we store color string or custom
        // In a real app we'd parse the color property back to a name
        if let storedColor = modifier.properties["color"] as? String {
             // Extract name if format is "color:name"
             if storedColor.hasPrefix("color:") {
                 let name = String(storedColor.dropFirst(6))
                 selectedColorName = name.capitalized // Naive capitalization
             }
        }
    }
    
    private func saveBorder() {
        var updatedModifier = modifier
        updatedModifier.properties["width"] = width
        updatedModifier.properties["color"] = "color:\(selectedColorName.lowercased())"
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Border Color Row
struct BorderColorRow: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color Preview
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                
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

// MARK: - Aspect Ratio Modifier Editor
// MARK: - Aspect Ratio Modifier Editor
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

// MARK: - Preset Ratio Row
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

// MARK: - Z Index Modifier Editor
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
