//
//  PropertiesSectionView.swift
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

struct PropertiesSection: View {
    @ObservedObject var component: UIComponent
    @ObservedObject var canvasManager: CanvasManager
    @Binding var showGallery: Bool
    @Binding var activePropertyKey: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(component.type == .statusBar ? "Canvas Settings" : component.type.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            // For status bar, only show isVisible
            if component.type == .image {
                // Explicit Schema for Image
                VStack(alignment: .leading, spacing: 0) {
                    
                    // 1. Image Picker (imageName)
                    PropertyEditor(
                        property: ComponentProperty(
                            key: "imageName",
                            displayName: "Image",
                            type: .string,
                            value: component.getProperty(key: "imageName") as? String ?? "photo",
                            defaultValue: "photo"
                        ),
                        component: component,
                        canvasManager: canvasManager,
                        showGallery: $showGallery,
                        activePropertyKey: $activePropertyKey
                    )
                    
                    Divider().opacity(0.3).padding(.vertical, 2)
                    
                    // 2. Resizable (Boolean) - Not usually in properties list but we force it key "resizable"
                    HStack {
                        Text("Resizable")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { component.getProperty(key: "resizable") as? Bool ?? false },
                            set: { canvasManager.updateComponentProperty(for: component, key: "resizable", value: $0) }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    
                    Divider().opacity(0.3).padding(.vertical, 2)
                    
                     // 3. Aspect Ratio (Dropdown: fit/fill)
                     HStack {
                         Text("Aspect Ratio")
                             .font(.system(size: 12, weight: .medium))
                             .foregroundColor(.primary)
                         Spacer()
                         Menu {
                             Button("Fit") { canvasManager.updateComponentProperty(for: component, key: "aspectRatio", value: "fit") }
                             Button("Fill") { canvasManager.updateComponentProperty(for: component, key: "aspectRatio", value: "fill") }
                         } label: {
                             HStack {
                                 Text((component.getProperty(key: "aspectRatio") as? String ?? "fit").capitalized)
                                     .foregroundColor(.primary)
                                 Image(systemName: "chevron.up.chevron.down")
                                     .font(.caption2).foregroundColor(.secondary)
                             }
                         }
                         .buttonStyle(.plain)
                     }
                     .padding(.horizontal, 12).padding(.vertical, 8)
                    
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.1)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
                
            } else {
                // For all other components, show their properties in a grouped form
                // Filter out minLength property for Spacer components, foregroundColor for all components, font properties, cornerRadius for buttons/shapes, fill for shapes, backgroundColor for SF Symbols, and imageName for images (use modifiers instead)
                let filteredProperties = component.properties.filter { property in
                    if property.key == "lineWidth" || property.key == "data" {
                        return false
                    }
                    if component.type == .chart && (property.key == "foregroundColor" || property.key == "backgroundColor") {
                         return false
                    }
                    if property.key == "minLength" && component.type == .spacer {
                        return false
                    }
                    if property.key == "foregroundColor" {
                        return false // Always filter out foregroundColor - use modifier instead
                    }
                    if property.key == "fontWeight" {
                        return false // Use Font modifier instead
                    }
                    if property.key == "fontSize" {
                        return false // Use Font Size modifier instead
                    }
                    if property.key == "backgroundColor" && component.type == .sfSymbol {
                        return false // Filter out backgroundColor for SF Symbols - use modifier instead
                    }
                    if property.key == "imageName" && component.type == .image {
                        // Do NOT filter out imageName - we want to show it using the ImagePickerEditor
                        return true
                    }
                    if property.key == "cornerRadius" {
                        if component.type == .rectangle || component.type == .circle || component.type == .capsule || component.type == .ellipse {
                            return false // Filter out cornerRadius for shapes - use modifier instead
                        }
                        if component.type == .shape {
                             let shapeType = component.getProperty(key: "shapeType") as? String ?? "Rectangle"
                             if shapeType != "Rounded Rectangle" {
                                 return false
                             }
                        }
                    }
                    if property.key == "fill" && (component.type == .rectangle || component.type == .roundedRectangle || component.type == .circle || component.type == .capsule || component.type == .ellipse) {
                        return false // Filter out fill for shapes - use modifier instead
                    }
                    return true
                }
                
                // Only show properties section if there are properties to display
                if !filteredProperties.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredProperties.enumerated()), id: \.element.id) { index, property in
                            PropertyEditor(property: property, component: component, canvasManager: canvasManager, showGallery: $showGallery, activePropertyKey: $activePropertyKey)
                            
                            // Add divider between properties if there are 2+ and not the last one
                            if filteredProperties.count >= 2 && index < filteredProperties.count - 1 {
                                Divider()
                                    .opacity(0.3)
                                    .padding(.vertical, 2)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                }
            }
        }
    }
}
