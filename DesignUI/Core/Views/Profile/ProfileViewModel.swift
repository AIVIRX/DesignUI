
import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?  // Uses shared Profile model from Core/Models/Profile.swift
    @Published var isLoading = false
    @Published var error: String?
    
    let supabase = SupabaseManager.shared.client
    
    func fetchProfile() async {
        do {
            guard let userId = supabase.auth.currentUser?.id else { return }
            
            let response = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let fetchedProfile = try decoder.decode(Profile.self, from: response.data)
            
            DispatchQueue.main.async { // Ensure UI updates on the main thread
                self.profile = fetchedProfile
            }
        } catch {
            print("Error fetching profile: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
