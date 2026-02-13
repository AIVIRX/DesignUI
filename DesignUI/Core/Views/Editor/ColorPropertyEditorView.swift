//
//  ColorPropertyEditorView.swift
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

struct ColorPropertyEditor: View {
    let title: String
    @Binding var colorString: String
    
    @State private var isPresented = false
    @State private var selectedColorName: String = "primary"
    @State private var opacityValue: Double = 1.0

    // Computed current color for preview
    private var currentColor: Color {
        let color = UniversalColorPickerView.color(for: selectedColorName)
        return color.opacity(opacityValue)
    }
    
    // Display name for the selected color
    private var selectedColorDisplayName: String {
        // Reverse lookup in UniversalColorPickerView
        if let match = UniversalColorPickerView.swiftUIColors.first(where: { $0.color == currentColor && opacityValue == 1.0 }) {
            return match.displayName
        }
        if selectedColorName.hasPrefix("#") {
            return selectedColorName.uppercased()
        }
        return selectedColorName.capitalized
    }

    var body: some View {
        HStack {
            Text(title)
                 .font(.system(size: 12, weight: .medium))
                 .foregroundColor(.primary)
            Spacer()
            
            Button(action: { 
                parseColorString()
                isPresented = true 
            }) {
                HStack(spacing: 6) {
                    // Preview Circle
                    ZStack {
                        if opacityValue < 1.0 {
                             Circle().fill(Color.gray.opacity(0.2)).frame(width: 16, height: 16)
                        }
                        Circle().fill(currentColor).frame(width: 16, height: 16)
                    }
                    .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    
                    // Name
                    Text(selectedColorDisplayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPresented) {
                 UniversalColorPickerView(
                    selectedColorName: $selectedColorName,
                    opacityValue: $opacityValue,
                    title: title,
                    onColorChanged: { saveColor() },
                    onColorConfirmed: { saveColor() }
                )
                .frame(width: 280, height: 350)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onAppear {
            parseColorString()
        }
        .onChange(of: colorString) { _, _ in
            parseColorString()
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
