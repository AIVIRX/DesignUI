//
//  CanvasScreenshotView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Canvas Screenshot View
/// A view specifically designed for capturing screenshots of the canvas
/// This renders only the device preview without UI controls, zoom, or offset
struct CanvasScreenshotView: View {
    let components: [UIComponent]
    let deviceSize: CGSize
    let colorScheme: ColorScheme
    let statusBarComponent: UIComponent?
    let statusBarHasBackground: Bool
    
    var body: some View {
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
                        selectedComponent: nil
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, (statusBarComponent?.isVisible ?? true) && !statusBarHasBackground ? 53 : 0) // Safe area for status bar
            
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
        .clipShape(RoundedRectangle(cornerRadius: deviceSize.width > 800 ? 8 : 50, style: .continuous))
    }
}
