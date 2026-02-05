//
//  SFSymbolPickerView.swift
//  DesignUI
//
//  Split from PropertiesPanelView.swift
//

import SwiftUI

struct SFSymbolPickerView: View {
    @Binding var selectedSymbol: String
    let onSymbolSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var debouncedSearch = ""
    @State private var searchTask: Task<Void, Never>?
    
    private var filteredSymbols: [String] {
        guard !debouncedSearch.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(debouncedSearch) }
    }
    
    private var grid: [GridItem] {
        [GridItem(.adaptive(minimum: 70), spacing: 8)]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select SF Symbol")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.clear)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search SF Symbols", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, newValue in
                        searchTask?.cancel()
                        searchTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 180_000_000)
                            debouncedSearch = newValue
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.clear)
            
            Divider()
            
            // Symbols grid
            ScrollView {
                LazyVGrid(columns: grid, spacing: 12) {
                    ForEach(filteredSymbols, id: \.self) { symbol in
                        Button(action: {
                            selectedSymbol = symbol
                            onSymbolSelected(symbol)
                            dismiss()
                        }) {
                            VStack(spacing: 6) {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                                    .symbolRenderingMode(.hierarchical)
                                
                                Text(symbol)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            .frame(width: 70, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedSymbol == symbol ? Color.blue.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedSymbol == symbol ? Color.blue : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .frame(width: 400, height: 500) // Fixed width and height for popover to support scrolling
    }
}

// MARK: - Image Picker Editor

