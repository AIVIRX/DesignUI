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
    @State private var radiusText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Blur Radius")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $radiusText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: radiusText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["radius"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if radiusText.isEmpty || Double(radiusText) == nil {
                            radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 0))
                        }
                    }
            }
        }
        .onAppear {
            radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 0))
        }
        .onChange(of: modifier) { _, _ in
            let currentRadius = modifier.getCGFloat(key: "radius", defaultValue: 0)
            if Double(radiusText) != Double(currentRadius) {
                radiusText = String(format: "%.0f", currentRadius)
            }
        }
    }
}

// MARK: - ClipShape Modifier Editor
struct ClipShapeModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private let shapeTypes = ["Rectangle", "RoundedRectangle", "Circle", "Capsule", "Ellipse"]
    
    private var selectedShape: String {
        modifier.properties["shape"] as? String ?? "Rectangle"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Shape")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { selectedShape },
                    set: { newValue in
                        var updatedModifier = modifier
                        updatedModifier.properties["shape"] = newValue
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                )) {
                    ForEach(shapeTypes, id: \.self) { shape in
                        Text(shape.capitalized).tag(shape)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if selectedShape == "roundedRectangle" {
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
        }
    }
}

// MARK: - Mask Modifier Editor
struct MaskModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
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
        }
    }
}

// MARK: - Border Modifier Editor
struct BorderModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var widthText: String = ""
    @State private var isColorPickerPresented = false
    
    private var currentColor: Color {
        modifier.getColor(key: "color", defaultValue: .primary)
    }
    
    private let swiftUIColors: [(String, Color)] = [
        ("Primary", .primary),
        ("Secondary", .secondary),
        ("Black", .black),
        ("White", .white),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Blue", .blue),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Gray", .gray)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            colorPickerSection
            widthSection
        }
        .onAppear {
            widthText = String(format: "%.0f", modifier.getCGFloat(key: "width", defaultValue: 1))
        }
    }
    
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Border Color")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: { isColorPickerPresented = true }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentColor)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    Text(colorName(for: currentColor))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(PlainButtonStyle())
            .popover(isPresented: $isColorPickerPresented) {
                colorGrid
            }
        }
    }
    
    private var widthSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Border Width")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("1", text: $widthText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: widthText) { _, newValue in
                    if newValue.isEmpty { return }
                    if let value = Double(newValue) {
                        var updatedModifier = modifier
                        updatedModifier.properties["width"] = CGFloat(value)
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                }
        }
    }
    
    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            ForEach(swiftUIColors, id: \.0) { colorName, color in
                Button(action: {
                    var updatedModifier = modifier
                    let storageValue: Any = (colorName == "Custom" || colorName == "Primary") ? color : "color:\(colorName.lowercased())"
                    updatedModifier.properties["color"] = storageValue
                    modifier = updatedModifier
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                    isColorPickerPresented = false
                }) {
                    Circle()
                        .fill(color)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .frame(width: 160)
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }
}

// MARK: - Aspect Ratio Modifier Editor
struct AspectRatioModifierEditor: View {
    @Binding var modifier: ComponentModifier
    
    private let aspectModes = ["fit", "fill"]
    
    private var selectedMode: String {
        modifier.properties["aspectRatio"] as? String ?? "fit"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Content Mode")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: Binding(
                get: { selectedMode },
                set: { newValue in
                    var updatedModifier = modifier
                    updatedModifier.properties["aspectRatio"] = newValue
                    modifier = updatedModifier
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
            )) {
                ForEach(aspectModes, id: \.self) { mode in
                    Text(mode.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Z Index Modifier Editor
struct ZIndexModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var indexText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Z Index")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("0", text: $indexText)
                .textFieldStyle(.roundedBorder)
                .onChange(of: indexText) { _, newValue in
                    if newValue.isEmpty { return }
                    if let value = Double(newValue) {
                        var updatedModifier = modifier
                        updatedModifier.properties["index"] = value
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                }
                .onSubmit {
                    if indexText.isEmpty || Double(indexText) == nil {
                        indexText = String(format: "%.0f", modifier.getDouble(key: "index", defaultValue: 0))
                    }
                }
        }
        .onAppear {
            indexText = String(format: "%.0f", modifier.getDouble(key: "index", defaultValue: 0))
        }
    }
}
