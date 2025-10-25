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
    @State private var widthType: FrameSizeType = .full
    @State private var heightType: FrameSizeType = .full
    @State private var widthValue: CGFloat = 100
    @State private var heightValue: CGFloat = 100
    
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
                        TextField("Width", value: $widthValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                modifier.properties["width"] = widthValue
                                NotificationCenter.default.post(name: .designChanged, object: nil)
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
                        TextField("Height", value: $heightValue, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .onSubmit {
                                modifier.properties["height"] = heightValue
                                NotificationCenter.default.post(name: .designChanged, object: nil)
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
            widthValue = modifier.properties["width"] as? CGFloat ?? 100
            heightValue = modifier.properties["height"] as? CGFloat ?? 100
        }
        .onChange(of: widthType) { _, newValue in
            modifier.properties["widthType"] = newValue.rawValue
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        .onChange(of: heightType) { _, newValue in
            modifier.properties["heightType"] = newValue.rawValue
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    }
}
