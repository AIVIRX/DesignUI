//
//  ComponentLibraryView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/26/25.
//

import SwiftUI

struct ComponentLibraryView: View {
    @Binding var selectedComponent: ComponentType?
    
    let components: [ComponentCategory: [ComponentType]] = [
        .layout: [
            ComponentType(name: "HStack", icon: "square.stack.3d.up", category: .layout),
            ComponentType(name: "VStack", icon: "square.stack.3d.forward", category: .layout),
            ComponentType(name: "ZStack", icon: "square.stack.3d.down", category: .layout)
        ],
        .controls: [
            ComponentType(name: "Button", icon: "button.programmable", category: .controls),
            ComponentType(name: "Toggle", icon: "switch.2", category: .controls),
            ComponentType(name: "Slider", icon: "slider.horizontal.3", category: .controls)
        ],
        .text: [
            ComponentType(name: "Text", icon: "text.alignleft", category: .text),
            ComponentType(name: "TextField", icon: "textbox", category: .text),
            ComponentType(name: "Label", icon: "tag", category: .text)
        ]
    ]
    
    var body: some View {
        List(ComponentCategory.allCases, id: \.self) { category in
            Section(category.rawValue) {
                ForEach(components[category] ?? []) { component in
                    ComponentRow(component: component)
                        .draggable(component)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct ComponentRow: View {
    let component: ComponentType
    
    var body: some View {
        Label(component.name, systemImage: component.icon)
            .padding(.vertical, 4)
    }
}
