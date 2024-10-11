//
//  User.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/14/24.
//

import Foundation

struct UserModel {
    var id: String
    var profileImage: String
    var displayName: String
    var username: String
    var bio: String
    var isVerified: Bool
}

struct ProfileModel: Decodable {
    var id: UUID
    var image_url: String
    var display_name: String
    var username: String
    var bio: String
    var is_verified: Bool
}
