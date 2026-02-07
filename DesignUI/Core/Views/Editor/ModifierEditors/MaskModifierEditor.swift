//
//  MaskModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/6/26.
//

import SwiftUI

struct MaskModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    @FocusState private var isCornerRadiusFocused: Bool
    
    private let maskTypes = ["rectangle", "roundedRectangle", "circle", "capsule", "linearGradient"]
    
    private var selectedMask: String {
        modifier.properties["shape"] as? String ?? "rectangle"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mask Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("", selection: Binding(
                    get: { selectedMask },
                    set: { newValue in
                        var updatedModifier = modifier
                        updatedModifier.properties["shape"] = newValue
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                )) {
                    ForEach(maskTypes, id: \.self) { mask in
                        Text(mask.capitalized).tag(mask)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if selectedMask == "roundedRectangle" {
                cornerRadiusField
            }
        }
    }
    
    private var cornerRadiusField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Corner Radius")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let radiusBinding = Binding<String>(
                get: { String(format: "%.0f", modifier.getCGFloat(key: "cornerRadius", defaultValue: 10)) },
                set: { newValue in
                    if let value = Double(newValue) {
                        var updatedModifier = modifier
                        updatedModifier.properties["cornerRadius"] = CGFloat(value)
                        modifier = updatedModifier
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
                }
            )
            
            TextField("10", text: radiusBinding)
                .textFieldStyle(.roundedBorder)
                .focused($isCornerRadiusFocused)
                .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                    isCornerRadiusFocused = false
                }
                .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                    isCornerRadiusFocused = false
                }
        }
    }
}

