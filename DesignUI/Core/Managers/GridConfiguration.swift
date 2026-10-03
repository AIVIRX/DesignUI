//
//  GridConfiguration.swift
//
//  Created by Maicol Cabreja on 2/8/25.
//

import SwiftUI

class GridConfiguration {
    static let shared = GridConfiguration()
    
    private init() {}
    
    var columns: [GridItem] {
        if PlatformLayoutContext.isMac {
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        } else if PlatformLayoutContext.isPhone {
            return [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
        } else {
            return [GridItem(.adaptive(minimum: 250), spacing: 16)]
        }
    }
}
