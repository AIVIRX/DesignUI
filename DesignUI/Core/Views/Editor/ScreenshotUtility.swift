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
    
    /// Captures a screenshot of a SwiftUI view at true size, saves as PNG
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
        // Use cgImage directly if available (macOS 13+)
        if let cgImage = renderer.cgImage {
            let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
            guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
                print("❌ Failed to convert CGImage to PNG")
                return nil
            }
            return pngData
        }
        
        // Fallback to nsImage if cgImage fails (unlikely on modern macOS with ImageRenderer)
        guard let nsImage = renderer.nsImage else {
            print("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert NSImage to PNG")
            return nil
        }
        
        print("✅ Screenshot captured (NSImage)")
        return pngData
        #else
        guard let uiImage = renderer.uiImage else {
            print("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        // Convert to PNG (no resizing - true size)
        guard let pngData = uiImage.pngData() else {
            print("❌ Failed to convert screenshot to PNG")
            return nil
        }
        
        return pngData
        #endif
    }
}

