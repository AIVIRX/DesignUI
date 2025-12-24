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
    @State private var isColorPickerPresented = false
    
    private var currentColor: Color {
        modifier.getColor(key: "color", defaultValue: .black)
    }
    
    private let swiftUIColors: [(String, Color)] = [
        ("Black", .black),
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            colorPickerSection
            
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
                            updatedModifier.properties["y"] = CGFloat(value)
                            modifier = updatedModifier
                            NotificationCenter.default.post(name: .designChanged, object: nil)
                        }
                    }
                    .onSubmit {
                        if offsetYText.isEmpty || Double(offsetYText) == nil {
                            offsetYText = String(format: "%.0f", modifier.getCGFloat(key: "y", defaultValue: 2))
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
                            
                            // Update the color with the new opacity
                            let baseValue = modifier.properties["color"] ?? "color:black"
                            let baseColor: Color
                            if let str = baseValue as? String {
                                baseColor = ComponentProperty.colorStringToColor(str.hasPrefix("color:") ? String(str.dropFirst(6)) : str)
                            } else {
                                baseColor = baseValue as? Color ?? .black
                            }
                            
                            updatedModifier.properties["color"] = baseColor.opacity(value)
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
            initializeFields()
        }
        .onChange(of: modifier) { _, _ in
            initializeFields()
        }
    }
    
    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Color")
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
    
    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
            ForEach(swiftUIColors, id: \.0) { colorName, color in
                Button(action: {
                    var updatedModifier = modifier
                    let opacity = modifier.getDouble(key: "opacity", defaultValue: 0.3)
                    
                    if opacity >= 0.99 && colorName != "Primary" && colorName != "Secondary" {
                        updatedModifier.properties["color"] = "color:\(colorName.lowercased())"
                    } else {
                        updatedModifier.properties["color"] = color.opacity(opacity)
                    }
                    
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

    private func initializeFields() {
        radiusText = String(format: "%.0f", modifier.getCGFloat(key: "radius", defaultValue: 4))
        // Support both "x"/"y" and "offsetX"/"offsetY" for backward compatibility
        if let x = modifier.properties["x"] as? CGFloat {
            offsetXText = String(format: "%.0f", x)
        } else if let offsetX = modifier.properties["offsetX"] as? CGFloat {
            offsetXText = String(format: "%.0f", offsetX)
        } else {
            offsetXText = "0"
        }
        
        if let y = modifier.properties["y"] as? CGFloat {
            offsetYText = String(format: "%.0f", y)
        } else if let offsetY = modifier.properties["offsetY"] as? CGFloat {
            offsetYText = String(format: "%.0f", offsetY)
        } else {
            offsetYText = "2"
        }
        
        // Initialize opacity text
        opacityText = String(format: "%.1f", modifier.getDouble(key: "opacity", defaultValue: 0.3))
    }
}
