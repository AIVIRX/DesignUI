//
//  CornerRadiusModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Corner Radius Modifier Editor
struct CornerRadiusModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var cornerRadius: CGFloat = 8
    
    var body: some View {
        HStack {
            Text("Radius")
            
            Spacer()
            
            TextField("8", value: $cornerRadius, formatter: NumberFormatter())
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .onChange(of: cornerRadius) { _, newValue in
                    modifier.properties["radius"] = newValue
                    NotificationCenter.default.post(name: .designChanged, object: nil)
                }
        }
        .onAppear {
            if let cgFloatRadius = modifier.properties["radius"] as? CGFloat {
                cornerRadius = cgFloatRadius
            } else if let doubleRadius = modifier.properties["radius"] as? Double {
                cornerRadius = CGFloat(doubleRadius)
            } else if let intRadius = modifier.properties["radius"] as? Int {
                cornerRadius = CGFloat(intRadius)
            } else {
                cornerRadius = 8
                print("⚠️ CornerRadiusModifierEditor: Could not cast radius to CGFloat, raw value: \(modifier.properties["radius"] ?? "nil")")
            }
        }
    }
}
