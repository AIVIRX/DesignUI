//
//  ColorModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Color Modifier Editor (Generic)
struct ColorModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    let title: String
    @State private var isPresented = false
    @State private var isHovered = false
    
    private var currentColor: Color {
        modifier.getColor(key: "color", defaultValue: Color.primary)
    }
    
    private let swiftUIColors: [(String, Color)] = [
        ("Primary", .primary),
        ("Secondary", .secondary),
        ("Tertiary", .primary.opacity(0.6)),
        ("Quaternary", .primary.opacity(0.3)),
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
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            colorPickerButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.gray.opacity(0.3) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .contentShape(Rectangle())
        .popover(isPresented: $isPresented) {
            colorPopoverContent
        }
    }
    
    private var colorPickerButton: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 6) {
                Circle()
                    .fill(currentColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text(selectedColorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var colorPopoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Color")
                .font(.headline)
                .padding(.bottom, 4)
            
            colorGrid
        }
        .padding()
        .frame(width: 220)
    }
    
    private var colorGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(swiftUIColors, id: \.0) { colorName, color in
                colorButton(colorName: colorName, color: color)
            }
        }
    }
    
    @ViewBuilder
    private func colorButton(colorName: String, color: Color) -> some View {
        Button(action: {
            selectColor(colorName, color)
        }) {
            VStack(spacing: 4) {
                colorCircle(colorName: colorName, color: color)
                    .overlay(selectionCheckmark(for: color))
                
                Text(colorName) 
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func colorCircle(colorName: String, color: Color) -> some View {
        Group {
            if colorName == "Primary" {
                primaryColorCircle
            } else if colorName == "Clear" {
                clearColorCircle
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 32, height: 32)
            }
        }
        .overlay(
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .contentShape(Circle())
    }
    
    private var primaryColorCircle: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .frame(width: 32, height: 32)
            
            Circle()
                .fill(Color.white)
                .frame(width: 32, height: 32)
                .mask(
                    Rectangle()
                        .frame(width: 16, height: 32)
                        .offset(x: 8)
                )
        }
    }
    
    private var clearColorCircle: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 32, height: 32)
            
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 32, height: 32)
            
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 20)
                .rotationEffect(.degrees(45))
        }
    }
    
    @ViewBuilder
    private func selectionCheckmark(for color: Color) -> some View {
        if isSelected(color) {
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1)
        }
    }
    
    private func selectColor(_ colorName: String, _ color: Color) {
        DispatchQueue.main.async {
            var updatedModifier = modifier
            let storageValue: Any
            if colorName == "Custom" || colorName == "Primary" {
                storageValue = color
            } else {
                storageValue = "color:\(colorName.lowercased())"
            }
            
            updatedModifier.properties["color"] = storageValue
            print("🎨 \(title) color changed to: \(colorName) (\(storageValue))")
            component.updateModifier(updatedModifier)
            modifier = updatedModifier
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        isPresented = false
    }
    
    private var selectedColorName: String {
        if let colorString = modifier.properties["color"] as? String {
            if colorString.hasPrefix("color:") {
                return String(colorString.dropFirst(6)).capitalized
            }
            return colorString.capitalized
        }
        return swiftUIColors.first { $0.1 == currentColor }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        // 1. Try to match by name if stored as string (Most reliable for named colors)
        if let targetName = swiftUIColors.first(where: { $0.1 == color })?.0,
           let storedString = modifier.properties["color"] as? String {
            let normalizedStored = storedString.replacingOccurrences(of: "color:", with: "")
            if normalizedStored.lowercased() == targetName.lowercased() {
                return true
            }
        }
        
        // 2. Fallback to Color equality (For custom colors)
        // Use the computed currentColor which already handles the resolution
        let resolvedColor = currentColor
        if resolvedColor == color {
            return true
        }
        return false
    }
}
