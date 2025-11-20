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
    @State private var widthType: FrameSizeType = .full
    @State private var heightType: FrameSizeType = .full
    @State private var widthText: String = ""
    @State private var heightText: String = ""
    
    enum FrameSizeType: String, CaseIterable {
        case `default` = "Default"
        case full = "Full"
        case custom = "Custom"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Width Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Width")
                    .font(.caption)
                    .fontWeight(.medium)
                
                HStack {
                    Picker("Width Type", selection: $widthType) {
                        ForEach(FrameSizeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if widthType == .custom {
                        TextField("Width", text: $widthText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: widthText) { _, newValue in
                                // Allow empty string while typing
                                if newValue.isEmpty {
                                    return
                                }
                                // Try to parse the value
                                if let value = Double(newValue) {
                                    print("📏 FrameModifierEditor: Setting width to \(value)")
                                    var updatedModifier = modifier
                                    updatedModifier.properties["width"] = CGFloat(value)
                                    modifier = updatedModifier
                                    component.updateModifier(updatedModifier)
                                }
                            }
                            .onSubmit {
                                // When user finishes editing, ensure we have a valid value
                                if widthText.isEmpty || Double(widthText) == nil {
                                    widthText = String(format: "%.0f", modifier.getCGFloat(key: "width", defaultValue: 100))
                                }
                            }
                    } else if widthType == .full {
                        Text("Full Width")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    } else {
                        Text("Default Width")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    }
                }
            }
            
            // Height Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Picker("Height Type", selection: $heightType) {
                        ForEach(FrameSizeType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if heightType == .custom {
                        TextField("Height", text: $heightText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onChange(of: heightText) { _, newValue in
                                // Allow empty string while typing
                                if newValue.isEmpty {
                                    return
                                }
                                // Try to parse the value
                                if let value = Double(newValue) {
                                    print("📏 FrameModifierEditor: Setting height to \(value)")
                                    var updatedModifier = modifier
                                    updatedModifier.properties["height"] = CGFloat(value)
                                    modifier = updatedModifier
                                    component.updateModifier(updatedModifier)
                                }
                            }
                            .onSubmit {
                                // When user finishes editing, ensure we have a valid value
                                if heightText.isEmpty || Double(heightText) == nil {
                                    heightText = String(format: "%.0f", modifier.getCGFloat(key: "height", defaultValue: 100))
                                }
                            }
                    } else if heightType == .full {
                        Text("Full Height")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    } else {
                        Text("Default Height")
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .leading)
                    }
                }
            }
        }
        .onAppear {
            // Load existing values
            widthType = (modifier.properties["widthType"] as? String).flatMap(FrameSizeType.init) ?? .default
            heightType = (modifier.properties["heightType"] as? String).flatMap(FrameSizeType.init) ?? .default
            widthText = String(format: "%.0f", modifier.getCGFloat(key: "width", defaultValue: 100))
            heightText = String(format: "%.0f", modifier.getCGFloat(key: "height", defaultValue: 100))
        }
        .onChange(of: modifier) { _, _ in
            // Update text fields if modifier changes externally
            if widthType == .custom {
                let currentWidth = modifier.getCGFloat(key: "width", defaultValue: 100)
                if Double(widthText) != Double(currentWidth) {
                    widthText = String(format: "%.0f", currentWidth)
                }
            }
            if heightType == .custom {
                let currentHeight = modifier.getCGFloat(key: "height", defaultValue: 100)
                if Double(heightText) != Double(currentHeight) {
                    heightText = String(format: "%.0f", currentHeight)
                }
            }
        }
        .onChange(of: widthType) { _, newValue in
            // Create updated modifier
            var updatedModifier = modifier
            updatedModifier.properties["widthType"] = newValue.rawValue
            // Ensure width value exists when switching to Custom
            if newValue == .custom && updatedModifier.properties["width"] == nil {
                updatedModifier.properties["width"] = CGFloat(100)
            }
            // Update the binding
            modifier = updatedModifier
            // Update the component to trigger save
            component.updateModifier(updatedModifier)
        }
        .onChange(of: heightType) { _, newValue in
            // Create updated modifier
            var updatedModifier = modifier
            updatedModifier.properties["heightType"] = newValue.rawValue
            // Ensure height value exists when switching to Custom
            if newValue == .custom && updatedModifier.properties["height"] == nil {
                updatedModifier.properties["height"] = CGFloat(100)
            }
            // Update the binding
            modifier = updatedModifier
            // Update the component to trigger save
            component.updateModifier(updatedModifier)
        }
    }
}
