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
    @State private var blurRadius: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Blur")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Blur Radius")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", value: $blurRadius, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: blurRadius) { _, newValue in
                        modifier.properties["radius"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            blurRadius = modifier.properties["radius"] as? Double ?? 0
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
