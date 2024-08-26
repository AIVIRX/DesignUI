//
//  DateFormater.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/25/24.
//

import SwiftUI
import Firebase

func formattedDate(from timestamp: Timestamp) -> String {
    let date = timestamp.dateValue()
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
}
