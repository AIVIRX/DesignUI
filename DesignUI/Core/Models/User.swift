//
//  User.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/14/24.
//

import Foundation

struct UserModel: Identifiable {
    var id: String
    var profileImage: String
    var displayName: String
    var bio: String
    var isVerified: Bool
}
