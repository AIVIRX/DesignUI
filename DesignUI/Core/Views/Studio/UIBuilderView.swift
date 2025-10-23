//
//  UIBuilderView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
extension Notification.Name {
    static let canvasUndo = Notification.Name("canvas.undo")
    static let canvasRedo = Notification.Name("canvas.redo")
    static let designChanged = Notification.Name("design.changed")
}
#endif
#if os(macOS)
enum DevicePreset: String, CaseIterable, Identifiable {
    // iPhone 16 Series (Latest)
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
        // iPhone 16 Series - Based on actual viewport dimensions (Latest)
        case .iphone16: return CGSize(width: 393, height: 852) // 6.1" display
        case .iphone16Plus: return CGSize(width: 430, height: 932) // 6.7" display
        case .iphone16Pro: return CGSize(width: 402, height: 874) // 6.3" display
        case .iphone16ProMax: return CGSize(width: 440, height: 956) // 6.9" display
        
        // iPhone 15 Series - Based on actual viewport dimensions
        case .iphone15Pro: return CGSize(width: 393, height: 852) // 6.1" display
        case .iphone15ProMax: return CGSize(width: 430, height: 932) // 6.7" display
        case .iphone15: return CGSize(width: 393, height: 852) // 6.1" display
        case .iphone15Plus: return CGSize(width: 430, height: 932) // 6.7" display
        
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
    @State private var selectedComponent: UIComponent?
    @State private var showCodePreview = false
    @State private var showPropertiesPanel = true
    @State private var selectedDevice: DevicePreset = .iphone16Pro
    @State private var baseZoomLevel: CGFloat = 1.0
    @State private var statusBarHasBackground: Bool = false
    
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Layers Panel (moved from right side)
                LayersPanelView(
                    canvasManager: canvasManager,
                    selectedComponent: $selectedComponent
                )
                .frame(width: 320)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Main Canvas Area
                VStack(spacing: 0) {                    
                    ZStack {
                        HStack(spacing: 0) {
                        // Canvas
                        CanvasView(
                            canvasManager: canvasManager,
                            selectedComponent: $selectedComponent,
                            selectedDevice: selectedDevice,
                            baseZoomLevel: $baseZoomLevel,
                            statusBarHasBackground: $statusBarHasBackground
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped() // Ensure canvas content doesn't overflow
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let newZoom = baseZoomLevel * value
                                    // Limit maximum zoom to prevent UI overlap
                                    let limitedZoom = min(newZoom, 3.0)
                                    canvasManager.setZoomLevel(limitedZoom)
                                }
                                .onEnded { value in
                                    baseZoomLevel = canvasManager.zoomLevel
                                }
                        )
                        
                        // Right Panels (now only Properties Panel)
                        if showPropertiesPanel {
                            Divider()
                            
                            PropertiesPanelView(
                                selectedComponent: $selectedComponent,
                                canvasManager: canvasManager
                            )
                            .frame(width: 280)
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                        }
                        
                        // Bottom right overlay controls
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                CanvasControlsOverlay(
                                    selectedDevice: $selectedDevice,
                                    canvasManager: canvasManager,
                                    baseZoomLevel: $baseZoomLevel,
                                    statusBarHasBackground: $statusBarHasBackground
                                )
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("SwiftUI Builder")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 8) {
                    Button(action: { 
                        print("💾 Manual save button pressed")
                        designManager.saveCurrentDesign()
                        print("💾 Manual save triggered")
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .help("Save Design")
                    
                    Button(action: { showCodePreview = true }) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .help("Show Code")
                }
            }
        }
        .sheet(isPresented: $showCodePreview) {
            CodePreviewView(canvasManager: canvasManager)
        }
        .onAppear {
            // Load components from design file
            canvasManager.components = designFile.components
            // Set the design name for code generation
            canvasManager.setDesignName(designFile.name)
        }
        .onChange(of: canvasManager.components) { _, _ in
            print("🔄 Components changed - syncing to design file")
            print("🔄 Components count: \(canvasManager.components.count)")
            // Sync components to design file
            designFile.components = canvasManager.components
            // Mark as changed and trigger auto-save
            designManager.markAsChanged()
            // Post notification for document editor
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        .onChange(of: selectedComponent) { _, _ in
            print("🔄 Selection changed - syncing to design file")
            // Sync components to design file when selection changes
            designFile.components = canvasManager.components
            designManager.markAsChanged()
            // Post notification for document editor
            NotificationCenter.default.post(name: .designChanged, object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasUndo)) { _ in
            canvasManager.undo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .canvasRedo)) { _ in
            canvasManager.redo()
        }
        .onReceive(NotificationCenter.default.publisher(for: .designChanged)) { _ in
            print("🔄 Design changed notification received - syncing components")
            // Sync components to design file
            designFile.components = canvasManager.components
            // Mark as changed and trigger auto-save
            designManager.markAsChanged()
        }
    }
}



// MARK: - Canvas Controls Overlay
struct CanvasControlsOverlay: View {
    @Binding var selectedDevice: DevicePreset
    let canvasManager: CanvasManager
    @Binding var baseZoomLevel: CGFloat
    @Binding var statusBarHasBackground: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Device picker
            Menu {
                ForEach(DevicePreset.allCases) { preset in
                    Button(preset.rawValue) {
                        selectedDevice = preset
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "iphone")
                        .font(.system(size: 12))
                    Text(selectedDevice.rawValue)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .help("Choose a device preset")
            
            // Status bar background toggle
            Button(action: { 
                statusBarHasBackground.toggle()
            }) {
                Image(systemName: statusBarHasBackground ? "rectangle.fill" : "rectangle")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .help(statusBarHasBackground ? "Hide Status Bar Background" : "Show Status Bar Background")
            
            // Reset zoom button
            Button(action: { 
                // Reset to optimal zoom for current device
                canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: CGSize(width: 800, height: 600))
                // Update baseZoomLevel to match the reset zoom level
                baseZoomLevel = canvasManager.zoomLevel
            }) {
                Image(systemName: "1.magnifyingglass")
                    .font(.system(size: 12))
            }
            .buttonStyle(.bordered)
            .help("Reset Zoom")
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.trailing, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    @Binding var baseZoomLevel: CGFloat
    @Binding var statusBarHasBackground: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Static grid background - doesn't zoom with canvas
                Rectangle()
                    .fill(Color(NSColor.textBackgroundColor))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        // Static grid pattern - fixed reference
                        Canvas { context, size in
                            let gridSize: CGFloat = 20
                            let maxLines = max(Int(size.width / gridSize), Int(size.height / gridSize)) + 10
                            
                            for i in 0..<maxLines {
                                // Vertical lines - extend beyond visible area
                                let x = CGFloat(i) * gridSize
                                context.stroke(
                                    Path(CGRect(x: x, y: -100, width: 0, height: size.height + 200)),
                                    with: .color(.gray.opacity(0.2)),
                                    lineWidth: 0.5
                                )
                                
                                // Horizontal lines - extend beyond visible area
                                let y = CGFloat(i) * gridSize
                                context.stroke(
                                    Path(CGRect(x: -100, y: y, width: size.width + 200, height: 0)),
                                    with: .color(.gray.opacity(0.2)),
                                    lineWidth: 0.5
                                )
                            }
                        }
                    )
                
                // Zoomable canvas content
                ZStack {
                    // Centered device frame
                    let deviceSize = selectedDevice.size
                    let screenCorner: CGFloat = selectedDevice == .mac ? 8 : 50
                    
                    ZStack {
                        // Screen area
                        ZStack {
                            Rectangle()
                                .fill(Color(NSColor.windowBackgroundColor))
                                .overlay(Color.white.opacity(0.02))
                            
                            // Components inside screen
                            VStack(spacing: 0) {
                                ForEach(canvasManager.components, id: \.id) { component in
                                    ComponentView(
                                        component: component,
                                        isSelected: selectedComponent?.id == component.id,
                                        onSelect: { selectedComponent = component },
                                        selectedDevice: selectedDevice,
                                        selectedComponent: selectedComponent,
                                        onSelectChild: { childComponent in
                                            // Find the component in the hierarchy and select it
                                            if let foundComponent = findComponentInHierarchy(componentId: childComponent.id, in: canvasManager.components) {
                                                selectedComponent = foundComponent
                                            }
                                        }
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, selectedDevice != .mac && !statusBarHasBackground ? 53 : 0) // Safe area for status bar
                            .clipped() // Prevent content from expanding beyond the screen bounds
                            .onTapGesture {
                                // Deselect when clicking empty space
                                selectedComponent = nil
                            }
                            if selectedDevice != .mac {
                                VStack {
                                    StatusBarView(
                                        deviceSize: deviceSize,
                                        isSelected: selectedComponent?.id == canvasManager.statusBarComponent?.id,
                                        onSelect: { 
                                            if let statusBarComponent = canvasManager.statusBarComponent {
                                                selectedComponent = statusBarComponent
                                            }
                                        }
                                    )
                                    .background(statusBarHasBackground ? Color.black.opacity(0.8) : .clear)
                                    .zIndex(1000) // Ensure status bar is on top
                                    
                                    Spacer()
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: screenCorner, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: screenCorner, style: .continuous)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .padding(selectedDevice == .mac ? 8 : 16)
                    }
                    .frame(width: deviceSize.width, height: deviceSize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .scaleEffect(canvasManager.zoomLevel)
                .offset(canvasManager.canvasOffset)
            }
        }
        .clipped()
        .onAppear {
            // Set optimal zoom when canvas appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: CGSize(width: 800, height: 600))
                // Update base zoom level to the initial optimal level
                baseZoomLevel = canvasManager.zoomLevel
            }
        }
        .onChange(of: selectedDevice) {
            // Update zoom when device changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: CGSize(width: 800, height: 600))
                // Update base zoom level to the new device's optimal level
                baseZoomLevel = canvasManager.zoomLevel
                
                // Update status bar component frame for new device
                if let statusBarComponent = canvasManager.statusBarComponent {
                    statusBarComponent.frame = CGRect(x: 0, y: 0, width: selectedDevice.size.width, height: 53)
                }
            }
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

struct ComponentView: View {
    @ObservedObject var component: UIComponent
    let isSelected: Bool
    let onSelect: () -> Void
    let selectedDevice: DevicePreset
    let selectedComponent: UIComponent?
    let onSelectChild: ((UIComponent) -> Void)?
    @State private var isHovered: Bool = false
    
    init(component: UIComponent, isSelected: Bool, onSelect: @escaping () -> Void, selectedDevice: DevicePreset, selectedComponent: UIComponent?, onSelectChild: ((UIComponent) -> Void)? = nil) {
        self.component = component
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.selectedDevice = selectedDevice
        self.selectedComponent = selectedComponent
        self.onSelectChild = onSelectChild
    }
    
    var body: some View {
        ComponentRenderer(component: component, deviceSize: selectedDevice.size, onTap: onSelect, onSelectChild: onSelectChild, selectedComponent: selectedComponent)
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

struct StatusBarView: View {
    let deviceSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }
    
    private var statusBarHeight: CGFloat {
        // Status bar height varies by device
        if deviceSize.height > 1000 { // iPad
            return 24
        } else if deviceSize.height > 800 { // iPhone Plus/Max
            return 44
        } else { // Regular iPhone
            return 44
        }
    }
    
    var body: some View {
        ZStack {
            HStack {
                // Left side - Time
                Text(timeString)
                    .font(.system(size: 15, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                    .frame(width: 109)

                Spacer()
                
                // Right side - Status indicators
                HStack(spacing: 5) {
                    // Signal bars - aligned to bottom
                    Image(systemName: "cellularbars")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // WiFi icon - aligned to bottom
                    Image(systemName: "wifi")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    // Battery - aligned to bottom
                    Image(systemName: "battery.100")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(width: 109)
            }
            .frame(height: 53)
            .padding(.horizontal)
            .padding(.top, 5)
            .background(.clear)
            .frame(maxWidth: .infinity)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            
            // Selection overlay
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(height: 53)
                    .padding(.horizontal)
                    .padding(.top, 5)
            }
        }
    }
}
#endif
