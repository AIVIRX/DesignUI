//
//  BlogViewModel.swift
//  DockUI
//
//  Created by Maicol Cabreja on 7/4/25.
//

import SwiftUI
import Supabase

class NewsViewModel: ObservableObject {
    @Published var posts: [NewsPost] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchNews() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            let response: [NewsPost] = try await SupabaseManager.shared.client
                .from("news")
                .select()
                .eq("public", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run {
                self.posts = response
                self.isLoading = false
            }
        } catch {
            print("Error fetching news:", error)
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Can’t load posts right now. Check your connection and try again."
            }
        }
    }
}
