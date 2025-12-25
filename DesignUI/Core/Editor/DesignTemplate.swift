//
//  DesignTemplate.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

// MARK: - Design Template Model
struct DesignTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let thumbnail: String // SF Symbol name for thumbnail
    let components: [UIComponent]
    let category: TemplateCategory
    
    enum TemplateCategory: String, CaseIterable {
        case blank = "Blank"
        case onboarding = "Onboarding"
        case dashboard = "Dashboard"
        case profile = "Profile"
        case settings = "Settings"
        case cards = "Cards"
    }
}

// MARK: - Template Manager
class DesignTemplateManager {
    static let shared = DesignTemplateManager()
    
    private init() {}
    
    var templates: [DesignTemplate] {
        return [
            // MARK: - How to Add a New Template
            // 1. Create a design in the editor with the components you want
            // 2. Copy the structure below and modify it with your components
            // 3. Add it to this array
            // 
            // Example structure:
            // DesignTemplate(
            //     name: "Template Name",
            //     description: "Brief description",
            //     thumbnail: "sf.symbol.name", // SF Symbol icon
            //     components: [
            //         UIComponent(...) // Your root component(s)
            //     ],
            //     category: .yourCategory // .blank, .onboarding, .dashboard, .profile, .settings, or .cards
            // )
            
            // Blank Template
            DesignTemplate(
                name: "Blank",
                description: "Start with an empty canvas",
                thumbnail: "doc.text",
                components: [],
                category: .blank
            ),
            
            // Introducing Features Template
            DesignTemplate(
                name: "Introducing Features",
                description: "Feature highlights with icons and descriptions",
                thumbnail: "sparkles.rectangle.stack",
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 12.0, defaultValue: 12.0)
                        ],
                        children: [
                            // Title
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Introducing New Features", defaultValue: "Introducing New Features")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"]),
                                    ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Default", "width": CGFloat(240)]),
                                    ComponentModifier(type: .textAlignment, properties: ["alignment": "center"]),
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(80), "location": "vertical"])
                                ]
                            ),
                            
                            // Features VStack
                            UIComponent(
                                type: .vstack,
                                properties: [
                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"]),
                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 20.0, defaultValue: 20.0)
                                ],
                                children: [
                                    // Feature 1: Ratings
                                    createFeatureRow(icon: "star.fill", title: "Ratings", description: "Lorem dolor scing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."),
                                    // Feature 2: Flight Tracker
                                    createFeatureRow(icon: "airplane", title: "Flight Tracker", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt."),
                                    // Feature 3: Meal Reservation
                                    createFeatureRow(icon: "fork.knife", title: "Meal Reservation", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt."),
                                    // Feature 4: Bag Locator
                                    createFeatureRow(icon: "bag.fill", title: "Bag Locator", description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt.")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0)
                            ),
                            
                            // Spacer
                            UIComponent(type: .spacer, properties: [], frame: CGRect(x: 0, y: 0, width: 0, height: 0)),
                            
                            // Continue Button (styled as button using Text with modifiers)
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Continue", defaultValue: "Continue")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(16), "location": "all"]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.white]),
                                    ComponentModifier(type: .backgroundColor, properties: ["color": Color.blue]),
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(12)]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"])
                                ]
                            ),
                            
                            // Bottom Spacer
                            UIComponent(type: .spacer, properties: [], frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                        ],
                        frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                        modifiers: [
                            ComponentModifier(type: .padding, properties: ["amount": CGFloat(30), "location": "horizontal"])
                        ]
                    )
                ],
                category: .onboarding
            )
        ]
    }
    
    func templates(for category: DesignTemplate.TemplateCategory) -> [DesignTemplate] {
        return templates.filter { $0.category == category }
    }
    
    // Helper to create feature rows for Introducing Features template
    private func createFeatureRow(icon: String, title: String, description: String) -> UIComponent {
        return UIComponent(
            type: .vstack,
            properties: [
                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 28.0, defaultValue: 28.0)
            ],
            children: [
                UIComponent(
                    type: .hstack,
                    properties: [
                        ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                        ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                    ],
                    children: [
                        // Icon
                        UIComponent(
                            type: .sfSymbol,
                            properties: [
                                ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: icon, defaultValue: icon)
                            ],
                            frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                            modifiers: [
                                ComponentModifier(type: .foregroundColor, properties: ["color": Color.blue]),
                                ComponentModifier(type: .fontSize, properties: ["fontSize": "title"]),
                                ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)])
                            ]
                        ),
                        // Text VStack
                        UIComponent(
                            type: .vstack,
                            properties: [
                                ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"]),
                                ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                            ],
                            children: [
                                UIComponent(
                                    type: .text,
                                    properties: [
                                        ComponentProperty(key: "text", displayName: "Text", type: .string, value: title, defaultValue: title)
                                    ],
                                    frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                    modifiers: [
                                        ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"]),
                                        ComponentModifier(type: .font, properties: ["fontWeight": "semibold"])
                                    ]
                                ),
                                UIComponent(
                                    type: .text,
                                    properties: [
                                        ComponentProperty(key: "text", displayName: "Text", type: .string, value: description, defaultValue: description)
                                    ],
                                    frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                    modifiers: [
                                        ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"]),
                                        ComponentModifier(type: .foregroundColor, properties: ["color": Color.secondary])
                                    ]
                                )
                            ],
                            frame: CGRect(x: 0, y: 0, width: 0, height: 0)
                        )
                    ],
                    frame: CGRect(x: 0, y: 0, width: 0, height: 0)
                )
            ],
            frame: CGRect(x: 0, y: 0, width: 0, height: 0)
        )
    }
    
}




