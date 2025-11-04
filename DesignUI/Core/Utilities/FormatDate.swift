//
//  FormatDate.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import Foundation

func formattedDate(from isoString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    // Support fractional seconds
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = isoFormatter.date(from: isoString) {
        let formatter = DateFormatter()
        formatter.dateStyle = .long // e.g., July 2, 2025
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    return isoString // fallback
}
