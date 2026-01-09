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
    @ObservedObject var component: UIComponent
    
    @State private var radius: CGFloat = 4
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 2
    @State private var opacity: Double = 0.3
    @State private var selectedColorName: String = "Black"
    @State private var isColorExpanded: Bool = false
    
    // Using consistent color list from ColorModifierEditor
    private let colors: [(name: String, color: Color)] = [
        ("Black", .black),
        ("White", .white),
        ("Gray", .gray),
        ("Red", .red),
        ("Orange", .orange),
        ("Yellow", .yellow),
        ("Green", .green),
        ("Mint", .mint),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Blue", .blue),
        ("Indigo", .indigo),
        ("Purple", .purple),
        ("Pink", .pink),
        ("Brown", .brown),
        ("Primary", .primary),
        ("Secondary", .secondary)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Shadow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(currentColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                    
                    Text("\(Int(radius))pt")
                        .font(.caption)
                        .foregroundColor(.primary)
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
                                ShadowColorRow(
                                    name: colorOption.name,
                                    color: colorOption.color,
                                    isSelected: selectedColorName == colorOption.name,
                                    onSelect: {
                                        selectedColorName = colorOption.name
                                        saveShadow()
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
                
                // Opacity Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(opacity * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "sun.min")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $opacity, in: 0...1)
                            .onChange(of: opacity) { _, _ in
                                saveShadow()
                            }
                        
                        Image(systemName: "sun.max")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                
                // Radius Slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Radius")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(radius))")
                            .font(.caption)
                            .monospacedDigit()
                    }
                    
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Slider(value: $radius, in: 0...50)
                            .onChange(of: radius) { _, _ in
                                saveShadow()
                            }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                
                // Offset Sliders
                VStack(spacing: 16) {
                    // X Offset
                    VStack(spacing: 8) {
                        HStack {
                            Text("Offset X")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(offsetX))")
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        Slider(value: $offsetX, in: -50...50)
                            .onChange(of: offsetX) { _, _ in
                                saveShadow()
                            }
                    }
                    
                    // Y Offset
                    VStack(spacing: 8) {
                        HStack {
                            Text("Offset Y")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(offsetY))")
                                .font(.caption)
                                .monospacedDigit()
                        }
                        
                        Slider(value: $offsetY, in: -50...50)
                            .onChange(of: offsetY) { _, _ in
                                saveShadow()
                            }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
            }
            .padding()
        }
        .frame(maxHeight: 500)
        .onAppear {
            loadShadow()
        }
        .onChange(of: modifier) { _, _ in
            loadShadow()
        }
    }
    
    private var currentColor: Color {
        colors.first(where: { $0.name == selectedColorName })?.color ?? .black
    }
    
    private func loadShadow() {
        radius = modifier.getCGFloat(key: "radius", defaultValue: 4)
        opacity = modifier.getDouble(key: "opacity", defaultValue: 0.3)
        
        // Load offset
        if let x = modifier.properties["x"] as? CGFloat { offsetX = x }
        else if let x = modifier.properties["offsetX"] as? CGFloat { offsetX = x }
        
        if let y = modifier.properties["y"] as? CGFloat { offsetY = y }
        else if let y = modifier.properties["offsetY"] as? CGFloat { offsetY = y }
        
        // Load color
        if let colorString = modifier.properties["colorString"] as? String {
             selectedColorName = colorString
        } else if let colorObj = modifier.properties["color"] as? Color {
             selectedColorName = colors.first(where: { $0.color == colorObj })?.name ?? "Black"
        } else {
             selectedColorName = "Black" // Default
        }
    }
    
    private func saveShadow() {
        var updatedModifier = modifier
        updatedModifier.properties["radius"] = radius
        updatedModifier.properties["opacity"] = opacity
        updatedModifier.properties["x"] = offsetX
        updatedModifier.properties["y"] = offsetY
        
        // Save the color name as string for better consistency
        updatedModifier.properties["colorString"] = selectedColorName
        
        // Also save the actual Color object with opacity applied for rendering
        let baseColor = colors.first(where: { $0.name == selectedColorName })?.color ?? .black
        updatedModifier.properties["color"] = baseColor.opacity(opacity)
        
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

// MARK: - Shadow Color Row
struct ShadowColorRow: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color Circle
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
                // Color Name
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
