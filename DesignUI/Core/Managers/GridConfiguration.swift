//
//  GridConfiguration.swift
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

enum GridConfiguration {
    static func columns(isCompact: Bool) -> [GridItem] {
        if PlatformLayoutContext.isMac {
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        } else if isCompact {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        } else {
            return [GridItem(.adaptive(minimum: 250), spacing: 16)]
        }
    }
}
