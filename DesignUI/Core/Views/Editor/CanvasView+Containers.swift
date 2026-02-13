//
//  CanvasView+Containers.swift
//
//  Split from CanvasView.swift
//

import SwiftUI

// Stable identifier that also refreshes when undo replaces instances
private func componentViewId(_ component: UIComponent) -> String {
    return "\(component.id)-\(ObjectIdentifier(component))-\(component.modifiers.count)-\(component.modifiers.map { "\($0.type.rawValue)-\($0.properties.count)" }.joined(separator: "-"))"
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

// MARK: - Components Container View
// Separate view to observe the status bar component's isVisible property for padding
struct ComponentsContainerView: View {

    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let statusBarComponent: UIComponent?
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
                    statusBarTopSafeArea: canvasManager.statusBarTopSafeArea,
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
    
}

// MARK: - Components Container With Status Bar
// Observes status bar component for visibility changes
struct ComponentsContainerWithStatusBar: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    @ObservedObject var statusBarComponent: UIComponent
    let statusBarTopSafeArea: Bool
    let screenGeometry: GeometryProxy
    let canvasManager: CanvasManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Top padding (Safe Area)
            if statusBarTopSafeArea {
                Spacer()
                    .frame(height: 50) // Top padding for status bar
            }
            
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
                        // Find the component in the hierarchy and select it
                        if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: components) {
                            canvasManager.selectComponent(foundComponent, additive: additive)
                        }
                    },
                    canvasManager: canvasManager
                )
                .id(componentViewId(component))
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
                .onAppear {
                    // Force a refresh after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    }
                }
            }
        }
        .frame(width: screenGeometry.size.width, height: screenGeometry.size.height)
        .clipped() // Prevent content from expanding beyond the screen bounds
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: components.map { $0.id })
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: statusBarTopSafeArea)
        .onTapGesture {
            // Deselect when clicking empty space
            canvasManager.deselectAll()
            // Dismiss keyboard/unfocus text fields
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            // On iPhone, minimize the sheet
            if UIDevice.current.userInterfaceIdiom == .phone {
                NotificationCenter.default.post(name: .minimizeSheet, object: nil)
            }
            #elseif os(macOS)
            NSApp.keyWindow?.makeFirstResponder(nil)
            #endif
        }
    }
    
}

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
                ComponentView(
                    component: component,
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
                    },
                    canvasManager: canvasManager
                )
                .id(componentViewId(component))
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .scale(scale: 0.95))
                ))
                .onAppear {
                    // Force a refresh after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
            // On iPhone, minimize the sheet
            if UIDevice.current.userInterfaceIdiom == .phone {
                NotificationCenter.default.post(name: .minimizeSheet, object: nil)
            }
            #elseif os(macOS)
            NSApp.keyWindow?.makeFirstResponder(nil)
            #endif
        }
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

// MARK: - Scroll Handler for macOS
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
            guard let self = self, self.isEnabled else { return event }
            
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

// MARK: - Content Adaptive Components View
/// A simplified components container for noSize mode that allows content to determine its own size
struct ContentAdaptiveComponentsView: View {
    let components: [UIComponent]
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let canvasManager: CanvasManager
    
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
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
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
            if UIDevice.current.userInterfaceIdiom == .phone {
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
