import SwiftUI

struct DesignDraftsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = DesignDraftsViewModel()
    let onOpen: (RemoteDesignDraft) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.drafts.isEmpty {
                    ProgressView("Loading AI drafts…")
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView("Couldn’t load drafts", systemImage: "exclamationmark.triangle", description: Text(error))
                } else if viewModel.drafts.isEmpty {
                    ContentUnavailableView("No AI drafts yet", systemImage: "sparkles", description: Text("Your next batch will appear here for review."))
                } else {
                    List(viewModel.drafts) { draft in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(draft.title).font(.headline)
                            Text(draft.devicePreset).font(.subheadline).foregroundStyle(.secondary)
                            Button("Open in Editor") {
                                onOpen(draft)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("AI Drafts")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button { Task { await viewModel.load() } } label: { Image(systemName: "arrow.clockwise") }
                        .accessibilityLabel("Refresh drafts")
                }
            }
            .task { await viewModel.load() }
        }
        #if os(macOS)
        .frame(minWidth: 720, idealWidth: 820, minHeight: 560, idealHeight: 680)
        #endif
    }
}
