import Foundation

struct Like: Codable {
    let id: String
    let userId: String
    let postId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case postId = "post_id"
    }
} 