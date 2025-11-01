//
//  MasonryLayout.swift
//  DesignUI
//
//  Created by Assistant on 1/10/25.
//

import SwiftUI

@available(iOS 16.0, *)
struct MasonryLayout: Layout {
    var columns: Int
    var spacing: CGFloat
    
    init(columns: Int = 2, spacing: CGFloat = 8) {
        self.columns = columns
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let width = proposal.width, width > 0, !subviews.isEmpty else {
            return CGSize(width: proposal.width ?? 0, height: 0)
        }
        
        let columnWidth = (width - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
        var columnHeights = Array(repeating: CGFloat(0), count: columns)
        
        for subview in subviews {
            let proposedSize = ProposedViewSize(width: columnWidth, height: nil)
            let subviewSize = subview.sizeThatFits(proposedSize)
            
            // Find the shortest column
            let shortestColumn = columnHeights.enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? 0
            
            columnHeights[shortestColumn] += subviewSize.height + spacing
        }
        
        let maxHeight = columnHeights.max() ?? 0
        return CGSize(width: width, height: maxHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard bounds.width > 0, !subviews.isEmpty else { return }
        
        let columnWidth = (bounds.width - (spacing * CGFloat(columns - 1))) / CGFloat(columns)
        
        var columnHeights = Array(repeating: bounds.minY, count: columns)
        
        for subview in subviews {
            let proposedSize = ProposedViewSize(width: columnWidth, height: nil)
            let subviewSize = subview.sizeThatFits(proposedSize)
            
            // Find the shortest column
            let shortestColumn = columnHeights.enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? 0
            
            let xPosition = bounds.minX + CGFloat(shortestColumn) * (columnWidth + spacing)
            let yPosition = columnHeights[shortestColumn]
            
            subview.place(at: CGPoint(x: xPosition, y: yPosition), proposal: proposedSize)
            
            columnHeights[shortestColumn] += subviewSize.height + spacing
        }
    }
}

