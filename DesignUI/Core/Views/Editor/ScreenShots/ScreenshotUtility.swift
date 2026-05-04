//
//  ScreenshotUtility.swift
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Screenshot Utility
class ScreenshotUtility {
    static let shared = ScreenshotUtility()
    
    private init() {}
    
    @MainActor
    func captureThumbnail<Content: View>(
        of view: Content,
        size: CGSize,
        colorScheme: ColorScheme = .light
    ) -> Data? {
        // Check if this is content-adaptive mode (size is zero)
        let isContentAdaptive = size.width == 0 && size.height == 0
        
        let contentView: AnyView
        if isContentAdaptive {
            // Content-adaptive: let the view determine its own size
            contentView = AnyView(
                view
                    .fixedSize()
                    .colorScheme(colorScheme)
            )
        } else {
            // Fixed size: apply frame constraint
            contentView = AnyView(
                view
                    .frame(width: size.width, height: size.height)
                    .colorScheme(colorScheme)
            )
        }
        
        #if os(macOS)
        let hostingView = NSHostingView(rootView: contentView)
        let targetSize: CGSize
        if isContentAdaptive {
            targetSize = hostingView.fittingSize
        } else {
            targetSize = size
        }
        guard targetSize.width > 0, targetSize.height > 0 else {
            debugLog("❌ Invalid screenshot target size: \(targetSize)")
            return nil
        }

        hostingView.frame = CGRect(origin: .zero, size: targetSize)
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            debugLog("❌ Failed to create bitmap image rep for screenshot capture")
            return nil
        }
        bitmapRep.size = targetSize
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            debugLog("❌ Failed to convert to PNG")
            return nil
        }
        return pngData
        #else
        // Use ImageRenderer for iOS capture.
        let renderer = ImageRenderer(content: contentView)
        renderer.scale = 3.0 // Super Retina quality

        guard let uiImage = renderer.uiImage else {
            debugLog("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        // Convert to PNG (no resizing - true size)
        guard let pngData = uiImage.pngData() else {
            debugLog("❌ Failed to convert screenshot to PNG")
            return nil
        }
        
        return pngData
        #endif
    }
}
