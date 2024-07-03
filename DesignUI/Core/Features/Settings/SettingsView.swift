//
//  SettingsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import AuthenticationServices
import FirebaseFirestore
import FirebaseAuth
import CryptoKit
import StoreKit

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Review")) {
                    Button{
                        requestReview()
                    } label: {
                        HStack{
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.yellow)
                                .background(Color.indigo)
                                .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5, height: 5)))
                            Text("Rate Us")
                        }
                    }
                }
                
                Section(header: Text("Our Apps")) {
                    Link(destination: URL(string: "https://apps.apple.com/af/app/tasknow-simple-to-do-list/id1639588217")!) {
                        HStack {
                            Image("CryptoProfitLogo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(5)
                            Text("Crypto Profit Loss Calculator")
                                
                        }
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/us/app/tasknow-simple-to-do-list/id1639588217")!) {
                        HStack {
                            Image("TaskNowLogo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(10)
                            Text("TaskNow - Simple To Do List")
                        }
                    }
                }
                
                Section("Privacy & Support") {
                    Link(destination: URL(string: "https://www.aivirx.com/crypto-profit-loss-calculator/privacy-policy")!) {
                        Text("Privacy Policy")
                    }
                    Link(destination: URL(string: "https://www.aivirx.com/contact")!) {
                        Text("Contact Us")
                           
                    }
                }
            }
            .accentColor(colorScheme == .dark ? .white : .black)
            .navigationBarTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SupportView: View {
    var body: some View {
        Text("Support Information")
            .navigationBarTitle("Support")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        Text("Privacy Policy")
            .navigationBarTitle("Privacy Policy")
    }
}

#Preview{
    let store = Store()
    return SettingsView()
        .environmentObject(store)
}
