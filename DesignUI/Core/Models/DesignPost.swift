import SwiftUI

// Helper for encoding/decoding Any values - used by UIComponent and Modifier
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        if let l = lhs.value as? Bool, let r = rhs.value as? Bool { return l == r }
        if let l = lhs.value as? Int, let r = rhs.value as? Int { return l == r }
        if let l = lhs.value as? Double, let r = rhs.value as? Double { return l == r }
        if let l = lhs.value as? String, let r = rhs.value as? String { return l == r }
        if let l = lhs.value as? [AnyCodable], let r = rhs.value as? [AnyCodable] { return l == r }
        if let l = lhs.value as? [String: AnyCodable], let r = rhs.value as? [String: AnyCodable] { return l == r }
        if lhs.value is NSNull && rhs.value is NSNull { return true }
        return false
    }
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.typeMismatch(Any.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        if value is NSNull {
            try container.encodeNil()
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let cgFloat = value as? CGFloat {
            try container.encode(Double(cgFloat))
        } else if let string = value as? String {
            try container.encode(string)
        } else if let array = value as? [Any] {
            try container.encode(array.map { AnyCodable($0) })
        } else if let dict = value as? [String: Any] {
            try container.encode(dict.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

struct DesignPost: Identifiable, Codable, Equatable {
    let id: String
    let slug: String
    let preview_image_url: String
    let title: String
    var description: String = ""
    var code_snippet: String = ""
    let created_at: String
    var design_json: DesignFileData? // Uses the robust DesignFileData decoder directly
    let profiles: AuthorProfile
    var isPremium: Bool = false
    var post_type: String?
    var status: String?
    
    /// Checks if design_json has actual data
    var isDesignEmpty: Bool {
        return design_json == nil
    }
    
    struct AuthorProfile: Codable, Equatable {
        let username: String
        let verified: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case id, slug, preview_image_url, title, description, code_snippet, created_at, profiles, isPremium, post_type, status, design_json
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        preview_image_url = try container.decode(String.self, forKey: .preview_image_url)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        code_snippet = try container.decodeIfPresent(String.self, forKey: .code_snippet) ?? ""
        created_at = try container.decode(String.self, forKey: .created_at)
        profiles = try container.decode(AuthorProfile.self, forKey: .profiles)
        isPremium = (try? container.decodeIfPresent(Bool.self, forKey: .isPremium)) ?? false
        post_type = try container.decodeIfPresent(String.self, forKey: .post_type)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        
        // Leniently decode design_json using our robust DesignFileData decoder
        design_json = try? container.decodeIfPresent(DesignFileData.self, forKey: .design_json)
    }
    
    /// Returns the design data (already decoded)
    func getDesignData() -> DesignFileData? {
        return design_json
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(slug, forKey: .slug)
        try container.encode(preview_image_url, forKey: .preview_image_url)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(code_snippet, forKey: .code_snippet)
        try container.encode(created_at, forKey: .created_at)
        try container.encode(profiles, forKey: .profiles)
        try container.encode(isPremium, forKey: .isPremium)
        try container.encodeIfPresent(post_type, forKey: .post_type)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(design_json, forKey: .design_json)
    }
    
    static func == (lhs: DesignPost, rhs: DesignPost) -> Bool {
        guard lhs.id == rhs.id else { return false }
        guard lhs.slug == rhs.slug else { return false }
        guard lhs.preview_image_url == rhs.preview_image_url else { return false }
        guard lhs.title == rhs.title else { return false }
        guard lhs.description == rhs.description else { return false }
        guard lhs.code_snippet == rhs.code_snippet else { return false }
        guard lhs.created_at == rhs.created_at else { return false }
        guard lhs.profiles == rhs.profiles else { return false }
        guard lhs.isPremium == rhs.isPremium else { return false }
        guard lhs.post_type == rhs.post_type else { return false }
        guard lhs.status == rhs.status else { return false }
        return true
    }
}
