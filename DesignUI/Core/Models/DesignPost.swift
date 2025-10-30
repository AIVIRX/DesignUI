//
//  DesignPost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//


struct DesignPost: Identifiable, Codable {
    let id: String
    let preview_image_url: String
    let title: String
    let description: String
    let code_snippet: String
    let created_at: String
    let profiles: AuthorProfile
    let likes_count: Int
    let isPremium: Bool?
    
    struct AuthorProfile: Codable {
        let username: String
        let verified: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case preview_image_url
        case title
        case description
        case code_snippet
        case created_at
        case profiles
        case likes_count
        case isPremium
        case is_premium
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        preview_image_url = try container.decode(String.self, forKey: .preview_image_url)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        code_snippet = try container.decode(String.self, forKey: .code_snippet)
        created_at = try container.decode(String.self, forKey: .created_at)
        profiles = try container.decode(AuthorProfile.self, forKey: .profiles)
        likes_count = try container.decode(Int.self, forKey: .likes_count)
        // Support either camelCase (isPremium) or snake_case (is_premium)
        if let premium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) {
            isPremium = premium
        } else {
            isPremium = try container.decodeIfPresent(Bool.self, forKey: .is_premium)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(preview_image_url, forKey: .preview_image_url)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(code_snippet, forKey: .code_snippet)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(profiles, forKey: .profiles)
        try container.encode(likes_count, forKey: .likes_count)
        if let isPremium = isPremium {
            try container.encode(isPremium, forKey: .isPremium)
        }
    }
}
