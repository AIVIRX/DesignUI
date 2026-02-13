//
//  LazyMasonryView.swift
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
    @State private var itemColumnAssignments: [Item.ID: Int] = [:]
    
    // Increased to 1000 to ensure stable layout for larger galleries (unbounded cache for ~50 items was causing layout instability)
    private let maxHeightCacheSize = 1000
    
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
            let assignedColumn: Int
            
            // If item already has a column assignment, preserve it
            if let existingColumn = itemColumnAssignments[item.id] {
                assignedColumn = existingColumn
            } else {
                // New item: find the shortest column
                assignedColumn = heights.enumerated()
                    .min(by: { $0.element < $1.element })?
                    .offset ?? 0
            }
            
            columns[assignedColumn].append(item)
            
            // Use known height if available, otherwise estimate based on typical sizes
            // Components are shorter (landscape), templates are taller (portrait)
            let itemHeight = itemHeights[item.id] ?? 400 // Default estimate
            heights[assignedColumn] += itemHeight + spacing
        }
        
        return columns
    }
    
    private func updateColumnAssignments() {
        let currentItemIds = Set(items.map { $0.id })
        
        // Clean up assignments for items that are no longer in the list
        itemColumnAssignments = itemColumnAssignments.filter { currentItemIds.contains($0.key) }
        
        // Assign columns for new items
        var heights = Array(repeating: CGFloat(0), count: self.columns)
        
        for item in items {
            if itemColumnAssignments[item.id] == nil {
                // New item: find the shortest column
                let shortestColumn = heights.enumerated()
                    .min(by: { $0.element < $1.element })?
                    .offset ?? 0
                
                itemColumnAssignments[item.id] = shortestColumn
            }
            
            // Update height for next iteration
            let itemHeight = itemHeights[item.id] ?? 400
            if let column = itemColumnAssignments[item.id] {
                heights[column] += itemHeight + spacing
            }
        }
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
                                    
                                    // Limit height cache size - remove entries for items no longer in array
                                    if itemHeights.count > maxHeightCacheSize {
                                        let currentItemIds = Set(items.map { $0.id })
                                        // Only keep heights for items that are currently visible
                                        itemHeights = itemHeights.filter { currentItemIds.contains($0.key) }
                                    }
                                }
                            }
                            .onAppear {
                                // Ensure column assignment exists when item appears
                                if itemColumnAssignments[item.id] == nil {
                                    updateColumnAssignments()
                                }
                            }
                            .onDisappear {
                                // Clear height cache when item scrolls off screen
                                // This allows LazyVStack to properly release the view's memory
                                itemHeights.removeValue(forKey: item.id)
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
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
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
        .onAppear {
            updateColumnAssignments()
        }
        .onChange(of: items.count) { oldValue, newValue in
            // Update assignments when items are added/removed
            updateColumnAssignments()
        }
    }
}
