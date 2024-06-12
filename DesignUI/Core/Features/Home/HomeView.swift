//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: Store
    @State private var designPosts: [DesignPost] = []
    @State private var componentPosts: [DesignPost] = []
    @State private var isRefreshing: Bool = false
    @Environment(\.refresh) private var refresh
    @State private var isNewDesignsLoaded = false
    @State private var teamName = "UI Snippet Team"
    @Namespace var namespace
    @State private var selectedPost: DesignPost?

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
                                    DesignCards(
                                        id: post.id,
                                        media: post.media,
                                        title: post.title,
                                        author: post.author,
                                        description: post.description,
                                        codeSnippet: post.codeSnippet,
                                        published: post.creationDate,
                                        type: post.type,
                                        tags: post.tags
                                    )
                                }
                            }
                        }
                        .scrollClipDisabled()
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
                                    DesignCards(
                                        id: post.id,
                                        media: post.media,
                                        title: post.title,
                                        author: post.author,
                                        description: post.description,
                                        codeSnippet: post.codeSnippet,
                                        published: post.creationDate,
                                        type: post.type,
                                        tags: post.tags
                                    )
                                }
                            }
                        }
                        .scrollClipDisabled()
                    }
                }
                .padding(5)
                .navigationBarTitle("Snippets UI")
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
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ArticleTemplate",
                        title: "Article Template",
                        author: teamName,
                        description: "This provides a simple and modern Article template, perfect for showcasing articles or blog content in your app. The template includes a title, publication date, cover image, subheadings, and body text.",
                        codeSnippet: "",
                        creationDate: "April 30, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ProfileTemplate",
                        title: "Profile Template",
                        author: teamName,
                        description: "Simple template for a profile. Includes 5 views to organize profile info",
                        codeSnippet: "",
                        creationDate: "May 1, 2023",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "SettingsTemplate",
                        title: "Settings Template",
                        author: teamName,
                        description: "Simple settings menu view. Used to showcase settings within an app",
                        codeSnippet: "",
                        creationDate: "May 1, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "LoginScreen",
                        title: "Login Screen",
                        author: teamName,
                        description: "Basic Login Screen with Sign In With Apple Button, other options button and cover image.",
                        codeSnippet: "",
                        creationDate: "May 1, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "WhatsNew",
                        title: "What's New",
                        author: teamName,
                        description: "Basic Login Screen with Sign In With Apple Button, other options button and cover image.",
                        codeSnippet: "",
                        creationDate: "May 1, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "NavigationBar",
                        title: "Navigation Bar",
                        author: teamName,
                        description: "Simple template for a profile. Includes 5 views to organize profile info",
                        codeSnippet: "",
                        creationDate: "May 1, 2023",
                        type: .image,
                        tags: nil
                    ),
                ]
                let newComp = [
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "LikeAnim",
                        title: "Like Button",
                        author: teamName,
                        description: "Like button with bouncing effect.",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "Counter",
                        title: "Counter",
                        author: teamName,
                        description: "Counter with ",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ColorPicker",
                        title: "Color Picker",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "OptionPicker",
                        title: "Option Picker",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ProgressBar",
                        title: "Progress Bar",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "FieldLimit",
                        title: "Text Field w/ Limit",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ToggleSwitch",
                        title: "Toggle Switch",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: "May 2, 2024",
                        type: .image,
                        tags: nil
                    ),
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
