//
//  UIBuilderView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
import NotchMyProblem
#endif

extension Notification.Name {
    static let canvasUndo = Notification.Name("canvas.undo")
    static let canvasRedo = Notification.Name("canvas.redo")
    static let designChanged = Notification.Name("design.changed")
    static let selectComponent = Notification.Name("selectComponent")
    static let designWillChange = Notification.Name("design.willChange") // Posted BEFORE a change for undo state capture
    static let dismissAIPromptFocus = Notification.Name("dismissAIPromptFocus")
    static let dismissChildNavigation = Notification.Name("dismissChildNavigation") // Dismiss child views (add components, modifiers)
    static let statusBarVisibilityChanged = Notification.Name("statusBar.visibilityChanged")
#if os(iOS)
    static let minimizeSheet = Notification.Name("minimizeSheet") // Minimize iOS sheet to height 80
#endif
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
    @EnvironmentObject private var toastManager: ToastManager
    @ObservedObject var designFile: DesignFile
    #if os(iOS)
    @EnvironmentObject private var designManager: DesignManager
    #endif
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @StateObject private var canvasManager = CanvasManager()
    @StateObject private var aiService = AIService.shared
    
    @State private var showCodePreview = false
    @State private var baseZoomLevel: CGFloat = 1.0
    @State private var canvasViewportSize: CGSize = .zero
    @State private var hasAppliedInitialCanvasView: Bool = false
    
    // Panel states
    @State private var showLayersPanel = true
    @State private var showPropertiesPanel = true
    private let fixedPanelWidth: CGFloat = 300
    
    @State private var currentPageIndex: Int = 0
    @State private var isSwitchingPage: Bool = false
    @State private var showRenamePageSheet: Bool = false
    @State private var renamePageText: String = ""
    @State private var isRestoringCanvasSettings: Bool = false

    @State private var showComponentLibrary = false
    @State private var componentLibraryMode: ComponentLibraryMode = .add
    @State private var showCommunitySubmission = false
    
    // Free tier limit
    private let freePageLimit = 3

    // AI
    @State private var isAIGenerating = false
    @State private var aiOperationUndoStack: [AIOperationHistoryEntry] = []
    @State private var aiOperationRedoStack: [AIOperationHistoryEntry] = []
    
    // Screenshot capture debouncing
    @State private var lastScreenshotRequestTime: Date = Date()
    private let screenshotDebounceInterval: TimeInterval = 2.0
    @State private var screenshotCaptureWorkItem: DispatchWorkItem?
    
    // Debounced design sync to avoid redundant saves/snapshots
    @State private var designSyncWorkItem: DispatchWorkItem?
    @State private var designChangedWorkItem: DispatchWorkItem?
    private let designChangedDebounceInterval: TimeInterval = 0.15

    private struct AIOperationHistoryEntry {
        var componentId: UUID
        let forward: [AIEditOperation]
        let inverse: [AIEditOperation]
    }
    
#if os(iOS)
    @State private var selection: PresentationDetent = UIDevice.current.userInterfaceIdiom == .phone ? .medium : .large
    @State private var activeTab: AppTab? = nil // Optional to allow closing
    @State private var activeSheet: IOSSheet?
    @State private var showLayerPropertiesNavigation = false
    
    enum AppTab: String, CaseIterable, Identifiable {
        case layers = "Layers"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .layers: return "square.3.layers.3d.top.filled"
            }
        }
    }

    enum IOSSheet: Identifiable {
        case layers
        case properties
        case canvasSettings

        var id: Int {
            switch self {
            case .layers: return 0
            case .properties: return 1
            case .canvasSettings: return 2
            }
        }
    }
    #endif

#if os(iOS)

    
    private func openLayersSheet() {
        selection = .medium
        activeSheet = .layers
    }
    
    private func openPropertiesSheet() {
        selection = .medium
        activeSheet = .properties
    }
    
    private func openCanvasSettingsSheet() {
        selection = .medium
        activeSheet = .canvasSettings
    }
#endif

    private func openCodePreviewSheet() {
#if os(iOS)
        selection = UIDevice.current.userInterfaceIdiom == .phone ? .medium : .large
#endif
        showCodePreview = true
    }

    private func attemptAddPage() {
        if !subscriptionManager.isSubscribed && designFile.pages.count >= freePageLimit {
            toastManager.showToast(
                ToastData(title: "Page Limit Reached", icon: "lock.fill")
            )
            PaywallManager.shared.present()
            return
        }
        let (_, newIndex) = designFile.addPage()
        switchToPage(newIndex)
    }

    private var defaultCanvasZoom: CGFloat {
#if os(macOS)
        return 0.75
#else
        return 1.0
#endif
    }

    private var targetCanvasViewportSize: CGSize {
        canvasViewportSize == .zero
            ? CGSize(width: 800, height: 600)
            : canvasViewportSize
    }

    private func applyInitialCanvasView() {
        canvasManager.canvasOffset = .zero
#if os(macOS)
        canvasManager.zoomLevel = defaultCanvasZoom
        baseZoomLevel = defaultCanvasZoom
#else
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            canvasManager.zoomLevel = defaultCanvasZoom
            baseZoomLevel = defaultCanvasZoom
        } else {
            let targetCanvasSize = targetCanvasViewportSize
            canvasManager.zoomToFitDevice(canvasManager.devicePreset.size, canvasSize: targetCanvasSize)
            baseZoomLevel = canvasManager.zoomLevel
        }
        #else
        let targetCanvasSize = targetCanvasViewportSize
        canvasManager.zoomToFitDevice(canvasManager.devicePreset.size, canvasSize: targetCanvasSize)
        baseZoomLevel = canvasManager.zoomLevel
        #endif
#endif
    }

    private func applyInitialCanvasViewIfReady() {
#if os(iOS)
        guard canvasViewportSize != .zero else { return }
#endif
        guard !hasAppliedInitialCanvasView else { return }
        applyInitialCanvasView()
        hasAppliedInitialCanvasView = true
    }

    private func animateRecenterCanvas() {
        canvasManager.isLayoutTransitioning = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            applyInitialCanvasView()
            canvasManager.centerCanvasTrigger.toggle()
        }
        baseZoomLevel = canvasManager.zoomLevel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            canvasManager.isLayoutTransitioning = false
        }
    }
    
    private func openCommunitySubmissionSheet() {
        showCommunitySubmission = true
    }

    private func presentRenameCurrentPage() {
        guard currentPageIndex >= 0, currentPageIndex < designFile.pages.count else { return }
        renamePageText = designFile.pages[currentPageIndex].name
        showRenamePageSheet = true
    }

    private func commitRenameCurrentPage() {
        let trimmed = renamePageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard currentPageIndex >= 0, currentPageIndex < designFile.pages.count else { return }
        designFile.renamePage(at: currentPageIndex, to: trimmed)
        designFile.markAsChanged()
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }

    private func deleteCurrentPage() {
        guard currentPageIndex > 0 else { return }
        if designFile.deletePage(at: currentPageIndex) {
            switchToPage(designFile.currentPageIndex)
        }
    }

    private func duplicateCurrentPage() {
        if let (_, newIndex) = designFile.duplicatePage(at: currentPageIndex) {
            switchToPage(newIndex)
        }
    }

    private var pageMenu: some View {
        PageMenuView(
            pages: designFile.pages,
            currentPageIndex: currentPageIndex,
            onSelectPage: switchToPage,
            onAddPage: attemptAddPage,
            onDuplicatePage: duplicateCurrentPage,
            onRenamePage: presentRenameCurrentPage,
            onDeletePage: deleteCurrentPage
        )
    }

    var body: some View {
        builderContent
            .toast($toastManager.currentToast)
    }

    private var builderContent: some View {
        withDesignChangeHandlers(
            withUndoRedoHandlers(
                withDeviceChangeHandlers(
                    withComponentChangeHandlers(
                        withLifecycleHandlers(
                            withEditorSheets(
                                withCommunitySheet(
                                    withRenamePageSheet(
                                        withCodePreviewSheet(
                                            withToolbar(baseNavigationContent)
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    }

    private var baseNavigationContent: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                platformSpecificContent
#if os(iOS)
                cutoutAccessoryOverlay
                #endif
            }
            .onAppear {
                canvasManager.validateStatusBarProperties()
            }
        }
        #if os(iOS)
        .statusBarHidden()
        #endif
    }
#if os(iOS)
    @ViewBuilder
    private var cutoutAccessoryOverlay: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            if #available(iOS 26.0, macOS 26.0, *) {
                glassCutoutAccessory
            } else {
                legacyCutoutAccessory
            }
        }
    }
    #endif

#if os(iOS)
    @available(iOS 26.0, *)
    private var glassCutoutAccessory: some View {
        CutoutAccessoryView(
            padding: .auto,
            leadingContent: {
                Button("Back") { handleCutoutCancel() }
                    .buttonStyle(.glass)
                    .bold()
            },
            trailingContent: {
                cutoutDoneMenu
                    .buttonStyle(.glassProminent)
                    .tint(.yellow)
                    .foregroundColor(.black)
                    .bold()
            }
        )
    }
    #endif
#if os(iOS)
    private var legacyCutoutAccessory: some View {
        CutoutAccessoryView(
            padding: .auto,
            leadingContent: {
                Button("Back") { handleCutoutCancel() }
                    .buttonStyle(.borderedProminent)
                    .bold()
            },
            trailingContent: {
                cutoutDoneMenu
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                    .foregroundColor(.black)
                    .bold()
            }
        )
    }
    #endif

    private var cutoutDoneMenu: some View {
        Menu("Done") {
            Button("View Code", systemImage: "swift") {
                openCodePreviewSheet()
            }
            .tint(.orange)
            Button("Save as Screenshot", systemImage: "photo") {
                saveAsScreenshot()
            }
            .tint(.blue)
            Button("Share to Community", systemImage: "person.2.fill") {
                openCommunitySubmissionSheet()
            }
            .tint(.green)
        }
    }

    private func handleCutoutCancel() {
        #if os(iOS)
        designFile.save()
        designManager.closeCurrentDesign()
        #endif
    }

    private func withToolbar<Content: View>(_ content: Content) -> some View {
        content
            .navigationTitle(designFile.name)
            .toolbar { toolbarButtons }
#if os(macOS)
            .toolbarBackground(.hidden, for: .windowToolbar)
#endif
    }

    private func withCodePreviewSheet<Content: View>(_ content: Content) -> some View {
#if os(macOS)
        content
            .sheet(isPresented: $showCodePreview) {
                CodePreviewView(canvasManager: canvasManager)
            }
#else
        content
            .sheet(isPresented: $showCodePreview) {
                CodePreviewView(canvasManager: canvasManager)
                    .presentationDetents(
                        UIDevice.current.userInterfaceIdiom == .phone ? [.medium] : [.large],
                        selection: $selection
                    )
                    .presentationBackgroundInteraction(
                        .enabled(
                            upThrough: UIDevice.current.userInterfaceIdiom == .phone ? .medium : .large
                        )
                    )
                    .presentationDragIndicator(.visible)
            }
#endif
    }

    private func withCommunitySheet<Content: View>(_ content: Content) -> some View {
        content
            .sheet(isPresented: $showCommunitySubmission) {
                SubmitToCommunityView(designFile: designFile)
            }
    }

    private func withRenamePageSheet<Content: View>(_ content: Content) -> some View {
        content
            .sheet(isPresented: $showRenamePageSheet) {
                renamePageSheetContent
            }
    }

    private var renamePageSheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Page")
                .font(.title3.weight(.semibold))

            TextField("Page Name", text: $renamePageText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    commitRenameAndDismissPageSheet()
                }

            HStack {
                Spacer()

                Button("Cancel") {
                    showRenamePageSheet = false
                }

                Button("Save") {
                    commitRenameAndDismissPageSheet()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(renamePageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 320)
    }

    private func commitRenameAndDismissPageSheet() {
        let trimmed = renamePageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        commitRenameCurrentPage()
        showRenamePageSheet = false
    }

    private func withEditorSheets<Content: View>(_ content: Content) -> some View {
#if os(iOS)
        content
            .sheet(item: $activeSheet) { sheet in
                iOSActiveSheetContent(sheet)
            }
#else
        content
#endif
    }

    private func withLifecycleHandlers<Content: View>(_ content: Content) -> some View {
        content
            .onAppear {
                setupCanvas()
                restoreCanvasSettings()
                performScreenshotCapture()
            }
    }

    private func withComponentChangeHandlers<Content: View>(_ content: Content) -> some View {
        content
            .onChange(of: canvasManager.components) { _, _ in
                handleCanvasComponentsChange()
            }
            .onChange(of: canvasManager.selectedComponent) { _, newSelection in
                handleSelectedComponentChange(newSelection)
            }
    }

    private func withDeviceChangeHandlers<Content: View>(_ content: Content) -> some View {
        content
            .onChange(of: canvasManager.devicePreset) { _, newDevice in
                handleDevicePresetChange(newDevice)
            }
            .onChange(of: canvasManager.colorScheme) { _, _ in
                handleColorSchemeChange()
            }
    }

    private func withUndoRedoHandlers<Content: View>(_ content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
                handleCanvasUndo()
            }
            .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
                handleCanvasRedo()
            }
    }

    private func withDesignChangeHandlers<Content: View>(_ content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .designChanged)) { _ in
                handleDesignChangedNotification()
            }
            .onChange(of: canvasManager.undoStackVersion) { _, _ in
                handleUndoStackVersionChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: .statusBarVisibilityChanged)) { notification in
                handleStatusBarVisibilityNotification(notification)
            }
    }

    private func handleCanvasComponentsChange() {
        if !isSwitchingPage {
            syncComponents()
        }
    }

    private func handleSelectedComponentChange(_ newSelection: UIComponent?) {
        guard !isSwitchingPage else { return }
        syncSelection()

#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            if newSelection != nil {
                activeSheet = .layers
                showLayerPropertiesNavigation = true
            } else {
                showLayerPropertiesNavigation = false
                activeSheet = nil
            }
        }
#endif
    }

    private func handleDevicePresetChange(_ newDevice: DevicePreset) {
        guard !isSwitchingPage && !isRestoringCanvasSettings else { return }
        saveCanvasSettings()

        let shouldShowStatusBar = !(newDevice.category == .widget || newDevice.category == .custom)
        designFile.statusBarVisible = shouldShowStatusBar
        canvasManager.statusBarComponent?.isVisible = shouldShowStatusBar
        NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: shouldShowStatusBar)

        if let statusBar = canvasManager.statusBarComponent {
            canvasManager.updateComponentProperty(for: statusBar, key: "topSafeArea", value: shouldShowStatusBar)
        }
    }

    private func handleColorSchemeChange() {
        if !isSwitchingPage {
            saveCanvasSettings()
        }
    }

    private func handleCanvasUndo() {
        if !performAIOperationUndo() {
            canvasManager.undo()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            captureScreenshot()
        }
    }

    private func handleCanvasRedo() {
        if !performAIOperationRedo() {
            canvasManager.redo()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            captureScreenshot()
        }
    }

    private func performAIOperationUndo() -> Bool {
        guard var entry = aiOperationUndoStack.popLast() else { return false }
        let target = canvasManager.findComponent(by: entry.componentId) ?? canvasManager.selectedComponent
        guard let target else {
            aiOperationRedoStack.removeAll()
            return false
        }

        do {
            let result = try AIOperationReducer.shared.applyWithInverse(to: target, operations: entry.inverse)
            canvasManager.replaceComponent(target, with: result.component, registerUndo: false)
            entry.componentId = result.component.id
            aiOperationRedoStack.append(entry)
            toastManager.showToast(ToastData(title: "Undo: AI edit", icon: "arrow.uturn.backward"))
            return true
        } catch {
            print("performAIOperationUndo failed: \(error.localizedDescription)")
            return false
        }
    }

    private func performAIOperationRedo() -> Bool {
        guard var entry = aiOperationRedoStack.popLast() else { return false }
        let target = canvasManager.findComponent(by: entry.componentId) ?? canvasManager.selectedComponent
        guard let target else {
            aiOperationUndoStack.removeAll()
            return false
        }

        do {
            let result = try AIOperationReducer.shared.applyWithInverse(to: target, operations: entry.forward)
            canvasManager.replaceComponent(target, with: result.component, registerUndo: false)
            entry.componentId = result.component.id
            aiOperationUndoStack.append(entry)
            toastManager.showToast(ToastData(title: "Redo: AI edit", icon: "arrow.uturn.forward"))
            return true
        } catch {
            print("performAIOperationRedo failed: \(error.localizedDescription)")
            return false
        }
    }

    private func handleDesignChangedNotification() {
        guard !isSwitchingPage else { return }

        // Coalesce bursts of design-changed notifications into a single save/sync pass.
        designChangedWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard !isSwitchingPage else { return }
            saveCanvasSettings()
            scheduleDesignSync(captureScreenshot: false)
        }
        designChangedWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + designChangedDebounceInterval, execute: workItem)
    }

    private func handleUndoStackVersionChange() {
        scheduleDesignSync(captureScreenshot: false)
        captureScreenshot()
    }

    private func handleStatusBarVisibilityNotification(_ notification: Notification) {
        if let isVisible = notification.object as? Bool {
            designFile.statusBarVisible = isVisible
            designFile.markAsChanged()
        }
    }

    private var propertiesSheetTitle: String {
        if let selected = canvasManager.selectedComponent {
            return selected.type.rawValue
        }
        return "Properties"
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
                .navigationTitle(designFile.name)
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
            mainCanvasArea()
            
            // Floating panels with proper margins
            HStack(spacing: 0) {
                // Left side: Layers panel
                if showLayersPanel {
                    sidebarPanel
                    .frame(width: fixedPanelWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .padding()
                }
                
                Spacer()
                
                if showPropertiesPanel && canvasManager.selectedComponent != nil {
                    propertiesPanel
                    .frame(width: fixedPanelWidth)
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
            mainCanvasArea()
            
            // Floating panels with proper margins
            HStack(spacing: 0) {
                // Left side: Layers panel
                if showLayersPanel {
                    sidebarPanel
                    .frame(width: fixedPanelWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    .padding()
                }
                
                // Center Canvas Area (just a spacer)
                Spacer()
                
                if showPropertiesPanel && canvasManager.selectedComponent != nil {
                    propertiesPanel
                    .frame(width: fixedPanelWidth)
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
        GeometryReader { _ in
            ZStack {
                mainCanvasArea(
                    pushScale: 1.0,
                    pushOffset: .zero
                )
            }
        }
        .onChange(of: activeSheet) { _, newValue in
            let isOverlayOpen = newValue == .layers || newValue == .properties
            canvasManager.isOverlayPanelOpen = isOverlayOpen
            canvasManager.isPropertiesSheetPresented = newValue == .properties
            if newValue != .layers {
                showLayerPropertiesNavigation = false
            }
        }
    }
    
    @ToolbarContentBuilder
    private var iOSToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button(action: { handleCanvasUndo() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!(canvasManager.canUndo || !aiOperationUndoStack.isEmpty))
            
            Button(action: { handleCanvasRedo() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!(canvasManager.canRedo || !aiOperationRedoStack.isEmpty))
        }
        
        ToolbarItem(placement: .principal){
            pageMenu
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: { openCanvasSettingsSheet() }) {
                Image(systemName: "iphone")
            }
            Button(action: { openLayersSheet() }) {
                Image(systemName: AppTab.layers.icon)
            }
        }
    }

    @ToolbarContentBuilder
    private var iPadToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            iPadDismissButton
            layersToolbarToggleButton
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            iPadDeviceMenu
            iPadColorSchemeMenu
            
            // Recenter button
            pageMenu
            
            // Undo/Redo
            Button(action: { handleCanvasUndo() }) {
                Image(systemName: "arrow.uturn.backward")
            }
            .disabled(!(canvasManager.canUndo || !aiOperationUndoStack.isEmpty))
            
            Button(action: { handleCanvasRedo() }) {
                Image(systemName: "arrow.uturn.forward")
            }
            .disabled(!(canvasManager.canRedo || !aiOperationRedoStack.isEmpty))
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            iPadExportMenu
        }

        ToolbarItem(placement: .principal) {
            Text(designFile.name)
                .font(.system(size: 14, weight: .semibold))
        }
    }

    private var iPadDismissButton: some View {
        Button(action: {
            designFile.save()
            designManager.closeCurrentDesign()
        }) {
            Image(systemName: "chevron.left")
        }
    }

    private var iPadDeviceMenu: some View {
        Menu {
            iPadDeviceSection("iPhone", presets: DevicePreset.iphones)
            Divider()
            iPadDeviceSection("iPad", presets: DevicePreset.ipads)
            iPadDeviceSection("Widgets", presets: DevicePreset.widgets)
            iPadDeviceSection("Custom", presets: DevicePreset.custom)
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
    private func iPadDeviceSection(_ title: String, presets: [DevicePreset]) -> some View {
        Section(title) {
            ForEach(presets) { preset in
                iPadDevicePresetRow(preset)
            }
        }
    }

    private func iPadDevicePresetRow(_ preset: DevicePreset) -> some View {
        Button {
            canvasManager.setDevicePreset(preset)
        } label: {
            iPadMenuRowLabel(preset.rawValue, isSelected: canvasManager.devicePreset == preset)
        }
    }

    private var iPadColorSchemeMenu: some View {
        Menu {
            iPadColorSchemeRow(.light, title: "Light Mode")
            iPadColorSchemeRow(.dark, title: "Dark Mode")
        } label: {
            Image(systemName: canvasManager.colorScheme == .light ? "sun.max.fill" : "moon.fill")
        }
    }

    private func iPadColorSchemeRow(_ scheme: ColorScheme, title: String) -> some View {
        Button {
            canvasManager.setColorScheme(scheme)
        } label: {
            iPadMenuRowLabel(title, isSelected: canvasManager.colorScheme == scheme)
        }
    }

    private func iPadMenuRowLabel(_ title: String, isSelected: Bool) -> some View {
        HStack {
            Text(title)
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var iPadExportMenu: some View {
        Menu {
            Button(action: { openCodePreviewSheet() }) {
                Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            Divider()
            Button(action: { saveAsScreenshot() }) {
                Label("Save as Screenshot", systemImage: "photo")
            }
            Divider()
            Button(action: { openCommunitySubmissionSheet() }) {
                Label("Share to Community", systemImage: "paperplane")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .medium))
        }
        .menuIndicator(.hidden)
        .help("Export")
    }

    @ViewBuilder
    private func iOSActiveSheetContent(_ sheet: IOSSheet) -> some View {
        switch sheet {
        case .canvasSettings:
            canvasSettingsSheet
                .presentationDetents([.height(400)])
                .presentationBackgroundInteraction(.enabled)
                .presentationBackground(.regularMaterial)
                .presentationDragIndicator(.visible)
        case .layers:
            NavigationStack {
                sheetContent(for: .layers)
                    .navigationBarTitleDisplayMode(.inline)
            }
            .presentationDetents([.height(400)])
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(.regularMaterial)
            .presentationDragIndicator(.visible)
        case .properties:
            NavigationStack {
                PropertiesPanelView(
                    selectedComponent: $canvasManager.selectedComponent,
                    canvasManager: canvasManager,
                    useNavigationStack: true,
                    showNavigationTitle: false,
                    showComponentActionsSection: UIDevice.current.userInterfaceIdiom != .phone
                )
                .navigationTitle(propertiesSheetTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            Button {
                                duplicateSelectedComponentFromPropertiesSheet()
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                            .disabled(!canPerformComponentToolbarActions)
                            
                            Button(role: .destructive) {
                                deleteSelectedComponentFromPropertiesSheet()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(!canPerformComponentToolbarActions)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    aiHubContent(inSheet: true)
                }
            }
            .presentationDetents([.height(400)])
            .presentationBackgroundInteraction(.enabled)
            .presentationBackground(.regularMaterial)
            .presentationDragIndicator(.visible)
        }
    }
#endif

#if os(iOS)
    private var canvasSettingsSheet: some View {
        NavigationStack {
            List {
                canvasSchemeSection
                devicePresetSection(title: "IPhone", presets: DevicePreset.iphones)
                devicePresetSection(title: "iPad", presets: DevicePreset.ipads)
                devicePresetSection(title: "Widgets", presets: DevicePreset.widgets)
                devicePresetSection(title: "Custom", presets: DevicePreset.custom)
            }
            .tint(.primary)
            .navigationTitle("Canvas Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { activeSheet = nil }
                }
            }
        }
    }

    private var canvasSchemeBinding: Binding<ColorScheme> {
        Binding(
            get: { canvasManager.colorScheme ?? .light },
            set: { canvasManager.setColorScheme($0) }
        )
    }

    private var canvasSchemeSection: some View {
        Section("Canvas Scheme") {
            Picker("Canvas Scheme", selection: canvasSchemeBinding) {
                Text("Light").tag(ColorScheme.light)
                Text("Dark").tag(ColorScheme.dark)
            }
            .pickerStyle(.palette)
        }
    }

    private func devicePresetSection(title: String, presets: [DevicePreset]) -> some View {
        Section(title) {
            ForEach(presets) { preset in
                devicePresetRow(preset)
            }
        }
    }

    private func devicePresetRow(_ preset: DevicePreset) -> some View {
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
#endif

    
    private var sidebarPanel: some View {
        VStack(spacing: 16) {
            // 1. Top Panel: Layers
            VStack(spacing: 0) {
                // Unified Header
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "square.3.layers.3d.top.filled")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                        Text("Layers")
                            .font(.headline).fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        componentLibraryMode = .add
                        showComponentLibrary = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                    }
                    .help("Add Component")
                    .buttonStyle(.bordered)
                    .frame(width: 28, height: 28)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Content
                layersPanel
                
                Spacer(minLength: 0) // Ensure panel stretches if content is short
            }
            .editorPanelStyle()
            
        }
    }
    
    private var layersPanel: some View {
        LayersPanelView(
            canvasManager: canvasManager,
            selectedComponent: $canvasManager.selectedComponent,
            showComponentLibrary: $showComponentLibrary,
            componentLibraryMode: $componentLibraryMode,
            onReplaceRequested: { component in
                canvasManager.selectedComponent = component
                componentLibraryMode = .replace
                showComponentLibrary = true
            }
        )
    }
    
    private func mainCanvasArea(pushScale: CGFloat = 1.0, pushOffset: CGSize = .zero) -> some View {
        ZStack(alignment: .top) {
            canvasView(pushScale: pushScale, pushOffset: pushOffset)
        }
        .ignoresSafeArea()
        .task {
            await aiService.refreshQuota()
        }
        .overlay(alignment: .bottom) {
            if shouldShowFloatingAIHubBar {
                aiHubBar
            }
        }
        .simultaneousGesture(TapGesture().onEnded {
            NotificationCenter.default.post(name: .dismissAIPromptFocus, object: nil)
        })
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        canvasViewportSize = geometry.size
                        applyInitialCanvasViewIfReady()
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        canvasViewportSize = newSize
                        applyInitialCanvasViewIfReady()
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
                // Save after the debounced screenshot capture has completed
                DispatchQueue.main.asyncAfter(deadline: .now() + screenshotDebounceInterval + 0.25) {
                    designFile.save()
                }
            }
        }
    }

    private var shouldShowFloatingAIHubBar: Bool {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone && activeSheet == .properties {
            return false
        }
        #endif
        return true
    }
    
    private func canvasView(pushScale: CGFloat = 1.0, pushOffset: CGSize = .zero) -> some View {
        return CanvasView(
            canvasManager: canvasManager,
            selectedComponent: $canvasManager.selectedComponent,
            selectedDevice: canvasManager.devicePreset,
            baseZoomLevel: $baseZoomLevel,
            colorScheme: $canvasManager.colorScheme,
            pushScale: pushScale,
            pushOffset: pushOffset,
            enableScrollHandler: true
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .contentShape(Rectangle())
        .gesture(magnificationGesture)
    }
    
    @ViewBuilder
    private var propertiesPanel: some View {
        #if os(iOS)
        let panel = PropertiesPanelView(
            selectedComponent: $canvasManager.selectedComponent,
            canvasManager: canvasManager,
            useNavigationStack: true
        )
        if UIDevice.current.userInterfaceIdiom == .phone {
            panel
        } else {
            panel.editorPanelStyle()
        }
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
#endif

    @ViewBuilder
    private var aiHubBar: some View {
        aiHubContent()
    }

    @ViewBuilder
    private func aiHubContent(inSheet: Bool = false) -> some View {
        AICommandBar(
            canvasManager: canvasManager,
            isGenerating: $isAIGenerating,
            onGenerate: { prompt in
                await generateWithAI(prompt: prompt)
            },
            selectedLabel: selectedComponentLabel(),
            quotaRemaining: aiService.lastQuotaRemaining,
            requiresSignIn: SupabaseManager.shared.client.auth.currentUser == nil
        )
        .frame(maxWidth: 400)
        .padding(.horizontal, 12)
        .padding(.bottom, inSheet ? 8 : 16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    #if os(iOS)
    @ViewBuilder
    private func sheetContent(for tab: AppTab) -> some View {
        switch tab {
        case .layers:                                                                    
            NavigationStack {
                VStack(spacing: 0) {
                    LayersPanelView(
                        canvasManager: canvasManager,
                        selectedComponent: $canvasManager.selectedComponent,
                        onLayerTapped: { _ in
                            showLayerPropertiesNavigation = true
                        },
                        showComponentLibrary: $showComponentLibrary,
                        componentLibraryMode: $componentLibraryMode,
                        onReplaceRequested: { component in
                            canvasManager.selectedComponent = component
                            componentLibraryMode = .replace
                            showComponentLibrary = true
                        }
                    )
                }
                // Background removed to allow material to show
                // .background(Color(uiColor: .systemBackground))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.3.layers.3d.top.filled")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                            Text("Layers")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            componentLibraryMode = .add
                            showComponentLibrary = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .navigationDestination(isPresented: $showLayerPropertiesNavigation) {
                    let panel = PropertiesPanelView(
                        selectedComponent: $canvasManager.selectedComponent,
                        canvasManager: canvasManager,
                        useNavigationStack: false,
                        showNavigationTitle: false,
                        showComponentActionsSection: UIDevice.current.userInterfaceIdiom != .phone
                    )
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        panel
                            .navigationTitle(propertiesSheetTitle)
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItemGroup(placement: .topBarTrailing) {
                                    Button {
                                        duplicateSelectedComponentFromPropertiesSheet()
                                    } label: {
                                        Label("Duplicate", systemImage: "doc.on.doc")
                                    }
                                    .disabled(!canPerformComponentToolbarActions)
                                    
                                    Button(role: .destructive) {
                                        deleteSelectedComponentFromPropertiesSheet()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    .disabled(!canPerformComponentToolbarActions)
                                }
                            }
                    } else {
                        panel.editorPanelStyle()
                    }
                }
            }
        }
    }
    #endif
    
    @ViewBuilder
    private var devicePresetsListSections: some View {
        devicePresetListSection(title: "iPhone", presets: DevicePreset.iphones)
        devicePresetListSection(title: "iPad", presets: DevicePreset.ipads)
        devicePresetListSection(title: "Widgets", presets: DevicePreset.widgets)
        devicePresetListSection(title: "Custom", presets: DevicePreset.custom)
    }

    private func devicePresetListSection(title: String, presets: [DevicePreset]) -> some View {
        Section(title) {
            ForEach(presets) { preset in
                devicePresetListRow(for: preset)
            }
        }
    }

    private func devicePresetListRow(for preset: DevicePreset) -> some View {
        Button {
            canvasManager.setDevicePreset(preset)
        } label: {
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


    @ToolbarContentBuilder
    private var toolbarButtons: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            layersToolbarToggleButton
        }

        ToolbarItemGroup(placement: .primaryAction) {
            devicePresetMenu
            colorSchemeMenu
            pageMenu
            undoToolbarButton
            redoToolbarButton
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            exportMenu
        }
    }

    private var layersToolbarToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showLayersPanel.toggle()
            }
        }) {
            Image(systemName: "sidebar.left")
        }
        .help(showLayersPanel ? "Hide Layers Panel" : "Show Layers Panel")
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
            animateRecenterCanvas()
        }) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("1", modifiers: .command)
        .help("Center Canvas")
    }
    
    private var undoToolbarButton: some View {
        Button(action: {
            handleCanvasUndo()
        }) {
            Image(systemName: "arrow.uturn.backward")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("z", modifiers: .command)
        .disabled(!(canvasManager.canUndo || !aiOperationUndoStack.isEmpty))
        .help("Undo")
    }
    
    private var redoToolbarButton: some View {
        Button(action: {
            handleCanvasRedo()
        }) {
            Image(systemName: "arrow.uturn.forward")
                .font(.system(size: 14, weight: .medium))
        }
        .keyboardShortcut("z", modifiers: [.command, .shift])
        .disabled(!(canvasManager.canRedo || !aiOperationRedoStack.isEmpty))
        .help("Redo")
    }
    
    private var exportMenu: some View {
        Menu {
            Button(action: { openCodePreviewSheet() }) {
                Label("View Code", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            
            Button(action: { saveAsScreenshot() }) {
                Label("Save as Screenshot", systemImage: "photo")
            }
            
            Divider()
            
            Button(action: { openCommunitySubmissionSheet() }) {
                Label("Share to Community", systemImage: "paperplane")
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
                toastManager.showCopyToast()
            }) {
                Label("Copy JSON", systemImage: "doc.on.clipboard")
            }
        } label: {
            #if os(macOS)
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .medium))
            #else
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 14, weight: .medium))
            #endif
        }
        .menuIndicator(.hidden)
        .help("Options")
    }
    
    private var canPerformComponentToolbarActions: Bool {
        guard let selected = canvasManager.selectedComponent else { return false }
        return selected.type != .statusBar
    }
    
    private func duplicateSelectedComponentFromPropertiesSheet() {
        guard canPerformComponentToolbarActions,
              let selected = canvasManager.selectedComponent else { return }
        canvasManager.duplicateComponent(selected)
    }
    
    private func deleteSelectedComponentFromPropertiesSheet() {
        guard canPerformComponentToolbarActions,
              let selected = canvasManager.selectedComponent else { return }
        canvasManager.removeComponent(selected)
        canvasManager.selectedComponent = nil
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
        let isWidget = canvasManager.devicePreset.category == .widget
        let screenshotView = CanvasScreenshotView(
            components: canvasManager.components,
            deviceSize: canvasManager.devicePreset.size,
            colorScheme: canvasManager.colorScheme ?? .light,
            statusBarVisible: isWidget ? false : canvasManager.statusBarVisible,
            statusBarTopSafeArea: isWidget ? false : canvasManager.statusBarTopSafeArea
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
                    toastManager.showToast(
                        ToastData(title: "Screenshot saved", icon: "checkmark.circle.fill")
                    )
                } catch {
                    debugLog("❌ Failed to save screenshot: \(error)")
                    toastManager.showToast(
                        ToastData(title: "Save failed", icon: "xmark.circle.fill")
                    )
                }
            }
        }
        #else
        // iOS: Save to Photos
        if let uiImage = UIImage(data: imageData) {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            toastManager.showToast(
                ToastData(title: "Saved to Photos", icon: "checkmark.circle.fill")
            )
        }
        #endif
    }
    
    private func setupCanvas() {
        // Initialize page index from design file
        currentPageIndex = designFile.currentPageIndex
        
        // Load components from current page
        canvasManager.components = designFile.components
        canvasManager.setDesignName(designFile.name)

        applyInitialCanvasViewIfReady()
        
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
            let isWidget = canvasManager.devicePreset.category == .widget
            let screenshotView = CanvasScreenshotView(
                components: canvasManager.components,
                deviceSize: canvasManager.devicePreset.size,
                colorScheme: canvasManager.colorScheme ?? .light,
                statusBarVisible: isWidget ? false : canvasManager.statusBarVisible,
                statusBarTopSafeArea: isWidget ? false : canvasManager.statusBarTopSafeArea
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
            canvasManager.statusBarVisible = designFile.statusBarVisible
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
        // Avoid per-change screenshot work here; undo/version handlers already drive snapshot updates.
        designFile.markAsChanged()
        NotificationCenter.default.post(name: .designChanged, object: nil)
    }
    
    private func syncSelection() {
        // Selection should not dirty the design file or trigger persistence/screenshot work.
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

    private enum LocalSelectionPromptAction {
        case duplicate
        case delete
    }

    private func localSelectionAction(for prompt: String) -> LocalSelectionPromptAction? {
        let lower = prompt.lowercased()
        if lower.range(of: #"\b(duplicate|copy|clone)\s+(this|selected|current)(\s+(component|layer|item|node|it))?\b"#, options: .regularExpression) != nil
            || lower.range(of: #"\b(duplicate|copy|clone)\s+(component|layer|item|node|it)\b"#, options: .regularExpression) != nil {
            return .duplicate
        }
        if lower.range(of: #"\b(delete|remove)\s+(this|selected|current)(\s+(component|layer|item|node|it))?\b"#, options: .regularExpression) != nil
            || lower.range(of: #"\b(delete|remove)\s+(component|layer|item|node|it)\b"#, options: .regularExpression) != nil {
            return .delete
        }
        return nil
    }

    private func generateWithAI(prompt: String) async {
        defer {
            Task { @MainActor in
                isAIGenerating = false
            }
        }

        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            toastManager.showToast(ToastData(title: "Describe your screen first", icon: "sparkles"))
            return
        }

        let selectedComponent = canvasManager.selectedComponent
        if let selectedComponent, let action = localSelectionAction(for: trimmed) {
            Task {
                await PromptLogManager.shared.logLocalPrompt(
                    trimmed,
                    selectedComponentType: selectedComponent.type.rawValue
                )
            }
            switch action {
            case .duplicate:
                canvasManager.duplicateComponent(selectedComponent)
                toastManager.showToast(ToastData(title: "Duplicated selected component", icon: "doc.on.doc"))
            case .delete:
                canvasManager.removeComponent(selectedComponent)
                canvasManager.selectedComponent = nil
                toastManager.showToast(ToastData(title: "Deleted selected component", icon: "trash"))
            }
            persistAIGeneratedPreview()
            return
        }
        let selectedJSON = canvasManager.getSelectedComponentJSON()
        let componentCount = selectedComponent != nil ? canvasManager.countComponents(in: selectedComponent!) : canvasManager.components.count
        let context: [String: AnyCodable] = [
            "devicePreset": AnyCodable(canvasManager.devicePreset.rawValue),
            "colorScheme": AnyCodable(canvasManager.colorScheme == .dark ? "dark" : (canvasManager.colorScheme == .light ? "light" : "system")),
            "componentCount": AnyCodable(componentCount),
            "selected_component_json": AnyCodable(selectedJSON ?? ""),
            "selected_component_type": AnyCodable(selectedComponent?.type.rawValue ?? ""),
            "selected_component": AnyCodable(selectedComponent?.type.rawValue ?? ""),
            "statusBarVisible": AnyCodable(canvasManager.statusBarVisible),
            "statusBarTopSafeArea": AnyCodable(canvasManager.statusBarTopSafeArea)
        ]

        do {
            let components = try await AIService.shared.generateComponents(prompt: trimmed, context: context)
            let operations = await MainActor.run {
                AIService.shared.consumeOperations()
            }
            let settingsApplied = await MainActor.run {
                applyAICanvasSettings()
            }
            if !components.isEmpty {
                await MainActor.run {
                    applyAIComponents(components, prompt: trimmed, operations: operations)
                }
            } else if !settingsApplied {
                toastManager.showToast(ToastData(title: "No components returned", icon: "exclamationmark.triangle"))
            }

        } catch {
            let message: String
            if let serviceError = error as? AIServiceError {
                switch serviceError {
                case .notAuthenticated:
                    message = "Sign in to use AI"
                case .missingSession:
                    message = "Session expired. Please sign in again."
                case .requestFailed(let detail):
                    message = detail
                case .invalidResponse:
                    message = "AI failed"
                case .emptyComponents:
                    message = "No components returned"
                }
            } else {
                let fallback = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                message = fallback.isEmpty ? "AI request failed" : fallback
            }
            print("AI generate error: \(message)")
            toastManager.showToast(ToastData(title: message, icon: "exclamationmark.triangle"))
        }
    }

    private func selectedComponentLabel() -> String? {
        guard let component = canvasManager.selectedComponent else { return nil }
        if component.type == .text {
            return "Text"
        }
        if let modifierType = component.modifierType {
            return modifierType.rawValue
        }
        switch component.type {
        case .text:
            let text = component.getProperty(key: "text") as? String ?? "Text"
            return text.isEmpty ? "Text" : text
        case .image:
            return "Image"
        default:
            return component.type.rawValue
        }
    }

    private func applyAIComponents(_ components: [UIComponent], prompt: String, operations: [AIEditOperation]? = nil) {
        guard !components.isEmpty else {
            toastManager.showToast(ToastData(title: "No components returned", icon: "exclamationmark.triangle"))
            return
        }

        let sanitizedComponents = sanitizeAIComponentsForDisplay(components, prompt: prompt)
        
        if handleAISelectedSingleComponent(prompt: prompt, operations: operations, sanitizedComponents: sanitizedComponents) {
            return
        }
        if handleAISelectedMultipleComponents(prompt: prompt, sanitizedComponents: sanitizedComponents) {
            return
        }
        if handleAINoSelectionSingleComponent(sanitizedComponents: sanitizedComponents) {
            return
        }

        canvasManager.registerUndoAction("AI Generate")
        clearAIOperationStacks()
        canvasManager.deselectAll()

        canvasManager.components = sanitizedComponents

        NotificationCenter.default.post(name: .designChanged, object: nil)
        persistAIGeneratedPreview()
        toastManager.showToast(ToastData(title: "AI generated components", icon: "sparkles"))
    }
    
    private func clearAIOperationStacks() {
        aiOperationUndoStack.removeAll()
        aiOperationRedoStack.removeAll()
    }
    
    private func handleAISelectedSingleComponent(
        prompt: String,
        operations: [AIEditOperation]?,
        sanitizedComponents: [UIComponent]
    ) -> Bool {
        guard let selected = canvasManager.selectedComponent, sanitizedComponents.count == 1 else { return false }
        
        let candidate: UIComponent
        var appliedAIEditOperations = false
        if let operations, !operations.isEmpty {
            do {
                let result = try AIOperationReducer.shared.applyWithInverse(to: selected, operations: operations)
                candidate = result.component
                appliedAIEditOperations = true
            } catch {
                print("AIOperationReducer failed: \(error.localizedDescription)")
                candidate = sanitizedComponents[0]
            }
        } else {
            candidate = sanitizedComponents[0]
        }
        
        if selected.type == .text && candidate.type == .text && !promptExplicitlyChangesText(prompt) {
            let existingText = selected.getProperty(key: "text") as? String ?? ""
            let newText = candidate.getProperty(key: "text") as? String ?? ""
            let isPlaceholder = newText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "text"
            if !existingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                (newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPlaceholder) {
                candidate.setProperty(key: "text", value: existingText)
            }
        }
        
        if let operations, !operations.isEmpty, appliedAIEditOperations {
            canvasManager.replaceComponent(selected, with: candidate, registerUndo: true, undoDescription: "AI Edit")
        } else {
            canvasManager.replaceComponent(selected, with: candidate)
        }
        clearAIOperationStacks()
        persistAIGeneratedPreview()
        toastManager.showToast(ToastData(title: "AI updated component", icon: "sparkles"))
        return true
    }
    
    private func handleAISelectedMultipleComponents(prompt: String, sanitizedComponents: [UIComponent]) -> Bool {
        guard let selected = canvasManager.selectedComponent, sanitizedComponents.count > 1 else { return false }
        guard let replacement = composeFilledSelectionReplacement(
            selected: selected,
            generated: sanitizedComponents,
            prompt: prompt
        ) else { return false }
        
        canvasManager.replaceComponent(selected, with: replacement, registerUndo: true, undoDescription: "AI Fill Selection")
        clearAIOperationStacks()
        persistAIGeneratedPreview()
        toastManager.showToast(ToastData(title: "AI filled selected component", icon: "sparkles"))
        return true
    }
    
    private func handleAINoSelectionSingleComponent(sanitizedComponents: [UIComponent]) -> Bool {
        guard canvasManager.selectedComponent == nil, sanitizedComponents.count == 1 else { return false }
        let candidate = sanitizedComponents[0]
        let isLikelyFullScreenRoot =
            (candidate.type == .stack || candidate.type == .vstack || candidate.type == .zstack || candidate.type == .scrollView) &&
            candidate.children.count >= 3
        
        if isLikelyFullScreenRoot {
            canvasManager.registerUndoAction("AI Generate Screen")
            clearAIOperationStacks()
            canvasManager.deselectAll()
            canvasManager.components = sanitizedComponents
            NotificationCenter.default.post(name: .designChanged, object: nil)
            persistAIGeneratedPreview()
            toastManager.showToast(ToastData(title: "AI generated screen", icon: "sparkles"))
        } else {
            clearAIOperationStacks()
            canvasManager.addComponent(candidate)
            persistAIGeneratedPreview()
            toastManager.showToast(ToastData(title: "AI added component", icon: "sparkles"))
        }
        return true
    }

    private func sanitizeAIComponentsForDisplay(_ components: [UIComponent], prompt: String) -> [UIComponent] {
        let clones = components.map { $0.clone() }
        for component in clones {
            sanitizeAIComponentTree(component)
        }
        return enforceStickyBottomCTAIfNeeded(clones, prompt: prompt)
    }

    private func sanitizeAIComponentTree(_ component: UIComponent) {
        if component.type == .text {
            let raw = (component.getProperty(key: "text") as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let sanitized = sanitizeInstructionalLabel(raw)
            if sanitized != raw {
                component.setProperty(key: "text", value: sanitized)
            }
        }
        for child in component.children {
            sanitizeAIComponentTree(child)
        }
    }

    private func sanitizeInstructionalLabel(_ text: String) -> String {
        guard !text.isEmpty else { return text }
        let lower = text.lowercased()

        if lower.contains("song cards with square artwork") { return "Songs" }
        if lower.contains("artist cards with square artwork") || lower.contains("circular profile/avatar items") { return "Artists" }
        if lower.contains("display curated mixes for the day") { return "Mixes" }
        if lower.contains("feature a horizontal rail of") && lower.contains("mix") { return "Mixes" }
        if lower.contains("prompt-lock") || lower.contains("must include") || lower.contains("rail spec") || lower.contains("horizontal rail of") {
            return "Featured"
        }
        return text
    }

    private func composeFilledSelectionReplacement(selected: UIComponent, generated: [UIComponent], prompt: String) -> UIComponent? {
        guard isCardLikeComponent(selected) else { return nil }

        let contentChildren = enrichedCardContent(from: generated, prompt: prompt)
        guard !contentChildren.isEmpty else { return nil }

        let background = selected.clone()
        background.children = []

        let contentStack = UIComponent(
            type: .stack,
            properties: UIComponent.defaultProperties(for: .stack),
            children: contentChildren.map { $0.clone() },
            modifiers: [
                ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Full"]),
                ComponentModifier(type: .padding, properties: ["location": "all", "amount": 16]),
            ]
        )
        contentStack.setProperty(key: "stackType", value: "vertical")
        contentStack.setProperty(key: "alignment", value: "leading")
        contentStack.setProperty(key: "spacing", value: 8.0)

        let wrapper = UIComponent(
            type: .stack,
            properties: UIComponent.defaultProperties(for: .stack),
            children: [background, contentStack],
            modifiers: selected.modifiers
        )
        wrapper.setProperty(key: "stackType", value: "z")
        wrapper.setProperty(key: "alignment", value: "topLeading")
        wrapper.setProperty(key: "spacing", value: 0.0)

        return wrapper
    }

    private func isCardLikeComponent(_ component: UIComponent) -> Bool {
        switch component.type {
        case .shape, .rectangle, .roundedRectangle, .capsule, .circle, .ellipse:
            return true
        default:
            return false
        }
    }

    private func enrichedCardContent(from generated: [UIComponent], prompt: String) -> [UIComponent] {
        let hasMeaningfulText = generated.contains { component in
            component.type == .text && !isPlaceholderText(component.getProperty(key: "text") as? String ?? "")
        }
        if hasMeaningfulText {
            return generated
        }
        return fallbackInfoComponents(for: prompt)
    }

    private func isPlaceholderText(_ text: String) -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty || normalized == "text" || normalized == "title" || normalized == "subtitle"
    }

    private func fallbackInfoComponents(for prompt: String) -> [UIComponent] {
        let lower = prompt.lowercased()
        let topic = inferredTopic(from: prompt)

        if lower.contains("nyc") || lower.contains("new york") {
            return [
                makeText("New York City", fontSize: "title3", weight: "bold"),
                makeText("Population: 8,804,190 (2020 Census)", fontSize: "subheadline", weight: "semibold"),
                makeText("Boroughs: Manhattan, Brooklyn, Queens, Bronx, Staten Island", fontSize: "caption", weight: "regular"),
                makeText("Known for: finance, media, arts, and iconic landmarks.", fontSize: "caption", weight: "regular")
            ]
        }

        return [
            makeText(topic, fontSize: "title3", weight: "bold"),
            makeText("Overview", fontSize: "subheadline", weight: "semibold"),
            makeText("Add key facts, highlights, and context here.", fontSize: "caption", weight: "regular")
        ]
    }

    private func inferredTopic(from prompt: String) -> String {
        let lower = prompt.lowercased()
        if let range = lower.range(of: "about ") {
            let start = prompt.index(prompt.startIndex, offsetBy: lower.distance(from: lower.startIndex, to: range.upperBound))
            let tail = String(prompt[start...]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !tail.isEmpty { return tail }
        }
        return "Card Details"
    }

    private func makeText(_ value: String, fontSize: String, weight: String) -> UIComponent {
        let component = UIComponent(
            type: .text,
            properties: [
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: value, defaultValue: value)
            ],
            modifiers: [
                ComponentModifier(type: .font, properties: ["fontSize": fontSize, "fontWeight": weight])
            ]
        )
        return component
    }

    private func enforceStickyBottomCTAIfNeeded(_ components: [UIComponent], prompt: String) -> [UIComponent] {
        guard promptRequestsStickyBottomCTA(prompt) else { return components }
        let expectedLabel = explicitCTALabelFromPrompt(prompt)
        return components.map { enforceStickyBottomCTAIfNeeded(in: $0, expectedLabel: expectedLabel) }
    }

    private func enforceStickyBottomCTAIfNeeded(in root: UIComponent, expectedLabel: String?) -> UIComponent {
        if root.type == .scrollView {
            if let promotedButton = removeFirstMatchingButton(from: &root.children, expectedLabel: expectedLabel) {
                return wrapScrollRootWithStickyCTA(scrollRoot: root, button: promotedButton)
            }
            return root
        }

        guard root.type == .stack || root.type == .vstack || root.type == .zstack else { return root }
        if hasFixedBottomCTA(in: root, expectedLabel: expectedLabel) {
            return root
        }

        guard let scrollIndex = root.children.firstIndex(where: { $0.type == .scrollView }) else {
            return root
        }

        let scrollComponent = root.children[scrollIndex]
        guard let promotedButton = removeFirstMatchingButton(from: &scrollComponent.children, expectedLabel: expectedLabel) else {
            return root
        }

        root.children.append(makeStickyBottomCTAContainer(button: promotedButton))
        return root
    }

    private func promptRequestsStickyBottomCTA(_ prompt: String) -> Bool {
        let p = prompt.lowercased()
        if p.contains("sticky bottom") || p.contains("bottom sticky") { return true }

        let mentionsBottom = p.contains("bottom")
        let mentionsCta = p.contains("cta") || p.contains("call to action") || p.contains("button")
        let mentionsPinned = p.contains("sticky") || p.contains("pinned") || p.contains("fixed")
        return (mentionsBottom && mentionsCta) || (mentionsBottom && mentionsPinned)
    }

    private func explicitCTALabelFromPrompt(_ prompt: String) -> String? {
        let pattern = #"[\"“”]([^\"“”]{1,80})[\"“”]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(prompt.startIndex..<prompt.endIndex, in: prompt)
        let matches = regex.matches(in: prompt, options: [], range: range)
        var candidates: [String] = []
        for match in matches {
            guard match.numberOfRanges > 1,
                  let textRange = Range(match.range(at: 1), in: prompt) else { continue }
            let candidate = prompt[textRange].trimmingCharacters(in: .whitespacesAndNewlines)
            if candidate.count >= 2 {
                candidates.append(candidate)
            }
        }
        guard !candidates.isEmpty else { return nil }
        let ctaTokens = ["begin", "start", "continue", "book", "checkout", "confirm", "submit", "save", "next", "go"]
        if let actionLike = candidates.first(where: { label in
            let normalized = normalizeLabel(label)
            return ctaTokens.contains { normalized.contains($0) }
        }) {
            return actionLike
        }
        return candidates.last
    }

    private func hasFixedBottomCTA(in root: UIComponent, expectedLabel: String?) -> Bool {
        for child in root.children where child.type != .scrollView {
            if containsMatchingButton(in: child, expectedLabel: expectedLabel) {
                return true
            }
        }
        return false
    }

    private func containsMatchingButton(in component: UIComponent, expectedLabel: String?) -> Bool {
        if isPrimaryCTAButton(component, expectedLabel: expectedLabel) {
            return true
        }
        for child in component.children {
            if containsMatchingButton(in: child, expectedLabel: expectedLabel) {
                return true
            }
        }
        return false
    }

    private func removeFirstMatchingButton(from children: inout [UIComponent], expectedLabel: String?) -> UIComponent? {
        var index = 0
        while index < children.count {
            let child = children[index]
            if isPrimaryCTAButton(child, expectedLabel: expectedLabel) {
                let matched = child.clone()
                children.remove(at: index)
                return matched
            }
            if let nestedMatch = removeFirstMatchingButton(from: &child.children, expectedLabel: expectedLabel) {
                return nestedMatch
            }
            index += 1
        }
        return nil
    }

    private func isPrimaryCTAButton(_ component: UIComponent, expectedLabel: String?) -> Bool {
        guard component.type == .button else { return false }
        let label = firstText(in: component)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !label.isEmpty else { return false }

        if let expectedLabel {
            if normalizeLabel(label) == normalizeLabel(expectedLabel) {
                return true
            }
        }

        let normalized = normalizeLabel(label)
        let ctaTokens = ["begin", "start", "continue", "book", "checkout", "confirm", "submit", "save", "next", "go"]
        return ctaTokens.contains { normalized.contains($0) }
    }

    private func firstText(in component: UIComponent) -> String? {
        if component.type == .text, let text = component.getProperty(key: "text") as? String {
            return text
        }
        for child in component.children {
            if let found = firstText(in: child) {
                return found
            }
        }
        return nil
    }

    private func normalizeLabel(_ value: String) -> String {
        let lowered = value.lowercased()
        let scalars = lowered.unicodeScalars.map { CharacterSet.alphanumerics.contains($0) ? Character($0) : " " }
        return String(scalars).replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func wrapScrollRootWithStickyCTA(scrollRoot: UIComponent, button: UIComponent) -> UIComponent {
        let wrapped = UIComponent(type: .stack, properties: UIComponent.defaultProperties(for: .stack), children: [
            scrollRoot,
            makeStickyBottomCTAContainer(button: button)
        ], modifiers: [
            ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Full"])
        ])
        wrapped.setProperty(key: "stackType", value: "vertical")
        wrapped.setProperty(key: "alignment", value: "leading")
        wrapped.setProperty(key: "spacing", value: 0.0)
        return wrapped
    }

    private func makeStickyBottomCTAContainer(button: UIComponent) -> UIComponent {
        let container = UIComponent(type: .stack, properties: UIComponent.defaultProperties(for: .stack), children: [
            button
        ], modifiers: [
            ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
            ComponentModifier(type: .padding, properties: ["location": "all", "amount": 16]),
        ])
        container.setProperty(key: "stackType", value: "vertical")
        container.setProperty(key: "alignment", value: "leading")
        container.setProperty(key: "spacing", value: 0.0)
        return container
    }

    private func promptExplicitlyChangesText(_ prompt: String) -> Bool {
        let p = prompt.lowercased()
        let patterns = [
            "\\bchange (?:the )?text\\b",
            "\\bchange what (?:it|this) says\\b",
            "\\bmake (?:the )?text say\\b",
            "\\bset (?:the )?text to\\b",
            "\\brename\\b",
            "\\bretitle\\b",
            "\\bupdate (?:the )?(?:title|label|copy|wording)\\b",
            "\\breplace (?:the )?text\\b",
            "\\btext should be\\b",
            "\\blabel should be\\b",
            "\\btitle should be\\b",
            "\\bsay\\b",
            "\\bwrite\\b"
        ]
        return patterns.contains { p.range(of: $0, options: .regularExpression) != nil }
    }

    private func persistAIGeneratedPreview() {
        captureScreenshot()
        let saveDelay = screenshotDebounceInterval + 0.25
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDelay) {
            designFile.save()
        }
    }

    private func applyAICanvasSettings() -> Bool {
        guard let settings = aiService.consumeCanvasSettings() else { return false }
        canvasManager.validateStatusBarProperties()
        var didChange = false

        if let visible = settings.statusBarVisible {
            canvasManager.statusBarVisible = visible
            canvasManager.statusBarComponent?.isVisible = visible
            NotificationCenter.default.post(name: .statusBarVisibilityChanged, object: visible)
            designFile.statusBarVisible = visible
            designFile.currentPage?.statusBarVisible = visible
            didChange = true
        }

        if let safeArea = settings.statusBarTopSafeArea {
            canvasManager.statusBarTopSafeArea = safeArea
            designFile.statusBarTopSafeArea = safeArea
            designFile.currentPage?.statusBarTopSafeArea = safeArea
            didChange = true
        }

        if let scheme = settings.canvasColorScheme {
            let normalizedScheme = scheme.lowercased()
            if normalizedScheme == "light" {
                canvasManager.colorScheme = .light
                designFile.canvasColorScheme = "light"
                didChange = true
            } else if normalizedScheme == "dark" {
                canvasManager.colorScheme = .dark
                designFile.canvasColorScheme = "dark"
                didChange = true
            }
        }

        if didChange {
            designFile.currentPage?.statusBarComponent = canvasManager.statusBarComponent?.clone()
            designFile.markAsChanged()
            NotificationCenter.default.post(name: .designChanged, object: nil)
            toastManager.showToast(ToastData(title: "Canvas settings updated", icon: "sparkles"))
        }
        return didChange
    }


    private func hydrateAIImages(query: String) async {
        let imageComponents = collectImageComponents(from: canvasManager.components)
        guard !imageComponents.isEmpty else { return }

        let baseQuery = buildImageQuery(from: query)
        var pool = (try? await UnsplashService.shared.searchPhotos(query: baseQuery)) ?? []
        if pool.isEmpty {
            pool = (try? await UnsplashService.shared.listPhotos()) ?? []
        }
        guard !pool.isEmpty else { return }

        for component in imageComponents {
            let imageName = component.getProperty(key: "imageName") as? String ?? ""
            let imageData = component.getProperty(key: "imageData") as? String ?? ""
            if !imageName.isEmpty || !imageData.isEmpty {
                continue
            }

            let photo = pool.randomElement()
            guard let selected = photo else { continue }
            if let index = pool.firstIndex(where: { $0.id == selected.id }) {
                pool.remove(at: index)
            }

            do {
                let data = try await UnsplashService.shared.downloadImage(from: selected.urls.regular)
                if let filename = ImageGalleryManager.shared.saveImage(data: data) {
                    await MainActor.run {
                        component.setProperty(key: "imageName", value: filename)
                        component.setProperty(key: "imageData", value: "")
                    }
                    await UnsplashService.shared.triggerDownload(photo: selected)
                }
            } catch {
                continue
            }
        }
    }

    private func collectImageComponents(from components: [UIComponent]) -> [UIComponent] {
        var results: [UIComponent] = []
        for component in components {
            if component.type == .image {
                results.append(component)
            }
            if !component.children.isEmpty {
                results.append(contentsOf: collectImageComponents(from: component.children))
            }
        }
        return results
    }

    private func buildImageQuery(from prompt: String) -> String {
        let words = prompt
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let keywords = words.prefix(4).joined(separator: " ")
        return keywords.isEmpty ? "abstract" : keywords
    }

    private func captureScreenshot() {
        // Update request time to now
        lastScreenshotRequestTime = Date()

        // Keep only the latest scheduled capture to avoid piling up delayed blocks.
        screenshotCaptureWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            guard Date().timeIntervalSince(self.lastScreenshotRequestTime) >= self.screenshotDebounceInterval - 0.1 else {
                return
            }
            self.performScreenshotCapture()
        }
        screenshotCaptureWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + screenshotDebounceInterval, execute: workItem)
    }
    
    private func performScreenshotCapture() {
        let isWidget = self.canvasManager.devicePreset.category == .widget
        let screenshotView = CanvasScreenshotView(
            components: self.canvasManager.components,
            deviceSize: self.canvasManager.devicePreset.size,
            colorScheme: self.canvasManager.colorScheme ?? .light,
            statusBarVisible: isWidget ? false : self.canvasManager.statusBarVisible,
            statusBarTopSafeArea: isWidget ? false : self.canvasManager.statusBarTopSafeArea
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
        ComponentRenderer(
            component: component,
            deviceSize: selectedDevice.isContentAdaptive ? nil : selectedDevice.size,
            colorScheme: colorScheme,
            onTap: onSelect,
            onSelectChild: onSelectChild,
            selectedComponentIds: selectedComponentIds,
            canvasManager: canvasManager
        )

            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: component.frame)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: component.isVisible)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
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

extension View {
    func editorPanelStyle() -> some View {
        modifier(EditorPanelStyle())
    }
}

private struct PageMenuView: View {
    let pages: [DesignPage]
    let currentPageIndex: Int
    let onSelectPage: (Int) -> Void
    let onAddPage: () -> Void
    let onDuplicatePage: () -> Void
    let onRenamePage: () -> Void
    let onDeletePage: () -> Void

    var body: some View {
        Menu {
            pageSection
            Divider()
            menuActions
        } label: {
            menuLabel
        }
    }

    private var pageSection: some View {
        Section("Pages") {
            ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                PageMenuRow(
                    index: index,
                    page: page,
                    isSelected: index == currentPageIndex,
                    onSelectPage: onSelectPage
                )
            }
        }
    }

    @ViewBuilder
    private var menuActions: some View {
        Button(action: onAddPage) {
            Label("Add Page", systemImage: "plus")
        }

        Button(action: onDuplicatePage) {
            Label("Duplicate Page", systemImage: "doc.on.doc")
        }

        Button(action: onRenamePage) {
            Label("Rename Page", systemImage: "pencil")
        }

        Button(role: .destructive, action: onDeletePage) {
            Label("Delete Page", systemImage: "trash")
        }
        .disabled(currentPageIndex == 0)
    }

    private var menuLabel: some View {
        HStack(spacing: 4) {
            Text("Pages")
                .tint(.primary)
            #if os(iOS)
            Image(systemName: "chevron.up.chevron.down")
                .tint(.secondary)
                .font(.caption)
            #endif
        }
        .bold()
    }
}

private struct PageMenuRow: View {
    let index: Int
    let page: DesignPage
    let isSelected: Bool
    let onSelectPage: (Int) -> Void

    var body: some View {
        Button {
            onSelectPage(index)
        } label: {
            HStack {
                Text(page.name)
                if isSelected {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

private struct PagePreviewCard: View {
    let index: Int
    let page: DesignPage
    let isSelected: Bool
    let phoneAspectRatio: CGFloat
    let phonePreviewWidth: CGFloat
    @Binding var renamingPageId: UUID?
    @Binding var renameText: String
    var onSelectPage: (Int) -> Void
    var onDuplicatePage: (Int) -> Void
    var onRenamePage: (Int, String) -> Void
    var onDeletePage: (Int) -> Void

    private var previewHeight: CGFloat {
        phonePreviewWidth / phoneAspectRatio
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnailPreview
            titleEditor
        }
        .padding(12)
        .background(cardBackground)
        .overlay(cardBorder)
        .contentShape(Rectangle())
        .onTapGesture { onSelectPage(index) }
        .contextMenu { contextMenuContent }
    }

    @ViewBuilder
    private var thumbnailPreview: some View {
        Group {
            if let thumbnail = page.thumbnail,
               let image = thumbnailImage(from: thumbnail) {
                image
                    .resizable()
                    .aspectRatio(phoneAspectRatio, contentMode: .fill)
                    .frame(width: phonePreviewWidth, height: previewHeight)
                    .clipped()
            } else {
                placeholderPreview
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(thumbnailBorder)
    }

    private var placeholderPreview: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.primary.opacity(0.06))
            .frame(width: phonePreviewWidth, height: previewHeight)
            .overlay(Image(systemName: "doc").foregroundColor(.secondary))
    }

    @ViewBuilder
    private var titleEditor: some View {
        if renamingPageId == page.id {
            TextField("Page Name", text: $renameText, onCommit: commitRename)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
        } else {
            Text(page.name)
                .font(.subheadline.weight(isSelected ? .bold : .regular))
                .lineLimit(1)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08))
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
    }

    private var thumbnailBorder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.primary.opacity(0.14), lineWidth: 1)
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Rename", action: beginRename)
        Button("Duplicate") {
            onDuplicatePage(index)
        }
        if index > 0 {
            Divider()
            Button("Delete", role: .destructive) {
                onDeletePage(index)
            }
        }
    }

    private func beginRename() {
        renamingPageId = page.id
        renameText = page.name
    }

    private func commitRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            onRenamePage(index, trimmed)
        }
        renamingPageId = nil
    }

    private func thumbnailImage(from data: Data) -> Image? {
        #if os(macOS)
        if let nsImage = NSImage(data: data) { return Image(nsImage: nsImage) }
        #else
        if let uiImage = UIImage(data: data) { return Image(uiImage: uiImage) }
        #endif
        return nil
    }
}
