//
//  Like.swift
//  DockUI
//
//  Created by Maicol Cabreja on 2/7/25.
//

import Foundation

struct Like: Codable {
    let id: UUID
    let user_id: UUID
    let post_id: UUID
    let created_at: String
}
