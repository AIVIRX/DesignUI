//
//  CommunitySubmissionViewModel.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/28/25.
//

import SwiftUI
import Supabase

/// Represents a user's community submission with moderation status
struct CommunitySubmission: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let preview_image_url: String?
    private let status_raw: String
    let created_at: String
    let original_post_id: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, preview_image_url, created_at, original_post_id
        case status_raw = "status"
    }
    
    enum SubmissionStatus: String {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
    }
    
    var status: SubmissionStatus {
        SubmissionStatus(rawValue: status_raw) ?? .pending
    }
}

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
}

@MainActor
class CommunitySubmissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: String = ""
    @Published var mySubmissions: [CommunitySubmission] = []
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var submissionSuccess = false
    
    private let client = SupabaseManager.shared.client
    private let storageBucket = "preview-images"
    
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
            let processedDesignJson = try await processDesignForUpload(designFile: designFile)
            
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
    
    // MARK: - Fetch My Submissions
    
    /// Fetch the current user's submissions
    func fetchMySubmissions() async {
        guard let userId = client.auth.currentUser?.id else { return }
        
        isLoading = true
        
        do {
            let response = try await client
                .from("posts")
                .select("id, title, description, preview_image_url, status, created_at, original_post_id")
                .eq("author_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let submissions = try JSONDecoder().decode([CommunitySubmission].self, from: response.data)
            mySubmissions = submissions
            
        } catch {
            print("❌ Failed to fetch submissions: \(error)")
            errorMessage = "Failed to load submissions"
        }
        
        isLoading = false
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
            statusBarComponent: nil,
            statusBarHasBackground: false
        )
        
        return ScreenshotUtility.shared.captureThumbnail(
            of: screenshotView,
            size: devicePreset.size,
            colorScheme: colorScheme
        )
    }
    
    /// Process design file and upload any embedded images
    private func processDesignForUpload(designFile: DesignFile) async throws -> String {
        // Encode design file to JSON using existing DesignFileData from DesignFile.swift
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        // Use the existing DesignFileData struct
        let designData = DesignFileData(
            name: designFile.name,
            pages: designFile.pages,
            currentPageIndex: designFile.currentPageIndex,
            lastModified: designFile.lastModified,
            thumbnail: nil, // Don't include thumbnail in submission
            devicePreset: designFile.devicePreset,
            selectedDevicePreset: designFile.selectedDevicePreset,
            canvasColorScheme: designFile.canvasColorScheme,
            statusBarVisible: designFile.statusBarVisible
        )
        
        let jsonData = try encoder.encode(designData)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw SubmissionError.jsonEncodingFailed
        }
        
        // TODO: Scan for local image URLs and upload them, replacing with storage URLs
        // For now, return the JSON as-is
        return jsonString
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

