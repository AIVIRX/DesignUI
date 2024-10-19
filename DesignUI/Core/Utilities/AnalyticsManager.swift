//
//  AnalyticsManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/25/24.
//

import Firebase
import FirebaseAnalytics
import FirebaseAnalyticsSwift

final class AnalyticsManager{
    static let shared = AnalyticsManager()
    private init() {}
    
    func likedPost(postID: String) {
        Analytics.logEvent("Liked_Post", parameters: [
            "post_id": postID,
            "timestamp": Date(),
            AnalyticsParameterContentType: "post"
        ])
    }
    
    func unlikedPost(postID: String) {
        Analytics.logEvent("Unliked_Post", parameters: [
            "post_id": postID,
            "timestamp": Date(),
            AnalyticsParameterContentType: "post"
        ])
    }
    
    func viewedPost(postID: String) {
        Analytics.logEvent("Viewed_Post", parameters: [
            "post_id": postID,
            "timestamp": Date(),
            AnalyticsParameterContentType: "post"
        ])
    }
    
    func setUserID(userID: String){
        Analytics.setUserID(userID)
    }
}
