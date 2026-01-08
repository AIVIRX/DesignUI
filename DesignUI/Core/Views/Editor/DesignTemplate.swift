//
//  DesignTemplate.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

struct DesignTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let thumbnail: String // Image name for image
    let devicePreset: String? // Optional device preset for initial canvas size
    let components: [UIComponent]
}

class DesignTemplateManager {
    static let shared = DesignTemplateManager()
    var templates: [DesignTemplate] {
        return [
            
            // Blank Template
            DesignTemplate(
                name: "Blank",
                description: "Start with an empty canvas",
                thumbnail: "blank",
                devicePreset: nil,
                components: [],
            ),
            
            // Introducing Features Template
            DesignTemplate(
                name: "Introducing Features",
                description: "Feature highlights with icons and descriptions",
                thumbnail: "introducingFeatures",
                devicePreset: nil,
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
            ),
            
            // Flight Status Template
            DesignTemplate(
                name: "Flight Status ",
                description: "Flight details with status and gate info",
                thumbnail: "flightInfoWidget",
                devicePreset: "Widget Medium",
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 16.0, defaultValue: 16.0)
                        ],
                        children: [
                            // Top Row: Gates and Plane
                            UIComponent(
                                type: .hstack,
                                properties: [
                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                                ],
                                children: [
                                    // Departure Gate & Airport
                                    UIComponent(
                                        type: .vstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 4.0, defaultValue: 4.0)
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Gate G12", defaultValue: "Gate G12")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "caption"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "LAX", defaultValue: "LAX")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"])
                                                ]
                                            )
                                        ]
                                    ),
                                    
                                    UIComponent(type: .spacer, properties: []),
                                    
                                    // Plane & Status
                                    UIComponent(
                                        type: .vstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0),
                                            ComponentProperty(key: "axis", displayName: "Axis", type: .segmentedControl, value: "vertical", defaultValue: "vertical"),
                                            ComponentProperty(key: "showsIndicators", displayName: "Shows Indicators", type: .boolean, value: true, defaultValue: true)
                                        ],
                                        children: [
                                            UIComponent(type: .spacer, properties: []),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "On Time", defaultValue: "On Time")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "subheadline"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.green]),
                                                    ComponentModifier(type: .font, properties: ["fontWeight": "semibold"])
                                                ]
                                            ),
                                            // ZStack containing line and plane
                                            UIComponent(
                                                type: .zstack,
                                                properties: [
                                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["topLeading", "top", "topTrailing", "leading", "center", "trailing", "bottomLeading", "bottom", "bottomTrailing"])
                                                ],
                                                children: [
                                                    // Line
                                                    UIComponent(
                                                        type: .rectangle,
                                                        properties: [],
                                                        modifiers: [
                                                            ComponentModifier(type: .frame, properties: ["widthType": "Default", "heightType": "Custom", "width": CGFloat(100), "height": CGFloat(2)]),
                                                            ComponentModifier(type: .backgroundColor, properties: ["color": Color.gray]),
                                                            ComponentModifier(type: .opacity, properties: ["value": 0.5])
                                                        ]
                                                    ),
                                                    // Plane
                                                    UIComponent(
                                                        type: .sfSymbol,
                                                        properties: [
                                                             ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "airplane", defaultValue: "star"),
                                                             ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: false)
                                                        ],
                                                        modifiers: [
                                                            ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(30), "height": CGFloat(30)])
                                                        ]
                                                    )
                                                ]
                                            ),
                                            UIComponent(type: .spacer, properties: [])
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Default", "width": CGFloat(80), "height": CGFloat(100)])
                                        ]
                                    ),
                                    
                                    UIComponent(type: .spacer, properties: []),
                                    
                                    // Arrival Gate & Airport
                                    UIComponent(
                                        type: .vstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 4.0, defaultValue: 4.0)
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Gate B5", defaultValue: "Gate B5")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "caption"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "JFK", defaultValue: "JFK")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"])
                                                ]
                                            )
                                        ]
                                    )
                                ]
                            ),
                            
                            // Bottom Row: Times
                            UIComponent(
                                type: .hstack,
                                properties: [
                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                                ],
                                children: [
                                    // Boarding Info
                                    UIComponent(
                                        type: .vstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 4.0, defaultValue: 4.0)
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Boarding", defaultValue: "Boarding")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "caption"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray]),
                                                    ComponentModifier(type: .font, properties: ["fontWeight": "semibold"])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "10:45 AM", defaultValue: "10:45 AM")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "subheadline"])
                                                ]
                                            )
                                        ]
                                    ),
                                    
                                    UIComponent(type: .spacer, properties: []),
                                    
                                    // Arrival Info
                                    UIComponent(
                                        type: .vstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "trailing", defaultValue: "trailing", options: ["leading", "center", "trailing"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 4.0, defaultValue: 4.0)
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Arrival", defaultValue: "Arrival")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "caption"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray]),
                                                    ComponentModifier(type: .font, properties: ["fontWeight": "semibold"])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "6:30 PM", defaultValue: "6:30 PM")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "subheadline"])
                                                ]
                                            )
                                        ]
                                    )
                                ]
                            )
                        ],
                        modifiers: [
                            ComponentModifier(type: .padding, properties: ["amount": CGFloat(16), "location": "all"])
                        ]
                    )
                ]
            ),
            
            // Create Account Template
            DesignTemplate(
                name: "Create Account",
                description: "Account creation screen with sign-in options",
                thumbnail: "createAccount",
                devicePreset: nil,
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                        ],
                        children: [
                            // Top Spacer
                            UIComponent(
                                type: .spacer,
                                properties: [],
                                frame: CGRect(x: 0, y: 0, width: 40, height: 40)
                            ),
                            
                            // Person Circle Icon
                            UIComponent(
                                type: .sfSymbol,
                                properties: [
                                    ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "person.circle", defaultValue: "star"),
                                    ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: false)
                                ],
                                frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(100), "height": CGFloat(100)])
                                ]
                            ),
                            
                            // Create Account Title
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Create Account", defaultValue: "Hello World")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"])
                                ]
                            ),
                            
                            // Spacer between title and buttons
                            UIComponent(
                                type: .spacer,
                                properties: [],
                                frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                            ),
                            
                            // Continue with Apple Button
                            UIComponent(
                                type: .hstack,
                                properties: [
                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                                ],
                                children: [
                                    // Apple Logo
                                    UIComponent(
                                        type: .sfSymbol,
                                        properties: [
                                            ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "apple.logo", defaultValue: "star"),
                                            ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: false)
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(20), "height": CGFloat(20)]),
                                            ComponentModifier(type: .foregroundColor, properties: ["color": Color.white])
                                        ]
                                    ),
                                    // Apple Button Text
                                    UIComponent(
                                        type: .text,
                                        properties: [
                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Continue with Apple", defaultValue: "Hello World")
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .font, properties: ["fontWeight": "medium"]),
                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "body"]),
                                            ComponentModifier(type: .foregroundColor, properties: ["color": Color.white])
                                        ]
                                    )
                                ],
                                frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(15), "location": "vertical"]),
                                    ComponentModifier(type: .backgroundColor, properties: ["color": Color.black]),
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(12)])
                                ]
                            ),
                            
                            // Continue with Email Button
                            UIComponent(
                                type: .hstack,
                                properties: [
                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                                ],
                                children: [
                                    // Email Icon
                                    UIComponent(
                                        type: .sfSymbol,
                                        properties: [
                                            ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "envelope.fill", defaultValue: "star"),
                                            ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: false)
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(20), "height": CGFloat(20)])
                                        ]
                                    ),
                                    // Email Button Text
                                    UIComponent(
                                        type: .text,
                                        properties: [
                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Continue with Email", defaultValue: "Hello World")
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .font, properties: ["fontWeight": "medium"]),
                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "body"])
                                        ]
                                    )
                                ],
                                frame: CGRect(x: 0, y: 0, width: 120, height: 120),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(15), "location": "vertical"]),
                                    ComponentModifier(type: .backgroundColor, properties: ["color": Color.gray]),
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(12)])
                                ]
                            ),
                            
                            // Continue as Guest Button
                            UIComponent(
                                type: .hstack,
                                properties: [
                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 8.0, defaultValue: 8.0)
                                ],
                                children: [
                                    // Person Icon
                                    UIComponent(
                                        type: .sfSymbol,
                                        properties: [
                                            ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "person.fill", defaultValue: "star"),
                                            ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: false)
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(20), "height": CGFloat(20)])
                                        ]
                                    ),
                                    // Guest Button Text
                                    UIComponent(
                                        type: .text,
                                        properties: [
                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Continue as a Guest", defaultValue: "Hello World")
                                        ],
                                        modifiers: [
                                            ComponentModifier(type: .font, properties: ["fontWeight": "medium"]),
                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "body"])
                                        ]
                                    )
                                ],
                                frame: CGRect(x: 0, y: 0, width: 140, height: 140),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(15), "location": "vertical"]),
                                    ComponentModifier(type: .backgroundColor, properties: ["color": Color.gray]),
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(12)])
                                ]
                            ),
                            
                            // Forgot Password Text
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Forgot password?", defaultValue: "Hello World")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 160, height: 160),
                                modifiers: [
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.secondary])
                                ]
                            ),
                            
                            // Bottom Spacer
                            UIComponent(type: .spacer, properties: [])
                        ],
                        frame: CGRect(x: 0, y: 0, width: 100, height: 100),
                        modifiers: [
                            ComponentModifier(type: .padding, properties: ["amount": CGFloat(10), "location": "all"])
                        ]
                    )
                ]
            )
        ]
    }
    
    func templates(for category: DesignTemplate) -> [DesignTemplate] {
        return templates
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
                        // Icon (Image Placeholder)
                        UIComponent(
                            type: .image,
                            properties: [
                                ComponentProperty(key: "imageName", displayName: "Image Name", type: .string, value: "", defaultValue: ""),
                                ComponentProperty(key: "imageData", displayName: "Image Data", type: .string, value: "", defaultValue: ""),
                                ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: true),
                                ComponentProperty(key: "aspectRatio", displayName: "Aspect Ratio", type: .segmentedControl, value: "fill", defaultValue: "fill", options: ["none", "fit", "fill"])
                            ],
                            frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                            modifiers: [
                                ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)]),
                                ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(8)])
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




