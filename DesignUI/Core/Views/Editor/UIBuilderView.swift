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
    static let designWillChange = Notification.Name("design.willChange") // Posted BEFORE a change for undo state capture
    static let designChanged = Notification.Name("design.changed")
    static let statusBarVisibilityChanged = Notification.Name("statusBar.visibilityChanged")
    static let selectComponent = Notification.Name("selectComponent")
    static let minimizeSheet = Notification.Name("minimizeSheet") // Minimize iOS sheet to height 80
    static let dismissChildNavigation = Notification.Name("dismissChildNavigation") // Dismiss child views (add components, modifiers)
}

// MARK: - Undoable Slider
/// A slider that properly handles undo state by only saving when editing starts,
/// not on every intermediate value during dragging.
struct UndoableSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step: Double? = nil
    
    /// Called during continuous dragging - use for live preview updates
    var onValueChanged: ((Double) -> Void)?
    
    /// Called when editing ends (finger lifted) - use for final save with undo state
    var onEditingEnded: ((Double) -> Void)?
    
    @State private var isEditing = false
    @State private var hasStartedEditing = false
    
    var body: some View {
        Group {
            if let step = step {
                Slider(value: $value, in: range, step: step, onEditingChanged: handleEditingChanged)
            } else {
                Slider(value: $value, in: range, onEditingChanged: handleEditingChanged)
            }
        }
        .onChange(of: value) { _, newValue in
            if isEditing {
                // During continuous editing, call the continuous handler
                onValueChanged?(newValue)
            }
        }
    }
    
    private func handleEditingChanged(_ editing: Bool) {
        isEditing = editing
        
        if editing {
            // Editing started - save undo state NOW (before any changes)
            if !hasStartedEditing {
                hasStartedEditing = true
                // Post undo save notification once at start
                NotificationCenter.default.post(name: .designWillChange, object: nil)
            }
        } else {
            // Editing ended - call the final handler
            hasStartedEditing = false
            onEditingEnded?(value)
        }
    }
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
    
    // iPad Series
    case ipadPro11 = "iPad Pro 11" 
    case ipadPro12 = "iPad Pro 12.9"
    
    // iOS Widgets
    case widgetSmall = "Widget Small"
    case widgetMedium = "Widget Medium"
    case widgetLarge = "Widget Large"
    case widgetExtraLarge = "Widget Extra Large"
    
    var id: String { rawValue }
    
    /// Category for grouping in UI
    enum Category: String {
        case iphone = "iPhone"
        case ipad = "iPad"
        case widget = "Widgets"
    }
    
    var category: Category {
        switch self {
        case .iphone17ProMax, .iphone16, .iphone16Plus, .iphone16Pro, .iphone16ProMax,
             .iphone15Pro, .iphone15ProMax, .iphone15, .iphone15Plus,
             .iphone14, .iphone14Pro, .iphone14ProMax,
             .iphone13Mini, .iphone13, .iphone13Pro, .iphone13ProMax:
            return .iphone
        case .ipadPro11, .ipadPro12:
            return .ipad
        case .widgetSmall, .widgetMedium, .widgetLarge, .widgetExtraLarge:
            return .widget
        }
    }
    
    /// Grouped presets for menu display
    static var iphones: [DevicePreset] {
        allCases.filter { $0.category == .iphone }
    }
    
    static var ipads: [DevicePreset] {
        allCases.filter { $0.category == .ipad }
    }
    
    static var widgets: [DevicePreset] {
        allCases.filter { $0.category == .widget }
    }
    
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
        
        // iPad Series - Landscape orientation
        case .ipadPro11: return CGSize(width: 1194, height: 834) // 11" display
        case .ipadPro12: return CGSize(width: 1366, height: 1024) // 12.9" display
        
        // iOS Widgets - Based on iPhone 14/15 Pro sizes (393pt width)
        case .widgetSmall: return CGSize(width: 170, height: 170)
        case .widgetMedium: return CGSize(width: 364, height: 170)
        case .widgetLarge: return CGSize(width: 364, height: 382)
        case .widgetExtraLarge: return CGSize(width: 795, height: 382) // iPad only
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
    
    // iOS half sheet states (iPhone only, iPad uses floating panels)
    @State private var showLayersSheet = false
    @State private var showPropertiesInPanel = false // For NavigationStack inside panel
    @State private var layersSheetHeight: CGFloat = 0.5 // Half open by default
    @State private var propertiesSheetHeight: CGFloat = 0.5 // Half open by default

    
    // Screenshot capture debouncing
    // Screenshot capture debouncing
    @State private var lastScreenshotRequestTime: Date = Date()
    private let screenshotDebounceInterval: TimeInterval = 0.5
    
    #if os(iOS)
    @State private var selection: PresentationDetent = .height(80)
    @State private var activeTab: AppTab = .layers
    @State private var sheetNavigationPath = NavigationPath()
    #endif
    

    var body: some View {
        NavigationStack {
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .phone {
                // iPhone: Full screen canvas with bottom sheet
                iOSCanvasContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { iOSToolbarContent }
            } else {
                // iPad: macOS-style floating panels
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
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { iPadToolbarContent }
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
            CodePreviewView(canvasManager: canvasManager)
        }
        // Undo/Redo Toast Overlay
        .overlay(alignment: .top) {
            if let message = canvasManager.undoMessage {
                UndoToastView(message: message)
                    .padding(.top, 60)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canvasManager.undoMessage)
            }
        }

#if os(iOS)
        // Only show sheet on iPhone (iPad uses floating panels)
        .sheet(isPresented: $showLayersSheet) {
            if UIDevice.current.userInterfaceIdiom == .phone {
                editorPanelSheet
                    .presentationDetents([.height(80), .medium], selection: $selection)
                    .presentationBackgroundInteraction(.enabled)
                    .interactiveDismissDisabled()
                    .presentationContentInteraction(.scrolls)
            }
        }
        
#endif
        .onAppear {
            setupCanvas()
            // Restore saved device preset and color scheme
            restoreCanvasSettings()
            // Capture initial screenshot
            captureScreenshot()
            
            #if os(iOS)
            // Show sheet on iPhone only
            if UIDevice.current.userInterfaceIdiom == .phone {
                showLayersSheet = true
            }
            #endif
        }
        .onChange(of: canvasManager.components) { _, _ in
            syncComponents()
        }
        .onChange(of: canvasManager.selectedComponent) { _, newSelection in
            syncSelection()
            #if os(iOS)
            // Only auto-show sheet on iPhone
            if UIDevice.current.userInterfaceIdiom == .phone && newSelection != nil {
                showLayersSheet = true
            }
            #endif
        }
        .onChange(of: selectedDevice) { _, newDevice in
            saveCanvasSettings()
            
            // Auto-hide status bar for widgets, show for others
            if newDevice.category == .widget {
                designFile.statusBarVisible = false
                canvasManager.statusBarComponent?.isVisible = false
                NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: false)
            } else {
                designFile.statusBarVisible = true
                canvasManager.statusBarComponent?.isVisible = true
                NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: true)
            }
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
        .onReceive(NotificationCenter.default.publisher(for: .statusBarVisibilityChanged)) { notification in
            if let isVisible = notification.object as? Bool {
                designFile.statusBarVisible = isVisible
                designManager.markAsChanged()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .minimizeSheet)) { _ in
            #if os(iOS)
            // Minimize sheet to height 80 when canvas background is tapped
            selection = .height(80)
            #endif
        }
    }
    
#if os(iOS)
    private var iOSCanvasContent: some View {
        ZStack {
            mainCanvasArea
                .ignoresSafeArea()
        }
    }
    
    @ToolbarContentBuilder
    private var iOSToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: {
                designManager.closeCurrentDesign()
            }) {
                Image(systemName: "chevron.left")
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            // Color scheme toggle - iPad only
            if UIDevice.current.userInterfaceIdiom == .pad {
                Button(action: {
                    colorScheme = colorScheme == .light ? .dark : .light
                }) {
                    Image(systemName: colorScheme == .light ? "sun.max.fill" : "moon.fill")
                }
            }
            
            // Recenter button
            Button(action: {
                canvasManager.canvasOffset = .zero
                canvasManager.zoomLevel = 1.0
                canvasManager.centerCanvasTrigger.toggle()
            }) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction){
            // Grouped Undo/Redo
            Button(action: { canvasManager.undo() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!canvasManager.canUndo)
            
            Button(action: { canvasManager.redo() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!canvasManager.canRedo)
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                if UIDevice.current.userInterfaceIdiom != .phone {
                    Button(action: { showCodePreview = true }) {
                        Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Divider()
                }
                
                Button(action: { saveAsScreenshot() }) {
                    Label("Save as Screenshot", systemImage: "photo")
                }
            } label: {
                 Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
            }
            .help("Export")
        }
    }
    
    @ToolbarContentBuilder
    private var iPadToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: {
                designManager.closeCurrentDesign()
            }) {
                Image(systemName: "chevron.left")
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            // Device Picker
            Menu {
                // iPhones section
                Section("iPhone") {
                    ForEach(DevicePreset.iphones) { preset in
                        Button(preset.rawValue) {
                            selectedDevice = preset
                        }
                    }
                }
                
                Divider()
                
                // iPads section
                Section("iPad") {
                    ForEach(DevicePreset.ipads) { preset in
                        Button(preset.rawValue) {
                            selectedDevice = preset
                        }
                    }
                }
                                
                // Widgets section
                Section("Widgets") {
                    ForEach(DevicePreset.widgets) { preset in
                        Button(preset.rawValue) {
                            selectedDevice = preset
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: deviceIcon)
                        .font(.system(size: 11))
                    Text(selectedDevice.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: 100) // Limit width
                        .lineLimit(1)
                }
            }
            .help("Choose Device")
                        
            // Color scheme toggle
            Button(action: {
                colorScheme = colorScheme == .light ? .dark : .light
            }) {
                Image(systemName: colorScheme == .light ? "sun.max.fill" : "moon.fill")
            }
            
            // Recenter button
            Button(action: {
                canvasManager.canvasOffset = .zero
                canvasManager.zoomLevel = 1.0
                canvasManager.centerCanvasTrigger.toggle()
            }) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
            }
            
            // Undo/Redo
            Button(action: { canvasManager.undo() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!canvasManager.canUndo)
            
            Button(action: { canvasManager.redo() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!canvasManager.canRedo)
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Menu {
                Button(action: { showCodePreview = true }) {
                    Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                Divider()
                
                Button(action: { saveAsScreenshot() }) {
                    Label("Save as Screenshot", systemImage: "photo")
                }
                

            } label: {
                 Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
            }
            .help("Export")
        }
    }
#endif

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
        .ignoresSafeArea()
        .animation(.spring(), value: canvasManager.selectedComponentIds.count)
        .onReceive(NotificationCenter.default.publisher(for: .imageDownloadsCompleted)) { notification in
            // When images are downloaded, refresh the thumbnail
            if let design = notification.object as? DesignFile,
               design === designFile { // Check it's the current design
                print("🖼️ Images downloaded, refreshing thumbnail for \(design.name)")
                // Capture screenshot to update thumbnail with actual images
                captureScreenshot()
                // Save to persist the thumbnail (wait shortly for capture)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    designManager.saveCurrentDesign()
                }
            }
        }
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
    private var editorPanelSheet: some View {
        VStack(spacing: 0) {
            NavigationStack(path: $sheetNavigationPath) {
                Group {
                    // Show different content based on active tab
                    switch activeTab {
                    case .layers:
                        LayersPanelView(
                            canvasManager: canvasManager,
                            selectedComponent: $canvasManager.selectedComponent
                        )
                        .background(Color(uiColor: .systemBackground))
                    case .properties:
                        propertiesPanelContent
                            .navigationTitle("Properties")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(action: {
                                        activeTab = .layers
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "chevron.left")
                                            Text("Layers")
                                        }
                                    }
                                }
                            }
                            .background(Color(uiColor: .systemBackground))
                    case .canvas:
                        List {
                            // Color Scheme Section
                            Section("Appearance") {
                                HStack(spacing: 12) {
                                    Button {
                                        colorScheme = .light
                                    } label: {
                                        HStack {
                                            Image(systemName: "sun.max.fill")
                                                .font(.system(size: 16))
                                            Text("Light")
                                            Spacer()
                                            if colorScheme == .light {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Divider()
                                    
                                    Button {
                                        colorScheme = .dark
                                    } label: {
                                        HStack {
                                            Image(systemName: "moon.fill")
                                                .font(.system(size: 16))
                                            Text("Dark")
                                            Spacer()
                                            if colorScheme == .dark {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.vertical, 4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            // Device Presets
                            devicePresetsListSections
                        }
                        .listStyle(.insetGrouped)
                        .navigationTitle("Canvas")
                        .navigationBarTitleDisplayMode(.inline)
                        .scrollContentBackground(.hidden)
                        .background(Color(uiColor: .systemBackground))
                    case .code:
                        codeTabContent
                            .navigationTitle("Code")
                            .navigationBarTitleDisplayMode(.inline)
                            .background(Color(uiColor: .systemBackground))
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            customTabBar()
                .background(Color(uiColor: .systemBackground))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    enum AppTab: String, CaseIterable{
        case layers = "Layers"
        case properties = "Properties"
        case canvas = "Canvas"
        case code = "Code"
        
        var symbolImage: String{
            switch self {
            case .layers:
                return "square.3.layers.3d.top.filled"
            case .properties:
                return "slider.horizontal.3"
            case .canvas:
                return "iphone"
            case .code:
                return "chevron.left.forwardslash.chevron.right"
            }
        }
    }
    
    @ViewBuilder
    func customTabBar() -> some View {
        HStack {
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                VStack(spacing: 6){
                    Image(systemName: tab.symbolImage)
                        .font(.title3)
                        .symbolVariant(.fill)
                    
                    Text(tab.rawValue)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(activeTab == tab ? .blue : .gray)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
                .onTapGesture {
                    // Reset navigation path and dismiss child views when switching tabs
                    if activeTab != tab {
                        sheetNavigationPath = NavigationPath()
                        // Post notification to dismiss any child views (Component Library, Modifier Editors, etc.)
                        NotificationCenter.default.post(name: .dismissChildNavigation, object: nil)
                    }
                    activeTab = tab
                    // Auto-expand sheet when tab is tapped
                    selection = .medium
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 10)
    }
    
    private var devicePresetsList: some View {
        List {
            Section("iPhone") {
                ForEach(DevicePreset.iphones) { preset in
                    Button(action: {
                        selectedDevice = preset
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedDevice == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Section("iPad") {
                ForEach(DevicePreset.ipads) { preset in
                    Button(action: {
                        selectedDevice = preset
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedDevice == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Section("Widgets") {
                ForEach(DevicePreset.widgets) { preset in
                    Button(action: {
                        selectedDevice = preset
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedDevice == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ViewBuilder
    private var devicePresetsListSections: some View {
        Section("iPhone") {
            ForEach(DevicePreset.iphones) { preset in
                Button(action: {
                    selectedDevice = preset
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedDevice == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        
        Section("iPad") {
            ForEach(DevicePreset.ipads) { preset in
                Button(action: {
                    selectedDevice = preset
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedDevice == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        
        Section("Widgets") {
            ForEach(DevicePreset.widgets) { preset in
                Button(action: {
                    selectedDevice = preset
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedDevice == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }

    private var propertiesPanelContent: some View {
        Group {
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
    }
    
    private var codeTabContent: some View {
        CodeTabView(canvasManager: canvasManager)
    }
#endif
    
    private var toolbarButtons: some ToolbarContent {
        Group{
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                Button(action: {
                    designManager.closeCurrentDesign()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                .help("Back to Designs")
            }
            #endif
            
            ToolbarItemGroup(placement: .primaryAction) {
                // Device Picker
                Menu {
                    // iPhones section
                    Section("iPhone") {
                        ForEach(DevicePreset.iphones) { preset in
                            Button(preset.rawValue) {
                                selectedDevice = preset
                            }
                        }
                    }
                    
                    Divider()
                    
                    // iPads section
                    Section("iPad") {
                        ForEach(DevicePreset.ipads) { preset in
                            Button(preset.rawValue) {
                                selectedDevice = preset
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Widgets section
                    Section("Widgets") {
                        ForEach(DevicePreset.widgets) { preset in
                            Button(preset.rawValue) {
                                selectedDevice = preset
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: deviceIcon)
                            .font(.system(size: 11))
                        Text(selectedDevice.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: 100) // Limit width
                            .lineLimit(1)
                    }
                }
                .help("Choose Device")
                
                // Color Scheme Picker
                Menu {
                    Button("Light") {
                        colorScheme = .light
                    }
                    Button("Dark") {
                        colorScheme = .dark
                    }
                } label: {
                    Image(systemName: colorScheme == .light ? "sun.max" : "moon")
                        .font(.system(size: 12))
                }
                .help("Color Scheme")
                
                // Center canvas button
                Button(action: {
                    // Reset zoom and trigger canvas centering with animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: CGSize(width: 800, height: 600))
                    }
                    // Update base zoom level after animation starts (no visual impact, just for state)
                    baseZoomLevel = canvasManager.zoomLevel
                    canvasManager.centerCanvasTrigger.toggle()
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 14, weight: .medium))
                }
                .keyboardShortcut("1", modifiers: .command)
                .help("Center Canvas")
                
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
            
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    #if os(iOS)
                    if UIDevice.current.userInterfaceIdiom != .phone {
                        Button(action: { showCodePreview = true }) {
                            Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                        
                        Divider()
                    }
                    #else
                    Button(action: { showCodePreview = true }) {
                        Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    Divider()
                    #endif
                    
                    Button(action: { saveAsScreenshot() }) {
                        Label("Save as Screenshot", systemImage: "photo")
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
    
    private func saveAsScreenshot() {
        let screenshotView = CanvasScreenshotView(
            components: canvasManager.components,
            deviceSize: selectedDevice.size,
            colorScheme: colorScheme ?? .light,
            statusBarComponent: canvasManager.statusBarComponent,
            statusBarHasBackground: statusBarHasBackground
        )
        
        guard let imageData = ScreenshotUtility.shared.captureThumbnail(
            of: screenshotView,
            size: selectedDevice.size,
            colorScheme: colorScheme ?? .light
        ) else {
            print("❌ Failed to capture screenshot for saving")
            return
        }
        
        #if os(macOS)
        // macOS: Show save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "\(designFile.name).png"
        savePanel.title = "Save Screenshot"
        savePanel.message = "Choose where to save the screenshot"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try imageData.write(to: url)
                    // Open in Finder
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } catch {
                    print("❌ Failed to save screenshot: \(error)")
                }
            }
        }
        #else
        // iOS: Save to Photos
        if let uiImage = UIImage(data: imageData) {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        }
        #endif
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
        
        // Restore status bar visibility
        canvasManager.statusBarComponent?.isVisible = designFile.statusBarVisible
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
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designManager.markAsChanged()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    
    private func syncSelection() {
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designManager.markAsChanged()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    
    private func syncDesignChanges() {
            
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designFile.objectWillChange.send() // Force design file to recognize changes
            designManager.markAsChanged()
    }
    
    // MARK: - Screenshot Capture
    private func captureScreenshot() {
        // Update request time to now
        lastScreenshotRequestTime = Date()
        
        // Schedule capture check
        DispatchQueue.main.asyncAfter(deadline: .now() + screenshotDebounceInterval) {
            // Check if this request is still the latest one (or close enough)
            // If a newer request came in significantly later, we skip this one

            
            // If the time since the last request is less than the interval (meaning a new request 
            // happened recently and reset the timer), we assume the new request's scheduled block 
            // will handle it. 
            // Wait... actually, we want to run ONLY if we are the last one.
            // But checking timeSinceLastRequest is tricky because it grows.
            
            // Better logic: The async block runs after N seconds.
            // When it runs, we verify if (Now - LastRequestTime) >= N.
            // If I request at t=0, LastReq=0. Block runs at t=0.5.
            // If I request at t=0.2, LastReq=0.2. 
            // At t=0.5 (first block), Now=0.5. diff = 0.3. 0.3 < 0.5. Skip.
            // At t=0.7 (second block), Now=0.7. diff = 0.5. Run.
            
            guard Date().timeIntervalSince(self.lastScreenshotRequestTime) >= self.screenshotDebounceInterval - 0.1 else {
                return
            }
            
            self.performScreenshotCapture()
        }
    }
    
    private func performScreenshotCapture() {
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
            print("📸 Screenshot captured and set on design file")
        } else {
            print("📸 Failed to capture screenshot")
        }
    }
    
    /// Returns appropriate icon based on selected device category
    private var deviceIcon: String {
        switch selectedDevice.category {
        case .iphone:
            return "iphone"
        case .ipad:
            return "ipad"
        case .widget:
            return "rectangle.grid.1x2"
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
    let canvasManager: CanvasManager
    @State private var isHovered: Bool = false
    
    init(component: UIComponent, isSelected: Bool, onSelect: @escaping (Bool) -> Void, selectedDevice: DevicePreset, colorScheme: ColorScheme?, selectedComponentIds: Set<UUID>, onSelectChild: ((UIComponent, Bool) -> Void)? = nil, canvasManager: CanvasManager) {
        self.component = component
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.selectedDevice = selectedDevice
        self.colorScheme = colorScheme
        self.selectedComponentIds = selectedComponentIds
        self.onSelectChild = onSelectChild
        self.canvasManager = canvasManager
    }
    
    var body: some View {
        ComponentRenderer(component: component, deviceSize: selectedDevice.size, colorScheme: colorScheme, onTap: onSelect, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)
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
            return Color(red: 28/255, green: 28/255, blue: 30/255) // #1C1C1E
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

#if os(iOS)
struct CodeTabView: View {
    @ObservedObject var canvasManager: CanvasManager
    @State private var highlightedText: AttributedString = AttributedString()
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                Text(highlightedText)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    UIPasteboard.general.string = canvasManager.exportCode()
                } label: {
                    Image(systemName: "doc.on.doc")
                }
            }
        }
        .onAppear {
            highlightCode()
        }
        .onChange(of: canvasManager.components) { _, _ in
            highlightCode()
        }
        .onChange(of: colorScheme) { _, _ in
            highlightCode()
        }
    }
    
    private func highlightCode() {
        let code = canvasManager.exportCode()
        Task {
            let result = await SyntaxHighlighter.shared.highlight(code, colorScheme: colorScheme)
            await MainActor.run {
                highlightedText = result
            }
        }
    }
}
#endif
