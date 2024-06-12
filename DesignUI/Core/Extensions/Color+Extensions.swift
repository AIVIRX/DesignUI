//
//  Color+Extensions.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

extension Color {
    var rgbString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        return "(\(String(format: "%.2f", red)), \(String(format: "%.2f", green)), \(String(format: "%.2f", blue)))"
    }
    
    var rgbString255: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        
        let red255 = Int(red * 255)
        let green255 = Int(green * 255)
        let blue255 = Int(blue * 255)
        
        return "(\(red255), \(green255), \(blue255))"
    }
}

