//
//  DesignPost.swift
//  DockUI
//
//  Created by Maicol Cabreja on 6/11/24.
//


struct DesignPost: Identifiable, Codable, Equatable {
    let id: String
    let slug: String
    let preview_image_url: String
    let title: String
    let description: String
    let code_snippet: String
    let created_at: String
    let profiles: AuthorProfile
    let isPremium: Bool?
    let post_type: String?
    let status: String?
    
    struct AuthorProfile: Codable, Equatable {
        let username: String
        let verified: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case slug
        case preview_image_url
        case title
        case description
        case code_snippet
        case created_at
        case profiles
        case isPremium
        case is_premium
        case post_type
        case status
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        preview_image_url = try container.decode(String.self, forKey: .preview_image_url)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        code_snippet = try container.decode(String.self, forKey: .code_snippet)
        created_at = try container.decode(String.self, forKey: .created_at)
        profiles = try container.decode(AuthorProfile.self, forKey: .profiles)
        // Support either camelCase (isPremium) or snake_case (is_premium)
        if let premium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) {
            isPremium = premium
        } else {
            isPremium = try container.decodeIfPresent(Bool.self, forKey: .is_premium)
        }
        post_type = try container.decodeIfPresent(String.self, forKey: .post_type)
        status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encode(preview_image_url, forKey: .preview_image_url)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(code_snippet, forKey: .code_snippet)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(profiles, forKey: .profiles)
        if let isPremium = isPremium {
            try container.encode(isPremium, forKey: .isPremium)
        }
        if let post_type = post_type {
            try container.encode(post_type, forKey: .post_type)
        }
        if let status = status {
            try container.encode(status, forKey: .status)
        }
    }
}
