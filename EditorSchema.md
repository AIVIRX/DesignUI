# DesignUI Editor Schema (Shorthand)

## Components & their properties
| Type | Key properties | Notes |
| :--- | :--- | :--- |
| `text` | `text` | |
| `image` | `imageName`, `aspectRatio` | `aspectRatio`: ["fit", "fill", "none"] |
| `sfSymbol` | `symbolName` | |
| `vstack` | `alignment`, `spacing` | `alignment`: ["leading", "center", "trailing"] |
| `hstack` | `alignment`, `spacing` | `alignment`: ["top", "center", "bottom"] |
| `zstack` | `alignment` | |
| `scrollView` | `axis` | `axis`: ["vertical", "horizontal"] |
| `shape` | `shapeType`, `cornerRadius` | `shapeType`: ["Rectangle", "Circle", "Capsule"] |
| `button` | `buttonStyle` | `buttonStyle`: ["bordered", "borderedProminent", "plain"] |
| `chart` | `chartStyle`, `pointCount` | `chartStyle`: ["Line + Area", "Bar"] |

## Modifiers & their values
| Modifier | Properties |
| :--- | :--- |
| `frame` | `width`, `height` |
| `padding` | `amount`, `location` ("all", "horizontal", "top", etc.) |
| `backgroundColor` | `color` (name, hex, or `name:opacity`) |
| `foregroundColor` | `color` |
| `font` | `fontSize` ("title", "body", "caption"), `fontWeight` ("bold", "regular") |
| `cornerRadius` | `radius` |
| `shadow` | `radius`, `x`, `y`, `color` |
| `opacity` | `opacity` (0.0 to 1.0) |
| `border` | `width`, `color` |
| `background` | (Contains child component at root of modifier) |
| `overlay` | (Contains child component at root of modifier) |

---

## Example Payload
```json
{
  "name": "Flight Status Widget",
  "description": "Flight details with status and gate info (Updated)",
  "thumbnail": "flightInfoWidget",
  "devicePreset": "Widget Medium",
  "canvasColorScheme": "dark",
  "components": [
    {
      "type": "VStack",
      "properties": {
        "spacing": 16
      },
      "modifiers": [
        {
          "type": "Padding",
          "properties": {
            "amount": 16,
            "location": "all"
          }
        }
      ],
      "children": [
        {
          "type": "HStack",
          "children": [
            {
              "type": "VStack",
              "properties": {
                "spacing": 4
              },
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Gate G12"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "caption",
                        "fontWeight": "regular"
                      }
                    },
                    {
                      "type": "Foreground Color",
                      "properties": {
                        "color": "color:gray"
                      }
                    }
                  ]
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "LAX"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "largeTitle",
                        "fontWeight": "bold"
                      }
                    }
                  ]
                }
              ]
            },
            {
              "type": "Spacer"
            },
            {
              "type": "VStack",
              "modifiers": [
                {
                  "type": "Frame",
                  "properties": {
                    "widthType": "Custom",
                    "heightType": "Default",
                    "width": 80,
                    "height": 100
                  }
                }
              ],
              "children": [
                {
                  "type": "Spacer"
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "On Time"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "subheadline",
                        "fontWeight": "semibold"
                      }
                    },
                    {
                      "type": "Foreground Color",
                      "properties": {
                        "color": "green:1.0"
                      }
                    }
                  ]
                },
                {
                  "type": "ZStack",
                  "children": [
                    {
                      "type": "RoundedRectangle",
                      "properties": {
                        "cornerRadius": 2
                      },
                      "modifiers": [
                        {
                          "type": "Frame",
                          "properties": {
                            "widthType": "Default",
                            "heightType": "Custom",
                            "height": 4
                          }
                        },
                        {
                          "type": "Foreground Color",
                          "properties": {
                            "color": "secondary:1.0"
                          }
                        },
                        {
                          "type": "Opacity",
                          "properties": {
                            "amount": 0.3
                          }
                        }
                      ]
                    },
                    {
                      "type": "SF Symbol",
                      "properties": {
                        "symbolName": "airplane"
                      },
                      "modifiers": [
                        {
                          "type": "Frame",
                          "properties": {
                            "widthType": "Custom",
                            "heightType": "Custom",
                            "width": 24,
                            "height": 24
                          }
                        }
                      ]
                    }
                  ]
                },
                {
                  "type": "Spacer"
                }
              ]
            },
            {
              "type": "Spacer"
            },
            {
              "type": "VStack",
              "properties": {
                "spacing": 4
              },
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Gate B5"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "caption",
                        "fontWeight": "regular"
                      }
                    },
                    {
                      "type": "Foreground Color",
                      "properties": {
                        "color": "color:gray"
                      }
                    }
                  ]
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "JFK"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "largeTitle",
                        "fontWeight": "bold"
                      }
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "type": "HStack",
          "children": [
            {
              "type": "VStack",
              "properties": {
                "alignment": "leading",
                "spacing": 8
              },
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Boarding"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "caption",
                        "fontWeight": "regular"
                      }
                    },
                    {
                      "type": "Foreground Color",
                      "properties": {
                        "color": "color:gray"
                      }
                    }
                  ]
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "10:45PM"
                  }
                }
              ]
            },
            {
              "type": "Spacer"
            },
            {
              "type": "VStack",
              "properties": {
                "alignment": "trailing",
                "spacing": 8
              },
              "children": [
                {
                  "type": "Text",
                  "properties": {
                    "text": "Arrival"
                  },
                  "modifiers": [
                    {
                      "type": "Font",
                      "properties": {
                        "fontSize": "caption",
                        "fontWeight": "regular"
                      }
                    },
                    {
                      "type": "Foreground Color",
                      "properties": {
                        "color": "color:gray"
                      }
                    }
                  ]
                },
                {
                  "type": "Text",
                  "properties": {
                    "text": "6:30PM"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}

```
