//
//  PromptLogManager.swift
//
//  Created by Codex on 4/27/26.
//

import Foundation

final class PromptLogManager {
    static let shared = PromptLogManager()

    private let supabase = SupabaseManager.shared.client

    private init() {}

    private struct PromptLogPayload: Encodable {
        let user_id: String
        let prompt: String
        let prompt_length: Int
        let selected_component_type: String?
        let has_selection: Bool
        let generation_mode: String
        let daily_count_at_request: Int
        let daily_limit: Int
        let created_at: String
    }

    func logLocalPrompt(_ prompt: String, selectedComponentType: String?) async {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let user = supabase.auth.currentUser else { return }

        let payload = PromptLogPayload(
            user_id: user.id.uuidString,
            prompt: trimmed,
            prompt_length: trimmed.count,
            selected_component_type: selectedComponentType,
            has_selection: selectedComponentType != nil,
            generation_mode: "local_action",
            daily_count_at_request: 0,
            daily_limit: 0,
            created_at: ISO8601DateFormatter().string(from: Date())
        )

        do {
            _ = try await supabase
                .from("ai_prompts")
                .insert(payload)
                .execute()
        } catch {
            print("PromptLogManager.logLocalPrompt failed: \(error)")
        }
    }
}
