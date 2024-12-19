struct Post: Identifiable, Codable {
    let id: String
    // ... existing properties ...
    
    // These won't be stored in the database, but will be computed
    var likeCount: Int = 0
    var isLiked: Bool = false
} 