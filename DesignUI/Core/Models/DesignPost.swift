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
    var description: String = ""  // Optional - not loaded in feed, fetched in DetailView
    var code_snippet: String = "" // Optional - not loaded in feed, fetched in DetailView
    let created_at: String
    var design_json: DesignFileData? // Optional - full design data
    let profiles: AuthorProfile
    var isPremium: Bool = false
    var post_type: String?
    var status: String?
    
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
        case post_type
        case status
        case design_json
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        preview_image_url = try container.decode(String.self, forKey: .preview_image_url)
        title = try container.decode(String.self, forKey: .title)
        // These are optional - not loaded in feed queries, fetched separately in DetailView
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        code_snippet = try container.decodeIfPresent(String.self, forKey: .code_snippet) ?? ""
        created_at = try container.decode(String.self, forKey: .created_at)
        profiles = try container.decode(AuthorProfile.self, forKey: .profiles)
        // Support either camelCase (isPremium) or snake_case (is_premium)
        if let premium = try container.decodeIfPresent(Bool.self, forKey: .isPremium) {
            isPremium = premium
        }
        post_type = try container.decodeIfPresent(String.self, forKey: .post_type)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        // Try decoding design_json directly if it matches DesignFileData
        // Use try? to prevent entire post fetch failure if design_json schema doesn't match
        design_json = try? container.decodeIfPresent(DesignFileData.self, forKey: .design_json)
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
        try container.encode(isPremium, forKey: .isPremium)
        if let post_type = post_type {
            try container.encode(post_type, forKey: .post_type)
        }
        if let status = status {
            try container.encode(status, forKey: .status)
        }
        try container.encodeIfPresent(design_json, forKey: .design_json)
    }
}
