//
//  PaddingModifierEditor.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

// MARK: - Padding Modifier Editor
struct PaddingModifierEditor: View {
    @Binding var modifier: ComponentModifier
    @ObservedObject var component: UIComponent
    
    // Computed properties to sync with modifier
    private var currentAmount: CGFloat {
        if let cgFloatAmount = modifier.properties["amount"] as? CGFloat {
            return cgFloatAmount
        } else if let doubleAmount = modifier.properties["amount"] as? Double {
            return CGFloat(doubleAmount)
        } else if let intAmount = modifier.properties["amount"] as? Int {
            return CGFloat(intAmount)
        } else {
            print("⚠️ PaddingModifierEditor: Could not cast amount to CGFloat, raw value: \(modifier.properties["amount"] ?? "nil")")
            return 10
        }
    }
    
    private var currentLocation: String {
        modifier.properties["location"] as? String ?? "all"
    }
    
    private let paddingLocations = [
        ("all", "All Sides"),
        ("leading", "Leading"),
        ("trailing", "Trailing"),
        ("top", "Top"),
        ("bottom", "Bottom"),
        ("horizontal", "Horizontal"),
        ("vertical", "Vertical")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 12) {
                // Padding Location
                HStack {
                    Text("Location")
                    
                    Spacer()
                    
                    Picker("", selection: Binding(
                        get: { currentLocation },
                        set: { newValue in
                            print("📏 Padding location changed to: \(newValue)")
                            var updatedModifier = modifier
                            updatedModifier.properties["location"] = newValue
                            component.updateModifier(updatedModifier)
                        }
                    )) {
                        ForEach(paddingLocations, id: \.0) { location in
                            Text(location.1).tag(location.0)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Padding Amount
                HStack {
                    Text("Amount")
                    
                    Spacer()
                    
                    TextField("10", value: Binding(
                        get: { currentAmount },
                        set: { newValue in
                            print("📏 Padding amount changed to: \(newValue)")
                            var updatedModifier = modifier
                            updatedModifier.properties["amount"] = newValue
                            component.updateModifier(updatedModifier)
                        }
                    ), formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
            }
        }
    }
}
