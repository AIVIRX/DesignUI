//
//  SettingsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.colorScheme) var colorScheme
    private let url = URL(string: "https://apps.apple.com/us/app/crypto-profit-loss-calculator/id1638849680")!
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .padding()
                Spacer()
            }
            NavigationLink(destination: StoreView()) {
                ZStack {
                    Color.indigo
                        .cornerRadius(20)
                    HStack {
                        VStack {
                            HStack {
                                Text("Shop")
                                    .foregroundColor(Color.white)
                                    .font(.title2)
                                    .bold()
                                Spacer()
                            }
                            HStack {
                                Text("Remove ads forever!")
                                    .foregroundColor(Color.white)
                                    .font(.callout)
                                Spacer()
                            }
                        }.padding()
                        VStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.yellow)
                                .padding()
                        }
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 40)
            .padding()
            
            List {
                Section("Support Us") {
                    Link(destination: URL(string: "https://apps.apple.com/af/app/tasknow-simple-to-do-list/id1639588217")!) {
                        HStack {
                            Image("CryptoProfitLogo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(10)
                            Text("Crypto Profit Loss Calculator")
                                .foregroundColor(colorScheme == .light ? .black : .white)
                        }
                    }
                    
                    Link(destination: URL(string: "https://apps.apple.com/us/app/tasknow-simple-to-do-list/id1639588217")!) {
                        HStack {
                            Image("TaskNowLogo")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .cornerRadius(10)
                            Text("TaskNow - Simple To Do List")
                                .foregroundColor(colorScheme == .light ? .black : .white)
                        }
                    }
                }
                
                Section("Privacy & Support") {
                    Link(destination: URL(string: "https://www.aivirx.com/crypto-profit-loss-calculator/privacy-policy")!) {
                        Text("Privacy Policy")
                            .foregroundColor(colorScheme == .light ? .black : .white)
                    }
                    Link(destination: URL(string: "https://www.aivirx.com/contact")!) {
                        Text("Contact Us")
                            .foregroundColor(colorScheme == .light ? .black : .white)
                    }
                }
            }
            Spacer()
            if !store.completedPurchases.isEmpty {
                AdView(adUnitID: "nil").frame(width: 320, height: 50)
            } else {
                AdView(adUnitID: AdUnitID.testAds).frame(width: 320, height: 50).padding([.top], 10)
            }
        }
        .navigationTitle("Settings")
    }
}
