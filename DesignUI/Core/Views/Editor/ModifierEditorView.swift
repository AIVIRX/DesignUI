//
//  ModifierEditorView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI

struct ModifierEditorView: View {
    @ObservedObject var component: UIComponent
    @Binding var modifier: ComponentModifier
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modifier header
            HStack {
                Image(systemName: modifier.type.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(modifier.type.rawValue)
                        .font(.headline)
                    
                    Text(modifier.type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Modifier-specific controls
            Group {
                switch modifier.type {
                case .frame:
                    FrameModifierEditor(modifier: $modifier, component: component)
                case .padding:
                    PaddingModifierEditor(modifier: $modifier, component: component)
                case .backgroundColor:
                    ColorModifierEditor(modifier: $modifier, component: component, title: "Background Color")
                case .background:
                    BackgroundElementModifierEditor(modifier: $modifier, component: component)
                case .foregroundColor:
                    ColorModifierEditor(modifier: $modifier, component: component, title: "Foreground Color")
                case .font:
                    FontModifierEditor(modifier: $modifier, component: component)
                case .cornerRadius:
                    CornerRadiusModifierEditor(modifier: $modifier, component: component)
                case .shadow:
                    ShadowModifierEditor(modifier: $modifier, component: component)
                case .opacity:
                    OpacityModifierEditor(modifier: $modifier)
                case .rotation:
                    RotationModifierEditor(modifier: $modifier, component: component)
                case .scale:
                    ScaleModifierEditor(modifier: $modifier, component: component)
                case .offset:
                    OffsetModifierEditor(modifier: $modifier, component: component)
                case .blur:
                    BlurModifierEditor(modifier: $modifier, component: component)
                case .clipShape:
                    ClipShapeModifierEditor(modifier: $modifier, component: component)
                case .mask:
                    MaskModifierEditor(modifier: $modifier, component: component)
                case .overlay:
                    OverlayModifierEditor(modifier: $modifier, component: component)
                case .border:
                    BorderModifierEditor(modifier: $modifier, component: component)
                case .textAlignment:
                    TextAlignmentModifierEditor(modifier: $modifier, component: component)
                case .fill:
                    ColorModifierEditor(modifier: $modifier, component: component, title: "Fill Color")
                case .aspectRatio:
                    AspectRatioModifierEditor(modifier: $modifier, component: component)
                case .zIndex:
                    ZIndexModifierEditor(modifier: $modifier, component: component)
                }
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 8)
        }
        .padding(16)
#if os(macOS)
        .frame(width: 320)
#endif
    }
}