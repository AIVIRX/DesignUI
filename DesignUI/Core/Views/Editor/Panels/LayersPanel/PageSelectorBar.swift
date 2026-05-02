//
//  PageSelectorBar.swift
//
//  Created by Maicol Cabreja on 1/18/26.
//

import SwiftUI

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
    
    private struct IndexedPage: Identifiable {
        let index: Int
        let page: DesignPage
        var id: UUID { page.id }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(indexedPages) { item in
                    pageTile(for: item)
                }
            }
            .padding(8)
        }
    }
    
    private var indexedPages: [IndexedPage] {
        Array(designFile.pages.enumerated()).map { IndexedPage(index: $0.offset, page: $0.element) }
    }
    
    private func pageTile(for item: IndexedPage) -> some View {
        PageTileView(
            page: item.page,
            isSelected: item.index == currentPageIndex,
            isRenaming: renamingPageId == item.page.id,
            canDelete: item.index > 0,
            renameText: $renameText,
            onSelect: {
                selectPage(at: item.index)
            },
            onRenameStart: {
                startRenaming(item.page)
            },
            onRenameEnd: {
                finishRenaming(at: item.index)
            },
            onDuplicate: {
                duplicatePage(at: item.index)
            },
            onDelete: {
                deletePage(at: item.index)
            }
        )
    }
    
    private func selectPage(at index: Int) {
        onPageChange?(index)
        currentPageIndex = index
    }
    
    private func startRenaming(_ page: DesignPage) {
        renamingPageId = page.id
        renameText = page.name
        isRenamingFieldFocused = true
    }
    
    private func finishRenaming(at index: Int) {
        if !renameText.isEmpty {
            designFile.renamePage(at: index, to: renameText)
        }
        renamingPageId = nil
    }
    
    private func duplicatePage(at index: Int) {
        if let (_, newIndex) = designFile.duplicatePage(at: index) {
            onPageChange?(newIndex)
            currentPageIndex = newIndex
        }
    }
    
    private func deletePage(at index: Int) {
        if designFile.deletePage(at: index) {
            onPageChange?(designFile.currentPageIndex)
        }
    }
}

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
            thumbnailView
            pageNameView
        }
        .padding(6)
        .background(tileBackground)
        .overlay(tileBorder)
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
        .contextMenu(menuItems: contextMenuContent)
    }
    
    private var tileBackgroundFill: Color {
        if isSelected { return Color.blue.opacity(0.15) }
        if isHovered { return Color.primary.opacity(0.05) }
        return .clear
    }
    
    private var tileBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(tileBackgroundFill)
    }
    
    private var tileBorderColor: Color {
        isSelected ? .blue : .clear
    }
    
    private var tileBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(tileBorderColor, lineWidth: 2)
    }
    
    @ViewBuilder
    private func contextMenuContent() -> some View {
        Button("Rename", action: onRenameStart)
        Button("Duplicate", action: onDuplicate)
        if canDelete {
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }
    
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
