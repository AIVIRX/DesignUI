//
//  DesignPost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import Foundation
import FirebaseFirestore

struct DesignPost: Identifiable, Decodable, Hashable {
    let id: String
    let media: String
    let title: String
    let author: String
    let description: String
    let codeSnippet: String
    let creationDate: Timestamp
    let type: String
    let tags: [String]
    let likesCount: Int
    let viewCount: Int
}
