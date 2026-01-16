//
//  RippleImageView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/7/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct RippleImageView: View {
    let mediaURL: String
    let aspectRatio: CGFloat
    let onLongPress: (CGPoint) -> Void
    
    @State private var rippleCounter: Int = 0
    @State private var rippleOrigin: CGPoint = .zero
    
    var body: some View {
        WebImage(url: URL(string: mediaURL)) { image in
            Color.clear
                .aspectRatio(aspectRatio, contentMode: .fit)
                .overlay(
                    image
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .modifier(RippleEffect(at: rippleOrigin, trigger: rippleCounter))
                .onLongPress(duration: 0.5) { location in
                    rippleOrigin = location
                    rippleCounter += 1
                    onLongPress(rippleOrigin)
                    #if os(iOS)
                    HapticManager.shared.triggerImpact(style: .soft)
                    #endif
                }
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.3))
    }
}
