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
        
        // Use ImageRenderer for modern iOS/macOS to properly capture blur effects
        let renderer = ImageRenderer(content: contentView)
        renderer.scale = 3.0 // Super Retina quality
        
        #if os(macOS)
        guard let cgImage = renderer.cgImage else {
            debugLog("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        // Convert to NSBitmapImageRep
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        // Ensure accurate scaling by setting the size and bits appropriately
        bitmapRep.size = size
        
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            debugLog("❌ Failed to convert to PNG")
            return nil
        }

        return pngData
        #else
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
