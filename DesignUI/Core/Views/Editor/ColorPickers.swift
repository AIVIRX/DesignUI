//
//  ColorPickers.swift
//  DesignUI
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

struct SimpleColorPicker: View {
    @Binding var colorString: String
    @State private var isPresented = false
    @State private var isHovered = false
    
    private let swiftUIColors: [(String, Color)] = [
        ("Primary", .primary),
        ("Secondary", .secondary),
        ("Black", .black),
        ("White", .white),
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
        ("Gray", .gray),
        ("Clear", .clear)
    ]
    
    private var currentColor: Color {
        ComponentProperty.colorStringToColor(colorString)
    }
    
    private func colorName(for color: Color) -> String {
        // Simple check against basic colors
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }

    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(currentColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text(colorString.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .popover(isPresented: $isPresented) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(swiftUIColors, id: \.0) { colorName, color in
                         Button(action: {
                            colorString = colorName.lowercased()
                            isPresented = false
                        }) {
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Text(colorName)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
            .frame(width: 220)
        }
    }
}

struct GradientColorPicker: View {
    @Binding var colorString: String
    @State private var isPresented = false
    @State private var selectedColorName: String = "blue"
    @State private var opacityValue: Double = 1.0
    
    private var currentColor: Color {
        let color = UniversalColorPickerView.color(for: selectedColorName)
        return color.opacity(opacityValue)
    }
    
    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 6) {
                // Color preview with transparency indicator
                ZStack {
                    if opacityValue < 1.0 {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 20, height: 20)
                    }
                    Circle()
                        .fill(currentColor)
                        .frame(width: 20, height: 20)
                }
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                Text("\(selectedColorName.capitalized) \(opacityValue < 1.0 ? "(\(Int(opacityValue * 100))%)" : "")")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            parseColorString()
        }
        .popover(isPresented: $isPresented) {
            // Use the universal color picker
            UniversalColorPickerView(
                selectedColorName: $selectedColorName,
                opacityValue: $opacityValue,
                title: "Gradient Color",
                onColorChanged: {
                    saveColor()
                },
                onColorConfirmed: {
                    saveColor()
                }
            )
            .frame(minWidth: 280, maxHeight: 400)
        }
    }
    
    private func parseColorString() {
        let parts = colorString.split(separator: ":")
        if parts.count >= 1 {
            selectedColorName = String(parts[0]).lowercased()
        }
        if parts.count >= 2, let opacity = Double(parts[1]) {
            opacityValue = opacity
        } else {
            opacityValue = 1.0
        }
    }
    
    private func saveColor() {
        colorString = "\(selectedColorName):\(opacityValue)"
    }
}

