//
//  SessionManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/7/25.
//

import Foundation

class SessionManager {
    static let shared = SessionManager()
    
    var hasRequestedReview = false
    
    private init() {}
}
