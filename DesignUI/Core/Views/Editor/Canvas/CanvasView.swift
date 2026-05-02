//
//  CanvasView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

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

struct CanvasView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    @Binding var baseZoomLevel: CGFloat
    @Binding var colorScheme: ColorScheme?
    let pushScale: CGFloat
    let pushOffset: CGSize
    let enableScrollHandler: Bool
    @Environment(\.colorScheme) private var appColorScheme
    @Environment(\.displayScale) private var displayScale
    
    // State for pan gesture
    @State private var currentOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    @State private var viewportSize: CGSize = .zero
    
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
        pushOffset: CGSize = .zero,
        enableScrollHandler: Bool = true
    ) {
        self.canvasManager = canvasManager
        self._selectedComponent = selectedComponent
        self.selectedDevice = selectedDevice
        self._baseZoomLevel = baseZoomLevel
        self._colorScheme = colorScheme
        self.pushScale = pushScale
        self.pushOffset = pushOffset
        self.enableScrollHandler = enableScrollHandler
    }
    
    var body: some View {
        GeometryReader { geometry in
            canvasBody(in: geometry)
        }
        .clipped()
    }

    @ViewBuilder
    private func canvasBody(in geometry: GeometryProxy) -> some View {
        #if os(macOS)
        macCanvasView(in: geometry)
        #else
        baseCanvasView(in: geometry)
        #endif
    }

    private func baseCanvasView(in geometry: GeometryProxy) -> some View {
        canvasContent(in: geometry)
            .gesture(canvasGestures)
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
            .onChange(of: geometry.size) { _, newSize in
                viewportSize = newSize
                currentOffset = clampOffset(currentOffset)
            }
            .onAppear {
                viewportSize = geometry.size
            }
            .onChange(of: canvasManager.centerCanvasTrigger) { centerCanvas() }
            .onChange(of: canvasManager.scrollToSelectionTrigger) { scrollToSelection() }
    }

    #if os(macOS)
    private func macCanvasView(in geometry: GeometryProxy) -> some View {
        baseCanvasView(in: geometry)
            .onHover { hovering in
                isCanvasHovered = hovering
            }
            .onPreferenceChange(ScrollableHoverPreferenceKey.self) { isHovering in
                isHoveringScrollable = isHovering
            }
            .background(macScrollHandler(in: geometry))
    }

    @ViewBuilder
    private func macScrollHandler(in geometry: GeometryProxy) -> some View {
        if enableScrollHandler {
            CanvasScrollHandler(
                isEnabled: isCanvasHovered,
                shouldPan: { !canvasManager.isHoveringScrollable },
                onPan: { deltaX, deltaY in
                    let proposed = CGSize(width: currentOffset.width + deltaX, height: currentOffset.height + deltaY)
                    currentOffset = clampOffset(proposed)
                },
                onZoom: { delta, mouseLocation in
                    handleMacZoom(delta: delta, mouseLocation: mouseLocation, geometry: geometry)
                }
            )
        }
    }
    #endif
    
    private func canvasContent(in geometry: GeometryProxy) -> some View {
        // Calculate zoom values
        let effectiveZoom = localZoomLevel * magnifyScale
        let combinedZoom = effectiveZoom * pushScale
        let isActiveGesture = abs(magnifyScale - 1.0) > 0.001
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
                .modifier(
                    ConditionalDrawingGroup(
                        shouldRasterize: !canvasManager.hasMapComponent
                            && !canvasManager.hasScrollableComponent
                            && !canvasManager.hasPlatformViewComponent
                    )
                )
                // Force view recreation when zoom completes for sharp rendering
                .id("canvas-\(zoomGeneration)")
                // Apply transaction to disable animation caching when stable
                .transaction { transaction in
                    // Only suppress animations during active zoom gestures to avoid jitter.
                    transaction.disablesAnimations = isActiveGesture
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
                    let proposed = CGSize(
                        width: currentOffset.width + value.translation.width,
                        height: currentOffset.height + value.translation.height
                    )
                    currentOffset = clampOffset(proposed)
                },
            MagnificationGesture()
                .updating($magnifyScale) { value, state, _ in state = value }
                .onEnded { value in
                    let newZoom = localZoomLevel * value
                    localZoomLevel = min(max(newZoom, 0.1), 5.0)
                    baseZoomLevel = localZoomLevel
                    canvasManager.zoomLevel = localZoomLevel
                    currentOffset = clampOffset(currentOffset)
                    // Update stable zoom to trigger sharp re-render
                    stableZoomLevel = localZoomLevel
                    zoomGeneration += 1
                }
        )
    }

    private func handleMacZoom(delta: CGFloat, mouseLocation: CGPoint, geometry: GeometryProxy) {
        let oldZoom = localZoomLevel
        let newZoom = min(max(oldZoom * (1.0 + delta), 0.1), 5.0)
        let zoomRatio = newZoom / oldZoom
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let mouseOffset = CGSize(width: mouseLocation.x - center.x, height: mouseLocation.y - center.y)
        
        let newOffsetX = mouseOffset.width - (mouseOffset.width - currentOffset.width) * zoomRatio
        let newOffsetY = mouseOffset.height - (mouseOffset.height - currentOffset.height) * zoomRatio
        
        currentOffset = clampOffset(CGSize(width: newOffsetX, height: newOffsetY))
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

    private func clampOffset(_ offset: CGSize) -> CGSize {
        // Intentionally unbounded: allow panning freely in any direction.
        return offset
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
            if canvasManager.isLayoutTransitioning {
                beginCanvasTransition()
                withAnimation(.interpolatingSpring(stiffness: 170, damping: 15)) {
                    localZoomLevel = newZoom
                    baseZoomLevel = newZoom
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    stableZoomLevel = newZoom
                    zoomGeneration += 1
                }
            } else {
                localZoomLevel = newZoom
                baseZoomLevel = newZoom
                stableZoomLevel = newZoom
            }
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
        let isContentAdaptive = selectedDevice.isContentAdaptive
        let deviceSize = selectedDevice.size
        let isWidget = selectedDevice.category == .widget
        let cornerRadius = deviceCornerRadius(isContentAdaptive: isContentAdaptive, isWidget: isWidget)
        let deviceBackgroundColor = deviceBackgroundColor()

        return ZStack {
            VStack(spacing: 8) {
                if isContentAdaptive {
                    contentAdaptivePreview
                } else {
                    fixedDevicePreview(
                        deviceSize: deviceSize,
                        cornerRadius: cornerRadius,
                        isWidget: isWidget,
                        deviceBackgroundColor: deviceBackgroundColor
                    )
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private var contentAdaptivePreview: some View {
        ContentAdaptiveComponentsView(
            components: canvasManager.components,
            selectedComponent: $selectedComponent,
            selectedDevice: selectedDevice,
            colorScheme: colorScheme,
            canvasManager: canvasManager
        )
        .colorScheme(colorScheme ?? .light)
        .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: selectedDevice)
        .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: canvasManager.components.map(\.id))
    }

    private func fixedDevicePreview(
        deviceSize: CGSize,
        cornerRadius: CGFloat,
        isWidget: Bool,
        deviceBackgroundColor: Color
    ) -> some View {
        ZStack {
            fixedDeviceBackground(color: deviceBackgroundColor)
            componentsLayer(deviceSize: deviceSize)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(alignment: .top) {
            statusBarOverlay(deviceSize: deviceSize, isWidget: isWidget)
        }
        .overlay(deviceBorder(cornerRadius: cornerRadius))
        .frame(width: deviceSize.width, height: deviceSize.height)
        .background(Color.clear)
        .colorScheme(colorScheme ?? .light)
        .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: selectedDevice)
    }
    
    private func fixedDeviceBackground(color: Color) -> some View {
        Rectangle()
            .fill(color)
            .overlay(Color.black.opacity(0.01))
            .animation(.easeInOut(duration: 0.3), value: colorScheme)
    }
    
    private func componentsLayer(deviceSize: CGSize) -> some View {
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
            .animation(.interpolatingSpring(stiffness: 170, damping: 15), value: canvasManager.components.map(\.id))
        }
        .frame(width: deviceSize.width, height: deviceSize.height)
    }
    
    @ViewBuilder
    private func statusBarOverlay(deviceSize: CGSize, isWidget: Bool) -> some View {
        if let statusBarComponent = canvasManager.statusBarComponent, !isWidget {
            StatusBarContainerView(
                statusBarComponent: statusBarComponent,
                deviceSize: deviceSize,
                colorScheme: colorScheme
            )
        }
    }
    
    private func deviceBorder(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
    }

    private func deviceCornerRadius(isContentAdaptive: Bool, isWidget: Bool) -> CGFloat {
        if isContentAdaptive { return 12 }
        if isWidget { return 22 }
        if selectedDevice.category == .iphone && !selectedDevice.rawValue.contains("SE") { return 48 }
        if selectedDevice.category == .ipad && !selectedDevice.rawValue.contains("Air") { return 18 }
        return 0
    }

    private func deviceBackgroundColor() -> Color {
        colorScheme == .light ? .white : .black
    }
    
}
