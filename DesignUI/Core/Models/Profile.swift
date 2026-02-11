//
//  Profile.swift
//  DockUI
//
//  Created by Maicol Cabreja on 12/18/24.
//

import Foundation

struct Profile: Codable {
    let username: String?
    let display_name: String?
    let bio: String?
    let verified: Bool?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case username, bio, verified
        case display_name
        case avatarUrl = "avatar_url"
    }
}
