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
    @State private var amountText: String = ""
    
    // Computed properties to sync with modifier
    private var currentAmount: CGFloat {
        modifier.getCGFloat(key: "amount", defaultValue: 10)
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
                    
                    TextField("10", text: $amountText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .onChange(of: amountText) { _, newValue in
                            // Allow empty string while typing
                            if newValue.isEmpty {
                                return
                            }
                            // Try to parse the value
                            if let value = Double(newValue) {
                                print("📏 Padding amount changed to: \(value)")
                                var updatedModifier = modifier
                                updatedModifier.properties["amount"] = CGFloat(value)
                                modifier = updatedModifier
                                component.updateModifier(updatedModifier)
                            }
                        }
                        .onSubmit {
                            // When user finishes editing, ensure we have a valid value
                            if amountText.isEmpty || Double(amountText) == nil {
                                amountText = String(format: "%.0f", currentAmount)
                            }
                        }
                }
            }
        }
        .onAppear {
            // Initialize the text field with current value
            amountText = String(format: "%.0f", currentAmount)
        }
        .onChange(of: currentAmount) { _, newValue in
            // Update text field if amount changes externally
            if Double(amountText) != Double(newValue) {
                amountText = String(format: "%.0f", newValue)
            }
        }
    }
}
