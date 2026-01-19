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
    
    var body: some View {
        // Optimize memory by requesting thumbnail decoding size
        // This prevents loading full 4K images into memory for small cards
        WebImage(url: URL(string: mediaURL), context: [.imageThumbnailPixelSize: CGSize(width: 720, height: 720)]) { image in
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
