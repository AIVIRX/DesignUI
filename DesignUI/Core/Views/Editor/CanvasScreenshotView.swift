//
//  CanvasScreenshotView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct CanvasScreenshotView: View {
    let components: [UIComponent]
    let deviceSize: CGSize
    let colorScheme: ColorScheme
    let statusBarComponent: UIComponent?
    let statusBarHasBackground: Bool
    
    /// Whether this is a content-adaptive (No Size) screenshot
    var isContentAdaptive: Bool {
        deviceSize.width == 0 && deviceSize.height == 0
    }
    
    var body: some View {
        if isContentAdaptive {
            // Content-adaptive mode: wrap tightly around content
            contentAdaptiveBody
        } else {
            // Fixed device size mode
            fixedSizeBody
        }
    }
    
    // MARK: - Content Adaptive Body (No Size mode)
    private var contentAdaptiveBody: some View {
        // No Size mode: just show content, no visible canvas
        VStack(spacing: 0) {
            ForEach(components, id: \.id) { component in
                ComponentRenderer(
                    component: component,
                    deviceSize: nil, // Pass nil to indicate content-adaptive mode
                    colorScheme: colorScheme,
                    onTap: nil,
                    onSelectChild: nil,
                    selectedComponentIds: []
                )
            }
        }
        .colorScheme(colorScheme)
    }
    
    // MARK: - Fixed Size Body (Device presets)
    private var fixedSizeBody: some View {
        ZStack {
            // Device background
            let deviceBackgroundColor: Color = {
                if colorScheme == .light {
                    return Color.white
                } else {
                    return Color.black
                }
            }()
            
            Rectangle()
                .fill(deviceBackgroundColor)
            
            // Components inside screen
            VStack(spacing: 0) {
                ForEach(components, id: \.id) { component in
                    ComponentRenderer(
                        component: component,
                        deviceSize: deviceSize,
                        colorScheme: colorScheme,
                        onTap: nil,
                        onSelectChild: nil,
                        selectedComponentIds: []
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, (statusBarComponent?.isVisible ?? false) && !statusBarHasBackground ? 50 : 0) // Safe area for status bar
            
            // Status bar if needed and visible
            if let statusBarComponent = statusBarComponent, statusBarComponent.isVisible {
                VStack {
                    StatusBarView(
                        deviceSize: deviceSize,
                        isSelected: false,
                        colorScheme: colorScheme,
                        onSelect: {}
                    )
                    .background(.clear)
                    
                    Spacer()
                }
            }
        }
        .frame(width: deviceSize.width, height: deviceSize.height)
        .colorScheme(colorScheme)
    }
    
    struct StatusBarView: View {
        let deviceSize: CGSize
        let isSelected: Bool
        let colorScheme: ColorScheme?
        let onSelect: () -> Void
        
        private var statusBarHeight: CGFloat {
            return 50.0
        }
        
        private var statusBarTextColor: Color {
            if colorScheme == .light {
                return .black
            } else {
                return .white
            }
        }
        
        var body: some View {
            HStack {
                // Left side - Time
                Text("9:41")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(statusBarTextColor)
                    .frame(width: 100)
                
                Spacer()
                
                // Right side - Status icons
                HStack(spacing: 5) {
                    // Signal strength
                    Image(systemName: "cellularbars")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(statusBarTextColor)
                    
                    // WiFi
                    Image(systemName: "wifi")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(statusBarTextColor)
                    
                    // Battery
                    Image(systemName: "battery.75percent")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(statusBarTextColor)
                }
                .frame(width: 100)
            }
            .padding(.horizontal, 15)
            .frame(width: deviceSize.width, height: statusBarHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}


