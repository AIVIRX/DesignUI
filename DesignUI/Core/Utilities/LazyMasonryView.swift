//
//  LazyMasonryView.swift
//  DockUI
//
//  Created by Assistant on 1/10/25.
//

import SwiftUI

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

@available(iOS 16.0, macOS 13.0, *)
struct LazyMasonryView<Content: View, Item: Identifiable>: View {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    let loadMoreHandler: ((Item?) -> Void)?
    let hasMorePosts: Bool
    let isLoading: Bool
    
    @State private var columnHeights: [CGFloat] = []
    @State private var itemHeights: [Item.ID: CGFloat] = [:]
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 8,
        hasMorePosts: Bool = true,
        isLoading: Bool = false,
        loadMoreHandler: ((Item?) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.content = content
        self.loadMoreHandler = loadMoreHandler
        self.hasMorePosts = hasMorePosts
        self.isLoading = isLoading
        _columnHeights = State(initialValue: Array(repeating: 0, count: columns))
    }
    
    private var columnItems: [[Item]] {
        var columns: [[Item]] = Array(repeating: [], count: self.columns)
        var heights = Array(repeating: CGFloat(0), count: self.columns)
        
        for item in items {
            // Find the shortest column
            let shortestColumn = heights.enumerated()
                .min(by: { $0.element < $1.element })?
                .offset ?? 0
            
            columns[shortestColumn].append(item)
            
            // Use known height if available, otherwise estimate based on typical sizes
            // Components are shorter (landscape), templates are taller (portrait)
            let itemHeight = itemHeights[item.id] ?? 400 // Default estimate
            heights[shortestColumn] += itemHeight + spacing
        }
        
        return columns
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    ForEach(columnItems[columnIndex]) { item in
                        content(item)
                            .frame(maxWidth: .infinity)
                            .background(
                                GeometryReader { itemGeometry in
                                    Color.clear
                                        .preference(
                                            key: HeightPreferenceKey.self,
                                            value: itemGeometry.size.height
                                        )
                                }
                            )
                            .onPreferenceChange(HeightPreferenceKey.self) { height in
                                if height > 0 {
                                    itemHeights[item.id] = height
                                }
                            }
                    }
                    
                    // Bottom sentinel for each column - triggers loading when scrolled into view
                    if hasMorePosts && !isLoading, let lastItem = columnItems[columnIndex].last {
                        Color.clear
                            .frame(height: 100)
                            .task {
                                loadMoreHandler?(lastItem)
                            }
                    }
                    
                    // Loading indicator at bottom of column
                    if isLoading && columnIndex == 0 { // Only show one loading indicator
                        #if os(macOS)
                        HStack {
                            Spacer()
                            Color.clear
                                .frame(width: 32, height: 32)
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                )
                            Spacer()
                        }
                        .padding()
                        #else
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                        #endif
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
