//
//  UIBuilderView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import FluidGradient
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
    #if os(iOS)
    static let minimizeSheet = Notification.Name("minimizeSheet") // Minimize iOS sheet to height 80
    #endif
    static let dismissChildNavigation = Notification.Name("dismissChildNavigation") // Dismiss child views (add components, modifiers)
    static let dismissAIPromptFocus = Notification.Name("dismissAIPromptFocus")
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
    #if os(iOS)
    @EnvironmentObject private var designManager: DesignManager
    #endif
    @StateObject private var canvasManager = CanvasManager()

    enum SidebarTab {
        case layers
        case pages
    }
    
    @State private var selectedSidebarTab: SidebarTab = .layers

    @State private var showCodePreview = false
    @State private var baseZoomLevel: CGFloat = 1.0
    @State private var canvasViewportSize: CGSize = .zero
    
    // Panel states
    @State private var layersPanelWidth: CGFloat = 300
    @State private var propertiesPanelWidth: CGFloat = 300
    @State private var showLayersPanel = true
    @State private var showPropertiesPanel = true
    
    @State private var currentPageIndex: Int = 0
    @State private var isSwitchingPage: Bool = false
    @State private var isRestoringCanvasSettings: Bool = false

    @State private var showComponentLibrary = false
    @State private var showCommunitySubmission = false
    
    // Screenshot capture debouncing
    @State private var lastScreenshotRequestTime: Date = Date()
    private let screenshotDebounceInterval: TimeInterval = 2.0
    
    // Debounced design sync to avoid redundant saves/snapshots
    @State private var designSyncWorkItem: DispatchWorkItem?
    
#if os(iOS)
    @State private var selection: PresentationDetent = .medium // Locked to medium
    @State private var activeTab: AppTab? = nil // Optional to allow closing
    @State private var showPropertiesSheet = false
    @State private var showCanvasSettingsSheet = false
    
    enum AppTab: String, CaseIterable, Identifiable {
        case layers = "Layers"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .layers: return "square.3.layers.3d.top.filled"
            }
        }
    }
    #endif

#if os(iOS)
    private func closeAllSheets() {
        activeTab = nil
        showPropertiesSheet = false
        showCanvasSettingsSheet = false
        showCodePreview = false
        selection = .medium
    }
    
    private func openLayersSheet() {
        closeAllSheets()
        selection = .medium
        activeTab = .layers
    }
    
    private func openPropertiesSheet() {
        closeAllSheets()
        selection = .medium
        showPropertiesSheet = true
    }
    
    private func openCanvasSettingsSheet() {
        closeAllSheets()
        selection = .medium
        showCanvasSettingsSheet = true
    }
    
    private func openCodePreviewSheet() {
        closeAllSheets()
        selection = .medium
        showCodePreview = true
    }
#endif
    
    private func openCommunitySubmissionSheet() {
        #if os(iOS)
        closeAllSheets()
        #endif
        showCommunitySubmission = true
    }

    var body: some View {
        let baseContent = NavigationStack {
            ZStack(alignment: .top) {
                Color.clear
                    .onAppear {
                        // Ensure status bar properties are valid (migration/hotfix)
                        canvasManager.validateStatusBarProperties()
                    }

                platformSpecificContent
            }
            .modifier(AIPromptDismissModifier())
        }

        let withToolbar = baseContent
            .navigationTitle(designFile.name)
            .toolbar { toolbarButtons }
#if os(macOS)
            .toolbarBackground(.hidden, for: .windowToolbar)
#endif

#if os(macOS)
        let withSheets = withToolbar
            .sheet(isPresented: $showCodePreview) {
                CodePreviewView(canvasManager: canvasManager)
            }
#else
        let withSheets = withToolbar
            .sheet(isPresented: $showCodePreview) {
                CodePreviewView(canvasManager: canvasManager)
                    .presentationDetents([.medium], selection: $selection)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationDragIndicator(.visible)
            }
#endif

        let withCommunitySheet = withSheets
            .sheet(isPresented: $showCommunitySubmission) {
                SubmitToCommunityView(designFile: designFile)
            }
        // Undo/Redo Toast Overlay handled by ToastManager

        let withOnAppear = withCommunitySheet
            .onAppear {
                setupCanvas()
                
                // Restore saved device preset and color scheme
                restoreCanvasSettings()
                
                // Capture initial screenshot IMMEDIATELY (no debounce) on open
                performScreenshotCapture()
            }

        let withSidebarChange = withOnAppear
            .onChange(of: selectedSidebarTab) { tab, _ in
                if tab == .pages {
                    // Force immediate capture when opening pages tab to ensure thumbnail is fresh
                    performScreenshotCapture()
                }
            }

        let withComponentChanges = withSidebarChange
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
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        if newSelection != nil {
                            openPropertiesSheet()
                        } else {
                            showPropertiesSheet = false
                        }
                    }
                    #endif
                }
            }

        let withDeviceChanges = withComponentChanges
            .onChange(of: canvasManager.devicePreset) { _, newDevice in
                if !isSwitchingPage && !isRestoringCanvasSettings {
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

        let withUndoRedoHandlers = withDeviceChanges
            .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                canvasManager.undo()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    captureScreenshot()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                canvasManager.redo()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    captureScreenshot()
                }
            }

        let withDesignChangeHandlers = withUndoRedoHandlers
            .onReceive(NotificationCenter.default.publisher(for: .designChanged)) { _ in
                if !isSwitchingPage {
                    saveCanvasSettings()
                    scheduleDesignSync(captureScreenshot: false)
                }
            }
            .onChange(of: canvasManager.undoStackVersion) { _, _ in
                // Trigger sync when undo stack changes (action performed, undo, or redo)
                // This catches changes like Canvas Settings that aren't in the components array
                scheduleDesignSync(captureScreenshot: false)
                captureScreenshot()
            }
            .onReceive(NotificationCenter.default.publisher(for: .statusBarVisibilityChanged)) { notification in
                if let isVisible = notification.object as? Bool {
                    designFile.statusBarVisible = isVisible
                    designFile.markAsChanged()
                }
            }

        return withDesignChangeHandlers
    }
    
    @ViewBuilder
    private var platformSpecificContent: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone: Full screen canvas with bottom sheet
            iOSCanvasContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { iOSToolbarContent }
        } else {
            // iPad: macOS-style floating panels
            iPadCanvasContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { iPadToolbarContent }
        }
        #else
        // macOS: Normal canvas layout with overlaid panels
        macOSCanvasContent
        #endif
    }
    
    #if os(iOS)
    private var iPadCanvasContent: some View {
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
                        sidebarPanel
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
    }
    #endif
    
    #if os(macOS)
    private var macOSCanvasContent: some View {
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
                
                // Center Canvas Area (just a spacer)
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
                    .animation(.easeInOut(duration: 0.3), value: canvasManager.selectedComponent)
                }
            }
        }
    }
    #endif
    
#if os(iOS)
    private var iOSCanvasContent: some View {
        ZStack {
            mainCanvasArea
            
            // AI Hub + Panel Controls
            VStack {
                Spacer()
                aiHubBar
            }
        }
        .sheet(isPresented: Binding(
            get: { activeTab != nil },
            set: { if !$0 { activeTab = nil } }
        )) {
            if let tab = activeTab {
                sheetContent(for: tab)
                    .presentationDetents([.medium], selection: $selection)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationBackground(.regularMaterial)
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showCanvasSettingsSheet) {
            canvasSettingsSheet
                .presentationDetents([.medium], selection: $selection)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationBackground(.regularMaterial)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPropertiesSheet) {
            propertiesPanel
                .ignoresSafeArea(.container, edges: .bottom)
                .presentationDetents(propertiesSheetDetents, selection: $selection)
                .presentationBackgroundInteraction(.enabled(upThrough: propertiesSheetMaxDetent))
                .presentationBackground(.regularMaterial)
                .presentationDragIndicator(.visible)
        }
    }

    private var propertiesSheetDetents: Set<PresentationDetent> {
        UIDevice.current.userInterfaceIdiom == .phone ? [.medium] : [.medium, .large]
    }

    private var propertiesSheetMaxDetent: PresentationDetent {
        UIDevice.current.userInterfaceIdiom == .phone ? .medium : .large
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
            Button(action: { openLayersSheet() }) {
                Image(systemName: AppTab.layers.icon)
            }
            
            Button(action: { openCanvasSettingsSheet() }) {
                Image(systemName: "iphone")
            }
            
            // Recenter button
            Button(action: {
                canvasManager.canvasOffset = .zero
                canvasManager.zoomLevel = 1.0
                canvasManager.centerCanvasTrigger.toggle()
            }) {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
            }
            
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
                    openCodePreviewSheet()
                }) {
                    Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                
                Divider()
                
                Button(action: { saveAsScreenshot() }) {
                    Label("Save as Screenshot", systemImage: "photo")
                }
                
                Divider()
                Button(action: { openCommunitySubmissionSheet() }) {
                    Label("Post to Community", systemImage: "paperplane")
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
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                
                Divider()
                
                Button(action: { openCommunitySubmissionSheet() }) {
                    Label("Submit to Community", systemImage: "paperplane")
                }

            } label: {
                 Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14, weight: .medium))
            }
            .help("Export")
        }
    }
#endif

#if os(iOS)
    private var canvasSettingsSheet: some View {
        NavigationStack {
            List {
                Section("Canvas Scheme") {
                    Picker("Canvas Scheme", selection: Binding(
                        get: { canvasManager.colorScheme ?? .light },
                        set: { canvasManager.setColorScheme($0) }
                    )) {
                        Text("Light").tag(ColorScheme.light)
                        Text("Dark").tag(ColorScheme.dark)
                    }
                    .pickerStyle(.palette)
                }
                
                Section("IPhone") {
                    ForEach(DevicePreset.iphones) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                Spacer()
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section("iPad") {
                    ForEach(DevicePreset.ipads) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                Spacer()
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section("Widgets") {
                    ForEach(DevicePreset.widgets) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                Spacer()
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                
                Section("Custom") {
                    ForEach(DevicePreset.custom) { preset in
                        Button {
                            canvasManager.setDevicePreset(preset)
                        } label: {
                            HStack {
                                Text(preset.rawValue)
                                Spacer()
                                if canvasManager.devicePreset == preset {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            .tint(.primary)
            .navigationTitle("Canvas Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showCanvasSettingsSheet = false }
                }
            }
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
        .ignoresSafeArea()
        .simultaneousGesture(TapGesture().onEnded {
            NotificationCenter.default.post(name: .dismissAIPromptFocus, object: nil)
        })
        .animation(.spring(), value: canvasManager.selectedComponentIds.count)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear { canvasViewportSize = geometry.size }
                    .onChange(of: geometry.size) { _, newSize in
                        canvasViewportSize = newSize
                    }
            }
        )
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
        #if os(iOS)
        NavigationStack {
            PropertiesPanelView(
                selectedComponent: $canvasManager.selectedComponent,
                canvasManager: canvasManager
            )
        }
        .editorPanelStyle()
        #else
        PropertiesPanelView(
            selectedComponent: $canvasManager.selectedComponent,
            canvasManager: canvasManager
        )
        .editorPanelStyle()
        #endif
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
    private var aiHubBar: some View {
        VStack(spacing: 10) {
            let isPhone = UIDevice.current.userInterfaceIdiom == .phone
            
            if isPhone {
                EmptyView()
            }
        }
        .padding(.horizontal, 12)
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
        }
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
    
    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            devicePresetMenu
            colorSchemeMenu
            centerCanvasButton
            undoToolbarButton
            redoToolbarButton
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            exportMenu
        }
    }
    
    private var devicePresetMenu: some View {
        Menu {
            devicePresetMenuContent
        } label: {
            HStack(spacing: 4) {
                Image(systemName: deviceIcon)
                    .font(.system(size: 11))
                Text(canvasManager.devicePreset.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: 100)
                    .lineLimit(1)
            }
        }
        .help("Choose Device")
    }
    
    @ViewBuilder
    private var devicePresetMenuContent: some View {
        Section("iPhone") {
            ForEach(DevicePreset.iphones) { preset in
                Button {
                    canvasManager.setDevicePreset(preset)
                } label: {
                    HStack {
                        Text(preset.rawValue)
                        Spacer()
                        if canvasManager.devicePreset == preset {
                            Image(systemName: "checkmark")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        
        Divider()
        
        Section("iPad") {
            ForEach(DevicePreset.ipads) { preset in
                Button {
                    canvasManager.setDevicePreset(preset)
                } label: {
                    HStack {
                        Text(preset.rawValue)
                        Spacer()
                        if canvasManager.devicePreset == preset {
                            Image(systemName: "checkmark")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        
        Divider()
        
        Section("Widgets") {
            ForEach(DevicePreset.widgets) { preset in
                Button {
                    canvasManager.setDevicePreset(preset)
                } label: {
                    HStack {
                        Text(preset.rawValue)
                        Spacer()
                        if canvasManager.devicePreset == preset {
                            Image(systemName: "checkmark")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        
        Divider()
        
        Section("Custom") {
            ForEach(DevicePreset.custom) { preset in
                Button {
                    canvasManager.setDevicePreset(preset)
                } label: {
                    HStack {
                        Text(preset.rawValue)
                        Spacer()
                        if canvasManager.devicePreset == preset {
                            Image(systemName: "checkmark")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    private var colorSchemeMenu: some View {
        Menu {
            Button {
                canvasManager.setColorScheme(.light)
            } label: {
                HStack {
                    Text("Light")
                    Spacer()
                    if canvasManager.colorScheme == .light {
                        Image(systemName: "checkmark")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                canvasManager.setColorScheme(.dark)
            } label: {
                HStack {
                    Text("Dark")
                    Spacer()
                    if canvasManager.colorScheme == .dark {
                        Image(systemName: "checkmark")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } label: {
            Image(systemName: canvasManager.colorScheme == .light ? "sun.max" : "moon")
                .font(.system(size: 12))
        }
        .help("Color Scheme")
    }
    
    private var centerCanvasButton: some View {
        Button(action: {
            let targetCanvasSize = canvasViewportSize == .zero
                ? CGSize(width: 800, height: 600)
                : canvasViewportSize
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                canvasManager.zoomToFitDevice(canvasManager.devicePreset.size, canvasSize: targetCanvasSize)
            }
            baseZoomLevel = canvasManager.zoomLevel
            canvasManager.centerCanvasTrigger.toggle()
        }) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("1", modifiers: .command)
        .help("Center Canvas")
    }
    
    private var undoToolbarButton: some View {
        Button(action: {
            canvasManager.undo()
        }) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("z", modifiers: .command)
        .disabled(!canvasManager.canUndo)
        .help("Undo")
    }
    
    private var redoToolbarButton: some View {
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
    
    private var exportMenu: some View {
        Menu {
            Button(action: { showCodePreview = true }) {
                Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            Button(action: { saveAsScreenshot() }) {
                Label("Save as Screenshot", systemImage: "photo")
            }
            
            Divider()
            
            Button(action: { openCommunitySubmissionSheet() }) {
                Label("Submit to Community", systemImage: "paperplane")
            }
            
            Divider()
            
//            Button(action: {
//                let json = canvasManager.getDesignAsJSON()
//                #if os(iOS)
//                UIPasteboard.general.string = json
//                #elseif os(macOS)
//                let pasteboard = NSPasteboard.general
//                pasteboard.clearContents()
//                pasteboard.setString(json, forType: .string)
//                #endif
//            }) {
//                Label("Copy JSON", systemImage: "doc.on.clipboard")
//            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .medium))
        }
        .help("Export")
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
    
    private func saveAsScreenshot() {
        let screenshotView = CanvasScreenshotView(
            components: canvasManager.components,
            deviceSize: canvasManager.devicePreset.size,
            colorScheme: canvasManager.colorScheme ?? .light,
            statusBarVisible: canvasManager.statusBarVisible,
            statusBarTopSafeArea: canvasManager.statusBarTopSafeArea
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
                statusBarVisible: canvasManager.statusBarVisible,
                statusBarTopSafeArea: canvasManager.statusBarTopSafeArea
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
            oldPage.statusBarTopSafeArea = canvasManager.statusBarTopSafeArea
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
            // Legacy/Default fallback (no saved component, use page's boolean fields)
            canvasManager.statusBarComponent?.isVisible = newPage.statusBarVisible
            canvasManager.statusBarTopSafeArea = newPage.statusBarTopSafeArea
        }
        // Sync settings from the loaded component (source of truth)
        canvasManager.validateStatusBarProperties()
        designFile.statusBarVisible = newPage.statusBarVisible
        
        // Reset undo/redo for the new page context
        canvasManager.saveInitialState()
        
        // Trigger save for the page switch
        designFile.markAsChanged()
        
        debugLog("📄 Switched to page \(pageIndex): \(newPage.name) with \(canvasManager.components.count) components")
    }
    
    private func restoreCanvasSettings() {
        isRestoringCanvasSettings = true
        defer { DispatchQueue.main.async { self.isRestoringCanvasSettings = false } }

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
            // Legacy/Default fallback (no saved component, use page's/file's boolean fields)
            canvasManager.statusBarComponent?.isVisible = designFile.statusBarVisible
            if let page = designFile.currentPage {
                canvasManager.statusBarTopSafeArea = page.statusBarTopSafeArea
            } else {
                canvasManager.statusBarTopSafeArea = designFile.statusBarTopSafeArea
            }
        }
        // Sync settings from the loaded component (source of truth)
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
        if let page = designFile.currentPage {
            page.statusBarTopSafeArea = canvasManager.statusBarTopSafeArea
        }
        designFile.statusBarTopSafeArea = canvasManager.statusBarTopSafeArea
        
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
            statusBarVisible: self.canvasManager.statusBarVisible,
            statusBarTopSafeArea: self.canvasManager.statusBarTopSafeArea
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
            .overlay(alignment: handlePosition == .left ? .leading : .trailing) {
                resizeHandle
                    .padding(.vertical, 8)
                    .padding(handlePosition == .left ? .leading : .trailing, 10)
                    .offset(x: handlePosition == .left ? 6 : -6)
            }
            .frame(maxHeight: .infinity)
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
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

struct AIPromptDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            content
        } else {
            content.simultaneousGesture(TapGesture().onEnded {
                NotificationCenter.default.post(name: .dismissAIPromptFocus, object: nil)
            })
        }
#else
        content.simultaneousGesture(TapGesture().onEnded {
            NotificationCenter.default.post(name: .dismissAIPromptFocus, object: nil)
        })
#endif
    }
}

extension View {
    func editorPanelStyle() -> some View {
        modifier(EditorPanelStyle())
    }
}
