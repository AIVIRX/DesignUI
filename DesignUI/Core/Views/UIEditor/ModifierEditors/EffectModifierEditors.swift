//
//  EffectModifierEditors.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Blur Modifier Editor
struct BlurModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var radiusText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blur")
                .font(.subheadline)
                .fontWeight(.semibold)
            
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
                            updatedModifier.properties["radius"] = value
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if radiusText.isEmpty || Double(radiusText) == nil {
                            radiusText = String(format: "%.0f", modifier.getDouble(key: "radius", defaultValue: 0))
                        }
                    }
            }
        }
        .onAppear {
            radiusText = String(format: "%.0f", modifier.getDouble(key: "radius", defaultValue: 0))
        }
        .onChange(of: modifier) { _, _ in
            let currentRadius = modifier.getDouble(key: "radius", defaultValue: 0)
            if Double(radiusText) != currentRadius {
                radiusText = String(format: "%.0f", currentRadius)
            }
        }
    }
}

// MARK: - Clip Shape Modifier Editor
struct ClipShapeModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var clipShapeType: String = "rectangle"
    
    private let clipShapeTypes = [
        ("rectangle", "Rectangle"),
        ("circle", "Circle"),
        ("roundedRectangle", "Rounded Rectangle"),
        ("capsule", "Capsule"),
        ("ellipse", "Ellipse")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clip Shape")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Shape Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Shape Type", selection: $clipShapeType) {
                    ForEach(clipShapeTypes, id: \.0) { shape in
                        Text(shape.1).tag(shape.0)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: clipShapeType) { _, newValue in
                    modifier.properties["shapeType"] = newValue
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
            }
        }
        .onAppear {
            clipShapeType = modifier.properties["shapeType"] as? String ?? "rectangle"
        }
    }
}

// MARK: - Mask Modifier Editor
struct MaskModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var maskType: String = "rectangle"
    
    private let maskTypes = [
        ("rectangle", "Rectangle"),
        ("circle", "Circle"),
        ("roundedRectangle", "Rounded Rectangle"),
        ("capsule", "Capsule"),
        ("ellipse", "Ellipse")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mask")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Mask Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Mask Type", selection: $maskType) {
                    ForEach(maskTypes, id: \.0) { mask in
                        Text(mask.1).tag(mask.0)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: maskType) { _, newValue in
                    modifier.properties["maskType"] = newValue
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
            }
        }
        .onAppear {
            maskType = modifier.properties["maskType"] as? String ?? "rectangle"
        }
    }
}

// MARK: - Border Modifier Editor
struct BorderModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var borderColor: Color = .black
    @State private var widthText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Border")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Border Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ColorPicker("Border Color", selection: $borderColor)
                    .labelsHidden()
                    .onChange(of: borderColor) { _, newValue in
                        modifier.properties["color"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Border Width")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", text: $widthText)
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
                    .onSubmit {
                        if widthText.isEmpty || Double(widthText) == nil {
                            widthText = String(format: "%.1f", modifier.getCGFloat(key: "width", defaultValue: 1))
                        }
                    }
            }
        }
        .onAppear {
            borderColor = modifier.properties["color"] as? Color ?? .black
            widthText = String(format: "%.1f", modifier.getCGFloat(key: "width", defaultValue: 1))
        }
        .onChange(of: modifier) { _, _ in
            let currentWidth = modifier.getCGFloat(key: "width", defaultValue: 1)
            if Double(widthText) != Double(currentWidth) {
                widthText = String(format: "%.1f", currentWidth)
            }
        }
    }
}
