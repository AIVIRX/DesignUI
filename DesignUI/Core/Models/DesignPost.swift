//
//  DesignPost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import Foundation

struct DesignPost: Identifiable, Codable {
    let id: String
    let image_url: String
    let title: String
    let description: String
    let code_snippet: String
    let created_at: String
    let tags: String
    let likes_count: Int
    let view_count: Int
    let hexadecimal: String
    let visibility: String
    let author: Author
}

struct Author: Codable {
    let id: String
    let display_name: String
    let is_verified: Bool
}
