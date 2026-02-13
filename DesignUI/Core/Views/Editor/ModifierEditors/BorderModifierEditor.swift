//
//  BorderModifierEditor.swift
//
//  Created by Maicol Cabreja on 2/6/26.
//

import SwiftUI

struct BorderModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var width: Double = 1
    @State private var selectedColorName: String = "Black"
    @State private var isColorExpanded: Bool = false
    
    private let colors: [(name: String, color: Color)] = [
        ("Black", .black),
        ("White", .white),
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
    
    // Helper to get current color
    private var currentColor: Color {
        colors.first { $0.name == selectedColorName }?.color ?? .black
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Border")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Circle()
                        .fill(currentColor)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color.primary.opacity(0.1)))
                    
                    Text("\(Int(width)) pt")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
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
                                BorderColorRow(
                                    name: colorOption.name,
                                    color: colorOption.color,
                                    isSelected: selectedColorName == colorOption.name,
                                    onSelect: {
                                        selectedColorName = colorOption.name
                                        saveBorder()
                                        withAnimation { isColorExpanded = false }
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
                
                // Width Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "lineweight")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider
                        Slider(value: $width, in: 0...20)
                            .onChange(of: width) { _, _ in
                                saveBorder()
                            }
                        
                        // Value label
                        Text("\(Int(width))")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.1))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Quick Width Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Width Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        ForEach([1, 2, 4, 8], id: \.self) { preset in
                            Button(action: {
                                width = Double(preset)
                                saveBorder()
                            }) {
                                Text("\(preset)pt")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Int(width) == preset ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
                                    .foregroundColor(Int(width) == preset ? .blue : .primary)
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(maxHeight: 450)
        .onAppear {
            loadBorder()
        }
        .onChange(of: modifier) { _, _ in
            loadBorder()
        }
    }
    
    private func loadBorder() {
        width = modifier.getDouble(key: "width", defaultValue: 1)
        // Load color logic - simplified for now as we store color string or custom
        // In a real app we'd parse the color property back to a name
        if let storedColor = modifier.properties["color"] as? String {
             // Extract name if format is "color:name"
             if storedColor.hasPrefix("color:") {
                 let name = String(storedColor.dropFirst(6))
                 selectedColorName = name.capitalized // Naive capitalization
             }
        }
    }
    
    private func saveBorder() {
        var updatedModifier = modifier
        updatedModifier.properties["width"] = width
        updatedModifier.properties["color"] = "color:\(selectedColorName.lowercased())"
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

struct BorderColorRow: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Color Preview
                Circle()
                    .fill(color)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                
                // Label
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
