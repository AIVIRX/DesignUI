//
//  OverlayModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Overlay Modifier Editor
struct OverlayModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @State private var overlayType: String = "color"
    
    private var color: Binding<Color> {
        Binding(
            get: { modifier.properties["color"] as? Color ?? Color.clear },
            set: { modifier.properties["color"] = $0 }
        )
    }
    
    private var overlayText: Binding<String> {
        Binding(
            get: { modifier.properties["text"] as? String ?? "Overlay" },
            set: { modifier.properties["text"] = $0 }
        )
    }
    
    private var overlayPosition: Binding<String> {
        Binding(
            get: { modifier.properties["position"] as? String ?? "topTrailing" },
            set: { modifier.properties["position"] = $0 }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overlay")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            // Overlay type picker
            Picker("Type", selection: $overlayType) {
                Text("Color").tag("color")
                Text("Text Badge").tag("text")
            }
            .pickerStyle(.segmented)
            .onChange(of: overlayType) { _, newValue in
                modifier.properties["overlayType"] = newValue
                NotificationCenter.default.post(name: .designChanged, object: nil)
            }
            
            if overlayType == "color" {
                // Color overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay Color")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ColorPicker("Color", selection: color)
                        .labelsHidden()
                }
            } else {
                // Text overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overlay Text")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Overlay", text: overlayText)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Position", selection: overlayPosition) {
                        Text("Top Leading").tag("topLeading")
                        Text("Top Trailing").tag("topTrailing")
                        Text("Bottom Leading").tag("bottomLeading")
                        Text("Bottom Trailing").tag("bottomTrailing")
                        Text("Center").tag("center")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .onAppear {
            overlayType = modifier.properties["overlayType"] as? String ?? "color"
        }
    }
}
