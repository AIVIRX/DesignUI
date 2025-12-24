//
//  CanvasView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    @Binding var selectedDevice: DevicePreset
    @Binding var baseZoomLevel: CGFloat
    @Binding var statusBarHasBackground: Bool
    @Binding var colorScheme: ColorScheme?
    @Environment(\.colorScheme) private var appColorScheme
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen canvas background with tap gesture for deselection
                Rectangle()
                    .fill(appColorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color(red: 0.9, green: 0.9, blue: 0.9)) // #262626 for dark, #e6e6e6 for light
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Deselect when clicking on canvas background
                        canvasManager.deselectAll()
                    }
                
                // Zoomable canvas content
                devicePreview(geometry: geometry)
                .scaleEffect(canvasManager.zoomLevel)
                .offset(canvasManager.canvasOffset)
            }
            .onAppear {
                // Set optimal zoom when canvas appears with actual geometry
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: geometry.size)
                    baseZoomLevel = canvasManager.zoomLevel
                }
            }
            .onChange(of: selectedDevice) {
                // Update zoom when device changes with actual geometry
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: geometry.size)
                    baseZoomLevel = canvasManager.zoomLevel
                }
                
                // Update status bar component frame for new device
                if let statusBarComponent = canvasManager.statusBarComponent {
                    statusBarComponent.frame = CGRect(x: 0, y: 0, width: selectedDevice.size.width, height: 53)
                }
            }
            .onChange(of: geometry.size) {
                // Update zoom when canvas size changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: geometry.size)
                    baseZoomLevel = canvasManager.zoomLevel
                }
            }
        }
        .clipped()
    }
    
    private func devicePreview(geometry: GeometryProxy) -> some View {
        ZStack {
            // Centered device frame
            let deviceSize = selectedDevice.size
            
            VStack(spacing: 8) {
                // Screen area
                ZStack {
                    let deviceBackgroundColor: Color = {
                        if colorScheme == .light {
                            return Color.white // Light device background
                        } else {
                            return Color.black // Dark device background
                        }
                    }()
                    
                    Rectangle()
                        .fill(deviceBackgroundColor)
                        .overlay(Color.black.opacity(0.01))
                        .animation(.easeInOut(duration: 0.3), value: colorScheme)
                    
                    // Components inside screen - constrained to device bounds
                    GeometryReader { screenGeometry in
                        ComponentsContainerView(
                            components: canvasManager.components,
                            selectedComponent: $selectedComponent,
                            selectedDevice: selectedDevice,
                            colorScheme: colorScheme,
                            statusBarComponent: canvasManager.statusBarComponent,
                            statusBarHasBackground: statusBarHasBackground,
                            canvasManager: canvasManager,
                            screenGeometry: screenGeometry
                        )
                    }
                    .frame(width: deviceSize.width, height: deviceSize.height)
                }
                .clipShape(Rectangle())
                .overlay(alignment: .top) {
                    if let statusBarComponent = canvasManager.statusBarComponent {
                        StatusBarContainerView(
                            statusBarComponent: statusBarComponent,
                            deviceSize: deviceSize,
                            isSelected: canvasManager.selectedComponentIds.contains(statusBarComponent.id),
                            colorScheme: colorScheme,
                            statusBarHasBackground: statusBarHasBackground,
                            onSelect: { 
                                canvasManager.selectComponent(statusBarComponent)
                            }
                        )
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .frame(width: deviceSize.width, height: deviceSize.height)
                .colorScheme(colorScheme ?? .light)
                
                // Controls directly under device screen
                CanvasControlsOverlay(
                    selectedDevice: $selectedDevice,
                    canvasManager: canvasManager,
                    baseZoomLevel: $baseZoomLevel,
                    statusBarHasBackground: $statusBarHasBackground,
                    colorScheme: $colorScheme
                )
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
    // MARK: - Helper Functions
    private func findComponentInHierarchy(componentId: UUID, in components: [UIComponent]) -> UIComponent? {
        for component in components {
            if component.id == componentId {
                return component
            }
            if let found = findComponentInHierarchy(componentId: componentId, in: component.children) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Components Container View
// Separate view to observe the status bar component's isVisible property for padding
struct ComponentsContainerView: View {

    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let statusBarComponent: UIComponent?
    let statusBarHasBackground: Bool
    let canvasManager: CanvasManager
    let screenGeometry: GeometryProxy
    
    var body: some View {
        Group {
            if let statusBarComponent = statusBarComponent {
                ComponentsContainerWithStatusBar(
                    components: components,
                    selectedComponent: $selectedComponent,
                    selectedDevice: selectedDevice,
                    colorScheme: colorScheme,
                    statusBarComponent: statusBarComponent,
                    statusBarHasBackground: statusBarHasBackground,
                    screenGeometry: screenGeometry,
                    canvasManager: canvasManager
                )
            } else {
                ComponentsContainerWithoutStatusBar(
                    components: components,
                    selectedComponent: $selectedComponent,
                    selectedDevice: selectedDevice,
                    colorScheme: colorScheme,
                    screenGeometry: screenGeometry,
                    canvasManager: canvasManager
                )
            }
        }
    }
    
    private func findComponentInHierarchy(componentId: UUID, in components: [UIComponent]) -> UIComponent? {
        for component in components {
            if component.id == componentId {
                return component
            }
            if let found = findComponentInHierarchy(componentId: componentId, in: component.children) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Components Container With Status Bar
// Observes status bar component for visibility changes
struct ComponentsContainerWithStatusBar: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    @ObservedObject var statusBarComponent: UIComponent
    let statusBarHasBackground: Bool
    let screenGeometry: GeometryProxy
    let canvasManager: CanvasManager
    
    var body: some View {
        VStack(spacing: 0) {
            if statusBarComponent.isVisible {
                Spacer()
                    .frame(height: 53) // Top padding for status bar
            }
            
            ForEach(components, id: \.id) { component in
                let _ = print("🎨 Rendering component: \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                ComponentView(
                    component: component,
                    isSelected: canvasManager.selectedComponentIds.contains(component.id),
                    onSelect: { additive in
                        canvasManager.selectComponent(component, additive: additive)
                    },
                    selectedDevice: selectedDevice,
                    colorScheme: colorScheme,
                    selectedComponentIds: canvasManager.selectedComponentIds,
                    onSelectChild: { childComponent, additive in
                        // Find the component in the hierarchy and select it
                        if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: components) {
                            canvasManager.selectComponent(foundComponent, additive: additive)
                        }
                    }
                )
                .id("\(component.id)-\(component.modifiers.count)-\(component.modifiers.map { "\($0.type.rawValue)-\($0.properties.count)" }.joined(separator: "-"))")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
                .onAppear {
                    print("🎨 ComponentView appeared for \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                    // Force a refresh after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("🎨 ComponentView force refresh for \(component.type.rawValue)")
                    }
                }
            }
        }
        .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
        .clipped() // Prevent content from expanding beyond the screen bounds
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: components.map { $0.id })
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statusBarComponent.isVisible)
        .onTapGesture {
            // Deselect when clicking empty space
            canvasManager.deselectAll()
        }
    }
    
    private func findComponentInHierarchy(componentId: UUID, in components: [UIComponent]) -> UIComponent? {
        for component in components {
            if component.id == componentId {
                return component
            }
            if let found = findComponentInHierarchy(componentId: componentId, in: component.children) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Components Container Without Status Bar
struct ComponentsContainerWithoutStatusBar: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let screenGeometry: GeometryProxy
    let canvasManager: CanvasManager
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(components, id: \.id) { component in
                let _ = print("🎨 Rendering component: \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                ComponentView(
                    component: component,
                    isSelected: canvasManager.selectedComponentIds.contains(component.id),
                    onSelect: { additive in
                        canvasManager.selectComponent(component, additive: additive)
                    },
                    selectedDevice: selectedDevice,
                    colorScheme: colorScheme,
                    selectedComponentIds: canvasManager.selectedComponentIds,
                    onSelectChild: { childComponent, additive in
                        // Find the component in the hierarchy and select it
                        if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: components) {
                            canvasManager.selectComponent(foundComponent, additive: additive)
                        }
                    }
                )
                .id("\(component.id)-\(component.modifiers.count)-\(component.modifiers.map { "\($0.type.rawValue)-\($0.properties.count)" }.joined(separator: "-"))")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
                .onAppear {
                    print("🎨 ComponentView appeared for \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                    // Force a refresh after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        print("🎨 ComponentView force refresh for \(component.type.rawValue)")
                    }
                }
            }
        }
        .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
        .clipped() // Prevent content from expanding beyond the screen bounds
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: components.map { $0.id })
        .onTapGesture {
            // Deselect when clicking empty space
            canvasManager.deselectAll()
        }
    }
    
    private func findComponentInHierarchy(componentId: UUID, in components: [UIComponent]) -> UIComponent? {
        for component in components {
            if component.id == componentId {
                return component
            }
            if let found = findComponentInHierarchy(componentId: componentId, in: component.children) {
                return found
            }
        }
        return nil
    }
}

// MARK: - Status Bar Container View
// Separate view to observe the status bar component's isVisible property
struct StatusBarContainerView: View {
    @ObservedObject var statusBarComponent: UIComponent
    let deviceSize: CGSize
    let isSelected: Bool
    let colorScheme: ColorScheme?
    let statusBarHasBackground: Bool
    let onSelect: () -> Void
    
    var body: some View {
        if statusBarComponent.isVisible {
            StatusBarView(
                deviceSize: deviceSize,
                isSelected: isSelected,
                colorScheme: colorScheme,
                onSelect: onSelect
            )
            .background(.clear)
            .allowsHitTesting(true)
        }
    }
}
