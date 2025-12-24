//
//  WidgetBuilderView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

enum WidgetSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var id: String { rawValue }
    
    var dimensions: (width: CGFloat, height: CGFloat) {
        switch self {
        case .small:
            return (158, 158) // 2x2 grid units
        case .medium:
            return (364, 158) // 4x2 grid units
        case .large:
            return (364, 382) // 4x4 grid units
        }
    }
    
    var displayName: String {
        return rawValue
    }
}

struct WidgetBuilderView: View {
    @State private var selectedWidgetSize: WidgetSize = .medium
    @State private var showCodePreview = false
    @State private var colorScheme: ColorScheme = .light
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                // Left Panel - Widget Size Selector
                widgetSizePanel
                
                // Main Canvas Area
                mainCanvasArea
                
                // Right Panel - Properties
                propertiesPanel
            }
            .navigationTitle("Widget Builder")
            
        }
        
    }
    
    // MARK: - Widget Size Panel
    private var widgetSizePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Widget Size")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                ForEach(WidgetSize.allCases) { size in
                    WidgetSizeButton(
                        size: size,
                        isSelected: selectedWidgetSize == size,
                        onTap: { selectedWidgetSize = size }
                    )
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 200)
        .background(Color(.gray))
    }
    
    // MARK: - Main Canvas Area
    private var mainCanvasArea: some View {
        VStack(spacing: 0) {
            // Canvas Controls
            canvasControls
            
            // Widget Canvas
            widgetCanvas
        }
    }
    
    private var canvasControls: some View {
        HStack {
            // Color Scheme Toggle
            Picker("Color Scheme", selection: $colorScheme) {
                Text("Light").tag(ColorScheme.light)
                Text("Dark").tag(ColorScheme.dark)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
            
            Spacer()
            
            // Widget Size Display
            Text("\(selectedWidgetSize.displayName) Widget")
                .font(.headline)
            
            Spacer()
            
            Button(action: { showCodePreview = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Text("View Code")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $showCodePreview) {
            // For now, we'll use an empty CanvasManager for the preview structure
            // In a real scenario, this would be tied to the actual widget canvas
            let canvasManager = CanvasManager()
            CodePreviewView(canvasManager: canvasManager, targetSize: CGSize(width: selectedWidgetSize.dimensions.width, height: selectedWidgetSize.dimensions.height))
        }
    }
    
    private var widgetCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                // Canvas Background
                Rectangle()
                    .fill(colorScheme == .dark ? Color(red: 0.15, green: 0.15, blue: 0.15) : Color(red: 0.9, green: 0.9, blue: 0.9))
                
                // Widget Preview
                widgetPreview
                    .frame(
                        width: selectedWidgetSize.dimensions.width,
                        height: selectedWidgetSize.dimensions.height
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(NSColor.controlBackgroundColor))
                            .shadow(radius: 8)
                    )
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var widgetPreview: some View {
        VStack {
            Text("Widget Preview")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("\(selectedWidgetSize.displayName) Size")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(Int(selectedWidgetSize.dimensions.width)) × \(Int(selectedWidgetSize.dimensions.height))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Properties Panel
    private var propertiesPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Properties")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                PropertyRow(title: "Size", value: selectedWidgetSize.displayName)
                PropertyRow(title: "Width", value: "\(Int(selectedWidgetSize.dimensions.width))")
                PropertyRow(title: "Height", value: "\(Int(selectedWidgetSize.dimensions.height))")
                PropertyRow(title: "Color Scheme", value: colorScheme == .dark ? "Dark" : "Light")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(width: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Supporting Views

struct WidgetSizeButton: View {
    let size: WidgetSize
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Size Preview
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(
                        width: size.dimensions.width / 4,
                        height: size.dimensions.height / 4
                    )
                
                Text(size.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PropertyRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
    }
}

#Preview {
    WidgetBuilderView()
}
