import Foundation
import Supabase

class BlogViewModel: ObservableObject {
    @Published var posts: [NewsPost] = []
    @Published var isLoading = false
    @Published var error: String?

    private let supabase = SupabaseManager.shared.client

    @MainActor
    func fetchPosts() async {
        isLoading = true
        error = nil
        do {
            let response = try await supabase
                .from("news")
                .select()
                .eq("public", value: true)
                .order("created_at", ascending: false)
                .execute()
            print("[BlogViewModel] Raw response data: \(String(data: response.data, encoding: .utf8) ?? "<nil>")")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let posts = try decoder.decode([NewsPost].self, from: response.data)
            print("[BlogViewModel] Decoded posts count: \(posts.count)")
            self.posts = posts
        } catch {
            print("[BlogViewModel] Error: \(error)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }
} 