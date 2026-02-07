import Foundation
import SwiftUI

// MARK: - Models

struct UnsplashPhoto: Codable, Identifiable {
    let id: String
    let width: Int
    let height: Int
    let color: String?
    let blur_hash: String?
    let description: String?
    let alt_description: String?
    let urls: UnsplashUrls
    let links: UnsplashLinks
    let user: UnsplashUser
}

struct UnsplashLinks: Codable {
    let selfLink: String
    let html: String
    let download: String
    let download_location: String
    
    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
        case html, download, download_location
    }
}

struct UnsplashUrls: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
    let small_s3: String?
}

struct UnsplashUser: Codable, Identifiable {
    let id: String
    let username: String
    let name: String
    let portfolio_url: String?
    let profile_image: UnsplashProfileImage?
    let links: UnsplashUserLinks
}

struct UnsplashUserLinks: Codable {
    let selfLink: String
    let html: String
    let photos: String
    let likes: String
    let portfolio: String
    
    enum CodingKeys: String, CodingKey {
        case selfLink = "self"
        case html, photos, likes, portfolio
    }
}

struct UnsplashProfileImage: Codable {
    let small: String
    let medium: String
    let large: String
}

struct UnsplashSearchResults: Codable {
    let total: Int
    let total_pages: Int
    let results: [UnsplashPhoto]
}

// MARK: - Service

enum UnsplashError: Error {
    case invalidURL
    case noData
    case apiError(String)
}

class UnsplashService: ObservableObject {
    static let shared = UnsplashService()

    // Supabase Edge Function proxy
    private let supabaseUrl = "https://dwxfipenxnqkhgtwggrv.supabase.co/functions/v1/unsplash"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3eGZpcGVueG5xa2hndHdnZ3J2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjgwNjU4OTMsImV4cCI6MjA0MzY0MTg5M30.0mg37FPNXhj0drM0TFSlSzpl2Ofc7nyaHqOTnobvjac"
    
    // Common request helper
    private func fetchFromProxy(payload: [String: Any]) async throws -> Data {
        guard let url = URL(string: supabaseUrl) else {
            throw UnsplashError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UnsplashError.apiError("Invalid response type")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message
            if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
               let errorMessage = errorJson["error"] {
                throw UnsplashError.apiError(errorMessage)
            }
            throw UnsplashError.apiError("Server returned error: \(httpResponse.statusCode)")
        }
        
        return data
    }
    
    func searchPhotos(query: String, page: Int = 1) async throws -> [UnsplashPhoto] {
        let payload: [String: Any] = [
            "action": "search",
            "query": query,
            "page": page,
            "per_page": 30
        ]
        
        let data = try await fetchFromProxy(payload: payload)
        let decodedResponse = try JSONDecoder().decode(UnsplashSearchResults.self, from: data)
        return decodedResponse.results
    }
    
    func listPhotos(page: Int = 1) async throws -> [UnsplashPhoto] {
        let payload: [String: Any] = [
            "action": "list",
            "page": page,
            "per_page": 30
        ]
        
        let data = try await fetchFromProxy(payload: payload)
        let decodedResponse = try JSONDecoder().decode([UnsplashPhoto].self, from: data)
        return decodedResponse
    }
    
    func triggerDownload(photo: UnsplashPhoto) async {
        let payload: [String: Any] = [
            "action": "download_track",
            "photoId": photo.id
        ]
        
        _ = try? await fetchFromProxy(payload: payload)
    }
    
    func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw UnsplashError.invalidURL
        }
        
        // Image download is still direct from URL (CDN)
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
