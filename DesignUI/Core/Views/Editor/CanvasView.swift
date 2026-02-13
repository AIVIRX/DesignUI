//
//  CanvasView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Canvas Render Scale Environment Key
/// Used to pass the current stable zoom level to child views for sharp text rendering
struct CanvasRenderScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

extension EnvironmentValues {
    var canvasRenderScale: CGFloat {
        get { self[CanvasRenderScaleKey.self] }
        set { self[CanvasRenderScaleKey.self] = newValue }
    }
}

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    @Binding var baseZoomLevel: CGFloat
    @Binding var colorScheme: ColorScheme?
    let pushScale: CGFloat
    let pushOffset: CGSize
    @Environment(\.colorScheme) private var appColorScheme
    @Environment(\.displayScale) private var displayScale
    
    // State for pan gesture
    @State private var currentOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    // State for zoom gesture  
    @GestureState private var magnifyScale: CGFloat = 1.0
    
    // Track if mouse is hovering over canvas (macOS)
    @State private var isCanvasHovered: Bool = false
    @State private var isHoveringScrollable: Bool = false
    
    // State for local zoom handling (performance optimization)
    @State private var localZoomLevel: CGFloat = 1.0
    // Debounce timer for syncing back to manager
    @State private var zoomSyncTask: Task<Void, Never>?
    
    // Stable zoom level for sharp rendering
    // Content is rendered at this scale; scaleEffect handles the delta
    @State private var stableZoomLevel: CGFloat = 1.0
    // Force redraw on zoom end for sharp text
    @State private var zoomGeneration: Int = 0
    @State private var isCanvasTransitioning: Bool = false
    
    init(
        canvasManager: CanvasManager,
        selectedComponent: Binding<UIComponent?>,
        selectedDevice: DevicePreset,
        baseZoomLevel: Binding<CGFloat>,
        colorScheme: Binding<ColorScheme?>,
        pushScale: CGFloat = 1.0,
        pushOffset: CGSize = .zero
    ) {
        self.canvasManager = canvasManager
        self._selectedComponent = selectedComponent
        self.selectedDevice = selectedDevice
        self._baseZoomLevel = baseZoomLevel
        self._colorScheme = colorScheme
        self.pushScale = pushScale
        self.pushOffset = pushOffset
    }
    
    var body: some View {
        GeometryReader { geometry in
            canvasContent(in: geometry)
                .gesture(canvasGestures)
                #if os(macOS)
                .onHover { hovering in
                    isCanvasHovered = hovering
                }
                .onPreferenceChange(ScrollableHoverPreferenceKey.self) { isHovering in
                    isHoveringScrollable = isHovering
                }
                .background(
                    CanvasScrollHandler(
                        isEnabled: isCanvasHovered,
                        shouldPan: { !canvasManager.isHoveringScrollable },
                        onPan: { deltaX, deltaY in
                            currentOffset = CGSize(width: currentOffset.width + deltaX, height: currentOffset.height + deltaY)
                        },
                        onZoom: { delta, mouseLocation in
                            handleMacZoom(delta: delta, mouseLocation: mouseLocation, geometry: geometry)
                        }
                    )
                )
                #endif
                .onAppear {
                     initializeZoom(geometry: geometry)
                }
                .onChange(of: canvasManager.zoomLevel) { syncLocalZoom() }
                .onChange(of: selectedDevice) { _, _ in
                    beginCanvasTransition()
                    updateDeviceLayout(geometry: geometry)
                }
                .onChange(of: colorScheme) { _, _ in
                    beginCanvasTransition()
                }
                .onChange(of: geometry.size) { updateLayoutForSizeChange(geometry: geometry) }
                .onChange(of: canvasManager.centerCanvasTrigger) { centerCanvas() }
                .onChange(of: canvasManager.scrollToSelectionTrigger) { scrollToSelection() }
        }
        .clipped()
    }
    
    private func canvasContent(in geometry: GeometryProxy) -> some View {
        // Calculate zoom values
        let effectiveZoom = localZoomLevel * magnifyScale
        let combinedZoom = effectiveZoom * pushScale
        let isActiveGesture = magnifyScale != 1.0
        // Render at higher backing scale when zoomed in to keep text sharp.
        // Clamp to avoid extreme memory use.
        let maxRenderScale = displayScale * 128.0
        let renderScale = min(max(displayScale, displayScale * stableZoomLevel), maxRenderScale)
        
        return ZStack {
            canvasBackground
            
            // When zooming is complete (magnifyScale == 1.0), we want sharp rendering
            // The stableZoomLevel tracks the last completed zoom for reference
            devicePreview(geometry: geometry)
                .environment(\.canvasRenderScale, stableZoomLevel)
                .environment(\.displayScale, renderScale)
                .scaleEffect(combinedZoom)
                .offset(
                    x: currentOffset.width + dragOffset.width + pushOffset.width,
                    y: currentOffset.height + dragOffset.height + pushOffset.height
                )
                .modifier(ConditionalDrawingGroup(shouldRasterize: !canvasManager.hasMapComponent && !canvasManager.hasScrollableComponent))
                // Force view recreation when zoom completes for sharp rendering
                .id("canvas-\(zoomGeneration)")
                // Apply transaction to disable animation caching when stable
                .transaction { transaction in
                    // Allow animations if we are in a transition managed by CanvasManager (device switch)
                    // or local transition (zoom gesture, centering)
                    if !isActiveGesture && !isCanvasTransitioning && !canvasManager.isLayoutTransitioning {
                        transaction.disablesAnimations = true
                    }
                }
        }
    }
    
    private var canvasGestures: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
#if os(iOS)
                    let canPan = UIDevice.current.userInterfaceIdiom == .phone || !canvasManager.isOverlayPanelOpen
#else
                    let canPan = !canvasManager.isOverlayPanelOpen
#endif
                    guard canPan else { return }
                    state = value.translation
                }
                .onEnded { value in
#if os(iOS)
                    let canPan = UIDevice.current.userInterfaceIdiom == .phone || !canvasManager.isOverlayPanelOpen
#else
                    let canPan = !canvasManager.isOverlayPanelOpen
#endif
                    guard canPan else { return }
                    currentOffset = CGSize(
                        width: currentOffset.width + value.translation.width,
                        height: currentOffset.height + value.translation.height
                    )
                },
            MagnificationGesture()
                .updating($magnifyScale) { value, state, _ in state = value }
                .onEnded { value in
                    let newZoom = localZoomLevel * value
                    localZoomLevel = min(max(newZoom, 0.1), 5.0)
                    baseZoomLevel = localZoomLevel
                    canvasManager.zoomLevel = localZoomLevel
                    // Update stable zoom to trigger sharp re-render
                    stableZoomLevel = localZoomLevel
                    zoomGeneration += 1
                }
        )
    }

    // MARK: - Event Handlers
    private func handleMacZoom(delta: CGFloat, mouseLocation: CGPoint, geometry: GeometryProxy) {
        let oldZoom = localZoomLevel
        let newZoom = min(max(oldZoom * (1.0 + delta), 0.1), 5.0)
        let zoomRatio = newZoom / oldZoom
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let mouseOffset = CGSize(width: mouseLocation.x - center.x, height: mouseLocation.y - center.y)
        
        let newOffsetX = mouseOffset.width - (mouseOffset.width - currentOffset.width) * zoomRatio
        let newOffsetY = mouseOffset.height - (mouseOffset.height - currentOffset.height) * zoomRatio
        
        currentOffset = CGSize(width: newOffsetX, height: newOffsetY)
        localZoomLevel = newZoom
        baseZoomLevel = newZoom
        
        // Debounce the sharp re-render until scrolling stops
        zoomSyncTask?.cancel()
        zoomSyncTask = Task {
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms debounce for sharp render
            if !Task.isCancelled {
                await MainActor.run {
                    canvasManager.zoomLevel = localZoomLevel
                    // Update stable zoom to trigger sharp re-render
                    stableZoomLevel = localZoomLevel
                    zoomGeneration += 1
                }
            }
        }
    }

    private func initializeZoom(geometry _: GeometryProxy) {
        localZoomLevel = canvasManager.zoomLevel
        baseZoomLevel = canvasManager.zoomLevel
        stableZoomLevel = canvasManager.zoomLevel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Respect user's current zoom preference or default, don't auto-fit
            localZoomLevel = canvasManager.zoomLevel
            baseZoomLevel = canvasManager.zoomLevel
            stableZoomLevel = canvasManager.zoomLevel
        }
    }

    private func syncLocalZoom() {
        // Don't sync when canvas layout is transitioning (e.g. device switch)
        // to avoid clashing with the animated zoom update
        guard !isCanvasTransitioning else { return }
        
        let newZoom = canvasManager.zoomLevel
        if abs(localZoomLevel - newZoom) > 0.001 {
            localZoomLevel = newZoom
            baseZoomLevel = newZoom
            stableZoomLevel = newZoom
        }
    }

    private func updateDeviceLayout(geometry _: GeometryProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                // Don't auto-zoom to fit
                currentOffset = .zero
            }
        }
        if let statusBarComponent = canvasManager.statusBarComponent {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                statusBarComponent.frame = CGRect(x: 0, y: 0, width: selectedDevice.size.width, height: 50)
            }
        }
    }

    private func updateLayoutForSizeChange(geometry _: GeometryProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Keep current zoom level on resize
            // No action needed for zoom
        }
    }

    private func beginCanvasTransition() {
        isCanvasTransitioning = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isCanvasTransitioning = false
        }
    }

    private func centerCanvas() {
        beginCanvasTransition()
        withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
            currentOffset = .zero
        }
    }

    private func scrollToSelection() {
        if let selected = canvasManager.selectedComponent {
            beginCanvasTransition()
            withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                let absoluteFrame = canvasManager.getAbsoluteFrame(for: selected)
                let center = CGPoint(x: absoluteFrame.midX, y: absoluteFrame.midY)
                let deviceSize = selectedDevice.size
                let deviceCenter = CGPoint(x: deviceSize.width / 2, y: deviceSize.height / 2)
                let targetOffsetX = (deviceCenter.x - center.x) * localZoomLevel
                let targetOffsetY = (deviceCenter.y - center.y) * localZoomLevel
                currentOffset = CGSize(width: targetOffsetX, height: targetOffsetY)
            }
        }
    }
    
    private var canvasBackground: some View {
        Rectangle()
            .fill(appColorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color(red: 0.9, green: 0.9, blue: 0.9))
            .contentShape(Rectangle())
            .onTapGesture {
                // Deselect components and dismiss keyboard
                guard !canvasManager.isTextInputActive else { return }
                canvasManager.didUserDeselect = true
                canvasManager.deselectAll()
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
    
    private func devicePreview(geometry: GeometryProxy) -> some View {
        ZStack {
            // Check if this is a content-adaptive (noSize) preset
            let isContentAdaptive = selectedDevice.isContentAdaptive
            
            // Centered device frame
            let deviceSize = selectedDevice.size
            let isWidget = selectedDevice.category == .widget
            // Corner radius: ~22pt for widgets, ~40-55pt for modern iPhones, 0 for Mac/older iPhones, 12pt for noSize
            let cornerRadius: CGFloat = {
                if isContentAdaptive { return 12 } // Subtle rounded corners for no-size mode
                if isWidget { return 22 }
                if selectedDevice.category == .iphone && !selectedDevice.rawValue.contains("SE") { return 48 } // Modern iPhones
                if selectedDevice.category == .ipad && !selectedDevice.rawValue.contains("Air") { return 18 } // iPads
                 return 0
            }()
            
            let deviceBackgroundColor: Color = {
                if colorScheme == .light {
                    return Color.white // Light device background
                } else {
                    return Color.black // Dark device background
                }
            }()
            
            VStack(spacing: 8) {
                // Screen area - different structure for content-adaptive vs fixed size
                if isContentAdaptive {
                    // Content-adaptive mode: just show content, no visible canvas
                    ContentAdaptiveComponentsView(
                        components: canvasManager.components,
                        selectedComponent: $selectedComponent,
                        selectedDevice: selectedDevice,
                        colorScheme: colorScheme,
                        canvasManager: canvasManager
                    )
                    // Force full rebind after undo/redo to avoid stale component instances
                    .id("content-adaptive-\(canvasManager.undoStackVersion)")
                    .colorScheme(colorScheme ?? .light)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: selectedDevice)
                } else {
                    // Fixed device size mode
                    ZStack {
                        Rectangle()
                            .fill(deviceBackgroundColor)
                            .overlay(Color.black.opacity(0.01))
                            .animation(.easeInOut(duration: 0.3), value: colorScheme)
                        
                        GeometryReader { screenGeometry in
                            ComponentsContainerView(
                                components: canvasManager.components,
                                selectedComponent: $selectedComponent,
                                selectedDevice: selectedDevice,
                                colorScheme: colorScheme,
                                statusBarComponent: canvasManager.statusBarComponent,
                                canvasManager: canvasManager,
                                screenGeometry: screenGeometry
                            )
                            // Force full rebind after undo/redo to avoid stale component instances
                            .id("components-\(canvasManager.undoStackVersion)")
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
                                colorScheme: colorScheme,
                            )
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(width: deviceSize.width, height: deviceSize.height)
                    .background(Color.clear)
                    .colorScheme(colorScheme ?? .light)
                    .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: selectedDevice)
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
    
}
