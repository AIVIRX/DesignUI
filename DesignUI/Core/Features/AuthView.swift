//
//  AuthView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/15/24.
//

import SwiftUI

struct AuthView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView()
            } else if authManager.isAuthenticated {
                ProfileView()
            } else {
                LoginView()
            }
        }
    }
}

#Preview {
    AuthView()
}
