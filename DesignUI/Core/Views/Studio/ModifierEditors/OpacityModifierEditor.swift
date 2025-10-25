//
//  OpacityModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Opacity Modifier Editor
struct OpacityModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var opacity: Double = 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Opacity")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Opacity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("1.0", value: $opacity, formatter: NumberFormatter())
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: opacity) { _, newValue in
                        modifier.properties["opacity"] = newValue
                        NotificationCenter.default.post(name: .designChanged, object: nil)
                    }
            }
        }
        .onAppear {
            opacity = modifier.properties["opacity"] as? Double ?? 1.0
        }
    }
}
