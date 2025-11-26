# AI JSON Schema Guide

This guide explains how the JSON schema works to structure AI responses for your UI Editor.

## Overview

The JSON schema tells the AI how to format its responses. Your edge function uses this schema to ensure the AI returns data in the correct format.

## Schema Types

### 1. Chat Schema (Default)
Used for general conversations and Q&A:

```json
{
  "type": "object",
  "properties": {
    "response": {
      "type": "string",
      "description": "The AI assistant's helpful response to the user"
    }
  },
  "required": ["response"]
}
```

**Example AI Response:**
```json
{
  "response": "To create a button in SwiftUI, use the Button view with an action closure..."
}
```

### 2. Component Schema
Used when generating SwiftUI components:

```json
{
  "type": "object",
  "properties": {
    "component": {
      "type": "object",
      "properties": {
        "type": {
          "type": "string",
          "enum": ["Text", "Image", "Button", "VStack", "HStack", ...],
          "description": "The type of SwiftUI component"
        },
        "properties": {
          "type": "object",
          "additionalProperties": true,
          "properties": {
            "text": { "type": "string" },
            "foregroundColor": { "type": "string" },
            ...
          }
        },
        "frame": {
          "type": "object",
          "properties": {
            "x": { "type": "number" },
            "y": { "type": "number" },
            "width": { "type": "number" },
            "height": { "type": "number" }
          }
        },
        "children": {
          "type": "array",
          "items": { "$ref": "#/properties/component" }
        },
        "modifiers": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "type": { "type": "string", "enum": ["background", "foregroundColor", "font", "fontSize", "padding", "cornerRadius", "shadow", "border", "opacity", "rotation", "scale", "offset"] },
              "properties": { "type": "object", "additionalProperties": true }
            }
          }
        }
      },
      "required": ["type"]
    }
  },
  "required": ["component"]
}
```

**Example AI Response:**
```json
{
  "component": {
    "type": "VStack",
    "properties": {
      "spacing": 16,
      "alignment": "center"
    },
    "frame": {
      "x": 100,
      "y": 100,
      "width": 300,
      "height": 200
    },
    "children": [
      {
        "type": "Text",
        "properties": {
          "text": "Hello World",
          "foregroundColor": "blue"
        },
        "frame": {
          "x": 0,
          "y": 0,
          "width": 0,
          "height": 0
        },
        "children": [],
        "modifiers": [
          {
            "type": "font",
            "properties": {
              "fontWeight": "bold"
            }
          },
          {
            "type": "fontSize",
            "properties": {
              "fontSize": "title"
            }
          }
        ]
      }
    ],
    "modifiers": [
      {
        "type": "padding",
        "properties": {
          "top": 16,
          "bottom": 16,
          "leading": 16,
          "trailing": 16
        }
      }
    ]
  }
}
```

## Component Types

The AI can generate these component types:
- `Text` - Text labels
- `Image` - Images
- `Button` - Interactive buttons
- `VStack` - Vertical stack
- `HStack` - Horizontal stack
- `ZStack` - Z-ordered stack
- `Spacer` - Flexible spacing
- `Divider` - Visual separator
- `Rectangle` - Rectangle shape
- `Circle` - Circle shape
- `RoundedRectangle` - Rounded rectangle
- `Capsule` - Capsule shape
- `Ellipse` - Ellipse shape
- `List` - List container
- `ScrollView` - Scrollable container
- `SF Symbol` - SF Symbol icon

## Property Types

### Text Properties
- `text` (string) - The text content
- `foregroundColor` (string) - Color name or RGB/RGBA string
- `alignment` (string) - "leading", "center", or "trailing"

### Stack Properties
- `spacing` (number) - Space between children (default: 8)
- `alignment` (string) - Alignment of children

### Image Properties
- `imageName` (string) - SF Symbol name (e.g., "star.fill", "heart")

### Shape Properties
- `backgroundColor` (string) - Background color

Use the `cornerRadius` modifier to round shapes instead of a direct property.

### Frame Properties
- `x` (number) - X position (default: 0)
- `y` (number) - Y position (default: 0)
- `width` (number) - Width (0 means auto-size)
- `height` (number) - Height (0 means auto-size)

## Color Format

Colors can be specified as:
- **Named colors**: `"primary"`, `"blue"`, `"red"`, `"green"`, etc.
- **RGB**: `"rgb(0.5,0.3,0.8)"` (values 0.0-1.0)
- **RGBA**: `"rgba(0.5,0.3,0.8,0.5)"` (with alpha 0.0-1.0)

## Modifiers

Available modifier types:
- `background` - Background color or view
- `foregroundColor` - Foreground color
- `font` - Font weight
- `fontSize` - Font size preset (Large Title, Title, etc.)
- `padding` - Padding around component
- `cornerRadius` - Corner radius
- `shadow` - Drop shadow
- `border` - Border stroke
- `opacity` - Opacity (0.0-1.0)
- `rotation` - Rotation in degrees
- `scale` - Scale factor
- `offset` - X/Y offset

## Usage in Code

### General Chat
```swift
let response = try await aiService.sendMessage(messages: messages)
// Returns: AIResponse with text content
```

### Component Generation
```swift
if let componentData = try await aiService.generateComponent(description: "A blue button with text") {
    // componentData is a [String: Any] dictionary matching the component schema
    // You can use this to create a UIComponent
}
```

## Customizing the Schema

You can modify the schema in `AIService.swift`:

1. **Add new component types**: Add to the `enum` in `getComponentSchema()`
2. **Add new properties**: Add to the `properties` object in the schema
3. **Change defaults**: Update the `description` fields with default values
4. **Add validation**: Use `enum` arrays to restrict values

## Tips for Better AI Responses

1. **Be specific**: "Create a blue button with white text" is better than "make a button"
2. **Include dimensions**: "A 200x50 button" helps the AI size correctly
3. **Specify layout**: "A VStack with 3 Text components" is clearer
4. **Mention styling**: "Rounded corners", "shadow", "padding" help

## Example Prompts

✅ **Good:**
- "Create a VStack with spacing 16 containing a bold title text 'Welcome' and a blue button labeled 'Get Started'"
- "Generate a 300x200 rounded rectangle with corner radius 12 and blue background"
- "Make a HStack with a star icon and text 'Favorite' with 8pt spacing"

❌ **Bad:**
- "Make a button" (too vague)
- "Create something nice" (not specific)
- "UI thing" (no details)

## Troubleshooting

### AI returns invalid JSON
- Check that your edge function properly handles the schema
- Verify the schema is correctly formatted
- Ensure the AI model supports structured outputs

### Component structure is wrong
- Review the schema to ensure all required fields are present
- Check that component types match your UIComponent enum
- Verify property names match your ComponentProperty keys

### Missing properties
- Add them to the schema's `properties` object
- Update the description to guide the AI
- Consider making them optional if not always needed

