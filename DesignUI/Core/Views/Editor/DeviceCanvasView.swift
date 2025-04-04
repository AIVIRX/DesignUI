//
//  DeviceCanvasView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/26/25.
//

import SwiftUI

struct DeviceCanvasView: View {
    let device: DevicePreset
    @Binding var components: [CanvasComponent]
    @Binding var selectedComponent: CanvasComponent?
    let onDrop: (ComponentType, CGPoint) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Device Frame
                RoundedRectangle(cornerRadius: device.cornerRadius)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: device.cornerRadius)
                            .fill(Color.gray)
                    )
                    .shadow(radius: 10, y: 5)
                
                // Safe Area Indicator
                RoundedRectangle(cornerRadius: device.cornerRadius - 2)
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                    .padding(.top, device.safeAreaInsets.top)
                    .padding(.bottom, device.safeAreaInsets.bottom)
                
                // Canvas Content
                ForEach(components) { component in
                    ComponentView(
                        component: component,
                        isSelected: component.id == selectedComponent?.id
                    )
                    .position(component.position)
                    .onTapGesture {
                        selectedComponent = component
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let index = components.firstIndex(where: { $0.id == component.id }) {
                                    components[index].position = value.location
                                }
                            }
                    )
                }
            }
            .frame(
                width: device.size.width,
                height: device.size.height,
                alignment: .center
            )
            .scaleEffect(calculateScale(for: geometry.size))
        }
        .dropDestination(for: ComponentType.self) { items, location in
            guard let component = items.first else { return false }
            onDrop(component, location)
            return true
        }
    }
    
    private func calculateScale(for size: CGSize) -> CGFloat {
        let widthScale = (size.width - 40) / device.size.width
        let heightScale = (size.height - 40) / device.size.height
        return min(widthScale, heightScale, 1.0)
    }
}

struct ComponentView: View {
    let component: CanvasComponent
    let isSelected: Bool
    
    var body: some View {
        Group {
            switch component.type.name {
            case "Button":
                Button("Button") { }
                    .frame(width: component.size.width, height: component.size.height)
            case "Text":
                Text("Text")
                    .frame(width: component.size.width, height: component.size.height)
            case "TextField":
                TextField("Placeholder", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: component.size.width, height: component.size.height)
            case "Toggle":
                Toggle("Toggle", isOn: .constant(false))
                    .frame(width: component.size.width, height: component.size.height)
            case "Slider":
                Slider(value: .constant(0.5))
                    .frame(width: component.size.width, height: component.size.height)
            default:
                Text(component.type.name)
                    .frame(width: component.size.width, height: component.size.height)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    DeviceCanvasView(
        device: DevicePreset.iPhone14Pro,
        components: .constant([]),
        selectedComponent: .constant(nil),
        onDrop: { _, _ in }
    )
}
