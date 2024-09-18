//
//  AlertItem.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 7/19/24.
//

import SwiftUI

struct AlertItem: Identifiable {
    var id = UUID()
    var title: Text
    var message: Text?
    var primaryButton: Alert.Button
    var secondaryButton: Alert.Button?
}
