//
//  UIBuilderView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

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
    @StateObject private var canvasManager = CanvasManager()
    @State private var selectedComponent: UIComponent?
    @State private var showCodePreview = false
    @State private var showLayersPanel = true
    @State private var showPropertiesPanel = true
    @State private var selectedDevice: DevicePreset = .iphone16Pro
    @State private var baseZoomLevel: CGFloat = 1.0
    
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Component Library Panel
                ComponentLibraryView(selectedComponent: $selectedComponent, canvasManager: canvasManager)
                    .frame(width: 280)
                    .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Main Canvas Area
                VStack(spacing: 0) {
                    // Toolbar
                    UIBuilderToolbar(
                        showCodePreview: $showCodePreview,
                        showLayersPanel: $showLayersPanel,
                        showPropertiesPanel: $showPropertiesPanel,
                        canvasManager: canvasManager,
                        selectedDevice: $selectedDevice
                    )
                    
                    Divider()
                    
                    HStack(spacing: 0) {
                        // Canvas
                        CanvasView(
                            canvasManager: canvasManager,
                            selectedComponent: $selectedComponent,
                            selectedDevice: selectedDevice,
                            baseZoomLevel: $baseZoomLevel
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
                        
                        // Right Panels
                        if showLayersPanel || showPropertiesPanel {
                            Divider()
                            
                            VStack(spacing: 0) {
                                if showLayersPanel {
                                    LayersPanelView(
                                        canvasManager: canvasManager,
                                        selectedComponent: $selectedComponent
                                    )
                                    .frame(height: 200)
                                    
                                    if showPropertiesPanel {
                                        Divider()
                                    }
                                }
                                
                                if showPropertiesPanel {
                                    PropertiesPanelView(
                                        selectedComponent: $selectedComponent,
                                        canvasManager: canvasManager
                                    )
                                    .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 300)
                            .background(Color(NSColor.controlBackgroundColor))
                        }
                    }
                }
            }
        }
        .navigationTitle("SwiftUI Builder")
        .sheet(isPresented: $showCodePreview) {
            CodePreviewView(canvasManager: canvasManager)
        }
    }
}

// MARK: - Toolbar
struct UIBuilderToolbar: View {
    @Binding var showCodePreview: Bool
    @Binding var showLayersPanel: Bool
    @Binding var showPropertiesPanel: Bool
    let canvasManager: CanvasManager
    @Binding var selectedDevice: DevicePreset
    
    var body: some View {
        HStack {
            // Left side - View controls
            HStack(spacing: 12) {
                Divider()
                    .frame(height: 20)
                
                Button(action: { canvasManager.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!canvasManager.canUndo)
                .help("Undo")
                
                Button(action: { canvasManager.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!canvasManager.canRedo)
                .help("Redo")
            }
            
            Spacer()
            
            // Center - Device picker and Canvas controls
            HStack(spacing: 12) {
                Menu {
                    ForEach(DevicePreset.allCases) { preset in
                        Button(preset.rawValue) {
                            selectedDevice = preset
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedDevice.rawValue)
                    }
                }
                .frame(minWidth: 150)
                .help("Choose a device preset")
                
                Divider()
                    .frame(height: 20)
                
                Button(action: { 
                    // Reset to optimal zoom for current device
                    canvasManager.zoomToFitDevice(selectedDevice.size, canvasSize: CGSize(width: 800, height: 600))
                }) {
                    Image(systemName: "1.magnifyingglass")
                }
                .help("Reset Zoom")
                
            }
            
            Spacer()
            
            // Right side - Export and preview
            HStack(spacing: 12) {
                Button(action: { showCodePreview = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                        Text("Code")
                    }
                }
                .help("Show Generated Code")
                
                Button(action: { canvasManager.exportCodeToFile() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Export")
                    }
                }
                .help("Export SwiftUI Code")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Canvas View
struct CanvasView: View {
    @ObservedObject var canvasManager: CanvasManager
    @Binding var selectedComponent: UIComponent?
    let selectedDevice: DevicePreset
    @Binding var baseZoomLevel: CGFloat
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
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
                        // Device frame background
                        RoundedRectangle(cornerRadius: screenCorner, style: .continuous)
                            .fill(Color.black.opacity(0.8))
                            .overlay(
                                RoundedRectangle(cornerRadius: screenCorner, style: .continuous)
                                    .stroke(Color.gray.opacity(0.6), lineWidth: 1)
                            )
                            .shadow(radius: 12)
                        
                        // Screen area
                        ZStack {
                            Rectangle()
                                .fill(Color(NSColor.windowBackgroundColor))
                                .overlay(Color.white.opacity(0.02))
                            
                            // Status bar (only for phones)
                            if selectedDevice != .mac {
                                StatusBarView(deviceSize: deviceSize)
                                    .zIndex(1000) // Ensure status bar is on top
                            }
                            
                            // Components inside screen
                            ZStack {
                                ForEach(canvasManager.components) { component in
                                    ComponentView(
                                        component: component,
                                        isSelected: selectedComponent?.id == component.id,
                                        onSelect: { selectedComponent = component },
                                        onMove: { offset in
                                            canvasManager.moveComponent(component, by: offset)
                                        },
                                        onResize: { newFrame in
                                            canvasManager.resizeComponent(component, to: newFrame)
                                        }
                                    )
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: screenCorner - 4, style: .continuous))
                        .padding(selectedDevice == .mac ? 8 : 16)
                    }
                    .frame(width: deviceSize.width, height: deviceSize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Drop zone overlay (full canvas)
                    if isDragging {
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, dash: [5]))
                            )
                            .overlay(
                                Text("Drop component here")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                            )
                    }
                }
                .scaleEffect(canvasManager.zoomLevel)
                .offset(canvasManager.canvasOffset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                            }
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            isDragging = false
                            dragOffset = .zero
                        }
                )
                
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
            }
        }
    }
}

struct ComponentView: View {
    @ObservedObject var component: UIComponent
    let isSelected: Bool
    let onSelect: () -> Void
    let onMove: (CGSize) -> Void
    let onResize: (CGRect) -> Void
    
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Component content
            ComponentRenderer(component: component)
                .frame(width: component.frame.width, height: component.frame.height)
                .position(x: component.frame.midX, y: component.frame.midY)
                .onTapGesture {
                    onSelect()
                }
            
            // Selection overlay
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: component.frame.width, height: component.frame.height)
                    .position(x: component.frame.midX, y: component.frame.midY)
                
                // Resize handles
                ForEach(0..<8) { index in
                    ResizeHandle(
                        position: handlePosition(for: index),
                        onDrag: { offset in
                            handleResize(handleIndex: index, offset: offset)
                        }
                    )
                }
            }
        }
        .highPriorityGesture(
            DragGesture()
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    onMove(dragOffset)
                    isDragging = false
                    dragOffset = .zero
                }
        )
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
    
    private func handleResize(handleIndex: Int, offset: CGSize) {
        var newFrame = component.frame
        
        switch handleIndex {
        case 0: // Top-left
            newFrame.origin.x += offset.width
            newFrame.origin.y += offset.height
            newFrame.size.width -= offset.width
            newFrame.size.height -= offset.height
        case 1: // Top-center
            newFrame.origin.y += offset.height
            newFrame.size.height -= offset.height
        case 2: // Top-right
            newFrame.origin.y += offset.height
            newFrame.size.width += offset.width
            newFrame.size.height -= offset.height
        case 3: // Right-center
            newFrame.size.width += offset.width
        case 4: // Bottom-right
            newFrame.size.width += offset.width
            newFrame.size.height += offset.height
        case 5: // Bottom-center
            newFrame.size.height += offset.height
        case 6: // Bottom-left
            newFrame.origin.x += offset.width
            newFrame.size.width -= offset.width
            newFrame.size.height += offset.height
        case 7: // Left-center
            newFrame.origin.x += offset.width
            newFrame.size.width -= offset.width
        default:
            break
        }
        
        onResize(newFrame)
    }
}

struct ResizeHandle: View {
    let position: CGPoint
    let onDrag: (CGSize) -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 8, height: 8)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        onDrag(dragOffset)
                        dragOffset = .zero
                    }
            )
    }
}

struct StatusBarView: View {
    let deviceSize: CGSize
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
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
        VStack() {
            HStack {
                // Left side - Time
                Text(timeString)
                    .font(.system(size: 16, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Right side - Status indicators
                HStack(spacing: 4) {
                    // Signal bars - aligned to bottom
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(height: 12, alignment: .bottom)
                    
                    // WiFi icon - aligned to bottom
                    Image(systemName: "wifi")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(height: 12, alignment: .bottom)
                    
                    // Battery - aligned to bottom
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.primary)
                            .frame(width: 20, height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.primary)
                                    .frame(width: 2, height: 4)
                                    .offset(x: 11)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.green)
                                    .frame(width: 16, height: 6)
                                    .offset(x: -1)
                            )
                    }
                    .frame(height: 12, alignment: .bottom) // Fixed height with bottom alignment
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(Color.black.opacity(0.05))
                    .overlay(
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: statusBarHeight) // Full width of container
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}

#Preview {
    UIBuilderView()
}
