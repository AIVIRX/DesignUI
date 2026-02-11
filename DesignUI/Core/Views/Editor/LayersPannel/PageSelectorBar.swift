//
//  PageSelectorBar.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/18/26.
//

import SwiftUI

// MARK: - Sidebar Pages View (Tile Layout)
struct SidebarPagesView: View {
    @ObservedObject var designFile: DesignFile
    @Binding var currentPageIndex: Int
    var onPageChange: ((Int) -> Void)?
    
    @State private var renamingPageId: UUID?
    @State private var renameText: String = ""
    @FocusState private var isRenamingFieldFocused: Bool
    
    // Grid columns for tile layout
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(designFile.pages.enumerated()), id: \.element.id) { index, page in
                    PageTileView(
                        page: page,
                        isSelected: index == currentPageIndex,
                        isRenaming: renamingPageId == page.id,
                        canDelete: index > 0, // First page cannot be deleted
                        renameText: $renameText,
                        onSelect: {
                            onPageChange?(index)
                            currentPageIndex = index
                        },
                        onRenameStart: {
                            renamingPageId = page.id
                            renameText = page.name
                            isRenamingFieldFocused = true
                        },
                        onRenameEnd: {
                            if !renameText.isEmpty {
                                designFile.renamePage(at: index, to: renameText)
                            }
                            renamingPageId = nil
                        },
                        onDuplicate: {
                            if let (_, newIndex) = designFile.duplicatePage(at: index) {
                                onPageChange?(newIndex)
                                currentPageIndex = newIndex
                            }
                        },
                        onDelete: {
                            if designFile.deletePage(at: index) {
                                onPageChange?(designFile.currentPageIndex)
                            }
                        }
                    )
                }
            }
            .padding(8)
        }
    }
}

// MARK: - Page Tile View
struct PageTileView: View {
    @ObservedObject var page: DesignPage
    let isSelected: Bool
    let isRenaming: Bool
    let canDelete: Bool // False for first page (home page)
    @Binding var renameText: String
    
    var onSelect: () -> Void
    var onRenameStart: () -> Void
    var onRenameEnd: () -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    
    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            // Thumbnail
            thumbnailView
            
            // Page name
            pageNameView
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.15) : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRenaming {
                onSelect()
            }
        }
        .onTapGesture(count: 2) {
            onRenameStart()
        }
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Rename") { onRenameStart() }
            Button("Duplicate") { onDuplicate() }
            if canDelete {
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
            }
        }
    }
    
    // MARK: - Thumbnail View
    private var thumbnailView: some View {
        Group {
            if let thumbnailData = page.thumbnail,
               let image = thumbnailImage(from: thumbnailData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.primary.opacity(0.05))
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .overlay(
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.5))
                    )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Page Name View
    private var pageNameView: some View {
        Group {
            if isRenaming {
                TextField("Page Name", text: $renameText, onCommit: onRenameEnd)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .focused($isFocused)
                    .onAppear { isFocused = true }
                    .onSubmit { onRenameEnd() }
            } else {
                Text(page.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }
    
    // MARK: - Helper
    private func thumbnailImage(from data: Data) -> Image? {
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #else
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #endif
        return nil
    }
}
