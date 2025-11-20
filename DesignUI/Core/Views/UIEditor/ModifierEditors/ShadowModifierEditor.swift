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
    @State private var radiusText: String = ""
    @State private var offsetXText: String = ""
    @State private var offsetYText: String = ""
    @State private var opacityText: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shadow")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Shadow Radius
            VStack(alignment: .leading, spacing: 4) {
                Text("Radius")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("4", text: $radiusText)
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
                            radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 4))
                        }
                    }
            }
            
            // Shadow Offset X
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
                            updatedModifier.properties["offsetX"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if offsetXText.isEmpty || Double(offsetXText) == nil {
                            offsetXText = String(format: "%.0f", modifier.getCGFloat(key: "offsetX", defaultValue: 0))
                        }
                    }
            }
            
            // Shadow Offset Y
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset Y")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("2", text: $offsetYText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: offsetYText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["offsetY"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if offsetYText.isEmpty || Double(offsetYText) == nil {
                            offsetYText = String(format: "%.0f", modifier.getCGFloat(key: "offsetY", defaultValue: 2))
                        }
                    }
            }
            
            // Shadow Opacity
            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0.3", text: $opacityText)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: opacityText) { _, newValue in
                        if newValue.isEmpty { return }
                        if let value = Double(newValue) {
                            var updatedModifier = modifier
                            updatedModifier.properties["opacity"] = value
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if opacityText.isEmpty || Double(opacityText) == nil {
                            opacityText = String(format: "%.1f", modifier.getDouble(key: "opacity", defaultValue: 0.3))
                        }
                    }
            }
        }
        .onAppear {
            radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 4))
            offsetXText = String(format: "%.0f", modifier.getCGFloat(key: "offsetX", defaultValue: 0))
            offsetYText = String(format: "%.0f", modifier.getCGFloat(key: "offsetY", defaultValue: 2))
            opacityText = String(format: "%.1f", modifier.getDouble(key: "opacity", defaultValue: 0.3))
        }
        .onChange(of: modifier) { _, _ in
            // Update text fields if modifier changes externally
            let currentRadius = modifier.getCGFloat(key: "radius", defaultValue: 4)
            if Double(radiusText) != Double(currentRadius) {
                radiusText = String(format: "%.0f", currentRadius)
            }
            let currentOffsetX = modifier.getCGFloat(key: "offsetX", defaultValue: 0)
            if Double(offsetXText) != Double(currentOffsetX) {
                offsetXText = String(format: "%.0f", currentOffsetX)
            }
            let currentOffsetY = modifier.getCGFloat(key: "offsetY", defaultValue: 2)
            if Double(offsetYText) != Double(currentOffsetY) {
                offsetYText = String(format: "%.0f", currentOffsetY)
            }
            let currentOpacity = modifier.getDouble(key: "opacity", defaultValue: 0.3)
            if Double(opacityText) != currentOpacity {
                opacityText = String(format: "%.1f", currentOpacity)
            }
        }
    }
}
