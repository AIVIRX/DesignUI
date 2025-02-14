import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?  // Mark as @Published to trigger view updates
    @Published var isLoading = false
    @Published var error: String?
    
    let supabase = SupabaseManager.shared.client
    
    struct Profile: Decodable {
        let display_name: String?
        let username: String?
    }
    
    func fetchProfile() async {
            do {
                let response = try await supabase
                    .from("profiles")
                    .select()
                    .eq("id", value: supabase.auth.currentUser?.id ?? "")
                    .single()
                    .execute()
                
                let decoder = JSONDecoder()
                let fetchedProfile = try decoder.decode(Profile.self, from: response.data)
                
                DispatchQueue.main.async { // Ensure UI updates on the main thread
                    self.profile = fetchedProfile
                }
            } catch {
                print("Error fetching profile: \(error.localizedDescription)")
            }
        isLoading = false
    }
}
