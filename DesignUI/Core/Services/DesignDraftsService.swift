import Foundation
import Supabase

struct RemoteDesignDraft: Identifiable, Decodable {
    let id: UUID
    let title: String
    let devicePreset: String
    let designJSON: DesignTemplate

    enum CodingKeys: String, CodingKey {
        case id, title
        case devicePreset = "device_preset"
        case designJSON = "design_json"
    }
}

@MainActor
final class DesignDraftsViewModel: ObservableObject {
    @Published private(set) var drafts: [RemoteDesignDraft] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let client = SupabaseManager.shared.client

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await client
                .from("design_drafts")
                .select("id,title,device_preset,design_json")
                .eq("status", value: "draft")
                .order("created_at", ascending: false)
                .execute()
            drafts = try JSONDecoder().decode([RemoteDesignDraft].self, from: response.data)
        } catch {
            errorMessage = "Couldn’t load your AI drafts."
        }
    }
}
