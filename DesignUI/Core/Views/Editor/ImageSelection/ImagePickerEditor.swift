//
//  ImagePickerEditor.swift
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI
#if os(iOS)
import PhotosUI
#endif
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct ImagePickerEditor: View {
    var property: ComponentProperty
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    var useImageData: Bool = false
    
    // Bindings to parent view state for gallery sheet
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image preview or placeholder - tappable to open picker
            let imageDataKey = useImageData ? "imageData" : property.key
            #if os(iOS)
            // iOS: Open gallery sheet (Photos or Unsplash)
            imagePreviewView(imageDataKey: imageDataKey)
                .contentShape(Rectangle())
                .onTapGesture {
                    activePropertyKey = property.key
                    showGallery = true
                }
            #else
            // macOS: Tappable view that opens gallery
            imagePreviewView(imageDataKey: imageDataKey)
                .contentShape(Rectangle())
                .onTapGesture {
                    activePropertyKey = property.key
                    showGallery = true
                }
            #endif
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func imagePreviewView(imageDataKey: String) -> some View {
        let imageDataString = component.getProperty(key: imageDataKey) as? String ?? ""
        let baseImageName = component.getProperty(key: "imageName") as? String ?? ""
        
        ZStack {
            // Priority 1: Gallery filename from imageName property
            if !baseImageName.isEmpty,
               let fileURL = ImageGalleryManager.shared.getImageUrl(filename: baseImageName),
               FileManager.default.fileExists(atPath: fileURL.path) {
                AsyncImage(url: fileURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    case .empty:
                        ProgressView()
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(maxWidth: .infinity, maxHeight: 150)
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Tap to select image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    @unknown default:
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(maxWidth: .infinity, maxHeight: 150)
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Tap to select image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .id(baseImageName)
            }
            // Priority 2: Direct load via ImageGalleryManager (Bundled Assets match here)
            else if !baseImageName.isEmpty, let platformImage = ImageGalleryManager.shared.loadImage(filename: baseImageName) {
                #if os(macOS)
                Image(nsImage: platformImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #else
                Image(uiImage: platformImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #endif
            }
            // Priority 3: Gallery filename from imageData property (old components)
            else if baseImageName.isEmpty && !imageDataString.isEmpty,
                    (imageDataString.hasSuffix(".jpg") || imageDataString.hasSuffix(".jpeg") || imageDataString.hasSuffix(".png") || imageDataString.hasSuffix(".gif") || imageDataString.hasSuffix(".heic") || ImageGalleryManager.shared.getAllImageFilenames().contains(imageDataString)) {
                
                Group {
                    // Try to load as file first
                    if let fileURL = ImageGalleryManager.shared.getImageUrl(filename: imageDataString),
                       FileManager.default.fileExists(atPath: fileURL.path) {
                        AsyncImage(url: fileURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity, maxHeight: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            case .empty:
                                ProgressView()
                            case .failure:
                                EmptyView()
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    // Fallback to load via Manager (for bundled assets in imageData)
                    else if let platformImage = ImageGalleryManager.shared.loadImage(filename: imageDataString) {
                        #if os(macOS)
                        Image(nsImage: platformImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        #else
                        Image(uiImage: platformImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        #endif
                    }
                    // If neither file nor bundled asset, show placeholder
                    else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.1))
                                .frame(maxWidth: .infinity, maxHeight: 150)
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundColor(.secondary)
                                Text("Tap to select image")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .id(imageDataString)
            }
            // Priority 4: Base64 image data
            else if !imageDataString.isEmpty,
               let imageData = Data(base64Encoded: imageDataString),
               let image = createImage(from: imageData) {
                // Show preview of selected image
                #if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #else
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                #endif
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 150)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("Tap to Select Image")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Clear button overlay (only show if image exists)
            if !imageDataString.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Clear image
                            if useImageData {
                                canvasManager.updateComponentProperty(for: component, key: "imageData", value: "")
                                canvasManager.updateComponentProperty(for: component, key: "imageName", value: "")
                            } else {
                                canvasManager.updateComponentProperty(for: component, key: property.key, value: "")
                                // If using a custom property key that isn't imageData, we might technically store filename elsewhere, but let's clear imageName too just in case
                                canvasManager.updateComponentProperty(for: component, key: "imageName", value: "")
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    #if os(macOS)
    private func createImage(from data: Data) -> NSImage? {
        return NSImage(data: data)
    }
    #else
    private func createImage(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    #endif
}
