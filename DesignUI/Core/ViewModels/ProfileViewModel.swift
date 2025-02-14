import Foundation

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading = false
    @Published var error: String?
    
    let supabase = SupabaseManager.shared.client
    
    func fetchProfile() async {
        isLoading = true
        
        do {
            let response: PostgrestResponse<Profile> = try await supabase.from("profiles")
                .select()
                .eq("id", value: supabase.auth.session?.user.id ?? "")
                .single()
                .execute()
            
            if let profile: Profile = try response.decode() {
                self.profile = profile
            }
        } catch {
            self.error = error.localizedDescription
            print("Error fetching profile: \(error)")
        }
        
        isLoading = false
    }
    
    func updateProfile(displayName: String, bio: String) async {
        isLoading = true
        
        do {
            let response: PostgrestResponse<Profile> = try await supabase.from("profiles")
                .update([
                    "display_name": displayName,
                    "bio": bio
                ])
                .eq("id", value: supabase.auth.session?.user.id ?? "")
                .single()
                .execute()
            
            if let updatedProfile: Profile = try response.decode() {
                self.profile = updatedProfile
            }
        } catch {
            self.error = error.localizedDescription
            print("Error updating profile: \(error)")
        }
        
        isLoading = false
    }
} 