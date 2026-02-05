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
    
    // iPad Series
    case ipadPro11 = "iPad Pro 11" 
    case ipadPro12 = "iPad Pro 12.9"
    
    // iOS Widgets
    case widgetSmall = "Widget Small"
    case widgetMedium = "Widget Medium"
    case widgetLarge = "Widget Large"
    case widgetExtraLarge = "Widget Extra Large"
    
    // Custom (No frame)
    case noSize = "No Size"
    
    var id: String { rawValue }
    
    /// Category for grouping in UI
    enum Category: String {
        case iphone = "iPhone"
        case ipad = "iPad"
        case widget = "Widgets"
        case custom = "Custom"
    }
    
    var category: Category {
        switch self {
        case .iphone17ProMax, .iphone16, .iphone16Plus, .iphone16Pro, .iphone16ProMax,
             .iphone15Pro, .iphone15ProMax, .iphone15, .iphone15Plus,
             .iphone14, .iphone14Pro, .iphone14ProMax:
            return .iphone
        case .ipadPro11, .ipadPro12:
            return .ipad
        case .widgetSmall, .widgetMedium, .widgetLarge, .widgetExtraLarge:
            return .widget
        case .noSize:
            return .custom
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
    
    static var custom: [DevicePreset] {
        allCases.filter { $0.category == .custom }
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
        
        // iPad Series - Landscape orientation
        case .ipadPro11: return CGSize(width: 1194, height: 834) // 11" display
        case .ipadPro12: return CGSize(width: 1366, height: 1024) // 12.9" display
        
        // iOS Widgets - Based on iPhone 14/15 Pro sizes (393pt width)
        case .widgetSmall: return CGSize(width: 170, height: 170)
        case .widgetMedium: return CGSize(width: 364, height: 170)
        case .widgetLarge: return CGSize(width: 364, height: 382)
        case .widgetExtraLarge: return CGSize(width: 795, height: 382) // iPad only
        
        // Custom - content-adaptive (zero signals dynamic sizing)
        case .noSize: return .zero
        }
    }
    
    /// Whether this preset uses content-adaptive sizing (no fixed frame)
    var isContentAdaptive: Bool {
        self == .noSize
    }
}

struct UIBuilderView: View {
    @ObservedObject var designFile: DesignFile
    @EnvironmentObject private var designManager: DesignManager
    @StateObject private var canvasManager = CanvasManager()

    enum SidebarTab {
        case layers
        case pages
    }
    
    @State private var selectedSidebarTab: SidebarTab = .layers

    @State private var showCodePreview = false
    @State private var baseZoomLevel: CGFloat = 1.0
    @State private var statusBarHasBackground: Bool = false
    
    // Panel states
    @State private var layersPanelWidth: CGFloat = 300
    @State private var propertiesPanelWidth: CGFloat = 300
    @State private var showLayersPanel = true
    @State private var showPropertiesPanel = true
    
    @State private var currentPageIndex: Int = 0
    @State private var isSwitchingPage: Bool = false

    // iOS half sheet states (iPhone only, iPad uses floating panels)
    @State private var showLayersSheet = false
    @State private var showPropertiesInPanel = false // For NavigationStack inside panel
    @State private var layersSheetHeight: CGFloat = 0.5 // Half open by default
    @State private var propertiesSheetHeight: CGFloat = 0.5 // Half open by default
    
    @State private var showComponentLibrary = false
    @State private var showCommunitySubmission = false
    
    // Screenshot capture debouncing
    @State private var lastScreenshotRequestTime: Date = Date()
    private let screenshotDebounceInterval: TimeInterval = 2.0
    
    // Debounced design sync to avoid redundant saves/snapshots
    @State private var designSyncWorkItem: DispatchWorkItem?
    
    @Environment(\.dismiss) private var dismiss
    
    #if os(iOS)
    @State private var selection: PresentationDetent = .medium // Locked to medium
    @State private var activeTab: AppTab? = nil // Optional to allow closing
    
    enum AppTab: String, CaseIterable, Identifiable {
        case layers = "Layers"
        case properties = "Properties"
        case canvas = "Canvas"
        case code = "Code"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .layers: return "square.3.layers.3d.top.filled"
            case .properties: return "slider.horizontal.3"
            case .canvas: return "iphone"
            case .code: return "chevron.left.forwardslash.chevron.right"
            }
        }
    }
    #endif

    var body: some View {

        NavigationStack {
            ZStack(alignment: .top) {
                Color.clear
                .onAppear {
                    // Ensure status bar properties are valid (migration/hotfix)
                    canvasManager.validateStatusBarProperties()
                }

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
                            .animation(.easeInOut(duration: 0.3), value: canvasManager.selectedComponent)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { iPadToolbarContent }
            }
#else
            // macOS: Normal canvas layout with overlaid panels
            ZStack(alignment: .top) {
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
                            sidebarPanel
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding()
                    }
                    
                    // Center Canvas Area with AI Bar
                    ZStack(alignment: .bottom) {
                        // Spacer to fill the remaining width between panels (acting like the original Spacer)
                        Color.clear
                        
                        // AI Command Bar constrained to the center area

                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
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
                        .animation(.easeInOut(duration: 0.3), value: canvasManager.selectedComponent)
                    }
                }
            }


#endif
            }
        }
        .navigationTitle("Studio")
        .toolbar { toolbarButtons }
        #if os(macOS)
        .sheet(isPresented: $showCodePreview) {
            CodePreviewView(canvasManager: canvasManager)
        }
        #endif
        .sheet(isPresented: $showCommunitySubmission) {
            SubmitToCommunityView(designFile: designFile)
        }
        // Undo/Redo Toast Overlay
        .overlay(alignment: .top) {
            if let message = canvasManager.undoMessage {
                UndoToastView(message: message)
                    .padding(.top, 60)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canvasManager.undoMessage)
            }
        }

        .onAppear {
            setupCanvas()
            
            // Restore saved device preset and color scheme
            restoreCanvasSettings()
            
            // Capture initial screenshot IMMEDIATELY (no debounce) on open
            performScreenshotCapture()
        }
        .onChange(of: selectedSidebarTab) { tab, _ in
            if tab == .pages {
                // Force immediate capture when opening pages tab to ensure thumbnail is fresh
                performScreenshotCapture()
            }
        }
        .onChange(of: canvasManager.components) { _, _ in
            // Skip sync if we are just switching pages (loading data)
            if !isSwitchingPage {
                syncComponents()
            }
        }
        .onChange(of: canvasManager.selectedComponent) { _, newSelection in
            if !isSwitchingPage {
                syncSelection()
                #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone && newSelection != nil {
                     activeTab = .properties
                }
                #endif
            }
        }
        .onChange(of: canvasManager.devicePreset) { _, newDevice in
            if !isSwitchingPage {
                saveCanvasSettings()
                
                // Auto-hide status bar for widgets and custom (noSize), show for others
                if newDevice.category == .widget || newDevice.category == .custom {
                    designFile.statusBarVisible = false
                    canvasManager.statusBarComponent?.isVisible = false
                    NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: false)
                    
                    // Also disable Top Safe Area for widgets and custom
                    if let statusBar = canvasManager.statusBarComponent {
                        canvasManager.updateComponentProperty(for: statusBar, key: "topSafeArea", value: false)
                    }
                } else {
                    designFile.statusBarVisible = true
                    canvasManager.statusBarComponent?.isVisible = true
                    NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: true)
                    
                    // Enable Top Safe Area for non-widgets
                    if let statusBar = canvasManager.statusBarComponent {
                        canvasManager.updateComponentProperty(for: statusBar, key: "topSafeArea", value: true)
                    }
                }
            }
        }
        .onChange(of: canvasManager.colorScheme) { _, _ in
            if !isSwitchingPage {
                saveCanvasSettings()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
            canvasManager.undo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
            canvasManager.redo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .designChanged)) { _ in
            if !isSwitchingPage {
                saveCanvasSettings()
                scheduleDesignSync(captureScreenshot: false)
            }
        }
        .onChange(of: canvasManager.undoStackVersion) { _, _ in
            // Trigger sync when undo stack changes (action performed, undo, or redo)
            // This catches changes like Canvas Settings that aren't in the components array
            scheduleDesignSync(captureScreenshot: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .statusBarVisibilityChanged)) { notification in
            if let isVisible = notification.object as? Bool {
                designFile.statusBarVisible = isVisible
                designFile.markAsChanged()
            }
        }

    }
    
#if os(iOS)
    private var iOSCanvasContent: some View {
        ZStack {
            mainCanvasArea
            
            // Floating Tab Bar
            VStack {
                Spacer()
                floatingTabBar
            }
        }
        .sheet(isPresented: Binding(
            get: { activeTab != nil },
            set: { if !$0 { activeTab = nil } }
        )) {
            if let tab = activeTab {
                sheetContent(for: tab)
                    .presentationDetents(tab == .code ? [.medium, .large] : [.medium], selection: $selection)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationBackground(.regularMaterial)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var iOSToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: {
                designFile.save()
                designManager.closeCurrentDesign()
            }) {
                Image(systemName: "chevron.left")
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            // Color scheme toggle - iPad only
            if UIDevice.current.userInterfaceIdiom == .pad {
                Button(action: {
                    canvasManager.setColorScheme(canvasManager.colorScheme == .light ? .dark : .light)
                }) {
                    Image(systemName: canvasManager.colorScheme == .light ? "sun.max.fill" : "moon.fill")
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

                
                Button(action: { 
                    #if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        activeTab = .code
                    } else {
                        showCodePreview = true
                    }
                    #else
                    showCodePreview = true 
                    #endif
                }) {
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
    
    @ToolbarContentBuilder
    private var iPadToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: {
                designFile.save()
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
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Divider()
                
                // iPads section
                Section("iPad") {
                    ForEach(DevicePreset.ipads) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                                
                // Widgets section
                Section("Widgets") {
                    ForEach(DevicePreset.widgets) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                // Custom section
                Section("Custom") {
                    ForEach(DevicePreset.custom) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: deviceIcon)
                        .font(.system(size: 11))
                    Text(canvasManager.devicePreset.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: 100) // Limit width
                        .lineLimit(1)
                }
            }
            .help("Choose Device")
                        
            // Color scheme menu
            Menu {
                Button {
                    canvasManager.setColorScheme(.light)
                } label: {
                    HStack {
                        Text("Light Mode")
                        if canvasManager.colorScheme == .light {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    canvasManager.setColorScheme(.dark)
                } label: {
                    HStack {
                        Text("Dark Mode")
                        if canvasManager.colorScheme == .dark {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                Image(systemName: canvasManager.colorScheme == .light ? "sun.max.fill" : "moon.fill")
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

    
    private var sidebarPanel: some View {
        VStack(spacing: 16) {
            // 1. Top Panel: Layers / Pages
            VStack(spacing: 0) {
                // Unified Header with Dropdown
                HStack {
                    Menu {
                        Button(action: { selectedSidebarTab = .layers }) {
                            Label("Layers", systemImage: "square.3.layers.3d")
                        }
                        Button(action: { selectedSidebarTab = .pages }) {
                            Label("Pages", systemImage: "doc.on.doc")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: selectedSidebarTab == .layers ? "square.3.layers.3d.top.filled" : "doc.on.doc.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            Text(selectedSidebarTab == .layers ? "Layers" : "Pages")
                                .font(.headline).fontWeight(.semibold)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        if selectedSidebarTab == .layers {
                            showComponentLibrary = true
                        } else {
                            let (_, newIndex) = designFile.addPage()
                            switchToPage(newIndex)
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .help(selectedSidebarTab == .layers ? "Add Component" : "Add Page")
                    .buttonStyle(.bordered)
                    .frame(width: 28, height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Content
                switch selectedSidebarTab {
                case .layers:
                    layersPanel
                case .pages:
                    SidebarPagesView(
                        designFile: designFile,
                        currentPageIndex: $currentPageIndex,
                        onPageChange: { index in
                            switchToPage(index)
                        }
                    )
                }
                
                Spacer(minLength: 0) // Ensure panel stretches if content is short
            }
            .editorPanelStyle()
        }
    }
    
    private var layersPanel: some View {
        LayersPanelView(
            canvasManager: canvasManager,
            selectedComponent: $canvasManager.selectedComponent,
            showComponentLibrary: $showComponentLibrary
        )
    }
    
    private var mainCanvasArea: some View {
        ZStack(alignment: .top) {
            canvasView
        }
        .animation(.spring(), value: canvasManager.selectedComponentIds.count)
        .onReceive(NotificationCenter.default.publisher(for: .imageDownloadsCompleted)) { notification in
            // When images are downloaded, refresh the thumbnail
            if let design = notification.object as? DesignFile,
               design === designFile { // Check it's the current design
                debugLog("🖼️ Images downloaded, refreshing thumbnail for \(design.name)")
                // Capture screenshot to update thumbnail with actual images
                captureScreenshot()
                // Save to persist the thumbnail (wait shortly for capture)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    designFile.save()
                }
            }
        }
    }
    
    private var canvasView: some View {
        CanvasView(
            canvasManager: canvasManager,
            selectedComponent: $canvasManager.selectedComponent,
            selectedDevice: canvasManager.devicePreset,
            baseZoomLevel: $baseZoomLevel,
            statusBarHasBackground: $statusBarHasBackground,
            colorScheme: $canvasManager.colorScheme
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(magnificationGesture)
#if os(macOS)
        .background(
        )
#endif
    }
    
    private var propertiesPanel: some View {
        PropertiesPanelView(
            selectedComponent: $canvasManager.selectedComponent,
            canvasManager: canvasManager
        )
        .editorPanelStyle()
    }
    
#if os(iOS)
    private var editorPanelSheet: some View {
        // Reduced to just the sheet modifier on the main canvas
        EmptyView()
    }
    
    @ViewBuilder
    private var floatingTabBar: some View {
        HStack(spacing: 8) {
            ForEach(AppTab.allCases) { tab in
                Button(action: {
                    if activeTab == tab {
                        activeTab = nil // Close if tapping active
                    } else {
                        activeTab = tab
                        selection = .medium // Reset detent
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 14))
                        
                        if activeTab == tab {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .fixedSize()
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, activeTab == tab ? 16 : 12)
                    .background(
                        Capsule()
                            .fill(activeTab == tab ? Color.blue : Color.clear)
                    )
                    .foregroundColor(activeTab == tab ? .white : .primary)
                    .background(
                        // Hover effect background for non-active
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                            .opacity(activeTab == tab ? 0 : 1)
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: activeTab)
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0)
        )
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private func sheetContent(for tab: AppTab) -> some View {
        switch tab {
        case .layers:
            NavigationStack {
                VStack(spacing: 0) {
                    // Header with Dropdown and Add Button
                    HStack {
                        Menu {
                            Button(action: { selectedSidebarTab = .layers }) {
                                Label("Layers", systemImage: "square.3.layers.3d")
                            }
                            Button(action: { selectedSidebarTab = .pages }) {
                                Label("Pages", systemImage: "doc.on.doc")
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedSidebarTab == .layers ? "square.3.layers.3d.top.filled" : "doc.on.doc.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                Text(selectedSidebarTab == .layers ? "Layers" : "Pages")
                                    .font(.headline).fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Button(action: {
                            if selectedSidebarTab == .layers {
                                showComponentLibrary = true
                            } else {
                                let (_, newIndex) = designFile.addPage()
                                switchToPage(newIndex)
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 36, height: 36)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Content Switching
                    if selectedSidebarTab == .layers {
                        LayersPanelView(
                            canvasManager: canvasManager,
                            selectedComponent: $canvasManager.selectedComponent,
                            showComponentLibrary: $showComponentLibrary
                        )
                    } else {
                        SidebarPagesView(
                            designFile: designFile,
                            currentPageIndex: $currentPageIndex,
                            onPageChange: { index in
                                switchToPage(index)
                            }
                        )
                    }
                }
                // Background removed to allow material to show
                // .background(Color(uiColor: .systemBackground))
                .toolbar(.hidden, for: .navigationBar)
            }
            
        case .properties:
            NavigationStack {
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button(action: {
                            canvasManager.deselectAll()
                            activeTab = .layers
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 16))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text("Properties")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            activeTab = nil // Close sheet
                        }) {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    // .background(Color(uiColor: .systemBackground))
                    
                    Divider()
                    
                    PropertiesPanelView(
                        selectedComponent: $canvasManager.selectedComponent,
                        canvasManager: canvasManager
                    )
                }
                .toolbar(.hidden, for: .navigationBar)
            }
            .id(canvasManager.selectedComponent?.id)
            .onChange(of: canvasManager.selectedComponent?.id) { oldValue, newValue in
                // On iPhone, when selection changes and we are in properties view, scroll to it
                if newValue != nil {
                    #if os(iOS)
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        // Small delay to ensure view is ready
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            canvasManager.scrollToSelectionTrigger.toggle()
                        }
                    }
                    #endif
                }
            }
            
        case .canvas:
            NavigationStack {
                List {
                    // Color Scheme Section
                    Section("Appearance") {
                        HStack(spacing: 12) {
                            Button {
                                canvasManager.colorScheme = .light
                            } label: {
                                HStack {
                                    Image(systemName: "sun.max.fill")
                                    Text("Light")
                                    Spacer()
                                    if canvasManager.colorScheme == .light {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            
                            Divider()
                            
                            Button {
                                canvasManager.colorScheme = .dark
                            } label: {
                                HStack {
                                    Image(systemName: "moon.fill")
                                    Text("Dark")
                                    Spacer()
                                    if canvasManager.colorScheme == .dark {
                                        Image(systemName: "checkmark").foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Device Presets
                    devicePresetsListSections
                }
                .navigationTitle("Canvas Settings")
                .navigationBarTitleDisplayMode(.inline)
                .scrollContentBackground(.hidden)
            }

        case .code:
            NavigationStack {
                CodePreviewView(canvasManager: canvasManager)
                    .navigationTitle("Code Preview")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var devicePresetsList: some View {
        List {
            Section("iPhone") {
                ForEach(DevicePreset.iphones) { preset in
                    Button(action: {
                        canvasManager.setDevicePreset(preset)
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if canvasManager.devicePreset == preset {
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
                        canvasManager.setDevicePreset(preset)
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if canvasManager.devicePreset == preset {
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
                        canvasManager.setDevicePreset(preset)
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if canvasManager.devicePreset == preset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            
            Section("Custom") {
                ForEach(DevicePreset.custom) { preset in
                    Button(action: {
                        canvasManager.setDevicePreset(preset)
                    }) {
                        HStack {
                            Text(preset.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if canvasManager.devicePreset == preset {
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
                    canvasManager.setDevicePreset(preset)
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if canvasManager.devicePreset == preset {
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
                    canvasManager.setDevicePreset(preset)
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if canvasManager.devicePreset == preset {
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
                    canvasManager.setDevicePreset(preset)
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if canvasManager.devicePreset == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        
        Section("Custom") {
            ForEach(DevicePreset.custom) { preset in
                Button(action: {
                    canvasManager.setDevicePreset(preset)
                }) {
                    HStack {
                        Text(preset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if canvasManager.devicePreset == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
    }


#endif
    
    private var toolbarButtons: some ToolbarContent {
        Group{
            ToolbarItemGroup(placement: .primaryAction) {
                // Device Picker
                Menu {
                    // iPhones section
                    Section("iPhone") {
                        ForEach(DevicePreset.iphones) { preset in
                            Button(preset.rawValue) {
                                canvasManager.setDevicePreset(preset)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // iPads section
                    Section("iPad") {
                        ForEach(DevicePreset.ipads) { preset in
                            Button(preset.rawValue) {
                                canvasManager.setDevicePreset(preset)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Widgets section
                    Section("Widgets") {
                        ForEach(DevicePreset.widgets) { preset in
                            Button(preset.rawValue) {
                                canvasManager.setDevicePreset(preset)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Custom section
                    Section("Custom") {
                        ForEach(DevicePreset.custom) { preset in
                            Button(preset.rawValue) {
                                canvasManager.setDevicePreset(preset)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: deviceIcon)
                            .font(.system(size: 11))
                        Text(canvasManager.devicePreset.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: 100) // Limit width
                            .lineLimit(1)
                    }
                }
                .help("Choose Device")
                
                // Color Scheme Picker
                Menu {
                    Button("Light") {
                        canvasManager.setColorScheme(.light)
                    }
                    Button("Dark") {
                        canvasManager.setColorScheme(.dark)
                    }
                } label: {
                    Image(systemName: canvasManager.colorScheme == .light ? "sun.max" : "moon")
                        .font(.system(size: 12))
                }
                .help("Color Scheme")
                
                // Center canvas button
                Button(action: {
                    // Reset zoom and trigger canvas centering with animation
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        canvasManager.zoomToFitDevice(canvasManager.devicePreset.size, canvasSize: CGSize(width: 800, height: 600))
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
                    Button(action: { 
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            activeTab = .code
                        } else {
                            showCodePreview = true
                        }
                    }) {
                        Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    
                    #else
                    Button(action: { showCodePreview = true }) {
                        Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    #endif
                    
                    Button(action: { saveAsScreenshot() }) {
                        Label("Save as Screenshot", systemImage: "photo")
                    }
                    
                    Divider()
                    
                    Button(action: { showCommunitySubmission = true }) {
                        Label("Submit to Community", systemImage: "globe")
                    }

                    Divider()

                    Button(action: {
                        let json = canvasManager.getDesignAsJSON()
                        #if os(iOS)
                        UIPasteboard.general.string = json
                        #elseif os(macOS)
                        let pasteboard = NSPasteboard.general
                        pasteboard.clearContents()
                        pasteboard.setString(json, forType: .string)
                        #endif
                    }) {
                        Label("Copy JSON", systemImage: "doc.on.clipboard")
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
            deviceSize: canvasManager.devicePreset.size,
            colorScheme: canvasManager.colorScheme ?? .light,
            statusBarComponent: canvasManager.statusBarComponent,
            statusBarHasBackground: statusBarHasBackground
        )
        
        guard let imageData = ScreenshotUtility.shared.captureThumbnail(
            of: screenshotView,
            size: canvasManager.devicePreset.size,
            colorScheme: canvasManager.colorScheme ?? .light
        ) else {
            debugLog("❌ Failed to capture screenshot for saving")
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
                    debugLog("❌ Failed to save screenshot: \(error)")
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
        // Initialize page index from design file
        currentPageIndex = designFile.currentPageIndex
        
        // Load components from current page
        canvasManager.components = designFile.components
        canvasManager.setDesignName(designFile.name)
        
        // Save the initial loaded state as the base state (but don't allow undo to this)
        // This ensures we can undo back to the loaded state, but undo is disabled until we make a change
        canvasManager.saveInitialState()
    }
    
    /// Switch to a different page
    private func switchToPage(_ pageIndex: Int) {
        // Guard against same page or invalid index
        guard pageIndex != currentPageIndex,
              pageIndex >= 0 && pageIndex < designFile.pages.count else {
            return
        }
        
        let newPage = designFile.pages[pageIndex]
        
        // Prevent redundant sync/save during switch
        isSwitchingPage = true
        defer {
            DispatchQueue.main.async { isSwitchingPage = false }
        }
        
        // Save current page's state before switching
        if currentPageIndex >= 0 && currentPageIndex < designFile.pages.count {
            let oldPage = designFile.pages[currentPageIndex]
            oldPage.components = canvasManager.components
            
            // Capture fresh screenshot for page thumbnail
            let screenshotView = CanvasScreenshotView(
                components: canvasManager.components,
                deviceSize: canvasManager.devicePreset.size,
                colorScheme: canvasManager.colorScheme ?? .light,
                statusBarComponent: canvasManager.statusBarComponent,
                statusBarHasBackground: statusBarHasBackground
            )
            if let thumbnailData = ScreenshotUtility.shared.captureThumbnail(
                of: screenshotView,
                size: canvasManager.devicePreset.size,
                colorScheme: canvasManager.colorScheme ?? .light
            ) {
                oldPage.thumbnail = thumbnailData
            }
            
            // Save canvas settings to old page
            oldPage.devicePreset = canvasManager.devicePreset.rawValue
            oldPage.colorScheme = canvasManager.colorScheme == .light ? "light" : (canvasManager.colorScheme == .dark ? "dark" : nil)
            oldPage.statusBarVisible = designFile.statusBarVisible
            oldPage.statusBarComponent = canvasManager.statusBarComponent?.clone()
        }
        
        // Update both the designFile and local state
        designFile.currentPageIndex = pageIndex
        currentPageIndex = pageIndex
        
        // Deselect any selected component
        canvasManager.deselectAll()
        
        // Load new page's components
        canvasManager.components = newPage.components
        
        // Restore canvas settings from new page
        if let savedDevicePreset = newPage.devicePreset,
           let devicePreset = DevicePreset.allCases.first(where: { $0.rawValue == savedDevicePreset }) {
            canvasManager.devicePreset = devicePreset
        }
        
        if let savedColorScheme = newPage.colorScheme {
            canvasManager.colorScheme = savedColorScheme.lowercased() == "light" ? .light : (savedColorScheme.lowercased() == "dark" ? .dark : nil)
        } else {
            canvasManager.colorScheme = nil  // System default
        }
        
        // Restore status bar visibility and component
        if let savedStatusBar = newPage.statusBarComponent {
            canvasManager.statusBarComponent = savedStatusBar.clone()
        } else {
            // Legacy/Default fallback
            canvasManager.statusBarComponent?.isVisible = newPage.statusBarVisible
        }
        canvasManager.validateStatusBarProperties()
        designFile.statusBarVisible = newPage.statusBarVisible
        
        // Reset undo/redo for the new page context
        canvasManager.saveInitialState()
        
        // Trigger save for the page switch
        designFile.markAsChanged()
        
        debugLog("📄 Switched to page \(pageIndex): \(newPage.name) with \(canvasManager.components.count) components")
    }
    
    private func restoreCanvasSettings() {
        // Restore selected device preset
        if let savedDevicePreset = designFile.selectedDevicePreset ?? designFile.devicePreset,
           let devicePreset = DevicePreset.allCases.first(where: { $0.rawValue == savedDevicePreset }) {
            canvasManager.devicePreset = devicePreset
        }
        
        // Restore canvas color scheme
        if let savedColorScheme = designFile.canvasColorScheme {
            if savedColorScheme.lowercased() == "light" {
                canvasManager.colorScheme = .light
            } else if savedColorScheme.lowercased() == "dark" {
                canvasManager.colorScheme = .dark
            }
        }
        
        // Restore status bar settings
        if let savedStatusBar = designFile.currentPage?.statusBarComponent {
            canvasManager.statusBarComponent = savedStatusBar.clone()
        } else {
             canvasManager.statusBarComponent?.isVisible = designFile.statusBarVisible
        }
        canvasManager.validateStatusBarProperties()
    }
    
    private func saveCanvasSettings() {
        // Save selected device preset
        designFile.selectedDevicePreset = canvasManager.devicePreset.rawValue
        
        // Save canvas color scheme
        if let scheme = canvasManager.colorScheme {
            designFile.canvasColorScheme = scheme == .light ? "light" : "dark"
        } else {
            designFile.canvasColorScheme = nil
        }
        
        // Save status bar settings to current page
        designFile.currentPage?.statusBarComponent = canvasManager.statusBarComponent?.clone()
        
        // Trigger save
        designFile.markAsChanged()
    }
    
    private func syncComponents() {
            designFile.components = canvasManager.components
            
            // Capture screenshot for thumbnail
            captureScreenshot()
            
            designFile.markAsChanged()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    
    private func syncSelection() {
            designFile.components = canvasManager.components
            // Don't capture screenshot on selection change - inefficient
            
            designFile.markAsChanged()
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
    
    private func syncDesignChanges() {
        // This is now predominantly handled by the observers to avoid loops
        // but we keep it for explicit calls if any remain
        if !isSwitchingPage {
            designFile.components = canvasManager.components
            designFile.markAsChanged()
        }
    }

    private func scheduleDesignSync(captureScreenshot: Bool) {
        // Coalesce rapid changes to avoid redundant saves/snapshots
        designSyncWorkItem?.cancel()
        let workItem = DispatchWorkItem { [designFile, canvasManager] in
            if !isSwitchingPage {
                designFile.components = canvasManager.components
                designFile.objectWillChange.send()
                designFile.markAsChanged()
                
                if captureScreenshot {
                    performScreenshotCapture()
                }
            }
        }
        designSyncWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
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
            deviceSize: self.canvasManager.devicePreset.size,
            colorScheme: self.canvasManager.colorScheme ?? .light,
            statusBarComponent: self.canvasManager.statusBarComponent,
            statusBarHasBackground: self.statusBarHasBackground
        )
        
        if let thumbnailData = ScreenshotUtility.shared.captureThumbnail(
            of: screenshotView,
            size: self.canvasManager.devicePreset.size,
            colorScheme: self.canvasManager.colorScheme ?? .light
        ) {
            // This will overwrite the previous thumbnail and store device preset
            self.designFile.setThumbnail(thumbnailData, devicePreset: self.canvasManager.devicePreset.rawValue)
            
            // Also save to current page for gallery preview
            self.designFile.currentPage?.thumbnail = thumbnailData
            
            debugLog("📸 Screenshot captured and set on design file and current page")
        } else {
            debugLog("📸 Failed to capture screenshot")
        }
    }
    
    /// Returns appropriate icon based on selected device category
    private var deviceIcon: String {
        switch canvasManager.devicePreset.category {
        case .iphone:
            return "iphone"
        case .ipad:
            return "ipad"
        case .widget:
            return "rectangle.grid.1x2"
        case .custom:
            return "aspectratio"
        }
    }
}

struct ComponentView: View {
    @ObservedObject var component: UIComponent
    let onSelect: (Bool) -> Void  // Bool indicates additive selection
    let selectedDevice: DevicePreset
    let colorScheme: ColorScheme?
    let selectedComponentIds: Set<UUID>
    let onSelectChild: ((UIComponent, Bool) -> Void)?
    let canvasManager: CanvasManager
    @State private var isHovered: Bool = false
    
    init(component: UIComponent, onSelect: @escaping (Bool) -> Void, selectedDevice: DevicePreset, colorScheme: ColorScheme?, selectedComponentIds: Set<UUID>, onSelectChild: ((UIComponent, Bool) -> Void)? = nil, canvasManager: CanvasManager) {
        self.component = component
        self.onSelect = onSelect
        self.selectedDevice = selectedDevice
        self.colorScheme = colorScheme
        self.selectedComponentIds = selectedComponentIds
        self.onSelectChild = onSelectChild
        self.canvasManager = canvasManager
    }
    
    var body: some View {
        ComponentRenderer(component: component, deviceSize: selectedDevice.size, colorScheme: colorScheme, onTap: onSelect, onSelectChild: onSelectChild, selectedComponentIds: selectedComponentIds, canvasManager: canvasManager)

            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: component.frame)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: component.isVisible)
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
        content
            .frame(width: width)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .overlay(
                resizeHandle,
                alignment: handlePosition == .left ? .leading : .trailing
            )
            .frame(maxHeight: .infinity)
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
        return Color.clear
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

import SwiftUI

struct EditorPanelStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    var panelBackgroundColor: Color {
        if colorScheme == .dark {
            return Color(red: 28/255, green: 28/255, blue: 30/255) // #1C1C1E
        } else {
            return Color.white
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(panelBackgroundColor)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func editorPanelStyle() -> some View {
        modifier(EditorPanelStyle())
    }
}
