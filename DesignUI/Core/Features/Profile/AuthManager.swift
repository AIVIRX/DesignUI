//
//  AuthManager.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/15/24.
//

import SwiftUI
import Supabase

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = true
    let client = SupabaseManager.shared.client
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        do {
            currentUser = try await client.auth.session.user
            isAuthenticated = currentUser != nil
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
}
