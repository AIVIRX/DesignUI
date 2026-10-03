//
//  SFSymbolPickerView.swift
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
        let query = debouncedSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(query) }
    }
    
    private var grid: [GridItem] {
        [GridItem(.adaptive(minimum: 70), spacing: 8)]
    }
    
    var body: some View {
        VStack(spacing: 10) {
#if os(macOS)
            searchHeader
#endif
            symbolGrid
        }
        .navigationTitle("Select SF Symbols")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
#endif
        .onChange(of: searchText, debounceSearch)
        .onDisappear { searchTask?.cancel() }
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
#endif
#if os(macOS)
        .frame(width: 420, height: 540)
#endif
    }

#if os(macOS)
    private var searchHeader: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search SF Symbols", text: $searchText)
                .textFieldStyle(.roundedBorder)
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
        .padding(.horizontal, 12)
    }
#endif

    private var symbolGrid: some View {
        ScrollView {
            LazyVGrid(columns: grid, spacing: 12) {
                ForEach(filteredSymbols, id: \.self) { symbol in
                    symbolCell(symbol)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func symbolCell(_ symbol: String) -> some View {
        Button(action: { selectSymbol(symbol) }) {
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
            .background(selectionBackground(for: symbol))
            .overlay(selectionStroke(for: symbol))
        }
        .buttonStyle(.plain)
    }

    private func selectionBackground(for symbol: String) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(selectedSymbol == symbol ? Color.blue.opacity(0.2) : Color.clear)
    }

    private func selectionStroke(for symbol: String) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(selectedSymbol == symbol ? Color.blue : Color.clear, lineWidth: 1)
    }

    private func selectSymbol(_ symbol: String) {
        selectedSymbol = symbol
        onSymbolSelected(symbol)
        dismiss()
    }

    private func debounceSearch(_: String, newValue: String) {
        searchTask?.cancel()
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 180_000_000)
            debouncedSearch = newValue
        }
    }
}
