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
    func captureThumbnail<Content: View>(
        of view: Content,
        size: CGSize,
        colorScheme: ColorScheme = .light
    ) -> Data? {
        let contentView = view
            .frame(width: size.width, height: size.height)
            .colorScheme(colorScheme)
        
        #if os(macOS)
        return captureThumbnailMacOS(content: contentView, size: size)
        #else
        return captureThumbnailiOS(content: contentView, size: size)
        #endif
    }
    
    #if os(macOS)
    private func captureThumbnailMacOS<Content: View>(
        content: Content,
        size: CGSize
    ) -> Data? {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = NSRect(origin: .zero, size: size)
        
        // Force layout
        hostingView.layout()
        
        // Create image from view
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            print("❌ Failed to create bitmap representation")
            return nil
        }
        
        bitmapRep.size = size
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
        // Resize to thumbnail
        let resizedSize = thumbnailSize
        let resizedImage = NSImage(size: resizedSize)
        resizedImage.lockFocus()
        
        bitmapRep.draw(
            in: NSRect(origin: .zero, size: resizedSize),
            from: NSRect(origin: .zero, size: bitmapRep.size),
            operation: .sourceOver,
            fraction: 1.0,
            respectFlipped: true,
            hints: nil
        )
        
        resizedImage.unlockFocus()
        
        // Convert to optimized JPEG
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.7]) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes")
        return jpegData
    }
    #else
    private func captureThumbnailiOS<Content: View>(
        content: Content,
        size: CGSize
    ) -> Data? {
        let hostingController = UIHostingController(rootView: content)
        hostingController.view.frame = CGRect(origin: .zero, size: size)
        hostingController.view.backgroundColor = .clear
        
        // Force layout
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        
        // Render to image
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }
        
        // Resize to thumbnail
        let resizedImage = resizeImage(image, to: thumbnailSize)
        
        // Convert to optimized JPEG
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ Failed to convert screenshot to JPEG")
            return nil
        }
        
        print("✅ Screenshot captured: \(jpegData.count) bytes")
        return jpegData
    }
    
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    #endif
}

