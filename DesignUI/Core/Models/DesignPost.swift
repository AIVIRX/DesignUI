//
//  DesignPost.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
import Foundation

struct DesignPost: Identifiable, Codable {
    let id: String
    let media: String
    let title: String
    let author: String
    let description: String
    let codeSnippet: String
    let creationDate: String
    let type: String
    let tags: [String]?
}
