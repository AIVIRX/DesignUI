//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var designPosts: [DesignPost] = []
    @State private var componentPosts: [DesignPost] = []
    @State private var isNewDesignsLoaded = false
    @State private var teamName = "UI Snippet Team"
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) {
                                LargeCardView(destination: SFIconsView(), name: "SF Symbols")
                                LargeCardView(destination: ColorPaletteGeneratorView(), name: "Color Palette")
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("Featured")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .padding(.top, 30)
                            .padding(.leading, 3)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) {
                                ForEach(designPosts) { post in
                                    let cardType: DesignType = post.type == .gif ? .gif : .image
                                    DesignCards(id: post.id, image: post.image, title: post.title, author: post.author, description: post.description, codeSnippet: post.codeSnippet, published: post.published, type: cardType)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Components")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .padding(.top, 30)
                            .padding(.leading, 3)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 3) {
                                ForEach(componentPosts) { post in
                                    let cardType: DesignType = post.type == .gif ? .gif : .image
                                    DesignCards(id: post.id, image: post.image, title: post.title, author: post.author, description: post.description, codeSnippet: post.codeSnippet, published: post.published, type: cardType)
                                }
                            }
                        }
                    }
                }
                .padding(5)
                .navigationBarTitle("Crypto Profit Calculator")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: HStack {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                })
                Spacer()
                
                if !store.completedPurchases.isEmpty {
                    AdView(adUnitID: "nil").frame(width: 320, height: 50)
                } else {
                    AdView(adUnitID: AdUnitID.testAds).frame(width: 320, height: 50)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            store.loadStoredPurchases()
            if !isNewDesignsLoaded {
                let newDesigns = [
                    DesignPost(id: UUID().uuidString, image: "ArticleTemplate", title: "Article Template", author: teamName, description: "This provides a simple and modern Article template, perfect for showcasing articles or blog content in your app. The template includes a title, publication date, cover image, subheadings, and body text.", codeSnippet: "", published: "April 30, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "ProfileTemplate", title: "Profile Template", author: teamName, description: "Simple template for a profile. Includes 5 views to organize profile info", codeSnippet: "", published: "May 1, 2023", type: .image),
                    DesignPost(id: UUID().uuidString, image: "SettingsTemplate", title: "Settings Template", author: teamName, description: "Simple settings menu view. Used to showcase settings within an app", codeSnippet: "", published: "May 1, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "LoginScreen", title: "Login Screen", author: teamName, description: "Basic Login Screen with Sign In With Apple Button, other options button, and cover image.", codeSnippet: "", published: "May 1, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "WhatsNew", title: "What's New", author: teamName, description: "Basic Login Screen with Sign In With Apple Button, other options button, and cover image.", codeSnippet: "", published: "May 1, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "NavigationBar", title: "Navigation Bar", author: teamName, description: "Simple template for a profile. Includes 5 views to organize profile info", codeSnippet: "", published: "May 1, 2023", type: .image)
                ]
                
                let newComp = [
                    DesignPost(id: UUID().uuidString, image: "LikeAnim", title: "Like Button", author: teamName, description: "Like button with bouncing effect.", codeSnippet: "", published: "May 2, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "Counter", title: "Counter", author: teamName, description: "Counter with ", codeSnippet: "", published: "May 2, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "ColorPicker", title: "Color Picker", author: teamName, description: "", codeSnippet: "", published: "May 2, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "OptionPicker", title: "Option Picker", author: teamName, description: "", codeSnippet: "", published: "May 2, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "ProgressBar", title: "Progress Bar", author: teamName, description: "", codeSnippet: "", published: "May 2, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "FieldLimit", title: "Text Field w/ Limit", author: teamName, description: "", codeSnippet: "", published: "May 2, 2024", type: .image),
                    DesignPost(id: UUID().uuidString, image: "ToggleSwitch", title: "Toggle Switch", author: teamName, description: "", codeSnippet: "", published: "May 2, 2024", type: .image)
                ]
                
                addNewAnims(newComp)
                addNewDesigns(newDesigns)
                isNewDesignsLoaded = true
            }
        }
    }
    
    func addNewDesigns(_ newDesigns: [DesignPost]) {
        designPosts.append(contentsOf: newDesigns)
    }
    
    func addNewAnims(_ newComp: [DesignPost]) {
        componentPosts.append(contentsOf: newComp)
    }
}
