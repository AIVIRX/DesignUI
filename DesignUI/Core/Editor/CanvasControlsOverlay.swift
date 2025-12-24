//
//  CanvasControlsOverlay.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Canvas Controls Overlay
struct CanvasControlsOverlay: View {
    @Binding var selectedDevice: DevicePreset
    let canvasManager: CanvasManager
    @Binding var baseZoomLevel: CGFloat
    @Binding var statusBarHasBackground: Bool
    @Binding var colorScheme: ColorScheme?
    
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
            
            // Color scheme picker
            Menu {
                Button("Light") {
                    colorScheme = .light
                }
                Button("Dark") {
                    colorScheme = .dark
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: colorScheme == .light ? "sun.max" : "moon")
                        .font(.system(size: 12))
                    Text(colorScheme == .light ? "Light" : "Dark")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .help("Choose color scheme")
            
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
        .padding(.trailing, 16)
    }
}
