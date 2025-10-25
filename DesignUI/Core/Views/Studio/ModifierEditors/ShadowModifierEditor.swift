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
    @State private var shadowRadius: CGFloat = 4
    @State private var shadowOffsetX: CGFloat = 0
    @State private var shadowOffsetY: CGFloat = 2
    @State private var shadowOpacity: Double = 0.3
    
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
                
                TextField("4", value: $shadowRadius, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: shadowRadius) { _, newValue in
                        modifier.properties["radius"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
            
            // Shadow Offset X
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset X")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0", value: $shadowOffsetX, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: shadowOffsetX) { _, newValue in
                        modifier.properties["offsetX"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
            
            // Shadow Offset Y
            VStack(alignment: .leading, spacing: 4) {
                Text("Offset Y")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("2", value: $shadowOffsetY, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: shadowOffsetY) { _, newValue in
                        modifier.properties["offsetY"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
            
            // Shadow Opacity
            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0.3", value: $shadowOpacity, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: shadowOpacity) { _, newValue in
                        modifier.properties["opacity"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            shadowRadius = modifier.properties["radius"] as? CGFloat ?? 4
            shadowOffsetX = modifier.properties["offsetX"] as? CGFloat ?? 0
            shadowOffsetY = modifier.properties["offsetY"] as? CGFloat ?? 2
            shadowOpacity = modifier.properties["opacity"] as? Double ?? 0.3
        }
    }
}
