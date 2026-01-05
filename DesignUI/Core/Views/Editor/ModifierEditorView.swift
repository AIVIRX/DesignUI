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
                    BackgroundColorModifierEditor(modifier: $modifier, component: component)
                case .background:
                    BackgroundElementModifierEditor(modifier: $modifier, component: component)
                case .foregroundColor:
                    ColorModifierEditor(modifier: $modifier, component: component, title: "Foreground Color")
                case .font:
                    FontModifierEditor(modifier: $modifier)
                case .fontSize:
                    FontSizeModifierEditor(modifier: $modifier)
                case .cornerRadius:
                    CornerRadiusModifierEditor(modifier: $modifier)
                case .shadow:
                    ShadowModifierEditor(modifier: $modifier)
                case .opacity:
                    OpacityModifierEditor(modifier: $modifier)
                case .rotation:
                    RotationModifierEditor(modifier: $modifier)
                case .scale:
                    ScaleModifierEditor(modifier: $modifier)
                case .offset:
                    OffsetModifierEditor(modifier: $modifier)
                case .blur:
                    BlurModifierEditor(modifier: $modifier)
                case .clipShape:
                    ClipShapeModifierEditor(modifier: $modifier)
                case .mask:
                    MaskModifierEditor(modifier: $modifier, component: component)
                case .overlay:
                    OverlayModifierEditor(modifier: $modifier, component: component)
                case .border:
                    BorderModifierEditor(modifier: $modifier)
                case .textAlignment:
                    TextAlignmentModifierEditor(modifier: $modifier, component: component)
                case .fill:
                    ColorModifierEditor(modifier: $modifier, component: component, title: "Fill Color")
                case .aspectRatio:
                    AspectRatioModifierEditor(modifier: $modifier)
                case .zIndex:
                    ZIndexModifierEditor(modifier: $modifier)
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