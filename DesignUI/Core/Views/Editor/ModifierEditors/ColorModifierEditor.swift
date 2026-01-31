//
//  ColorModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Universal Color Modifier Editor
struct ColorModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    let title: String
    
    @State private var selectedColorName: String = "primary"
    @State private var opacityValue: Double = 1.0
    
    private let swiftUIColors: [(name: String, displayName: String, color: Color)] = [
        ("primary", "Primary", .primary),
        ("secondary", "Secondary", .secondary),
        ("black", "Black", .black),
        ("white", "White", .white),
        ("red", "Red", .red),
        ("orange", "Orange", .orange),
        ("yellow", "Yellow", .yellow),
        ("green", "Green", .green),
        ("mint", "Mint", .mint),
        ("teal", "Teal", .teal),
        ("cyan", "Cyan", .cyan),
        ("blue", "Blue", .blue),
        ("indigo", "Indigo", .indigo),
        ("purple", "Purple", .purple),
        ("pink", "Pink", .pink),
        ("brown", "Brown", .brown),
        ("gray", "Gray", .gray),
        ("clear", "Clear", .clear)
    ]
    
    private var currentColor: Color {
        let baseColor = swiftUIColors.first { $0.name == selectedColorName }?.color ?? .primary
        return baseColor.opacity(opacityValue)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Color Preview Header
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Color preview circle with transparency indicator
                    ZStack {
                        // Checkered background to show transparency
                        if opacityValue < 1.0 {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                        }
                        
                        Circle()
                            .fill(currentColor)
                            .frame(width: 24, height: 24)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Opacity Slider (in list style)
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Opacity icon
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider
                        UndoableSlider(
                            value: $opacityValue,
                            range: 0...1,
                            onValueChanged: { _ in saveColorContinuous() },
                            onEditingEnded: { _ in saveColor() }
                        )
                        
                        // Percentage label
                        Text("\(Int(opacityValue * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Color List
                VStack(spacing: 0) {
                    ForEach(swiftUIColors, id: \.name) { colorInfo in
                        ColorRowView(
                            colorName: colorInfo.name,
                            displayName: colorInfo.displayName,
                            color: colorInfo.color,
                            isSelected: selectedColorName == colorInfo.name,
                            onSelect: {
                                selectedColorName = colorInfo.name
                                saveColor()
                            }
                        )
                        
                        if colorInfo.name != swiftUIColors.last?.name {
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
            .padding()
        }
        .frame(maxHeight: 400)
        .onAppear {
            loadColor()
        }
        .onChange(of: modifier) { _, _ in
            loadColor()
        }
    }
    
    private func loadColor() {
        // Parse "colorname:opacity" format
        if let colorData = modifier.properties["color"] as? String {
            let parts = colorData.split(separator: ":")
            if parts.count >= 1 {
                selectedColorName = String(parts[0]).lowercased()
            }
            if parts.count >= 2, let opacity = Double(parts[1]) {
                opacityValue = opacity
            } else {
                opacityValue = 1.0
            }
        } else {
            selectedColorName = "primary"
            opacityValue = 1.0
        }
    }
    
    private func saveColor() {
        var updatedModifier = modifier
        // Save in "colorname:opacity" format
        updatedModifier.properties["color"] = "\(selectedColorName):\(opacityValue)"
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    private func saveColorContinuous() {
        var updatedModifier = modifier
        // Save in "colorname:opacity" format
        updatedModifier.properties["color"] = "\(selectedColorName):\(opacityValue)"
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

// MARK: - Color Row View
struct ColorRowView: View {
    let colorName: String
    let displayName: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color circle
                colorCircle
                
                // Color name
                Text(displayName)
                    .font(.system(size: 14))
                
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
    
    @ViewBuilder
    private var colorCircle: some View {
        if colorName == "primary" {
            // Split circle for primary (black/white)
            ZStack {
                Circle()
                    .fill(Color.black)
                    .frame(width: 24, height: 24)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .mask(
                        Rectangle()
                            .frame(width: 12, height: 24)
                            .offset(x: 6)
                    )
            }
            .overlay(
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        } else if colorName == "clear" {
            // Clear color indicator
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 24, height: 24)
                
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: 24, height: 24)
                
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 2, height: 16)
                    .rotationEffect(.degrees(45))
            }
        } else {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Universal Color Picker View (Reusable)
/// A standalone color picker view that can be used anywhere.
/// Use this for gradient stops, background colors, etc.
struct UniversalColorPickerView: View {
    @Binding var selectedColorName: String
    @Binding var opacityValue: Double
    let title: String
    var onColorChanged: (() -> Void)?
    var onColorConfirmed: (() -> Void)?
    
    static let swiftUIColors: [(name: String, displayName: String, color: Color)] = [
        ("primary", "Primary", .primary),
        ("secondary", "Secondary", .secondary),
        ("black", "Black", .black),
        ("white", "White", .white),
        ("red", "Red", .red),
        ("orange", "Orange", .orange),
        ("yellow", "Yellow", .yellow),
        ("green", "Green", .green),
        ("mint", "Mint", .mint),
        ("teal", "Teal", .teal),
        ("cyan", "Cyan", .cyan),
        ("blue", "Blue", .blue),
        ("indigo", "Indigo", .indigo),
        ("purple", "Purple", .purple),
        ("pink", "Pink", .pink),
        ("brown", "Brown", .brown),
        ("gray", "Gray", .gray),
        ("clear", "Clear", .clear)
    ]
    
    private var currentColor: Color {
        let baseColor = Self.swiftUIColors.first { $0.name == selectedColorName }?.color ?? .primary
        return baseColor.opacity(opacityValue)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Color Preview Header
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Color preview circle with transparency indicator
                    ZStack {
                        if opacityValue < 1.0 {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 24, height: 24)
                        }
                        
                        Circle()
                            .fill(currentColor)
                            .frame(width: 24, height: 24)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Opacity Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        UndoableSlider(
                            value: $opacityValue,
                            range: 0...1,
                            onValueChanged: { _ in onColorChanged?() },
                            onEditingEnded: { _ in onColorConfirmed?() }
                        )
                        
                        Text("\(Int(opacityValue * 100))%")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 44, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Color List
                VStack(spacing: 0) {
                    ForEach(Self.swiftUIColors, id: \.name) { colorInfo in
                        ColorRowView(
                            colorName: colorInfo.name,
                            displayName: colorInfo.displayName,
                            color: colorInfo.color,
                            isSelected: selectedColorName == colorInfo.name,
                            onSelect: {
                                selectedColorName = colorInfo.name
                                onColorChanged?()
                                onColorConfirmed?()
                            }
                        )
                        
                        if colorInfo.name != Self.swiftUIColors.last?.name {
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
            .padding()
        }
        .frame(minWidth: 280, maxHeight: 400)
    }
    
    /// Helper to get Color from name
    static func color(for name: String) -> Color {
        swiftUIColors.first { $0.name == name }?.color ?? .primary
    }
}
