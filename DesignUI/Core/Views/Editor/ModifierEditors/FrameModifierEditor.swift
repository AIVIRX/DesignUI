//
//  FrameModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Frame Modifier Editor
struct FrameModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @State private var widthType: FrameSizeType = .default
    @State private var heightType: FrameSizeType = .default
    @State private var widthValue: CGFloat = 100
    @State private var heightValue: CGFloat = 100
    
    enum FrameSizeType: String, CaseIterable {
        case `default` = "Default"
        case full = "Full"
        case custom = "Custom"
        
        var displayName: String { rawValue }
        var icon: String {
            switch self {
            case .default: return "arrow.up.left.and.arrow.down.right"
            case .full: return "arrow.left.and.right"
            case .custom: return "ruler"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Width Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Width")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(FrameSizeType.allCases, id: \.self) { type in
                            FrameOptionRow(
                                type: type,
                                isSelected: widthType == type,
                                value: widthType == .custom && type == .custom ? widthValue : nil,
                                onSelect: {
                                    widthType = type
                                    saveFrame()
                                },
                                onValueChangeContinuous: { newValue in
                                    widthValue = newValue
                                    saveFrameContinuous()
                                },
                                onValueCommit: { newValue in
                                    widthValue = newValue
                                    saveFrame()
                                }
                            )
                            
                            if type != FrameSizeType.allCases.last {
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
                
                // Height Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach(FrameSizeType.allCases, id: \.self) { type in
                            FrameOptionRow(
                                type: type,
                                isSelected: heightType == type,
                                value: heightType == .custom && type == .custom ? heightValue : nil,
                                onSelect: {
                                    heightType = type
                                    saveFrame()
                                },
                                onValueChangeContinuous: { newValue in
                                    heightValue = newValue
                                    saveFrameContinuous()
                                },
                                onValueCommit: { newValue in
                                    heightValue = newValue
                                    saveFrame()
                                }
                            )
                            
                            if type != FrameSizeType.allCases.last {
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
            loadFrame()
        }
        .onChange(of: modifier) { _, _ in
            loadFrame()
        }
    }
    
    private var previewText: String {
        let w = widthType == .custom ? "\(Int(widthValue))" : widthType.rawValue
        let h = heightType == .custom ? "\(Int(heightValue))" : heightType.rawValue
        return "\(w) × \(h)"
    }
    
    private func loadFrame() {
        widthType = (modifier.properties["widthType"] as? String).flatMap(FrameSizeType.init) ?? .default
        heightType = (modifier.properties["heightType"] as? String).flatMap(FrameSizeType.init) ?? .default
        widthValue = modifier.getCGFloat(key: "width", defaultValue: 100)
        heightValue = modifier.getCGFloat(key: "height", defaultValue: 100)
    }
    
    private func saveFrame() {
        var updatedModifier = modifier
        updatedModifier.properties["widthType"] = widthType.rawValue
        updatedModifier.properties["heightType"] = heightType.rawValue
        updatedModifier.properties["width"] = widthValue
        updatedModifier.properties["height"] = heightValue
        modifier = updatedModifier
    }

    private func saveFrameContinuous() {
        var updatedModifier = modifier
        updatedModifier.properties["widthType"] = widthType.rawValue
        updatedModifier.properties["heightType"] = heightType.rawValue
        updatedModifier.properties["width"] = widthValue
        updatedModifier.properties["height"] = heightValue
        
        DispatchQueue.main.async {
            component.updateModifierContinuous(updatedModifier)
        }
    }
}

// MARK: - Frame Option Row
struct FrameOptionRow: View {
    let type: FrameModifierEditor.FrameSizeType
    let isSelected: Bool
    let value: CGFloat?
    let onSelect: () -> Void
    let onValueChangeContinuous: (CGFloat) -> Void
    let onValueCommit: (CGFloat) -> Void
    
    @State private var isHovered = false
    @State private var textValue: String = ""
    @FocusState private var isTextFocused: Bool
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24, height: 24)
                
                // Label
                Text(type.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Value input for custom
                if let val = value, isSelected && type == .custom {
                    TextField("", text: $textValue)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .monospacedDigit()
                        .frame(width: 60)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                        )
                        .focused($isTextFocused)
                        .onAppear {
                            syncText(from: val)
                        }
                        .onChange(of: value) { _, newValue in
                            guard !isTextFocused, let newValue else { return }
                            syncText(from: newValue)
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                            isTextFocused = false
                            if let val = value {
                                syncText(from: val)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                            isTextFocused = false
                            if let val = value {
                                syncText(from: val)
                            }
                        }
                        .onChange(of: textValue) { _, newValue in
                            guard isTextFocused else { return }
                            if let parsed = Double(newValue) {
                                onValueChangeContinuous(CGFloat(parsed))
                            }
                        }
                        .onSubmit {
                            if textValue.isEmpty || Double(textValue) == nil {
                                textValue = String(format: "%.0f", value ?? 100)
                            }
                            if let parsed = Double(textValue) {
                                onValueCommit(CGFloat(parsed))
                            }
                        }
                        .onChange(of: isTextFocused) { _, isFocused in
                            if !isFocused, let parsed = Double(textValue) {
                                onValueCommit(CGFloat(parsed))
                            }
                        }
                } else if isSelected {
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
    
    private func syncText(from value: CGFloat) {
        textValue = String(format: "%.0f", value)
    }
}
