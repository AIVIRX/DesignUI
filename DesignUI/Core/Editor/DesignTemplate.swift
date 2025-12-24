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
            
            // Onboarding Templates
            DesignTemplate(
                name: "Welcome Screen",
                description: "A simple welcome screen with title and button",
                thumbnail: "hand.wave",
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 24.0, defaultValue: 24.0)
                        ],
                        children: [
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Welcome", defaultValue: "Welcome")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"])
                                ]
                            ),
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Get started with your new app", defaultValue: "Get started with your new app")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "body"]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.secondary])
                                ]
                            ),
                            UIComponent(
                                type: .button,
                                properties: [
                                    ComponentProperty(key: "title", displayName: "Title", type: .string, value: "Get Started", defaultValue: "Get Started"),
                                    ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: "blue", defaultValue: "blue")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(16), "location": "all"]),
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(12)])
                                ]
                            )
                        ],
                        frame: CGRect(x: 0, y: 0, width: 0, height: 0)
                    )
                ],
                category: .onboarding
            ),
            
            // Card Template
            DesignTemplate(
                name: "Card",
                description: "A simple card with image, title, and description",
                thumbnail: "rectangle.stack",
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 12.0, defaultValue: 12.0)
                        ],
                        children: [
                            UIComponent(
                                type: .image,
                                properties: [
                                    ComponentProperty(key: "imageData", displayName: "Image", type: .string, value: "", defaultValue: ""),
                                    ComponentProperty(key: "resizable", displayName: "Resizable", type: .boolean, value: true, defaultValue: true),
                                    ComponentProperty(key: "aspectRatio", displayName: "Aspect Ratio", type: .dropdown, value: "fill", defaultValue: "fill", options: ["fit", "fill", "none"])
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 200),
                                modifiers: [
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(12)])
                                ]
                            ),
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Card Title", defaultValue: "Card Title")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "title2"]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "semibold"])
                                ]
                            ),
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Card description goes here", defaultValue: "Card description goes here")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "body"]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.secondary])
                                ]
                            )
                        ],
                        frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                        modifiers: [
                            ComponentModifier(type: .padding, properties: ["amount": CGFloat(16), "location": "all"]),
                            ComponentModifier(type: .background, properties: ["color": Color.secondary.opacity(0.1)]),
                            ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(16)])
                        ]
                    )
                ],
                category: .cards
            ),
            
            // Profile Template
            DesignTemplate(
                name: "Profile Screen",
                description: "A profile screen with avatar, name, and bio",
                thumbnail: "person.circle",
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 16.0, defaultValue: 16.0)
                        ],
                        children: [
                            UIComponent(
                                type: .sfSymbol,
                                properties: [
                                    ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "person.circle.fill", defaultValue: "person.circle.fill")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.blue])
                                ]
                            ),
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "John Doe", defaultValue: "John Doe")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "title"]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "bold"])
                                ]
                            ),
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "iOS Developer", defaultValue: "iOS Developer")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "body"]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.secondary])
                                ]
                            )
                        ],
                        frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                        modifiers: [
                            ComponentModifier(type: .padding, properties: ["amount": CGFloat(24), "location": "all"])
                        ]
                    )
                ],
                category: .profile
            ),
            
            // What's New Template
            DesignTemplate(
                name: "What's New",
                description: "A what's new screen with feature highlights",
                thumbnail: "sparkles",
                components: [
                    UIComponent(
                        type: .vstack,
                        properties: [
                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["leading", "center", "trailing"]),
                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .number, value: 20.0, defaultValue: 20.0)
                        ],
                        children: [
                            // Title
                            UIComponent(
                                type: .text,
                                properties: [
                                    ComponentProperty(key: "text", displayName: "Text", type: .string, value: "What's new in DockUI", defaultValue: "What's new in DockUI")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"]),
                                    ComponentModifier(type: .padding, properties: ["amount": CGFloat(60), "location": "all"]),
                                    ComponentModifier(type: .textAlignment, properties: ["alignment": "center"]),
                                    ComponentModifier(type: .font, properties: ["fontWeight": "semibold"])
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
                                    // Feature 1: UI Designer
                                    UIComponent(
                                        type: .hstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .sfSymbol,
                                                properties: [
                                                    ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "hand.draw.fill", defaultValue: "hand.draw.fill")
                                                ],
                                                frame: CGRect(x: 60, y: 60, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color(red: 1, green: 0.8392157554626465, blue: 0, opacity: 1)]),
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "largeTitle"])
                                                ]
                                            ),
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
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "UI Designer", defaultValue: "UI Designer")
                                                        ],
                                                        frame: CGRect(x: 60, y: 60, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .font, properties: ["fontWeight": "bold"]),
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    ),
                                                    UIComponent(
                                                        type: .text,
                                                        properties: [
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Create your own SwiftUI view designs  with DockUI Studio.", defaultValue: "Create your own SwiftUI view designs  with DockUI Studio.")
                                                        ],
                                                        frame: CGRect(x: 60, y: 60, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    )
                                                ],
                                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .vstack,
                                                properties: [
                                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"]),
                                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
                                                ],
                                                frame: CGRect(x: 160, y: 160, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                ]
                                            )
                                        ],
                                        frame: CGRect(x: 160, y: 160, width: 0, height: 0)
                                    ),
                                    
                                    // Feature 2: Snippets
                                    UIComponent(
                                        type: .hstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .sfSymbol,
                                                properties: [
                                                    ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "text.line.first.and.arrowtriangle.forward", defaultValue: "text.line.first.and.arrowtriangle.forward")
                                                ],
                                                frame: CGRect(x: 40, y: 40, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)])
                                                ]
                                            ),
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
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Snippets", defaultValue: "Snippets")
                                                        ],
                                                        frame: CGRect(x: 40, y: 40, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .font, properties: ["fontWeight": "bold"]),
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    ),
                                                    UIComponent(
                                                        type: .text,
                                                        properties: [
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Generate code snippets based on what you create, using our UI Designer.", defaultValue: "Generate code snippets based on what you create, using our UI Designer.")
                                                        ],
                                                        frame: CGRect(x: 40, y: 40, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    )
                                                ],
                                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                ]
                                            )
                                        ],
                                        frame: CGRect(x: 140, y: 140, width: 0, height: 0)
                                    ),
                                    
                                    // Feature 3: Like Designs
                                    UIComponent(
                                        type: .hstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .sfSymbol,
                                                properties: [
                                                    ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "heart.fill", defaultValue: "heart.fill")
                                                ],
                                                frame: CGRect(x: 20, y: 20, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color(red: 1, green: 0.25882354378700256, blue: 0.2705882489681244, opacity: 1)])
                                                ]
                                            ),
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
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Like Designs", defaultValue: "Like Designs")
                                                        ],
                                                        frame: CGRect(x: 20, y: 20, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .font, properties: ["fontWeight": "bold"]),
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    ),
                                                    UIComponent(
                                                        type: .text,
                                                        properties: [
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Hit the like button on your favorite designs!", defaultValue: "Hit the like button on your favorite designs!")
                                                        ],
                                                        frame: CGRect(x: 20, y: 20, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    )
                                                ],
                                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                ]
                                            )
                                        ],
                                        frame: CGRect(x: 120, y: 120, width: 0, height: 0)
                                    ),
                                    
                                    // Feature 4: Share Templates
                                    UIComponent(
                                        type: .hstack,
                                        properties: [
                                            ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "center", defaultValue: "center", options: ["top", "center", "bottom", "firstTextBaseline", "lastTextBaseline"]),
                                            ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
                                        ],
                                        children: [
                                            UIComponent(
                                                type: .sfSymbol,
                                                properties: [
                                                    ComponentProperty(key: "symbolName", displayName: "Symbol Name", type: .string, value: "person.fill", defaultValue: "person.fill")
                                                ],
                                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .frame, properties: ["widthType": "Custom", "heightType": "Custom", "width": CGFloat(50), "height": CGFloat(50)]),
                                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color(red: 0, green: 0.5686274766921997, blue: 1, opacity: 1)])
                                                ]
                                            ),
                                            UIComponent(
                                                type: .vstack,
                                                properties: [
                                                    ComponentProperty(key: "alignment", displayName: "Alignment", type: .segmentedControl, value: "leading", defaultValue: "leading", options: ["leading", "center", "trailing"]),
                                                    ComponentProperty(key: "spacing", displayName: "Spacing", type: .dropdown, value: "default", defaultValue: "default", options: ["default", "0", "4", "8", "12", "16", "20", "24", "32"])
                                                ],
                                                children: [
                                                    UIComponent(
                                                        type: .text,
                                                        properties: [
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Share Templates", defaultValue: "Share Templates")
                                                        ],
                                                        frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .font, properties: ["fontWeight": "bold"]),
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    ),
                                                    UIComponent(
                                                        type: .text,
                                                        properties: [
                                                            ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Easily share, discuss, and see updates about your presentation.", defaultValue: "Easily share, discuss, and see updates about your presentation.")
                                                        ],
                                                        frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                                        modifiers: [
                                                            ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                        ]
                                                    )
                                                ],
                                                frame: CGRect(x: 100, y: 100, width: 0, height: 0),
                                                modifiers: [
                                                    ComponentModifier(type: .fontSize, properties: ["fontSize": "footnote"])
                                                ]
                                            )
                                        ],
                                        frame: CGRect(x: 100, y: 100, width: 0, height: 0)
                                    )
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0)
                            ),
                            
                            // Spacer
                            UIComponent(
                                type: .spacer,
                                properties: [],
                                frame: CGRect(x: 100, y: 100, width: 0, height: 0)
                            ),
                            
                            // Continue Button
                            UIComponent(
                                type: .button,
                                properties: [
                                    ComponentProperty(key: "title", displayName: "Title", type: .string, value: "Continue", defaultValue: "Continue"),
                                    ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: "blue", defaultValue: "blue"),
                                    ComponentProperty(key: "foregroundColor", displayName: "Foreground Color", type: .color, value: "white", defaultValue: "white"),
                                    ComponentProperty(key: "cornerRadius", displayName: "Corner Radius", type: .cornerRadius, value: 50.0, defaultValue: 50.0)
                                ],
                                frame: CGRect(x: 100, y: 100, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
                                    ComponentModifier(type: .cornerRadius, properties: ["radius": CGFloat(10)]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.white])
                                ]
                            ),
                            
                            // Spacer
                            UIComponent(
                                type: .spacer,
                                properties: [],
                                frame: CGRect(x: 120, y: 120, width: 0, height: 0)
                            )
                        ],
                        frame: CGRect(x: 100, y: 100, width: 0, height: 0),
                        modifiers: [
                            ComponentModifier(type: .padding, properties: ["amount": CGFloat(15), "location": "all"])
                        ]
                    )
                ],
                category: .onboarding
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
                            
                            // Continue Button
                            UIComponent(
                                type: .button,
                                properties: [
                                    ComponentProperty(key: "title", displayName: "Title", type: .string, value: "Continue", defaultValue: "Continue"),
                                    ComponentProperty(key: "backgroundColor", displayName: "Background Color", type: .color, value: "blue", defaultValue: "blue")
                                ],
                                frame: CGRect(x: 0, y: 0, width: 0, height: 0),
                                modifiers: [
                                    ComponentModifier(type: .frame, properties: ["widthType": "Full", "heightType": "Default"]),
                                    ComponentModifier(type: .foregroundColor, properties: ["color": Color.white]),
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




