//
//  DesignPost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import Foundation

struct DesignPost: Identifiable, Codable {
    let id: String
    let preview_image_url: String
    let title: String
    let description: String
    let code_snippet: String
    let created_at: String
    let like_count: Int
    var isLiked: Bool?
    let profiles: profiles
    
    struct profiles: Codable {
        let username: String
        let verified: Bool
    }
}
