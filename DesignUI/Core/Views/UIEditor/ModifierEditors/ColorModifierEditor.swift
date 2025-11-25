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
        modifier.properties["color"] as? Color ?? Color.primary
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
            
            Button(action: { isPresented = true }) {
                HStack(spacing: 6) {
                    // Color preview circle
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
                    
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
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
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Color")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // Color Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(swiftUIColors, id: \.0) { colorName, color in
                        Button(action: {
                            DispatchQueue.main.async {
                                var updatedModifier = modifier
                                updatedModifier.properties["color"] = color
                                print("🎨 \(title) color changed to: \(color)")
                                component.updateModifier(updatedModifier)
                                modifier = updatedModifier
                                NotificationCenter.default.post(name: .designChanged, object: nil)
                            }
                            isPresented = false
                        }) {
                            VStack(spacing: 4) {
                                Group {
                                    if colorName == "Primary" {
                                        // Split circle for Primary color
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
                                    } else if colorName == "Clear" {
                                        // Special visual for Clear color
                                        ZStack {
                                            Circle()
                                                .fill(Color.gray.opacity(0.1))
                                                .frame(width: 32, height: 32)
                                            
                                            Circle()
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                                .frame(width: 32, height: 32)
                                            
                                            // Diagonal line to indicate "no color"
                                            Rectangle()
                                                .fill(Color.red)
                                                .frame(width: 2, height: 20)
                                                .rotationEffect(.degrees(45))
                                        }
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
        }
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Primary"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let storedColor = modifier.properties["color"] as? Color else { return false }
        
        // Direct color comparison
        if storedColor == color {
            return true
        }
        
        // Fallback to name comparison
        let currentColorName = colorName(for: storedColor)
        let targetColorName = swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
        return currentColorName == targetColorName && currentColorName != "Custom"
    }
}
