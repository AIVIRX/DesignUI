//
//  ColorPickers.swift
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

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
