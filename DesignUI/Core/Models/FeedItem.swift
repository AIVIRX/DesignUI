//
//  FeedItem.swift
//  DockUI
//
//  Created by Assistant on 1/11/25.
//

import Foundation

enum FeedItem: Identifiable {
    case post(DesignPost)
    case ad(String) // Ad identifier
    
    var id: String {
        switch self {
        case .post(let post):
            return post.id
        case .ad(let identifier):
            return "ad-\(identifier)"
        }
    }
    
    var isAd: Bool {
        if case .ad = self {
            return true
        }
        return false
    }
    
    var post: DesignPost? {
        if case .post(let post) = self {
            return post
        }
        return nil
    }
}

