//
//  BackgroundModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Background Modifier Editor
struct BackgroundModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var isPresented = false
    @State private var opacityText: String = ""
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { newColor in
                print("🎨 Background color changed to: \(newColor)")
                modifier.properties["color"] = newColor
                // Trigger change detection
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
        )
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
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("Background Color")
                
                Spacer()
                
                Button(action: { isPresented = true }) {
                    HStack(spacing: 6) {
                        // Color preview circle
                        Circle()
                            .fill(color.wrappedValue)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text(colorName(for: color.wrappedValue))
                            .font(.caption)
                            .foregroundColor(.primary)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .popover(isPresented: $isPresented) {
                ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose Background Color")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    // Opacity Text Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Opacity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("100", text: $opacityText)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: opacityText) { _, newValue in
                                    if newValue.isEmpty { return }
                                    if let percentage = Double(newValue), percentage >= 0 && percentage <= 100 {
                                        let opacity = percentage / 100.0
                                        updateColorWithOpacity(opacity)
                                    }
                                }
                                .onSubmit {
                                    if opacityText.isEmpty || Double(opacityText) == nil {
                                        // Restore current opacity as percentage (default to 100%)
                                        opacityText = "100"
                                    }
                                }
                            
                            Text("%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    Divider()
                    
                    // Color Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(swiftUIColors, id: \.0) { colorName, color in
                            Button(action: {
                                DispatchQueue.main.async {
                                    let opacityValue = Double(opacityText) ?? 100.0
                                    let opacity = max(0, min(100, opacityValue)) / 100.0
                                    let colorWithOpacity = color.opacity(opacity)
                                    self.color.wrappedValue = colorWithOpacity
                                }
                                isPresented = false
                            }) {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(color.opacity((Double(opacityText) ?? 100.0) / 100.0))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .overlay(
                                            Group {
                                                if isSelected(color) {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .shadow(color: .black, radius: 1)
                                                }
                                            }
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
                .onAppear {
                    // Initialize opacity from current color (default to 100% if we can't determine)
                    opacityText = "100"
                }
                }
            }
        }
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let currentColor = modifier.properties["color"] as? Color else { return false }
        
        // Try direct comparison first
        if currentColor == color {
            return true
        }
        
        // Fallback to name comparison
        let currentColorName = colorName(for: currentColor)
        let targetColorName = swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
        return currentColorName == targetColorName && currentColorName != "Custom"
    }
    
    private func updateColorWithOpacity(_ newOpacity: Double) {
        // Get the current color and apply the new opacity
        if let currentColor = modifier.properties["color"] as? Color {
            // Find the base color without opacity
            let baseColor = findBaseColor(for: currentColor)
            let colorWithOpacity = baseColor.opacity(newOpacity)
            print("🎨 Background color opacity changed to: \(newOpacity) for color: \(colorWithOpacity)")
            modifier.properties["color"] = colorWithOpacity
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
    
    private func findBaseColor(for color: Color) -> Color {
        // Try to find the base color by comparing with known colors
        for (_, baseColor) in swiftUIColors {
            if color == baseColor {
                return baseColor
            }
        }
        // If no match found, return the color as-is
        return color
    }
}
