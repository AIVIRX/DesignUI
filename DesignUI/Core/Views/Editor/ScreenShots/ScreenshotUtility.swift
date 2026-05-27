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
        // Primary path (macOS): NSHostingView is more reliable for fixed-size captures
        // that include ScrollView content + overlay bars in one composited frame.
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

        // If content is unexpectedly blank in fixed-size mode, fall back to ImageRenderer.
        // This keeps us resilient for edge cases while preferring stable layout behavior.
        if !isContentAdaptive, let image = NSImage(data: pngData), isLikelyBlank(image: image) {
            let renderer = ImageRenderer(content: contentView)
            renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0
            if let nsImage = renderer.nsImage,
               let tiff = nsImage.tiffRepresentation,
               let rep = NSBitmapImageRep(data: tiff),
               let rendererPNG = rep.representation(using: .png, properties: [:]) {
                return rendererPNG
            }
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

#if os(macOS)
    private func isLikelyBlank(image: NSImage) -> Bool {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.bitmapData else {
            return false
        }

        let width = rep.pixelsWide
        let height = rep.pixelsHigh
        guard width > 0, height > 0 else { return true }

        let bytesPerPixel = max(rep.bitsPerPixel / 8, 4)
        let rowBytes = rep.bytesPerRow

        var sampled = 0
        var nearBackground = 0
        let step = max(1, min(width, height) / 24)

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * rowBytes + x * bytesPerPixel
                let r = Int(data[offset])
                let g = Int(data[offset + 1])
                let b = Int(data[offset + 2])
                sampled += 1

                // Near iOS light canvas gray/white background.
                if abs(r - g) < 8, abs(g - b) < 8, r >= 225 {
                    nearBackground += 1
                }
            }
        }

        guard sampled > 0 else { return false }
        let ratio = Double(nearBackground) / Double(sampled)
        return ratio > 0.97
    }
#endif
}
