//
//  AuthView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/12/24.
//

import SwiftUI
import Supabase
import AuthenticationServices

struct AuthView: View {
    @ObservedObject var authManager = AuthManager.shared
    @State private var isAuthenticated: Bool = false
    @State private var hasUsername: Bool = false
    @State private var userSession: Session?
    let client: SupabaseClient // Add this property to accept the SupabaseClient
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Show the main content view if authenticated and has a username
                ProfileView(client: client)
            } else {
                // Show the username setup view if authenticated but no username
                SignInView()
            }
        }
        .onAppear{
            authManager.checkSession()
        }
    }
}

