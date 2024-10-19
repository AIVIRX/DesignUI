//
//  UserViewModel.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/10/24.
//

import Foundation
import Supabase

class UserViewModel: ObservableObject {
    @Published var profile: ProfileModel?
    let client = SupabaseManager.shared.client
    static let shared = UserViewModel()
    
    func fetchProfileData() async {
        do {
            let session = try await client.auth.session // Fetch session, can throw
            
            // Assuming the user ID is stored in the session as UUID
            let userId = session.user.id.uuidString // Convert UUID to String
            
            let profileData: ProfileModel = try await fetchProfileFromBackend(userId: userId)
            DispatchQueue.main.async {
                self.profile = profileData
            }
        } catch {
            print("Failed to fetch session or profile data: \(error.localizedDescription)")
        }
    }
    
    func fetchProfileFromBackend(userId: String) async throws -> ProfileModel {
        // Fetch profile data from Supabase
        let response = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
        
        print("Response data: \(String(describing: response.data))")
        
        if let jsonString = String(data: response.data, encoding: .utf8) {
            print("Fetched JSON: \(jsonString)")
        }
        
        // Check if response has data and decode it into an array of ProfileModel
        guard let profileData = try? JSONDecoder().decode([ProfileModel].self, from: response.data) else {
            throw NSError(domain: "ProfileDataError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }
        
        // Return the first profile
        guard let firstProfile = profileData.first else {
            throw NSError(domain: "ProfileDataError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No profiles found"])
        }
        return firstProfile
    }
}

