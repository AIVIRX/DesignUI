//
//  HapticManager.swift
//  DockUI
//
//  Created by Maicol Cabreja on 3/24/25.
//

import SwiftUI

final class HapticManager {
    static let shared = HapticManager()

#if os(iOS)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)

    private init() {}

    func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light: generator = lightImpact
        case .medium: generator = mediumImpact
        case .heavy: generator = heavyImpact
        case .soft: generator = heavyImpact
        case .rigid: generator = heavyImpact
        @unknown default: generator = lightImpact
        }
        generator.prepare()
        generator.impactOccurred()
    }
#endif
}
