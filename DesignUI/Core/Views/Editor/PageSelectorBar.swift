//
//  PageSelectorBar.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 1/18/26.
//

import SwiftUI

// MARK: - Sidebar Pages View
struct SidebarPagesView: View {
    @ObservedObject var designFile: DesignFile
    @Binding var currentPageIndex: Int
    var onPageChange: ((Int) -> Void)?
    
    @State private var renamingPageId: UUID?
    @State private var renameText: String = ""
    @FocusState private var isRenamingFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            
            // List
            ScrollView {
                VStack(spacing: 1) {
                    ForEach(Array(designFile.pages.enumerated()), id: \.element.id) { index, page in
                        SidebarPageRow(
                            page: page,
                            isSelected: index == currentPageIndex,
                            isRenaming: renamingPageId == page.id,
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
                .padding(.horizontal, 8)
            }
        }
    }
}

struct SidebarPageRow: View {
    @ObservedObject var page: DesignPage
    let isSelected: Bool
    let isRenaming: Bool
    @Binding var renameText: String
    
    var onSelect: () -> Void
    var onRenameStart: () -> Void
    var onRenameEnd: () -> Void
    var onDuplicate: () -> Void
    var onDelete: () -> Void
    
    @State private var isHovered = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Icon
            Image(systemName: "doc.text")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 32)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(4)
            
            // Name
            if isRenaming {
                TextField("Page Name", text: $renameText, onCommit: onRenameEnd)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onAppear { isFocused = true }
                    .onSubmit { onRenameEnd() } // Ensure submit triggers end
            } else {
                Text(page.name)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.blue : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
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
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
