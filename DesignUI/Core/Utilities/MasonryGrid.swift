//
//  MasonryGrid.swift
//  DockUI
//
//  Created by Assistant on 1/14/25.
//

import SwiftUI

/// Height storage that persists across view updates without causing cycles
final class MasonryHeightCache<ID: Hashable>: ObservableObject {
    private var heights: [ID: CGFloat] = [:]
    private var columnAssignments: [ID: Int] = [:]
    
    func getHeight(for id: ID) -> CGFloat {
        heights[id] ?? 250 // Default estimate
    }
    
    func setHeight(_ height: CGFloat, for id: ID) {
        guard height > 0, abs((heights[id] ?? 0) - height) > 1 else { return }
        heights[id] = height
    }
    
    func getColumn(for id: ID) -> Int? {
        columnAssignments[id]
    }
    
    func setColumn(_ column: Int, for id: ID) {
        columnAssignments[id] = column
    }
    
    func clearAssignments() {
        columnAssignments.removeAll()
    }
}

/// Pinterest-style masonry that places items in the shortest column
struct MasonryGrid<Item: Identifiable, Content: View>: View where Item.ID: Hashable {
    let items: [Item]
    let columns: Int
    let spacing: CGFloat
    let content: (Item) -> Content
    let loadMoreHandler: ((Item?) -> Void)?
    let hasMorePosts: Bool
    let isLoading: Bool
    
    @StateObject private var heightCache = MasonryHeightCache<Item.ID>()
    
    init(
        items: [Item],
        columns: Int = 2,
        spacing: CGFloat = 12,
        hasMorePosts: Bool = true,
        isLoading: Bool = false,
        loadMoreHandler: ((Item?) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.columns = columns
        self.spacing = spacing
        self.hasMorePosts = hasMorePosts
        self.isLoading = isLoading
        self.loadMoreHandler = loadMoreHandler
        self.content = content
    }
    
    /// Distributes items into columns by placing each in the shortest column
    private func distributeItems() -> [[Item]] {
        guard columns > 0 else { return [] }
        
        var columnArrays: [[Item]] = Array(repeating: [], count: columns)
        var columnHeights: [CGFloat] = Array(repeating: 0, count: columns)
        
        for item in items {
            // Check if item already has a valid assignment
            let assignedColumn: Int
            if let existingColumn = heightCache.getColumn(for: item.id), existingColumn < columns {
                // Use cached assignment only if it's still valid for current column count
                assignedColumn = existingColumn
            } else {
                // Find shortest column
                assignedColumn = columnHeights.enumerated()
                    .min(by: { $0.element < $1.element })?
                    .offset ?? 0
                heightCache.setColumn(assignedColumn, for: item.id)
            }
            
            columnArrays[assignedColumn].append(item)
            columnHeights[assignedColumn] += heightCache.getHeight(for: item.id) + spacing
        }
        
        return columnArrays
    }
    
    var body: some View {
        let distributedColumns = distributeItems()
        
        HStack(alignment: .top, spacing: spacing) {
            ForEach(0..<columns, id: \.self) { columnIndex in
                LazyVStack(spacing: spacing) {
                    if columnIndex < distributedColumns.count {
                        ForEach(distributedColumns[columnIndex]) { item in
                            content(item)
                                .frame(maxWidth: .infinity)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(key: ItemHeightPreferenceKey.self, value: [String(describing: item.id): geo.size.height])
                                    }
                                )
                        }
                    }
                    
                    // Load more trigger
                    if columnIndex == 0 && hasMorePosts && !isLoading && !items.isEmpty {
                        Color.clear
                            .frame(height: 50)
                            .onAppear {
                                loadMoreHandler?(items.last)
                            }
                    }
                    
                    // Loading indicator
                    if columnIndex == 0 && isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onPreferenceChange(ItemHeightPreferenceKey.self) { heights in
            // Update heights after render cycle completes
            DispatchQueue.main.async {
                for (idString, height) in heights {
                    // Find item with matching string ID
                    if let item = items.first(where: { String(describing: $0.id) == idString }) {
                        heightCache.setHeight(height, for: item.id)
                    }
                }
            }
        }
        .onChange(of: items.count) { oldCount, newCount in
            if newCount < oldCount {
                // Items removed, clear assignments to recalculate
                heightCache.clearAssignments()
            }
        }
    }
}

/// Preference key for collecting item heights
private struct ItemHeightPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGFloat] = [:]
    
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

/// Adaptive masonry grid with platform-aware column count
struct AdaptiveMasonryGrid<Item: Identifiable, Content: View>: View where Item.ID: Hashable {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content
    let loadMoreHandler: ((Item?) -> Void)?
    let hasMorePosts: Bool
    let isLoading: Bool
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(
        items: [Item],
        spacing: CGFloat = 12,
        hasMorePosts: Bool = true,
        isLoading: Bool = false,
        loadMoreHandler: ((Item?) -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.spacing = spacing
        self.hasMorePosts = hasMorePosts
        self.isLoading = isLoading
        self.loadMoreHandler = loadMoreHandler
        self.content = content
    }
    
    private var columnCount: Int {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            return 2
        } else {
            return horizontalSizeClass == .compact ? 3 : 5
        }
        #else
        return 5
        #endif
    }
    
    var body: some View {
        MasonryGrid(
            items: items,
            columns: columnCount,
            spacing: spacing,
            hasMorePosts: hasMorePosts,
            isLoading: isLoading,
            loadMoreHandler: loadMoreHandler,
            content: content
        )
    }
}
