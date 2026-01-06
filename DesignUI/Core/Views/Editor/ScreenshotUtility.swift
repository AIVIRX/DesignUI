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
        
        // Convert to JPEG (no resizing - true size)
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes, size: \(nsImage.size)")
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

