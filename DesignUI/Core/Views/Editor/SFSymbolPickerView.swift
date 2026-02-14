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
        guard !debouncedSearch.isEmpty else { return symbols }
        return symbols.filter { $0.localizedCaseInsensitiveContains(debouncedSearch) }
    }
    
    private var grid: [GridItem] {
        [GridItem(.adaptive(minimum: 70), spacing: 8)]
    }
    
    var body: some View {
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
        .navigationTitle("Select SF Symbols")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        #endif
        .onChange(of: searchText) { _, newValue in
            searchTask?.cancel()
            searchTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 180_000_000)
                debouncedSearch = newValue
            }
        }
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
#endif
#if os(macOS)
        .frame(width: 400, height: 500)
#endif
    }
}
