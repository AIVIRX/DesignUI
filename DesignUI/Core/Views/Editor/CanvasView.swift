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
    
    // State for pan gesture
    @State private var currentOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    // State for zoom gesture  
    @GestureState private var magnifyScale: CGFloat = 1.0
    
    // Track if mouse is hovering over canvas (macOS)
    @State private var isCanvasHovered: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas background
                Rectangle()
                    .fill(appColorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color(red: 0.9, green: 0.9, blue: 0.9))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // Deselect components and dismiss keyboard
                        canvasManager.deselectAll()
                        #if os(iOS)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        #elseif os(macOS)
                        NSApp.keyWindow?.makeFirstResponder(nil)
                        #endif
                    }
                
                // Device preview with zoom and pan transforms
                devicePreview(geometry: geometry)
                    .scaleEffect(canvasManager.zoomLevel * magnifyScale)
                    .offset(
                        x: currentOffset.width + dragOffset.width,
                        y: currentOffset.height + dragOffset.height
                    )
            }
            // Simultaneous pan and zoom gestures (like Photos app)
            .gesture(
                SimultaneousGesture(
                    // Drag gesture for panning
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            currentOffset = CGSize(
                                width: currentOffset.width + value.translation.width,
                                height: currentOffset.height + value.translation.height
                            )
                        },
                    // Magnification gesture for zooming
                    MagnificationGesture()
                        .updating($magnifyScale) { value, state, _ in
                            state = value
                        }
                        .onEnded { value in
                            let newZoom = canvasManager.zoomLevel * value
                            canvasManager.zoomLevel = min(max(newZoom, 0.1), 5.0)
                            baseZoomLevel = canvasManager.zoomLevel
                        }
                )
            )
            #if os(macOS)
            // Track hover state
            .onHover { hovering in
                isCanvasHovered = hovering
            }
            // macOS: Cmd/Option + scroll for zooming, normal scroll for panning
            .background(
                CanvasScrollHandler(
                    isEnabled: isCanvasHovered,
                    onPan: { deltaX, deltaY in
                        currentOffset = CGSize(
                            width: currentOffset.width + deltaX,
                            height: currentOffset.height + deltaY
                        )
                    },
                    onZoom: { delta, mouseLocation in
                        let oldZoom = canvasManager.zoomLevel
                        let newZoom = min(max(oldZoom * (1.0 + delta), 0.1), 5.0)
                        
                        // Calculate zoom ratio
                        let zoomRatio = newZoom / oldZoom
                        
                        // Center of the canvas view
                        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                        // Mouse position relative to center
                        let mouseOffset = CGSize(
                            width: mouseLocation.x - center.x,
                            height: mouseLocation.y - center.y
                        )
                        
                        // Calculate new offset to keeping the point under mouse stable
                        // Formula: O_new = P_mouse - (P_mouse - O_old) * (Zoom_new / Zoom_old)
                        let newOffsetX = mouseOffset.width - (mouseOffset.width - currentOffset.width) * zoomRatio
                        let newOffsetY = mouseOffset.height - (mouseOffset.height - currentOffset.height) * zoomRatio
                        
                        currentOffset = CGSize(width: newOffsetX, height: newOffsetY)
                        canvasManager.zoomLevel = newZoom
                        baseZoomLevel = newZoom
                    }
                )
            )
            #endif
            .onAppear {
                // Set optimal zoom when canvas appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: geometry.size)
                    baseZoomLevel = canvasManager.zoomLevel
                }
            }
            .onChange(of: selectedDevice) {
                // Update zoom when device changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: geometry.size)
                    baseZoomLevel = canvasManager.zoomLevel
                    // Reset offset when changing device
                    currentOffset = .zero
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
            .onChange(of: canvasManager.centerCanvasTrigger) {
                // Reset offset to center canvas when triggered from toolbar
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentOffset = .zero
                }
            }
        }
        .clipped()
    }
    
    private func devicePreview(geometry: GeometryProxy) -> some View {
        ZStack {
            // Centered device frame
            let deviceSize = selectedDevice.size
            let isWidget = selectedDevice.category == .widget
            // Corner radius: ~22pt for widgets, ~40-55pt for modern iPhones, 0 for Mac/older iPhones
            let cornerRadius: CGFloat = {
                if isWidget { return 22 }
                if selectedDevice.category == .iphone && !selectedDevice.rawValue.contains("SE") { return 48 } // Modern iPhones
                if selectedDevice.category == .ipad && !selectedDevice.rawValue.contains("Air") { return 18 } // iPads
                 return 0
            }()
            
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
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(alignment: .top) {
                    // Only show status bar if it exists AND it's not a widget
                    if let statusBarComponent = canvasManager.statusBarComponent, !isWidget {
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
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .frame(width: deviceSize.width, height: deviceSize.height)
                .colorScheme(colorScheme ?? .light)
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
                // let _ = print("🎨 Rendering component: \(component.type.rawValue) with \(component.modifiers.count) modifiers")
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
                        // print("🎨 ComponentView force refresh for \(component.type.rawValue)")
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
            // Dismiss keyboard/unfocus text fields
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #elseif os(macOS)
            NSApp.keyWindow?.makeFirstResponder(nil)
            #endif
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
                // let _ = print("🎨 Rendering component: \(component.type.rawValue) with \(component.modifiers.count) modifiers")
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
                        // print("🎨 ComponentView force refresh for \(component.type.rawValue)")
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
            // Dismiss keyboard/unfocus text fields
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #elseif os(macOS)
            NSApp.keyWindow?.makeFirstResponder(nil)
            #endif
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

// MARK: - Scroll Handler for macOS
#if os(macOS)
/// NSViewRepresentable for trackpad scroll (pan) and Cmd+scroll (zoom)
struct CanvasScrollHandler: NSViewRepresentable {
    let isEnabled: Bool
    let onPan: (CGFloat, CGFloat) -> Void
    let onZoom: (CGFloat, CGPoint) -> Void
    
    func makeNSView(context: Context) -> CanvasScrollNSView {
        let view = CanvasScrollNSView()
        view.onPan = onPan
        view.onZoom = onZoom
        view.isEnabled = isEnabled
        return view
    }
    
    func updateNSView(_ nsView: CanvasScrollNSView, context: Context) {
        nsView.onPan = onPan
        nsView.onZoom = onZoom
        nsView.isEnabled = isEnabled
    }
}

/// NSView that captures scroll wheel and magnify events when enabled
class CanvasScrollNSView: NSView {
    var onPan: ((CGFloat, CGFloat) -> Void)?
    var onZoom: ((CGFloat, CGPoint) -> Void)?
    var isEnabled: Bool = false
    
    private var scrollMonitor: Any?
    private var magnifyMonitor: Any?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupEventMonitors()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupEventMonitors()
    }
    
    override var isFlipped: Bool {
        return true
    }

    private func setupEventMonitors() {
        // Monitor scroll wheel events
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }
            
            if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) {
                // Zoom with Cmd/Option + scroll
                let delta = event.scrollingDeltaY * 0.01
                let locationInView = self.convert(event.locationInWindow, from: nil)
                self.onZoom?(delta, locationInView)
                return nil // Consume event
            } else {
                // Pan with normal two-finger scroll
                self.onPan?(event.scrollingDeltaX, event.scrollingDeltaY)
                return nil // Consume event
            }
        }
        
        // Monitor pinch/magnify gestures
        magnifyMonitor = NSEvent.addLocalMonitorForEvents(matching: .magnify) { [weak self] event in
            guard let self = self, self.isEnabled else { return event }
            
            let locationInView = self.convert(event.locationInWindow, from: nil)
            self.onZoom?(event.magnification, locationInView)
            return nil // Consume event
        }
    }
    
    deinit {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = magnifyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
#endif
