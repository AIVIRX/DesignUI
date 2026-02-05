//
//  PaddingModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Padding Modifier Editor
struct PaddingModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var paddingAmount: Double = 10
    @State private var selectedLocation: String = "all"
    
    private let paddingLocations: [(key: String, displayName: String, icon: String)] = [
        ("all", "All Sides", "square.dashed"),
        ("horizontal", "Horizontal", "arrow.left.and.right"),
        ("vertical", "Vertical", "arrow.up.and.down"),
        ("leading", "Leading", "arrow.left"),
        ("trailing", "Trailing", "arrow.right"),
        ("top", "Top", "arrow.up"),
        ("bottom", "Bottom", "arrow.down")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Preview Header
                HStack {
                    Text("Padding")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Preview showing current padding
                    Text("\(Int(paddingAmount))pt \(locationDisplayName)")
                        .font(.caption)
                        .foregroundColor(.primary)
                        .monospacedDigit()
                }
                
                // Amount Slider
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        // Icon
                        Image(systemName: "ruler")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                        
                        // Slider with proper undo handling
                        UndoableSlider(
                            value: $paddingAmount,
                            range: 0...100,
                            onValueChanged: { _ in
                                // Continuous update during drag - no undo save
                                savePaddingContinuous()
                            },
                            onEditingEnded: { _ in
                                // Final save when drag ends
                                savePadding()
                            }
                        )
                        
                        // Value label
                        Text("\(Int(paddingAmount))")
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
                
                // Location List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(paddingLocations, id: \.key) { location in
                            PaddingLocationRow(
                                key: location.key,
                                displayName: location.displayName,
                                icon: location.icon,
                                isSelected: selectedLocation == location.key,
                                onSelect: {
                                    selectedLocation = location.key
                                    savePadding()
                                }
                            )
                            
                            if location.key != paddingLocations.last?.key {
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
        .onAppear {
            loadPadding()
        }
        .onChange(of: modifier) { _, _ in
            loadPadding()
        }
    }
    
    private var locationDisplayName: String {
        paddingLocations.first { $0.key == selectedLocation }?.displayName ?? "All Sides"
    }
    
    private func loadPadding() {
        paddingAmount = modifier.getCGFloat(key: "amount", defaultValue: 10)
        selectedLocation = modifier.properties["location"] as? String ?? "all"
    }
    
    private func savePadding() {
        var updatedModifier = modifier
        updatedModifier.properties["amount"] = paddingAmount
        updatedModifier.properties["location"] = selectedLocation
        modifier = updatedModifier
    }
    
    /// Continuous save during slider drag - no undo state save
    private func savePaddingContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["amount"] = paddingAmount
        updatedModifier.properties["location"] = selectedLocation
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

// MARK: - Padding Location Row
struct PaddingLocationRow: View {
    let key: String
    let displayName: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24, height: 24)
                
                // Label
                Text(displayName)
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
