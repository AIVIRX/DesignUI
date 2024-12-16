//
//  ProfileView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/15/24.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthManager.shared
    var body: some View {
        Text("Hello, ")
        
        Button("Sign Out"){
            Task{
                await authManager.signOut()
            }
        }
    }
}

#Preview {
    ProfileView()
}
