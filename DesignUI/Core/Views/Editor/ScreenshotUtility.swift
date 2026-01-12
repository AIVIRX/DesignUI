//
//  ScreenshotUtility.swift
//  DesignUI
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
    
    /// Captures a screenshot of a SwiftUI view at true size, only compresses as JPEG
    @MainActor
    func captureThumbnail<Content: View>(
        of view: Content,
        size: CGSize,
        colorScheme: ColorScheme = .light
    ) -> Data? {
        let contentView = view
            .frame(width: size.width, height: size.height)
            .colorScheme(colorScheme)
        
        // Use ImageRenderer for modern iOS/macOS to properly capture blur effects
        let renderer = ImageRenderer(content: contentView)
        renderer.scale = 2.0 // Retina quality
        
        #if os(macOS)
        guard let nsImage = renderer.nsImage else {
            print("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        // Create an opaque bitmap representation explicitly to avoid "opaque image with alpha" warnings
        // and save memory/disk space
        let width = Int(nsImage.size.width * renderer.scale)
        let height = Int(nsImage.size.height * renderer.scale)
        
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 3, // RGB, no alpha
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: NSColorSpaceName.sRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            print("❌ Failed to create opaque bitmap representation")
            return nil
        }
        
        // Draw the rendered image into the opaque bitmap
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        // Clear with white (or matching background) first to ensure opacity
        NSColor.white.set()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        
        // Draw the image
        // Note: nsImage.draw respects the context. Since the context is built from a bitmap of size (width, height),
        // we draw into that rect.
        nsImage.draw(in: NSRect(x: 0, y: 0, width: width, height: height),
                     from: .zero,
                     operation: .sourceOver,
                     fraction: 1.0)
        
        NSGraphicsContext.restoreGraphicsState()
        
        // Convert to JPEG
        guard let jpegData = bitmapRep.representation(using: .jpeg, properties: [NSBitmapImageRep.PropertyKey.compressionFactor: 0.7]) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes, size: \(width)x\(height)")
        return jpegData
        #else
        guard let uiImage = renderer.uiImage else {
            print("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        // Convert to JPEG (no resizing - true size)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes, size: \(uiImage.size)")
        return jpegData
        #endif
    }
}

