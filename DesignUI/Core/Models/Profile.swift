//
//  Profile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/18/24.
//

import Foundation

struct Profile: Codable {
    let id: UUID
    let username: String?
    let display_name: String?
    let bio: String?
    let verified: Bool?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username, bio, verified
        case display_name
        case avatarUrl = "avatar_url"
    }
}
