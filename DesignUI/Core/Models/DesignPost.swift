//
//  DesignPost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
import Foundation

struct DesignPost: Identifiable {
    let id: String
    let media: String
    let title: String
    let author: String
    let description: String
    let codeSnippet: String
    let creationDate: String
    let type: DesignType
    var likes: String?
    var isFavorited: Bool?
    var viewCount: String?
    let tags: [String]?
}
