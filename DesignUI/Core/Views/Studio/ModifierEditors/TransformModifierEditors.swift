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
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rotation")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Angle (degrees)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", value: $rotationAngle, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: rotationAngle) { _, newValue in
                        modifier.properties["angle"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            rotationAngle = modifier.properties["angle"] as? Double ?? 0
        }
    }
}

// MARK: - Scale Modifier Editor
struct ScaleModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var scaleX: Double = 1.0
    @State private var scaleY: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scale")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Scale X")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", value: $scaleX, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: scaleX) { _, newValue in
                        modifier.properties["scaleX"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Scale Y")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", value: $scaleY, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: scaleY) { _, newValue in
                        modifier.properties["scaleY"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            scaleX = modifier.properties["scaleX"] as? Double ?? 1.0
            scaleY = modifier.properties["scaleY"] as? Double ?? 1.0
        }
    }
}

// MARK: - Offset Modifier Editor
struct OffsetModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Offset")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset X")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", value: $offsetX, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: offsetX) { _, newValue in
                        modifier.properties["offsetX"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset Y")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", value: $offsetY, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: offsetY) { _, newValue in
                        modifier.properties["offsetY"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            offsetX = modifier.properties["offsetX"] as? CGFloat ?? 0
            offsetY = modifier.properties["offsetY"] as? CGFloat ?? 0
        }
    }
}
