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
                        selectedComponent = nil
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
            let screenCorner: CGFloat = selectedDevice == .mac ? 8 : 50
            
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
                    
                    // Components inside screen
                    VStack(spacing: 0) {
                        ForEach(canvasManager.components, id: \.id) { component in
                            let _ = print("🎨 Rendering component: \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                            ComponentView(
                                component: component,
                                isSelected: selectedComponent?.id == component.id,
                                onSelect: { selectedComponent = component },
                                selectedDevice: selectedDevice,
                                selectedComponent: selectedComponent,
                                onSelectChild: { childComponent in
                                    // Find the component in the hierarchy and select it
                                    if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: canvasManager.components) {
                                        selectedComponent = foundComponent
                                    }
                                }
                            )
                            .id("\(component.id)-\(component.modifiers.count)-\(component.modifiers.map { "\($0.type.rawValue)-\($0.properties.count)" }.joined(separator: "-"))")
                            .onAppear {
                                print("🎨 ComponentView appeared for \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                                // Force a refresh after a short delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    print("🎨 ComponentView force refresh for \(component.type.rawValue)")
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, selectedDevice != .mac && !statusBarHasBackground ? 53 : 0) // Safe area for status bar
                    .clipped() // Prevent content from expanding beyond the screen bounds
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Deselect when clicking empty space
                        selectedComponent = nil
                    }
                    if selectedDevice != .mac {
                        VStack {
                            StatusBarView(
                                deviceSize: deviceSize,
                                isSelected: selectedComponent?.id == canvasManager.statusBarComponent?.id,
                                colorScheme: colorScheme,
                                onSelect: { 
                                    if let statusBarComponent = canvasManager.statusBarComponent {
                                        selectedComponent = statusBarComponent
                                    }
                                }
                            )
                            .background(statusBarHasBackground ? Color.black.opacity(0.8) : .clear)
                            .zIndex(1000) // Ensure status bar is on top
                            
                            Spacer()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: screenCorner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: screenCorner, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(selectedDevice == .mac ? 8 : 16)
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
