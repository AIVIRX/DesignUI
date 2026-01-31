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
        // detailed crash fix: ImageRenderer on some macOS versions/configurations crashes with
        // "unable to load binary archive for shader library" when rendering SF Symbols (IconRendering).
        // specificially: /System/Library/PrivateFrameworks/IconRendering.framework/Resources/binary.metallib
        // We fallback to the legacy NSHostingView rasterization which is more robust.
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = CGRect(origin: .zero, size: size)
        
        // Force layout
        hostingView.layout()
        
        // Render to bitmap
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            print("❌ Failed to create bitmap rep")
            return nil
        }
        
        // Clear background if needed, though usually SwiftUI views handles it. 
        // hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep) caused issues in some contexts, 
        // but let's try standard layer rendering first.
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("❌ Failed to convert to PNG")
            return nil
        }

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

