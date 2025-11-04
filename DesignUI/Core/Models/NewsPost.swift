//
//  NewsPost.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import Foundation

struct NewsPost: Identifiable, Codable {
    let id: String
    let title: String
    let description: String?
    let image_url: String?
    let created_at: String
    let content: String
    let slug: String
}

extension NewsPost {
    var blocks: [NewsBlock] {
        guard let data = content.data(using: .utf8) else { return [] }
        do {
            return try JSONDecoder().decode([NewsBlock].self, from: data)
        } catch {
            print("Failed to decode blocks:", error)
            return []
        }
    }
}

enum NewsBlockType: String, Codable {
    case heading
    case paragraph
    case image
    case code
    case bulletedList = "bulleted-list"
    case link
}

struct NewsBlock: Codable, Identifiable {
    var id: UUID { UUID() } // For SwiftUI ForEach
    let type: NewsBlockType
    let text: String?
    let url: String?
    let code: String?
    let items: [String]?
    let level: Int?
    let language: String?
    let title: String?
}
