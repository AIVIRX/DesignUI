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

    private let previewCornerRadius: CGFloat = 8
    private let previewMaxHeight: CGFloat = 150
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let imageDataKey = useImageData ? "imageData" : property.key
            imagePreviewView(imageDataKey: imageDataKey)
                .contentShape(Rectangle())
                .onTapGesture {
                    activePropertyKey = property.key
                    showGallery = true
                }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func imagePreviewView(imageDataKey: String) -> some View {
        let imageDataString = component.getProperty(key: imageDataKey) as? String ?? ""
        let baseImageName = component.getProperty(key: "imageName") as? String ?? ""
        
        ZStack {
            if !baseImageName.isEmpty,
               let fileURL = ImageGalleryManager.shared.getImageUrl(filename: baseImageName),
               FileManager.default.fileExists(atPath: fileURL.path) {
                asyncPreview(url: fileURL, showsPlaceholderOnFailure: true)
                .id(baseImageName)
            }
            else if !baseImageName.isEmpty, let platformImage = ImageGalleryManager.shared.loadImage(filename: baseImageName) {
                styledImage(platformImageView(platformImage))
            }
            else if baseImageName.isEmpty && !imageDataString.isEmpty,
                    isFilenameOrStoredImage(imageDataString) {
                
                Group {
                    if let fileURL = ImageGalleryManager.shared.getImageUrl(filename: imageDataString),
                       FileManager.default.fileExists(atPath: fileURL.path) {
                        asyncPreview(url: fileURL, showsPlaceholderOnFailure: false)
                    } else if let platformImage = ImageGalleryManager.shared.loadImage(filename: imageDataString) {
                        styledImage(platformImageView(platformImage))
                    }
                    else {
                        standardPlaceholder(icon: "photo", text: "Tap to select image")
                    }
                }
                .id(imageDataString)
            }
            else if !imageDataString.isEmpty,
               let imageData = Data(base64Encoded: imageDataString),
               let image = createImage(from: imageData) {
                styledImage(platformImageView(image))
            } else {
                addPlaceholder
            }
            
            if !imageDataString.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: clearImage) {
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

    private func isFilenameOrStoredImage(_ value: String) -> Bool {
        value.hasSuffix(".jpg")
            || value.hasSuffix(".jpeg")
            || value.hasSuffix(".png")
            || value.hasSuffix(".gif")
            || value.hasSuffix(".heic")
            || ImageGalleryManager.shared.getAllImageFilenames().contains(value)
    }

    @ViewBuilder
    private func asyncPreview(url: URL, showsPlaceholderOnFailure: Bool) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                styledImage(image)
            case .empty:
                ProgressView()
            case .failure:
                if showsPlaceholderOnFailure {
                    standardPlaceholder(icon: "photo", text: "Tap to select image")
                } else {
                    EmptyView()
                }
            @unknown default:
                if showsPlaceholderOnFailure {
                    standardPlaceholder(icon: "photo", text: "Tap to select image")
                } else {
                    EmptyView()
                }
            }
        }
    }

    private func platformImageView(_ image: PlatformImage) -> Image {
        #if os(macOS)
        return Image(nsImage: image)
        #else
        return Image(uiImage: image)
        #endif
    }

    private func styledImage(_ image: Image) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: previewMaxHeight)
            .clipShape(RoundedRectangle(cornerRadius: previewCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: previewCornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }

    private func standardPlaceholder(icon: String, text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: previewCornerRadius)
                .fill(Color.gray.opacity(0.1))
                .frame(maxWidth: .infinity, maxHeight: previewMaxHeight)
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                Text(text)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var addPlaceholder: some View {
        RoundedRectangle(cornerRadius: previewCornerRadius)
            .fill(Color.gray.opacity(0.1))
            .frame(height: previewMaxHeight)
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
                RoundedRectangle(cornerRadius: previewCornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }

    private func clearImage() {
        if useImageData {
            canvasManager.clearImageSelection(for: component, propertyKey: "imageData")
        } else {
            canvasManager.clearImageSelection(for: component, propertyKey: property.key)
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
