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
    @State private var angleText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Angle (degrees)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $angleText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: angleText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["angle"] = value
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if angleText.isEmpty || Double(angleText) == nil {
                            angleText = String(format: "%.0f", modifier.getDouble(key: "angle", defaultValue: 0))
                        }
                    }
            }
        }
        .onAppear {
            angleText = String(format: "%.0f", modifier.getDouble(key: "angle", defaultValue: 0))
        }
        .onChange(of: modifier) { _, _ in
            let currentAngle = modifier.getDouble(key: "angle", defaultValue: 0)
            if Double(angleText) != currentAngle {
                angleText = String(format: "%.0f", currentAngle)
            }
        }
    }
}

// MARK: - Scale Modifier Editor
struct ScaleModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var scaleXText: String = ""
    @State private var scaleYText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scale X")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", text: $scaleXText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: scaleXText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["x"] = value
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if scaleXText.isEmpty || Double(scaleXText) == nil {
                            scaleXText = String(format: "%.1f", modifier.getDouble(key: "x", defaultValue: 1.0))
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Scale Y")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", text: $scaleYText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: scaleYText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["y"] = value
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if scaleYText.isEmpty || Double(scaleYText) == nil {
                            scaleYText = String(format: "%.1f", modifier.getDouble(key: "y", defaultValue: 1.0))
                        }
                    }
            }
        }
        .onAppear {
            scaleXText = String(format: "%.1f", modifier.getDouble(key: "x", defaultValue: 1.0))
            scaleYText = String(format: "%.1f", modifier.getDouble(key: "y", defaultValue: 1.0))
        }
        .onChange(of: modifier) { _, _ in
            let currentScaleX = modifier.getDouble(key: "x", defaultValue: 1.0)
            if Double(scaleXText) != currentScaleX {
                scaleXText = String(format: "%.1f", currentScaleX)
            }
            let currentScaleY = modifier.getDouble(key: "y", defaultValue: 1.0)
            if Double(scaleYText) != currentScaleY {
                scaleYText = String(format: "%.1f", currentScaleY)
            }
        }
    }
}

// MARK: - Offset Modifier Editor
struct OffsetModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var offsetXText: String = ""
    @State private var offsetYText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset X")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $offsetXText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: offsetXText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["x"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if offsetXText.isEmpty || Double(offsetXText) == nil {
                            offsetXText = String(format: "%.0f", modifier.getCGFloat(key: "x", defaultValue: 0))
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset Y")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", text: $offsetYText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: offsetYText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["y"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if offsetYText.isEmpty || Double(offsetYText) == nil {
                            offsetYText = String(format: "%.0f", modifier.getCGFloat(key: "y", defaultValue: 0))
                        }
                    }
            }
        }
        .onAppear {
            offsetXText = String(format: "%.0f", modifier.getCGFloat(key: "x", defaultValue: 0))
            offsetYText = String(format: "%.0f", modifier.getCGFloat(key: "y", defaultValue: 0))
        }
        .onChange(of: modifier) { _, _ in
            let currentOffsetX = modifier.getCGFloat(key: "x", defaultValue: 0)
            if Double(offsetXText) != Double(currentOffsetX) {
                offsetXText = String(format: "%.0f", currentOffsetX)
            }
            let currentOffsetY = modifier.getCGFloat(key: "y", defaultValue: 0)
            if Double(offsetYText) != Double(currentOffsetY) {
                offsetYText = String(format: "%.0f", currentOffsetY)
            }
        }
    }
}
