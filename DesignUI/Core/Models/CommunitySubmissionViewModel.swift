//
//  CommunitySubmissionViewModel.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/28/25.
//

import SwiftUI
import Supabase

/// Payload for creating a new community submission
private struct SubmissionPayload: Encodable {
    let id: String
    let title: String
    let description: String
    let preview_image_url: String
    let design_json: String
    let author_id: String
    let status: String
    let original_post_id: String?
    let slug: String
    let post_type: String
    // New posts start as not public until approved
    let `public`: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case preview_image_url
        case design_json
        case author_id
        case status
        case original_post_id
        case slug
        case post_type
        case `public`
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(preview_image_url, forKey: .preview_image_url)
        try container.encode(design_json, forKey: .design_json)
        try container.encode(author_id, forKey: .author_id)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(original_post_id, forKey: .original_post_id)
        try container.encode(slug, forKey: .slug)
        try container.encode(post_type, forKey: .post_type)
        try container.encode(`public`, forKey: .public)
    }
}

@MainActor
class CommunitySubmissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: String = ""
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var submissionSuccess = false
    
    private let client = SupabaseManager.shared.client
    private let storageBucket = "preview-images"
    private let designAssetsFolder = "design-assets"
    
    // MARK: - Submit Design
    
    /// Submit a design to the community
    /// - Parameters:
    ///   - designFile: The DesignFile to submit
    ///   - title: Title for the community post
    ///   - description: Description for the community post
    ///   - existingPostId: If updating an existing post, provide its ID
    func submitDesign(
        designFile: DesignFile,
        title: String,
        description: String,
        existingPostId: String? = nil
    ) async -> Bool {
        guard let userId = client.auth.currentUser?.id else {
            errorMessage = "You must be logged in to submit designs"
            showError = true
            return false
        }
        
        isLoading = true
        isUploading = true
        uploadProgress = "Preparing design..."
        
        do {
            // 1. Capture preview screenshot
            uploadProgress = "Generating preview..."
            guard let previewData = captureDesignPreview(designFile: designFile) else {
                throw SubmissionError.previewCaptureFailed
            }
            
            // 2. Generate Post ID
            let postId = UUID().uuidString
            
            // 3. Upload preview image
            uploadProgress = "Uploading preview image..."
            // Path: userid/postid/image.jpg (using png extension for consistency with data)
            let imagePath = "\(userId)/\(postId)/preview.png"
            
            let previewUrl = try await uploadImage(
                data: previewData,
                path: imagePath
            )
            
            // 3. Process design JSON - upload any embedded images
            uploadProgress = "Processing design assets..."
            let processedDesignJson = try await processDesignForUpload(
                designFile: designFile,
                userId: userId.uuidString,
                postId: postId
            )
            
            // 4. Create slug from title
            let slug = createSlug(from: title)
            
            // 5. Create submission payload
            uploadProgress = "Submitting to community..."
            let payload = SubmissionPayload(
                id: postId,
                title: title,
                description: description,
                preview_image_url: previewUrl,
                design_json: processedDesignJson,
                author_id: userId.uuidString,
                status: "pending",
                original_post_id: existingPostId,
                slug: slug,
                post_type: "design",
                public: false // Not public until approved
            )
            
            // 6. Insert into posts table
            try await client
                .from("posts")
                .insert(payload)
                .execute()
            
            uploadProgress = "Submitted successfully!"
            submissionSuccess = true
            isLoading = false
            isUploading = false
            
            return true
            
        } catch {
            print("❌ Submission error: \(error)")
            
            let errorString = "\(error)"
            if errorString.localizedCaseInsensitiveContains("bucket not found") || error.localizedDescription.localizedCaseInsensitiveContains("bucket not found") {
                errorMessage = "Configuration Error: Storage bucket '\(storageBucket)' not found. Please create it in Supabase."
            } else {
                errorMessage = "Failed to submit design: \(error.localizedDescription)"
            }
            
            showError = true
            isLoading = false
            isUploading = false
            return false
        }
    }
    
    // MARK: - Image Upload
    
    /// Upload an image to Supabase storage
    private func uploadImage(data: Data, path: String) async throws -> String {

        
        _ = try await client.storage
            .from(storageBucket)
            .upload(
                path,
                data: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/png",
                    upsert: true
                )
            )
        
        let publicUrl = try client.storage
            .from(storageBucket)
            .getPublicURL(path: path)
        
        return publicUrl.absoluteString
    }
    
    // MARK: - Design Processing
    
    /// Capture a preview screenshot of the design
    private func captureDesignPreview(designFile: DesignFile) -> Data? {
        // Get device preset from saved settings or default
        let devicePresetName = designFile.selectedDevicePreset ?? "iPhone 16 Pro Max"
        let devicePreset = DevicePreset.allCases.first { $0.rawValue == devicePresetName } ?? .iphone16ProMax
        
        // Determine color scheme
        let colorScheme: ColorScheme
        if let savedScheme = designFile.canvasColorScheme {
            colorScheme = savedScheme.lowercased() == "dark" ? .dark : .light
        } else {
            colorScheme = .light
        }
        
        let screenshotView = CanvasScreenshotView(
            components: designFile.components,
            deviceSize: devicePreset.size,
            colorScheme: colorScheme,
            statusBarVisible: designFile.statusBarVisible,
            statusBarTopSafeArea: designFile.statusBarTopSafeArea
        )
        
        return ScreenshotUtility.shared.captureThumbnail(
            of: screenshotView,
            size: devicePreset.size,
            colorScheme: colorScheme
        )
    }
    
    /// Process design file and upload any embedded images
    private func processDesignForUpload(designFile: DesignFile, userId: String, postId: String) async throws -> String {
        // Clone pages/components to avoid mutating the live design
        let clonedPages: [DesignPage]? = {
            if !designFile.pages.isEmpty {
                return designFile.pages.map { page in
                    let clonedComponents = page.components.map { $0.clone() }
                    let clonedStatusBar = page.statusBarComponent?.clone()
                    return DesignPage(
                        id: page.id,
                        name: page.name,
                        components: clonedComponents,
                        thumbnail: nil,
                        devicePreset: page.devicePreset,
                        colorScheme: page.colorScheme,
                        statusBarVisible: page.statusBarVisible,
                        statusBarTopSafeArea: page.statusBarTopSafeArea,
                        statusBarComponent: clonedStatusBar
                    )
                }
            }
            return nil
        }()
        
        let clonedComponents: [UIComponent]? = {
            if designFile.pages.isEmpty {
                return designFile.components.map { $0.clone() }
            }
            return nil
        }()
        
        // Upload local image assets and replace with public URLs
        var uploadedUrlCache: [String: String] = [:]
        if let pages = clonedPages {
            for page in pages {
                try await replaceLocalImagesWithRemoteURLs(
                    in: page.components,
                    userId: userId,
                    postId: postId,
                    cache: &uploadedUrlCache
                )
            }
        } else if let components = clonedComponents {
            try await replaceLocalImagesWithRemoteURLs(
                in: components,
                userId: userId,
                postId: postId,
                cache: &uploadedUrlCache
            )
        }
        
        // Encode design file to JSON using existing DesignFileData from DesignFile.swift
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        // Use the existing DesignFileData struct
        let designData: DesignFileData
        if let pages = clonedPages, !pages.isEmpty {
            designData = DesignFileData(
                name: designFile.name,
                pages: pages,
                currentPageIndex: designFile.currentPageIndex,
                lastModified: designFile.lastModified,
                thumbnail: nil, // Don't include thumbnail in submission
                devicePreset: designFile.devicePreset,
                selectedDevicePreset: designFile.selectedDevicePreset,
                canvasColorScheme: designFile.canvasColorScheme,
                statusBarVisible: designFile.statusBarVisible,
                statusBarTopSafeArea: designFile.statusBarTopSafeArea
            )
        } else {
            designData = DesignFileData(
                name: designFile.name,
                components: clonedComponents ?? [],
                lastModified: designFile.lastModified,
                thumbnail: nil,
                devicePreset: designFile.devicePreset,
                selectedDevicePreset: designFile.selectedDevicePreset,
                canvasColorScheme: designFile.canvasColorScheme,
                statusBarVisible: designFile.statusBarVisible,
                statusBarTopSafeArea: designFile.statusBarTopSafeArea
            )
        }
        
        let jsonData = try encoder.encode(designData)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SubmissionError.jsonEncodingFailed
        }
        
        return jsonString
    }

    private func replaceLocalImagesWithRemoteURLs(
        in components: [UIComponent],
        userId: String,
        postId: String,
        cache: inout [String: String]
    ) async throws {
        for component in components {
            if component.type == .image {
                let imageName = component.getProperty(key: "imageName") as? String ?? ""
                let imageDataString = component.getProperty(key: "imageData") as? String ?? ""
                
                if let remoteUrl = try await uploadImageForComponent(
                    imageName: imageName,
                    imageDataString: imageDataString,
                    userId: userId,
                    postId: postId,
                    cache: &cache
                ) {
                    component.setProperty(key: "imageName", value: remoteUrl)
                    component.setProperty(key: "imageData", value: "")
                }
            }
            
            if !component.children.isEmpty {
                try await replaceLocalImagesWithRemoteURLs(
                    in: component.children,
                    userId: userId,
                    postId: postId,
                    cache: &cache
                )
            }
        }
    }
    
    private func uploadImageForComponent(
        imageName: String,
        imageDataString: String,
        userId: String,
        postId: String,
        cache: inout [String: String]
    ) async throws -> String? {
        // If already a remote URL, keep it
        if imageName.lowercased().hasPrefix("http://") || imageName.lowercased().hasPrefix("https://") {
            return imageName
        }
        
        // Deduplicate by local key (filename or base64 hash)
        if !imageName.isEmpty, let cached = cache[imageName] {
            return cached
        }
        
        // 1. Local gallery filename
        if !imageName.isEmpty,
           let fileURL = ImageGalleryManager.shared.getImageUrl(filename: imageName),
           let data = try? Data(contentsOf: fileURL) {
            let remoteUrl = try await uploadDesignAsset(data: data, userId: userId, postId: postId, originalFilename: imageName)
            cache[imageName] = remoteUrl
            return remoteUrl
        }
        
        // 2. Base64 image data (legacy/pasted)
        if !imageDataString.isEmpty,
           let data = Data(base64Encoded: imageDataString, options: .ignoreUnknownCharacters) {
            let key = "base64_\(imageDataString.hashValue)"
            if let cached = cache[key] {
                return cached
            }
            let remoteUrl = try await uploadDesignAsset(data: data, userId: userId, postId: postId, originalFilename: nil)
            cache[key] = remoteUrl
            return remoteUrl
        }
        
        return nil
    }
    
    private func uploadDesignAsset(data: Data, userId: String, postId: String, originalFilename: String?) async throws -> String {
        let ext = (originalFilename as NSString?)?.pathExtension
        let fileExtension = (ext?.isEmpty == false) ? ext! : "jpg"
        let assetId = UUID().uuidString
        let path = "\(userId)/\(postId)/\(designAssetsFolder)/\(assetId).\(fileExtension)"
        return try await uploadImage(data: data, path: path)
    }
    
    /// Create a URL-safe slug from a title
    private func createSlug(from title: String) -> String {
        let lowercased = title.lowercased()
        let alphanumeric = lowercased.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let slug = alphanumeric.replacingOccurrences(of: " ", with: "-")
        return "\(slug)-\(UUID().uuidString.prefix(8))"
    }
}

// MARK: - Errors

enum SubmissionError: LocalizedError {
    case previewCaptureFailed
    case jsonEncodingFailed
    case uploadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .previewCaptureFailed:
            return "Failed to capture design preview"
        case .jsonEncodingFailed:
            return "Failed to encode design data"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        }
    }
}
