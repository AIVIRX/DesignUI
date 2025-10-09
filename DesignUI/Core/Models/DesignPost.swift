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
    let profiles: profiles
    let likes_count: Int
    
    struct profiles: Codable {
        let username: String
        let verified: Bool
    }
}
