//
//  ImageUploadService.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/5/26.
//

import SwiftUI
import Foundation
import Supabase
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Service for compressing images and uploading to Supabase Storage
class ImageUploadService {
    static let shared = ImageUploadService()
    
    private let supabase = SupabaseManager.shared.client
    private let bucketName = "design-images"
    private let maxSizeKB = 500
    
    private init() {}
    
    // MARK: - Image Compression
    
    /// Compress image data to target size (default 500KB)
    func compressImage(_ data: Data, maxSizeKB: Int? = nil) -> Data? {
        let targetSizeKB = maxSizeKB ?? self.maxSizeKB
        let targetBytes = targetSizeKB * 1024
        
        // If already under target size, return as-is
        if data.count <= targetBytes {
            print("📷 Image already under \(targetSizeKB)KB (\(data.count / 1024)KB)")
            return data
        }
        
        #if os(iOS)
        guard let image = UIImage(data: data) else {
            print("❌ Failed to create UIImage from data")
            return nil
        }
        
        // Try progressive compression
        var quality: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: quality)
        
        while let compressed = compressedData, compressed.count > targetBytes, quality > 0.1 {
            quality -= 0.1
            compressedData = image.jpegData(compressionQuality: quality)
            print("📷 Compressing at quality \(String(format: "%.1f", quality)): \(compressed.count / 1024)KB")
        }
        
        // If still too large, resize the image
        if let compressed = compressedData, compressed.count > targetBytes {
            var scaleFactor: CGFloat = 0.8
            var resizedImage = image
            
            while compressedData?.count ?? 0 > targetBytes, scaleFactor > 0.2 {
                let newSize = CGSize(
                    width: image.size.width * scaleFactor,
                    height: image.size.height * scaleFactor
                )
                
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                image.draw(in: CGRect(origin: .zero, size: newSize))
                resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                UIGraphicsEndImageContext()
                
                compressedData = resizedImage.jpegData(compressionQuality: 0.7)
                scaleFactor -= 0.1
                print("📷 Resizing to \(Int(scaleFactor * 100))%: \(compressedData?.count ?? 0 / 1024)KB")
            }
        }
        
        print("✅ Final compressed size: \(compressedData?.count ?? 0 / 1024)KB")
        return compressedData
        
        #else
        guard let image = NSImage(data: data) else {
            print("❌ Failed to create NSImage from data")
            return nil
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("❌ Failed to get CGImage")
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        // Try progressive compression
        var quality: CGFloat = 0.8
        var compressedData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
        
        while let compressed = compressedData, compressed.count > targetBytes, quality > 0.1 {
            quality -= 0.1
            compressedData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
            print("📷 Compressing at quality \(String(format: "%.1f", quality)): \(compressed.count / 1024)KB")
        }
        
        // If still too large, resize
        if let compressed = compressedData, compressed.count > targetBytes {
            var scaleFactor: CGFloat = 0.8
            
            while compressedData?.count ?? 0 > targetBytes, scaleFactor > 0.2 {
                let newSize = NSSize(
                    width: image.size.width * scaleFactor,
                    height: image.size.height * scaleFactor
                )
                
                let resizedImage = NSImage(size: newSize)
                resizedImage.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: newSize))
                resizedImage.unlockFocus()
                
                if let resizedCGImage = resizedImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    let resizedBitmapRep = NSBitmapImageRep(cgImage: resizedCGImage)
                    compressedData = resizedBitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
                }
                
                scaleFactor -= 0.1
                print("📷 Resizing to \(Int(scaleFactor * 100))%: \(compressedData?.count ?? 0 / 1024)KB")
            }
        }
        
        print("✅ Final compressed size: \(compressedData?.count ?? 0 / 1024)KB")
        return compressedData
        #endif
    }
    
    // MARK: - Upload to Supabase Storage
    
    /// Upload image to Supabase Storage and return public URL
    /// Images are stored in a folder with the user's ID
    func uploadImage(_ data: Data, filename: String, userId: UUID) async throws -> URL {
        let path = "\(userId.uuidString)/\(UUID().uuidString)_\(filename).jpg"
        
        print("📤 Uploading image to \(bucketName)/\(path)...")
        
        try await supabase.storage
            .from(bucketName)
            .upload(path, data: data, options: .init(contentType: "image/jpeg"))
        
        // Get public URL
        let publicURL = try supabase.storage
            .from(bucketName)
            .getPublicURL(path: path)
        
        print("✅ Uploaded successfully: \(publicURL)")
        return publicURL
    }
    
    // MARK: - Process Design for Sharing
    
    /// Process all components, upload images, and replace base64 with URLs
    func processDesignForSharing(_ components: [UIComponent], userId: UUID) async throws -> [UIComponent] {
        var processedComponents: [UIComponent] = []
        
        for component in components {
            let processedComponent = try await processComponent(component, userId: userId)
            processedComponents.append(processedComponent)
        }
        
        return processedComponents
    }
    
    private func processComponent(_ component: UIComponent, userId: UUID) async throws -> UIComponent {
        // Clone the component
        let clonedComponent = component.clone()
        
        // Check if this component has imageData (base64)
        if let imageDataString = clonedComponent.getProperty(key: "imageData") as? String,
           !imageDataString.isEmpty,
           let imageData = Data(base64Encoded: imageDataString) {
            
            print("🖼️ Found image in component, compressing and uploading...")
            
            // Compress the image
            if let compressedData = compressImage(imageData) {
                // Upload to Supabase
                let imageURL = try await uploadImage(compressedData, filename: "design_image", userId: userId)
                
                // Replace base64 with URL in imageName property (URLs are supported)
                clonedComponent.setProperty(key: "imageName", value: imageURL.absoluteString)
                // Clear the base64 data
                clonedComponent.setProperty(key: "imageData", value: "")
                
                print("✅ Replaced base64 with URL: \(imageURL)")
            }
        }
        
        // Process children recursively
        var processedChildren: [UIComponent] = []
        for child in clonedComponent.children {
            let processedChild = try await processComponent(child, userId: userId)
            processedChildren.append(processedChild)
        }
        clonedComponent.children = processedChildren
        
        return clonedComponent
    }
}
