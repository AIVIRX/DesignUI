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
    /// If size is .zero, the view will be rendered at its intrinsic/content size
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
        renderer.scale = 2.0 // Retina quality
        
        #if os(macOS)
        // detailed crash fix: ImageRenderer on some macOS versions/configurations crashes with
        // "unable to load binary archive for shader library" when rendering SF Symbols (IconRendering).
        // specificially: /System/Library/PrivateFrameworks/IconRendering.framework/Resources/binary.metallib
        // We fallback to the legacy NSHostingView rasterization which is more robust.
        
        let hostingView = NSHostingView(rootView: contentView)
        
        if isContentAdaptive {
            // For content-adaptive, let the hosting view determine its size
            hostingView.frame = CGRect(origin: .zero, size: hostingView.intrinsicContentSize)
            
            // If intrinsic size is not valid, use fitting size
            if hostingView.frame.width <= 0 || hostingView.frame.height <= 0 {
                let fittingSize = hostingView.fittingSize
                hostingView.frame = CGRect(origin: .zero, size: fittingSize)
            }
        } else {
            hostingView.frame = CGRect(origin: .zero, size: size)
        }
        
        // Force layout
        hostingView.layout()
        
        // Render to bitmap
        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            debugLog("❌ Failed to create bitmap rep")
            return nil
        }
        
        // Clear background if needed, though usually SwiftUI views handles it. 
        // hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep) caused issues in some contexts, 
        // but let's try standard layer rendering first.
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)
        
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
