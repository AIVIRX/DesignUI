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
    
    // Thumbnail size for preview (optimized for performance)
    private let thumbnailSize = CGSize(width: 400, height: 300)
    
    private init() {}
    
    /// Captures a screenshot of a SwiftUI view and returns optimized thumbnail data
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
        
        // Resize to thumbnail
        let resizedImage = resizeImage(nsImage, to: thumbnailSize)
        
        // Convert to optimized JPEG
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes")
        return jpegData
        #else
        guard let uiImage = renderer.uiImage else {
            print("❌ Failed to render image with ImageRenderer")
            return nil
        }
        
        // Resize to thumbnail
        let resizedImage = resizeImage(uiImage, to: thumbnailSize)
        
        // Convert to optimized JPEG
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes")
        return jpegData
        #endif
    }
    
    #if os(macOS)
    private func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        
        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .sourceOver,
            fraction: 1.0
        )
        
        resizedImage.unlockFocus()
        return resizedImage
    }
    #else
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    #endif
}
