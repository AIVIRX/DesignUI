//
//  InspectorView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/26/25.
//

import SwiftUI

struct InspectorView: View {
    @Binding var selectedComponent: CanvasComponent?
    
    var body: some View {
        ScrollView {
            if let component = selectedComponent {
                VStack(alignment: .leading, spacing: 20) {
                    // Component Header
                    HStack {
                        Label(component.type.name, systemImage: component.type.icon)
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            // Delete component action
                            selectedComponent = nil
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Position Section
                    InspectorSection(title: "Position") {
                        HStack(spacing: 16) {
                            InspectorNumberField(
                                label: "X",
                                value: Binding(
                                    get: { component.position.x },
                                    set: { newValue in
                                        selectedComponent?.position.x = newValue
                                    }
                                )
                            )
                            
                            InspectorNumberField(
                                label: "Y",
                                value: Binding(
                                    get: { component.position.y },
                                    set: { newValue in
                                        selectedComponent?.position.y = newValue
                                    }
                                )
                            )
                        }
                    }
                    
                    // Size Section
                    InspectorSection(title: "Size") {
                        HStack(spacing: 16) {
                            InspectorNumberField(
                                label: "Width",
                                value: Binding(
                                    get: { component.size.width },
                                    set: { newValue in
                                        selectedComponent?.size.width = newValue
                                    }
                                )
                            )
                            
                            InspectorNumberField(
                                label: "Height",
                                value: Binding(
                                    get: { component.size.height },
                                    set: { newValue in
                                        selectedComponent?.size.height = newValue
                                    }
                                )
                            )
                        }
                    }
                    
                    // Style Section
                    InspectorSection(title: "Style") {
                        VStack(spacing: 12) {
                            // Component-specific properties
                            switch component.type.name {
                            case "Text":
                                TextField("Text Content", text: .constant("Text"))
                                    .textFieldStyle(.roundedBorder)
                                
                                Picker("Font Size", selection: .constant(16)) {
                                    ForEach([12, 14, 16, 18, 20, 24], id: \.self) { size in
                                        Text("\(size)").tag(size)
                                    }
                                }
                                
                            case "Button":
                                TextField("Button Title", text: .constant("Button"))
                                    .textFieldStyle(.roundedBorder)
                                
                                Picker("Style", selection: .constant("Default")) {
                                    Text("Default").tag("Default")
                                    Text("Bordered").tag("Bordered")
                                    Text("Borderless").tag("Borderless")
                                }
                                
                            case "TextField":
                                TextField("Placeholder", text: .constant("Placeholder"))
                                    .textFieldStyle(.roundedBorder)
                                
                            case "Toggle":
                                TextField("Label", text: .constant("Toggle"))
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Default State", isOn: .constant(false))
                                
                            case "Slider":
                                HStack {
                                    TextField("Min", text: .constant("0"))
                                        .textFieldStyle(.roundedBorder)
                                    Text("-")
                                    TextField("Max", text: .constant("100"))
                                        .textFieldStyle(.roundedBorder)
                                }
                                
                            default:
                                Text("No additional properties")
                            }
                        }
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "square.dashed",
                    description: Text("Select a component to view its properties")
                )
                .padding()
            }
        }
    }
}

struct InspectorSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            content
        }
    }
}

struct InspectorNumberField: View {
    let label: String
    @Binding var value: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(label, value: $value, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 80)
        }
    }
}

#Preview {
    InspectorView(selectedComponent: .constant(
        CanvasComponent(
            type: ComponentType(
                name: "Button",
                icon: "button.programmable",
                category: .controls
            ),
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 100, height: 44)
        )
    ))
}
