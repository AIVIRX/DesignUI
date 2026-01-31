//
//  AIService.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/31/26.
//

import Foundation
import Supabase
import SwiftUI

// MARK: - API Models

struct AIRequest: Encodable {
    let prompt: String
    let schemaType: String // "chat" or "component"
    let context: [String: String]?
}

struct AIResponse: Decodable {
    // Chat response
    let response: String?
    
    // Component response keys
    let type: String?
    let properties: [String: AIPropertyValue]?
    let modifiers: [AIModifier]?
    let children: [AIResponse]?
    
    var isComponent: Bool { type != nil }
}

struct AIModifier: Decodable {
    let type: String
    let properties: [String: AIPropertyValue]?
}

enum AIPropertyValue: Decodable {
    case string(String)
    case double(Double)
    case bool(Bool)
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let x = try? container.decode(Double.self) {
            self = .double(x)
        } else if let x = try? container.decode(Bool.self) {
            self = .bool(x)
        } else if let x = try? container.decode(String.self) {
            self = .string(x)
        } else {
            self = .string("") // Fallback
        }
    }
    
    var anyValue: Any? {
        switch self {
        case .string(let s): return s
        case .double(let d): return d
        case .bool(let b): return b
        case .null: return nil
        }
    }
}

// MARK: - Service

class AIService {
    static let shared = AIService()
    private let client = SupabaseManager.shared.client
    
    func generateResponse(prompt: String, context: [String: String] = [:]) async throws -> (String?, UIComponent?) {
        let request = AIRequest(prompt: prompt, schemaType: "component", context: context)
        
        // Call Edge Function
        let response: AIResponse = try await client.functions
            .invoke("StudioAI", options: FunctionInvokeOptions(body: request))
        
        if response.isComponent {
            // It's a component
            let component = convertToUIComponent(from: response)
            return (nil, component)
        } else {
            // It's a chat message
            return (response.response, nil)
        }
    }
    
    private func convertToUIComponent(from data: AIResponse) -> UIComponent {
        guard let typeString = data.type,
              let componentType = ComponentType.allCases.first(where: { $0.rawValue == typeString } ) ?? 
                                  ComponentType.allCases.first(where: { $0.rawValue.lowercased() == typeString.lowercased() }) 
        else {
            // Fallback for unknown types
            return UIComponent(type: .text, properties: [
                ComponentProperty(key: "text", displayName: "Text", type: .string, value: "Unknown Type: \(data.type ?? "?")", defaultValue: "")
            ])
        }
        
        var properties: [ComponentProperty] = []
        if let rawProps = data.properties {
            for (key, val) in rawProps {
                guard let propValue = val.anyValue else { continue } // Skip null values
                
                // Heuristic to determine property type
                let propType: PropertyType
                
                if key.lowercased().contains("color") { propType = .color }
                else if key == "font" { propType = .font }
                else if key == "padding" || key == "spacing" || key == "cornerRadius" || key == "width" || key == "height" { propType = .number }
                else { propType = .string }
                
                properties.append(ComponentProperty(
                    key: key,
                    displayName: key.capitalized,
                    type: propType,
                    value: propValue,
                    defaultValue: propValue
                ))
            }
        }
        
        let component = UIComponent(type: componentType, properties: properties)
        
        // Process Modifiers
        if let aiModifiers = data.modifiers {
            for mod in aiModifiers {
                if let modType = ModifierType.allCases.first(where: { $0.rawValue.lowercased() == mod.type.lowercased() || $0.rawValue.replacingOccurrences(of: " ", with: "").lowercased() == mod.type.replacingOccurrences(of: " ", with: "").lowercased() }) {
                    
                    var modProps: [String: Any] = [:]
                    if let rawModProps = mod.properties {
                        for (key, val) in rawModProps {
                            if let validVal = val.anyValue {
                                modProps[key] = validVal
                            }
                        }
                    }
                    
                    // Create modifier with defaults first, then override
                    var modifier = ComponentModifier.createWithDefaults(type: modType)
                    // Merge/Override properties
                    for (k, v) in modProps {
                        modifier.properties[k] = v
                    }
                    
                    component.addModifier(modifier)
                }
            }
        }
        
        if let childrenData = data.children {
            for childData in childrenData {
                let childComponent = convertToUIComponent(from: childData)
                component.addChild(childComponent)
            }
        }
        
        return component
    }
}
