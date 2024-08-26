//
//  FormatCount.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/25/24.
//

import SwiftUI

func formatCount(_ count: Int) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.numberStyle = .decimal
    
    if count >= 1_000_000_000 {
        let formattedCount = Double(count) / 1_000_000_000
        numberFormatter.maximumFractionDigits = 2
        return "\(numberFormatter.string(from: NSNumber(value: formattedCount))!)B"
    } else if count >= 1_000_000 {
        let formattedCount = Double(count) / 1_000_000
        numberFormatter.maximumFractionDigits = 2
        return "\(numberFormatter.string(from: NSNumber(value: formattedCount))!)M"
    } else if count >= 1_000 {
        let formattedCount = Double(count) / 1_000
        numberFormatter.maximumFractionDigits = 2
        return "\(numberFormatter.string(from: NSNumber(value: formattedCount))!)K"
    } else {
        return "\(count)"
    }
}
