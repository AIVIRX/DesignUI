//
//  ClipShapeModifierEditor.swift
//
//  Created by Maicol Cabreja on 2/6/26.
//

import SwiftUI

struct ClipShapeModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    @State private var selectedShape: String = "Rectangle"
    @State private var cornerRadius: Double = 10
    
    private let shapes: [(name: String, icon: String, id: String)] = [
        ("Rectangle", "rectangle", "Rectangle"),
        ("Rounded Rectangle", "rectangle.roundedtop", "RoundedRectangle"),
        ("Circle", "circle", "Circle"),
        ("Capsule", "capsule", "Capsule"),
        ("Ellipse", "oval", "Ellipse")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Clip Shape")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(selectedShape)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                // Corner Radius (only for RoundedRectangle)
                if selectedShape == "RoundedRectangle" {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Corner Radius")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(cornerRadius))")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                        
                        Slider(value: $cornerRadius, in: 0...100)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 10)
                            .onChange(of: cornerRadius) { _, _ in
                                saveShape()
                            }
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.05)))
                }
                
                // Shapes List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shapes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(shapes, id: \.id) { shape in
                            PresetShapeRow(
                                name: shape.name,
                                icon: shape.icon,
                                isSelected: selectedShape == shape.id,
                                onSelect: {
                                    selectedShape = shape.id
                                    saveShape()
                                }
                            )
                            
                            if shape.id != "Ellipse" {
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
            .padding()
        }
        .frame(maxHeight: 450)
        .onAppear {
            loadShape()
        }
        .onChange(of: modifier) { _, _ in
            loadShape()
        }
    }
    
    private func loadShape() {
        selectedShape = modifier.properties["shape"] as? String ?? "Rectangle"
        cornerRadius = modifier.getDouble(key: "cornerRadius", defaultValue: 10)
    }
    
    private func saveShape() {
        var updatedModifier = modifier
        updatedModifier.properties["shape"] = selectedShape
        if selectedShape == "RoundedRectangle" {
            updatedModifier.properties["cornerRadius"] = cornerRadius
        } else {
            updatedModifier.properties.removeValue(forKey: "cornerRadius")
        }
        modifier = updatedModifier
        
        DispatchQueue.main.async {
            component.updateModifier(updatedModifier)
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}

struct PresetShapeRow: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSelected ? .blue : .primary)
                
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

