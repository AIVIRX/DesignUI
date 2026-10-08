//
//  CanvasView+Containers.swift
//
//  Split from CanvasView.swift
//

import SwiftUI

// Stable identifier to keep SwiftUI diffing consistent for animations
private func componentViewId(_ component: UIComponent) -> String {
    return component.id.uuidString
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

// Separate view to observe the status bar component's isVisible property for padding
struct ComponentsContainerView: View {

    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let statusBarComponent: UIComponent?
    let canvasManager: CanvasManager
    let screenGeometry: GeometryProxy
    let topContentInset: CGFloat
    
    var body: some View {
        Group {
            if let statusBarComponent = statusBarComponent {
                ComponentsContainerWithStatusBar(
                    components: components,
                    selectedComponent: $selectedComponent,
                    selectedDevice: selectedDevice,
                    colorScheme: colorScheme,
                    statusBarComponent: statusBarComponent,
                    screenGeometry: screenGeometry,
                    canvasManager: canvasManager,
                    topContentInset: topContentInset
                )
            } else {
                ComponentsContainerWithoutStatusBar(
                    components: components,
                    selectedComponent: $selectedComponent,
                    selectedDevice: selectedDevice,
                    colorScheme: colorScheme,
                    screenGeometry: screenGeometry,
                    canvasManager: canvasManager,
                    topContentInset: topContentInset
                )
            }
        }
    }
    
}

// Observes status bar component for visibility changes
struct ComponentsContainerWithStatusBar: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    @ObservedObject var statusBarComponent: UIComponent
    let screenGeometry: GeometryProxy
    let canvasManager: CanvasManager
    let topContentInset: CGFloat
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var animatedComponentIds: [UUID] {
        components.map(\.id)
    }
    
    private func selectChildComponent(_ childComponent: UIComponent, additive: Bool) {
        if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: components) {
            canvasManager.selectComponent(foundComponent, additive: additive)
        }
    }
    
    @ViewBuilder
    private func componentRow(_ component: UIComponent) -> some View {
        ComponentView(
            component: component,
            onSelect: { additive in
                canvasManager.selectComponent(component, additive: additive)
            },
            selectedDevice: selectedDevice,
            colorScheme: colorScheme,
            selectedComponentIds: canvasManager.selectedComponentIds,
            onSelectChild: { childComponent, additive in
                selectChildComponent(childComponent, additive: additive)
            },
            canvasManager: canvasManager
        )
        .id(componentViewId(component))
    }
    
    private func handleBackgroundTap() {
        canvasManager.deselectAll()
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if horizontalSizeClass == .compact {
            NotificationCenter.default.post(name: .minimizeSheet, object: nil)
        }
        #elseif os(macOS)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top padding (Safe Area)
            Spacer()
                .frame(height: topContentInset)
            
            ForEach(components, id: \.id) { component in
                componentRow(component)
            }
        }
        .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
        .clipped() // Prevent content from expanding beyond the screen bounds
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animatedComponentIds)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: topContentInset)
        .onTapGesture(perform: handleBackgroundTap)
    }
    
}

struct ComponentsContainerWithoutStatusBar: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset 
    let colorScheme: ColorScheme?
    let screenGeometry: GeometryProxy
    let canvasManager: CanvasManager
    let topContentInset: CGFloat
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var animatedComponentIds: [UUID] {
        components.map(\.id)
    }
    
    private func selectChildComponent(_ childComponent: UIComponent, additive: Bool) {
        if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: components) {
            canvasManager.selectComponent(foundComponent, additive: additive)
        }
    }
    
    @ViewBuilder
    private func componentRow(_ component: UIComponent) -> some View {
        ComponentView(
            component: component,
            onSelect: { additive in
                canvasManager.selectComponent(component, additive: additive)
            },
            selectedDevice: selectedDevice,
            colorScheme: colorScheme,
            selectedComponentIds: canvasManager.selectedComponentIds,
            onSelectChild: { childComponent, additive in
                selectChildComponent(childComponent, additive: additive)
            },
            canvasManager: canvasManager
        )
        .id(componentViewId(component))
    }
    
    private func handleBackgroundTap() {
        canvasManager.deselectAll()
        #if os(iOS)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if horizontalSizeClass == .compact {
            NotificationCenter.default.post(name: .minimizeSheet, object: nil)
        }
        #elseif os(macOS)
        NSApp.keyWindow?.makeFirstResponder(nil)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: topContentInset)
            ForEach(components, id: \.id) { component in
                componentRow(component)
            }
        }
        .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
        .clipped() // Prevent content from expanding beyond the screen bounds
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: animatedComponentIds)
        .onTapGesture(perform: handleBackgroundTap)
    }
    
}

// Separate view to observe the status bar component's isVisible property
struct StatusBarContainerView: View {
    @ObservedObject var statusBarComponent: UIComponent
    let deviceSize: CGSize
    let colorScheme: ColorScheme?
    var body: some View {
        // Show status bar overlay if enabled
        if let showStatusBar = statusBarComponent.properties.first(where: { $0.key == "showStatusBar" })?.value as? Bool, showStatusBar {
            StatusBarView(
                deviceSize: deviceSize,
                colorScheme: colorScheme
            )
            .background(.clear)
            .allowsHitTesting(false)
        }
    }
}

#if os(macOS)
/// NSViewRepresentable for trackpad scroll (pan) and Cmd+scroll (zoom)
struct CanvasScrollHandler: NSViewRepresentable {
    let isEnabled: Bool
    var shouldPan: (() -> Bool)? = nil
    let onPan: (CGFloat, CGFloat) -> Void
    let onZoom: (CGFloat, CGPoint) -> Void
    
    func makeNSView(context: Context) -> CanvasScrollNSView {
        let view = CanvasScrollNSView()
        view.onPan = onPan
        view.onZoom = onZoom
        view.shouldPan = shouldPan
        view.isEnabled = isEnabled
        return view
    }
    
    func updateNSView(_ nsView: CanvasScrollNSView, context: Context) {
        nsView.onPan = onPan
        nsView.onZoom = onZoom
        nsView.shouldPan = shouldPan
        nsView.isEnabled = isEnabled
    }
}

/// NSView that captures scroll wheel and magnify events when enabled
class CanvasScrollNSView: NSView {
    var onPan: ((CGFloat, CGFloat) -> Void)?
    var onZoom: ((CGFloat, CGPoint) -> Void)?
    var shouldPan: (() -> Bool)?
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
            guard let self, self.shouldHandle(event) else { return event }
            
            if event.modifierFlags.contains(.command) || event.modifierFlags.contains(.option) {
                // Zoom with Cmd/Option + scroll
                let delta = event.scrollingDeltaY * 0.01
                let locationInView = self.convert(event.locationInWindow, from: nil)
                self.onZoom?(delta, locationInView)
                return nil // Consume event
            } else {
                // Check if we should pan
                if let shouldPan = self.shouldPan {
                    if !shouldPan() {
                        return event // Don't consume, let view handle it (e.g. ScrollView)
                    }
                }
                
                // Pan with normal two-finger scroll
                self.onPan?(event.scrollingDeltaX, event.scrollingDeltaY)
                return nil // Consume event
            }
        }
        
        // Monitor pinch/magnify gestures
        magnifyMonitor = NSEvent.addLocalMonitorForEvents(matching: .magnify) { [weak self] event in
            guard let self, self.shouldHandle(event) else { return event }
            
            let locationInView = self.convert(event.locationInWindow, from: nil)
            self.onZoom?(event.magnification, locationInView)
            return nil // Consume event
        }
    }

    private func shouldHandle(_ event: NSEvent) -> Bool {
        guard isEnabled, let window, event.window === window else { return false }
        let location = convert(event.locationInWindow, from: nil)
        return bounds.contains(location)
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

struct ScrollableHoverPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
#endif

// Helper modifier to conditionally apply drawingGroup
struct ConditionalDrawingGroup: ViewModifier {
    var shouldRasterize: Bool
    
    func body(content: Content) -> some View {
        if shouldRasterize {
            content.drawingGroup()
        } else {
            content
        }
    }
}

/// A simplified components container for noSize mode that allows content to determine its own size
struct ContentAdaptiveComponentsView: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let canvasManager: CanvasManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if components.isEmpty {
                // Show a minimal placeholder for empty canvas in noSize mode
                Image(systemName: "plus.circle.dashed")
                    .font(.title2)
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(16)
            } else {
                // Use VStack for layout - components stack vertically and canvas grows with them
                VStack(spacing: 0) {
                    ForEach(components, id: \.id) { component in
                        ComponentView(
                            component: component,
                            onSelect: { additive in
                                canvasManager.selectComponent(component, additive: additive)
                            },
                            selectedDevice: selectedDevice,
                            colorScheme: colorScheme,
                            selectedComponentIds: canvasManager.selectedComponentIds,
                            onSelectChild: { childComponent, additive in
                                if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: components) {
                                    canvasManager.selectComponent(foundComponent, additive: additive)
                                }
                            },
                            canvasManager: canvasManager
                        )
                        .id(componentViewId(component))
                    }
                }
            }
        }
        // No padding - just show raw content in noSize mode
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: components.map { $0.id })
        .onTapGesture {
            // Deselect when clicking empty space
            canvasManager.deselectAll()
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            if horizontalSizeClass == .compact {
                NotificationCenter.default.post(name: .minimizeSheet, object: nil)
            }
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
