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
    let title: String
    @State private var isPresented = false
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { newColor in
                print("🎨 \(title) color changed to: \(newColor)")
                modifier.properties["color"] = newColor
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
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { isPresented = true }) {
                    HStack(spacing: 6) {
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
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose \(title)")
                        .font(.headline)
                        .padding(.bottom, 4)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(swiftUIColors, id: \.0) { colorName, color in
                            Button(action: {
                                DispatchQueue.main.async {
                                    self.color.wrappedValue = color
                                }
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
    }
    
    private func colorName(for color: Color) -> String {
        return swiftUIColors.first { $0.1 == color }?.0 ?? "Custom"
    }
    
    private func isSelected(_ color: Color) -> Bool {
        guard let currentColor = modifier.properties["color"] as? Color else { return false }
        return currentColor == color
    }
}
