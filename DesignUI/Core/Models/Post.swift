//
//  Post.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/3/24.
//

import Foundation
import FirebaseFirestore

struct Post: Identifiable, Decodable, Equatable {
        var id: String
        var title: String
        var description: String
        var mediaURL: String
        var authorUID: String
        var authorDisplayName: String
        var creationDate: Timestamp
        var snippet: String
        var type: String
        var likesCount: Int
        var viewCount: Int
        var likeTimestamp: Timestamp
        var tags: [String]
    }
