//
//  DesignStudioView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/26/25.
//

import SwiftUI

struct DesignStudioView: View {
    @State private var selectedDevice = DevicePreset.iPhone14Pro
    @State private var selectedComponent: ComponentType?
    @State private var canvasComponents: [CanvasComponent] = []
    @State private var selectedCanvasComponent: CanvasComponent?
    @State private var showingInspector = true
    
    var body: some View {
        NavigationSplitView {
            // Components Library Sidebar
            ComponentLibraryView(selectedComponent: $selectedComponent)
        } content: {
            // Canvas Area
            HStack(spacing: 0) {
                // Device Canvas
                DeviceCanvasView(
                    device: selectedDevice,
                    components: $canvasComponents,
                    selectedComponent: $selectedCanvasComponent,
                    onDrop: handleDrop
                )
                .padding()
                
                // Inspector Panel
                if showingInspector {
                    InspectorView(
                        selectedComponent: $selectedCanvasComponent
                    )
                    .frame(width: 280)
                    .background(Color.gray)
                    .border(Color.secondary.opacity(0.2), width: 1)
                }
            }
        } detail: {}
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                DevicePickerView(selectedDevice: $selectedDevice)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingInspector.toggle() }) {
                    Label("Toggle Inspector", systemImage: "sidebar.right")
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button(action: exportSwiftUICode) {
                    Label("Export SwiftUI", systemImage: "arrow.up.doc")
                }
            }
        }
    }
    
    private func handleDrop(_ component: ComponentType, at position: CGPoint) {
        let newComponent = CanvasComponent(
            type: component,
            position: position,
            size: CGSize(width: 100, height: 44)
        )
        canvasComponents.append(newComponent)
    }
    
    private func exportSwiftUICode() {
        // Generate SwiftUI code from components
    }
}

// Supporting Types
struct ComponentType: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: ComponentCategory
}

enum ComponentCategory: String, CaseIterable {
    case layout = "Layout"
    case controls = "Controls"
    case text = "Text"
    case images = "Images"
    case charts = "Charts"
}

struct CanvasComponent: Identifiable {
    let id = UUID()
    var type: ComponentType
    var position: CGPoint
    var size: CGSize
    var properties: [String: Any] = [:]
}

struct DevicePreset {
    let name: String
    let size: CGSize
    let cornerRadius: CGFloat
    let safeAreaInsets: EdgeInsets
    
    static let iPhone14Pro = DevicePreset(
        name: "iPhone 14 Pro",
        size: CGSize(width: 393, height: 852),
        cornerRadius: 55,
        safeAreaInsets: EdgeInsets(top: 59, leading: 0, bottom: 34, trailing: 0)
    )
}
