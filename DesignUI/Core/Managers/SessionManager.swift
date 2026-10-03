//
//  SessionManager.swift
//
//  Created by Maicol Cabreja on 2/7/25.
//

import Foundation

@MainActor
final class SessionManager {
    static let shared = SessionManager()

    private var hasRequestedReview = false

    private init() {}

    func requestReviewAfterSuccessfulExport(_ request: () -> Void) {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        request()
    }
}
