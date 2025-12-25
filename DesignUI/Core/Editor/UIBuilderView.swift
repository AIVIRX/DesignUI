//
//  UIBuilderView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension Notification.Name {
    static let canvasUndo = Notification.Name("canvas.undo")
    static let canvasRedo = Notification.Name("canvas.redo")
    static let designChanged = Notification.Name("design.changed")
}

enum DevicePreset: String, CaseIterable, Identifiable {
    // iPhone 17 Series (Latest)
    case iphone17ProMax = "iPhone 17 Pro Max"
    
    // iPhone 16 Series
    case iphone16 = "iPhone 16"
    case iphone16Plus = "iPhone 16 Plus"
    case iphone16Pro = "iPhone 16 Pro"
    case iphone16ProMax = "iPhone 16 Pro Max"
    
    // iPhone 15 Series
    case iphone15Pro = "iPhone 15 Pro"
    case iphone15ProMax = "iPhone 15 Pro Max"
    case iphone15 = "iPhone 15"
    case iphone15Plus = "iPhone 15 Plus"
    
    // iPhone 14 Series
    case iphone14 = "iPhone 14"
    case iphone14Pro = "iPhone 14 Pro"
    case iphone14ProMax = "iPhone 14 Pro Max"
    
    // iPhone 13 Series
    case iphone13Mini = "iPhone 13 mini"
    case iphone13 = "iPhone 13"
    case iphone13Pro = "iPhone 13 Pro"
    case iphone13ProMax = "iPhone 13 Pro Max"
    
    // iPhone SE
    case iphoneSE3 = "iPhone SE (3rd gen)"
    
    // iPad Series
    case ipadPro11 = "iPad Pro 11" 
    case ipadPro12 = "iPad Pro 12.9"
    
    // Mac Canvas
    case mac = "Mac Canvas"
    
    var id: String { rawValue }
    
    var size: CGSize {
        switch self {
        // iPhone 17 Series - Based on actual viewport dimensions (Latest)
        // Physical pixels: 1320 × 2868, Logical points: 440 × 956 (3x scale)
        case .iphone17ProMax: return CGSize(width: 440, height: 956) // 6.9" display
        
        // iPhone 16 Series - Logical points (matches iOS Simulator exactly)
        case .iphone16: return CGSize(width: 390, height: 844) // 6.1" display
        case .iphone16Plus: return CGSize(width: 428, height: 926) // 6.7" display
        case .iphone16Pro: return CGSize(width: 414, height: 896) // 6.3" display
        case .iphone16ProMax: return CGSize(width: 430, height: 932) // 6.9" display
        
        // iPhone 15 Series - Logical points (matches iOS Simulator)
        case .iphone15Pro: return CGSize(width: 393, height: 852) // 6.1" display
        case .iphone15ProMax: return CGSize(width: 430, height: 932) // 6.9" display
        case .iphone15: return CGSize(width: 390, height: 844) // 6.1" display
        case .iphone15Plus: return CGSize(width: 428, height: 926) // 6.7" display
        
        // iPhone 14 Series - Based on actual viewport dimensions
        case .iphone14: return CGSize(width: 390, height: 844) // 6.1" display
        case .iphone14Pro: return CGSize(width: 393, height: 852) // 6.1" display
        case .iphone14ProMax: return CGSize(width: 430, height: 932) // 6.7" display
        
        // iPhone 13 Series - Based on actual viewport dimensions
        case .iphone13Mini: return CGSize(width: 375, height: 812) // 5.4" display
        case .iphone13: return CGSize(width: 390, height: 844) // 6.1" display
        case .iphone13Pro: return CGSize(width: 390, height: 844) // 6.1" display
        case .iphone13ProMax: return CGSize(width: 428, height: 926) // 6.7" display
        
        // iPhone SE (3rd gen) - Based on actual viewport dimensions
        case .iphoneSE3: return CGSize(width: 320, height: 568) // 4.7" display
        
        // iPad Series - Based on actual viewport dimensions
        case .ipadPro11: return CGSize(width: 834, height: 1194) // 11" display
        case .ipadPro12: return CGSize(width: 1024, height: 1366) // 12.9" display
        
        // Mac Canvas
        case .mac: return CGSize(width: 1280, height: 800)
        }
    }
}

struct UIBuilderView: View {
    @ObservedObject var designFile: DesignFile
    @EnvironmentObject private var designManager: DesignManager
    @StateObject private var canvasManager = CanvasManager()

    @State private var showCodePreview = false
    @State private var selectedDevice: DevicePreset = .iphone16Pro
    @State private var baseZoomLevel: CGFloat = 1.0
    @State private var statusBarHasBackground: Bool = false
    @State private var colorScheme: ColorScheme? = .light
    
    // Panel states
    @State private var layersPanelWidth: CGFloat = 300
    @State private var propertiesPanelWidth: CGFloat = 300
    @State private var showLayersPanel = true
    @State private var showPropertiesPanel = true
    
    // iOS half sheet states
    @State private var showLayersSheet = false
    @State private var showPropertiesSheet = false
    @State private var layersSheetHeight: CGFloat = 0.5 // Half open by default
    @State private var propertiesSheetHeight: CGFloat = 0.5 // Half open by default
    
    // Screenshot capture debouncing
    @State private var lastScreenshotTime: Date = Date.distantPast
    private let screenshotDebounceInterval: TimeInterval = 0.5 // Minimum 0.5 seconds between screenshots
    
    
    var body: some View {
        NavigationStack {
#if os(iOS)
            // iOS: Full screen canvas with floating panels
            ZStack {
                mainCanvasArea
                    .ignoresSafeArea()
                
                // Floating action buttons for panels (respects safe area)
                VStack {
                    HStack {
                        // Close button (top-left)
                        Button(action: { 
                            designManager.closeCurrentDesign()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.secondary.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 12) {
                            Button(action: { showLayersSheet = true }) {
                                Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            
                            Button(action: { showPropertiesSheet = true }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
#else
            // macOS: Resizable panels layout
            ZStack {
                mainCanvasArea
                
                // Floating panels with proper margins
                HStack(spacing: 0) {
                    // Left side: Layers panel
                    if showLayersPanel {
                        ResizablePanel(
                            width: $layersPanelWidth,
                            minWidth: 250,
                            maxWidth: 500,
                            isVisible: $showLayersPanel,
                            handlePosition: .right
                        ) {
                            layersPanel
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding()
                        .animation(.easeInOut(duration: 0.3), value: showLayersPanel)
                    }
                    
                    Spacer()
                    
                    if showPropertiesPanel && canvasManager.selectedComponent != nil {
                        ResizablePanel(
                            width: $propertiesPanelWidth,
                            minWidth: 250,
                            maxWidth: 500,
                            isVisible: $showPropertiesPanel,
                            handlePosition: .left
                        ) {
                            propertiesPanel
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .padding()
                        .animation(.easeInOut(duration: 0.3), value: showPropertiesPanel)
                    }
                }
            }
#endif
        }
        .navigationTitle("Studio")
        .toolbar { toolbarButtons }
        .sheet(isPresented: $showCodePreview) {
            CodePreviewView(canvasManager: canvasManager, targetSize: selectedDevice.size)
        }
#if os(iOS)
        .sheet(isPresented: $showLayersSheet) {
            layersHalfSheet
        }
        .sheet(isPresented: $showPropertiesSheet) {
            propertiesHalfSheet
        }
#endif
        .onAppear {
            setupCanvas()
            // Restore saved device preset and color scheme
            restoreCanvasSettings()
            // Capture initial screenshot if design has components
            if !canvasManager.components.isEmpty {
                captureScreenshot()
            }
        }
        .onChange(of: canvasManager.components) { _, _ in
            syncComponents()
        }
        .onChange(of: canvasManager.selectedComponent) { _, _ in
            syncSelection()
        }
        .onChange(of: selectedDevice) { _, _ in
            saveCanvasSettings()
        }
        .onChange(of: colorScheme) { _, _ in
            saveCanvasSettings()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
            canvasManager.undo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
            canvasManager.redo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .designChanged)) { _ in
            syncDesignChanges()
        }
    }
    
    private var layersPanel: some View {
        LayersPanelView(
            canvasManager: canvasManager,
            selectedComponent: $canvasManager.selectedComponent
        )
    }
    
    private var mainCanvasArea: some View {
        ZStack(alignment: .top) {
            canvasView
        }
        .animation(.spring(), value: canvasManager.selectedComponentIds.count)
    }
    
    private var canvasView: some View {
        CanvasView(
            canvasManager: canvasManager,
            selectedComponent: $canvasManager.selectedComponent,
            selectedDevice: $selectedDevice,
            baseZoomLevel: $baseZoomLevel,
            statusBarHasBackground: $statusBarHasBackground,
            colorScheme: $colorScheme
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(magnificationGesture)
#if os(macOS)
        .background(
            // Hidden buttons to capture keyboard shortcuts without showing focus ring
            Group {
                // Delete key (not for status bar)
                Button(action: {
                    if let component = canvasManager.selectedComponent, component.type != .statusBar {
                        canvasManager.removeComponent(component)
                        canvasManager.deselectAll()
                    }
                }) {
                    EmptyView()
                }
                .keyboardShortcut(.delete, modifiers: [])
                .hidden()
                
                // Copy (Cmd+C) - not for status bar
                Button(action: {
                    if let component = canvasManager.selectedComponent, component.type != .statusBar {
                        canvasManager.copyComponent(component)
                    }
                }) {
                    EmptyView()
                }
                .keyboardShortcut("c", modifiers: .command)
                .hidden()
                
                // Paste (Cmd+V)
                Button(action: {
                    canvasManager.pasteComponent()
                }) {
                    EmptyView()
                }
                .keyboardShortcut("v", modifiers: .command)
                .hidden()
                
                
                // Cut (Cmd+X) - Removed as per request
                /*
                Button(action: {
                    if let component = canvasManager.selectedComponent, component.type != .statusBar {
                        canvasManager.cutComponent(component)
                        canvasManager.deselectAll()
                    }
                }) {
                    EmptyView()
                }
                .keyboardShortcut("x", modifiers: .command)
                .hidden()
                */
                
                // Duplicate (Cmd+D) - not for status bar
                Button(action: {
                    if let component = canvasManager.selectedComponent, component.type != .statusBar {
                        canvasManager.duplicateComponent(component)
                        // Select the duplicated component
                        // selectedComponent = canvasManager.selectedComponent // Already handled by canvasManager
                    }
                }) {
                    EmptyView()
                }
                .keyboardShortcut("d", modifiers: .command)
                .hidden()
            }
            .frame(width: 0, height: 0)
        )
#endif
    }
    
    private var propertiesPanel: some View {
        PropertiesPanelView(
            selectedComponent: $canvasManager.selectedComponent,
            canvasManager: canvasManager
        )
    }
    
#if os(iOS)
    private var layersHalfSheet: some View {
        VStack(spacing: 0) {
            // Handle for dragging
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            // Layers content
            LayersPanelView(
                canvasManager: canvasManager,
                selectedComponent: $canvasManager.selectedComponent
            )
        }
        .presentationDetents([.fraction(0.3), .fraction(0.5), .fraction(0.7)])
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }
    
    private var propertiesHalfSheet: some View {
        VStack(spacing: 0) {
            // Handle for dragging
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary)
                .frame(width: 36, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
            // Properties content
            if canvasManager.selectedComponent != nil {
                PropertiesPanelView(
                    selectedComponent: $canvasManager.selectedComponent,
                    canvasManager: canvasManager
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "cursorarrow.click")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No Component Selected")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Tap on a component in the canvas to edit its properties")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .presentationDetents([.fraction(0.3), .fraction(0.5), .fraction(0.7)])
        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.5)))
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }
#endif
    
    private var toolbarButtons: some ToolbarContent {
        Group{
            ToolbarItemGroup(placement: .primaryAction) {
                // Undo button
                Button(action: {
                    canvasManager.undo()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .medium))
                }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(!canvasManager.canUndo)
                .help("Undo")
                
                // Redo button
                Button(action: {
                    canvasManager.redo()
                }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 14, weight: .medium))
                }
                .keyboardShortcut("z", modifiers: [.command, .shift])
                .disabled(!canvasManager.canRedo)
                .help("Redo")
            }
            
            #if os(macOS)
            if #available(macOS 26.0, *) {
                ToolbarSpacer(.flexible, placement: .primaryAction)
            }
            #endif
            
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button(action: { showCodePreview = true }) {
                        Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Button(action: { copyDesignAsJSON() }) {
                        Label("Copy JSON", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .medium))
                }
                .help("Export")
            }
        }
    }

        
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newZoom = baseZoomLevel * value
                let limitedZoom = min(newZoom, 3.0)
                canvasManager.setZoomLevel(limitedZoom)
            }
            .onEnded { _ in
                baseZoomLevel = canvasManager.zoomLevel
            }
    }
    
    
    // MARK: - Actions
    
    private func copyDesignAsJSON() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(canvasManager.components)
            if let jsonString = String(data: data, encoding: .utf8) {
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(jsonString, forType: .string)
                #else
                UIPasteboard.general.string = jsonString
                #endif
                print("✅ JSON copied to clipboard")
            }
        } catch {
            print("❌ Failed to copy JSON: \(error)")
        }
    }
    
    private func saveDesign() {
        print("💾 Manual save button pressed")
        // Capture screenshot before saving
        captureScreenshot()
        // Wait a bit for screenshot to be captured, then save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.designManager.saveCurrentDesign()
            print("💾 Manual save triggered")
        }
    }
    
    private func setupCanvas() {
            canvasManager.components = designFile.components
            canvasManager.setDesignName(designFile.name)
            
            // Save the initial loaded state as the base state (but don't allow undo to this)
            // This ensures we can undo back to the loaded state, but undo is disabled until we make a change
            canvasManager.saveInitialState()
        }
    
    private func restoreCanvasSettings() {
        // Restore selected device preset
        if let savedDevicePreset = designFile.selectedDevicePreset,
           let devicePreset = DevicePreset.allCases.first(where: { $0.rawValue == savedDevicePreset }) {
            selectedDevice = devicePreset
        }
        
        // Restore canvas color scheme
        if let savedColorScheme = designFile.canvasColorScheme {
            if savedColorScheme.lowercased() == "light" {
                colorScheme = .light
            } else if savedColorScheme.lowercased() == "dark" {
                colorScheme = .dark
            }
        }
    }
    
    private func saveCanvasSettings() {
        // Save selected device preset
        designFile.selectedDevicePreset = selectedDevice.rawValue
        
        // Save canvas color scheme
        if let scheme = colorScheme {
            designFile.canvasColorScheme = scheme == .light ? "light" : "dark"
        } else {
            designFile.canvasColorScheme = nil
        }
        
        // Trigger save
        designManager.markAsChanged()
    }
    
    private func syncComponents() {
            print("🔄 syncComponents: Components changed - syncing to design file")
            print("🔄 syncComponents: Components count: \(canvasManager.components.count)")
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designManager.markAsChanged()
            print("🔄 syncComponents: Posting .designChanged notification")
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    
    private func syncSelection() {
            print("🔄 Selection changed - syncing to design file")
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designManager.markAsChanged()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    
    private func syncDesignChanges() {
            print("🔄 Design changed notification received - syncing components")
            print("🔄 Canvas components count: \(canvasManager.components.count)")
            print("🔄 Design file components count: \(designFile.components.count)")
            
            // Debug: Print modifier details before sync
            for (index, component) in canvasManager.components.enumerated() {
                print("🔄 Canvas component \(index): \(component.type.rawValue) with \(component.modifiers.count) modifiers")
                for (modIndex, modifier) in component.modifiers.enumerated() {
                    print("🔄   - Modifier \(modIndex): \(modifier.type.rawValue) with properties: \(modifier.properties)")
                }
            }
            
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designFile.objectWillChange.send() // Force design file to recognize changes
            designManager.markAsChanged()
    }
    
    // MARK: - Screenshot Capture
    private func captureScreenshot() {
        // Debounce: Only capture if enough time has passed since last capture
        let now = Date()
        guard now.timeIntervalSince(lastScreenshotTime) >= screenshotDebounceInterval else {
            print("⏭️ Skipping screenshot capture (too soon since last capture)")
            return
        }
        
        // Update last capture time
        lastScreenshotTime = now
        
        // Capture screenshot asynchronously to avoid blocking UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let screenshotView = CanvasScreenshotView(
                components: self.canvasManager.components,
                deviceSize: self.selectedDevice.size,
                colorScheme: self.colorScheme ?? .light,
                statusBarComponent: self.canvasManager.statusBarComponent,
                statusBarHasBackground: self.statusBarHasBackground
            )
            
            if let thumbnailData = ScreenshotUtility.shared.captureThumbnail(
                of: screenshotView,
                size: self.selectedDevice.size,
                colorScheme: self.colorScheme ?? .light
            ) {
                // This will overwrite the previous thumbnail and store device preset
                self.designFile.setThumbnail(thumbnailData, devicePreset: self.selectedDevice.rawValue)
                print("✅ Screenshot captured and set on design file (overwrites previous)")
            } else {
                print("⚠️ Failed to capture screenshot")
            }
        }
    }
}

struct ComponentView: View {
    @ObservedObject var component: UIComponent
    let isSelected: Bool
    let onSelect: (Bool) -> Void  // Bool indicates additive selection
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let selectedComponentIds: Set<UUID>
    let onSelectChild: ((UIComponent, Bool) -> Void)?
    @State private var isHovered: Bool = false
    
    init(component: UIComponent, isSelected: Bool, onSelect: @escaping (Bool) -> Void, selectedDevice: DevicePreset, colorScheme: ColorScheme?, selectedComponentIds: Set<UUID>, onSelectChild: ((UIComponent, Bool) -> Void)? = nil) {
        self.component = component
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.selectedDevice = selectedDevice
        self.colorScheme = colorScheme
        self.selectedComponentIds = selectedComponentIds
        self.onSelectChild = onSelectChild
    }
    
    var body: some View {
        ComponentRenderer(component: component, deviceSize: selectedDevice.size, colorScheme: colorScheme, onTap: onSelect, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds)
            .overlay(
                // Selection and hover overlays
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue, lineWidth: 2)
                            .allowsHitTesting(false)
                    } else if isHovered && component.children.isEmpty {
                        // Only show hover for leaf components (components without children)
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            .allowsHitTesting(false)
                    }
                }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: component.frame)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: component.isVisible)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
    
    private func handlePosition(for index: Int) -> CGPoint {
        let frame = component.frame
        switch index {
        case 0: return CGPoint(x: frame.minX, y: frame.minY) // Top-left
        case 1: return CGPoint(x: frame.midX, y: frame.minY) // Top-center
        case 2: return CGPoint(x: frame.maxX, y: frame.minY) // Top-right
        case 3: return CGPoint(x: frame.maxX, y: frame.midY) // Right-center
        case 4: return CGPoint(x: frame.maxX, y: frame.maxY) // Bottom-right
        case 5: return CGPoint(x: frame.midX, y: frame.maxY) // Bottom-center
        case 6: return CGPoint(x: frame.minX, y: frame.maxY) // Bottom-left
        case 7: return CGPoint(x: frame.minX, y: frame.midY) // Left-center
        default: return CGPoint.zero
        }
    }
}


// MARK: - Resizable Panel Component
struct ResizablePanel<Content: View>: View {
    @Binding var width: CGFloat
    let minWidth: CGFloat
    let maxWidth: CGFloat
    @Binding var isVisible: Bool
    let content: Content
    let handlePosition: HandlePosition
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isDragging = false
    @State private var isHoveringHandle = false
    
    enum HandlePosition {
        case left, right
    }
    
    init(
        width: Binding<CGFloat>,
        minWidth: CGFloat,
        maxWidth: CGFloat,
        isVisible: Binding<Bool>,
        handlePosition: HandlePosition = .right,
        @ViewBuilder content: () -> Content
    ) {
        self._width = width
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self._isVisible = isVisible
        self.handlePosition = handlePosition
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Handle on left for Properties panel
            if handlePosition == .left {
                resizeHandle
            }
            
            // Panel content
            content
                .frame(width: width)
                .padding(.vertical, 8)
                .padding(.horizontal, 4)
            
            // Handle on right for Layers panel
            if handlePosition == .right {
                resizeHandle
            }
        }
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(panelBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var panelBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 17/255, green: 17/255, blue: 17/255) // #111111
        } else {
            return Color.white
        }
    }
    
    private var handleColor: Color {
        if isHoveringHandle || isDragging {
            // Show subtle indicator when hovering or dragging
            if colorScheme == .dark {
                return Color(red: 0.2, green: 0.2, blue: 0.2) // Slightly lighter on hover
            } else {
                return Color(red: 0.9, green: 0.9, blue: 0.9) // Slightly darker on hover
            }
        }
        // Blend in with panel when not hovering
        return panelBackgroundColor
    }
    
    private var resizeHandle: some View {
        Rectangle()
            .fill(handleColor)
            .frame(width: 4)
            .frame(maxHeight: .infinity)
            .onHover { hovering in
                isHoveringHandle = hovering
#if os(macOS)
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
#endif
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        let translation = handlePosition == .left ? -value.translation.width : value.translation.width
                        let newWidth = width + translation
                        // Clamp between minWidth and maxWidth
                        let clampedWidth = max(minWidth, min(maxWidth, newWidth))
                        width = clampedWidth
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }
}
