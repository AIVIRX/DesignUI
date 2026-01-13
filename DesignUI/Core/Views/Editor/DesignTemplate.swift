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
                                    ComponentModifier(type: .font, properties: ["fontSize": "largeTitle", "fontWeight": "bold"]),
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
                                    ComponentModifier(type: .font, properties: ["fontSize": "body", "fontWeight": "bold"])
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
                name: "Flight Status Widget",
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
                                                    ComponentModifier(type: .font, properties: ["fontSize": "caption", "fontWeight": "regular"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "LAX", defaultValue: "LAX")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .font, properties: ["fontSize": "largeTitle", "fontWeight": "bold"])
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
                                                    ComponentModifier(type: .font, properties: ["fontSize": "subheadline", "fontWeight": "semibold"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.green])
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
                                                    ComponentModifier(type: .font, properties: ["fontSize": "caption", "fontWeight": "regular"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "JFK", defaultValue: "JFK")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .font, properties: ["fontSize": "largeTitle", "fontWeight": "bold"])
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
                                                    ComponentModifier(type: .font, properties: ["fontSize": "caption", "fontWeight": "semibold"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "10:45 AM", defaultValue: "10:45 AM")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .font, properties: ["fontSize": "subheadline", "fontWeight": "regular"])
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
                                                    ComponentModifier(type: .font, properties: ["fontSize": "caption", "fontWeight": "semibold"]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.gray])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .text,
                                                properties: [
                                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "6:30 PM", defaultValue: "6:30 PM")
                                                ],
                                                modifiers: [
                                                    ComponentModifier(type: .font, properties: ["fontSize": "subheadline", "fontWeight": "regular"])
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
                        // Icon (SF Symbol)
                        UIComponent(
                            type: .sfSymbol,
                            properties: [
                                ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: icon, defaultValue: icon),
                                ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: false, defaultValue: false)
                            ],
                            frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                            modifiers: [
                                ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)]),
                                ComponentModifier(type: .foregroundColor, properties: ["color": Color.blue])
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
                                        ComponentModifier(type: .font, properties: ["fontSize": "footnote", "fontWeight": "semibold"])
                                    ]
                                ),
                                UIComponent(
                                    type: .text,
                                    properties: [
                                        ComponentProperty(key: "text", displayName: "Text", type: .string, value: description, defaultValue: description)
                                    ],
                                    frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                    modifiers: [
                                        ComponentModifier(type: .font, properties: ["fontSize": "footnote", "fontWeight": "regular"]),
                                        ComponentModifier(type: .foregroundColor, properties: ["color": Color.secondary])
                                    ]
                                )
                            ],
                        )
                    ],
                )
            ],
        )
    }
}
