//
//  CanvasScreenshotView.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct CanvasScreenshotView: View {
    let components: [UIComponent]
    let deviceSize: CGSize
    let colorScheme: ColorScheme
    let statusBarVisible: Bool
    let statusBarTopSafeArea: Bool
    var previewToolbarVisible: Bool = false
    var previewToolbarTitle: String = "Title"
    
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
                    selectedComponentIds: [],
                    isScreenshotCapture: true
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
                        selectedComponentIds: [],
                        isScreenshotCapture: true
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, topContentInset)
            
            // Status bar if needed and visible
            if statusBarVisible {
                VStack {
                    StatusBarView(
                        deviceSize: deviceSize,
                        colorScheme: colorScheme
                    )
                    .background(.clear)
                    
                    Spacer()
                }
            }

            if previewToolbarVisible {
                PreviewToolbarChrome(
                    title: previewToolbarTitle.isEmpty ? "Title" : previewToolbarTitle
                )
                .padding(.top, statusBarTopSafeArea ? 50 : 0)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .allowsHitTesting(false)
            }
        }
        .frame(width: deviceSize.width, height: deviceSize.height)
        .colorScheme(colorScheme)
    }

    private var topContentInset: CGFloat {
        (statusBarTopSafeArea ? 50 : 0) + (previewToolbarVisible ? 44 : 0)
    }
}

private struct PreviewToolbarChrome: View {
    let title: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.04), in: Circle())

                Spacer(minLength: 0)

                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 28, height: 28)
                    .background(Color.primary.opacity(0.04), in: Circle())
            }
            .padding(.horizontal, 14)
        }
        .frame(height: 44)
    }
}
