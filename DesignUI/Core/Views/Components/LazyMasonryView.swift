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
        let columnsData = columnItems
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                columnView(columnIndex: columnIndex, itemsInColumn: columnsData[columnIndex])
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

    private func columnView(columnIndex: Int, itemsInColumn: [Item]) -> some View {
        LazyVStack(spacing: spacing) {
            ForEach(itemsInColumn) { item in
                masonryItemView(item)
            }
            loadMoreSentinel(for: itemsInColumn.last)
            if isLoading && columnIndex == 0 {
                loadingIndicator
            }
        }
    }

    private func masonryItemView(_ item: Item) -> some View {
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
                handleHeightChange(height, for: item.id)
            }
            .onAppear {
                if itemColumnAssignments[item.id] == nil {
                    updateColumnAssignments()
                }
            }
            .onDisappear {
                itemHeights.removeValue(forKey: item.id)
            }
    }

    @ViewBuilder
    private func loadMoreSentinel(for lastItem: Item?) -> some View {
        if hasMorePosts && !isLoading, let lastItem {
            Color.clear
                .frame(height: 100)
                .task {
                    loadMoreHandler?(lastItem)
                }
        }
    }

    private var loadingIndicator: some View {
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

    private func handleHeightChange(_ height: CGFloat, for id: Item.ID) {
        guard height > 0 else { return }
        itemHeights[id] = height

        if itemHeights.count > maxHeightCacheSize {
            let currentItemIds = Set(items.map { $0.id })
            itemHeights = itemHeights.filter { currentItemIds.contains($0.key) }
        }
    }
}
