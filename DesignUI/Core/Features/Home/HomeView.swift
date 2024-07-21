//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//


import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedIndex = 0
    var body: some View {
        TabView(selection: $selectedIndex) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: selectedIndex == 0 ? "house.fill" : "house")
                    .environment(\.symbolVariants, .none)
                }
                .tag(0)
            UploadDesignView()
                .tabItem {
                    Label("Upload", systemImage: selectedIndex == 1 ? "plus.square.fill" : "plus.square.dashed")
                    .environment(\.symbolVariants, .none)
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: selectedIndex == 2 ? "person.crop.circle.fill" : "person.crop.circle")
                    .environment(\.symbolVariants, .none)
                }
                .tag(2)
        }
        .accentColor(colorScheme == .dark ? .white : .black)
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var designPosts: [DesignPost] = []
    @State private var componentPosts: [DesignPost] = []
    @State private var communityPosts: [DesignPost] = []
    @State private var lastFetchedDocument: DocumentSnapshot?
    @State private var isNewDesignsLoaded = false
    @State private var teamName = "Dock UI"
    @State private var selectedPost: DesignPost?
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    private let postsLimit = 2

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading) {
                        HStack(spacing: 3) {
                            LargeCardView(
                                name: "Shop",
                                height: 100,
                                fontSize: 35,
                                padding: 10,
                                colors: [.cyan, .purple, .black, .purple, .pink],
                                destination: StoreView()
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                    VStack {
                        VStack(alignment: .leading) {
                            Text("Featured")
                                .font(.title2)
                                .fontWeight(.heavy)
                                .padding(.top, 10)
                                .padding(.leading, 3)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 3) {
                                    ForEach(designPosts) { post in
                                        DesignCards(
                                            id: post.id,
                                            media: post.media,
                                            title: post.title,
                                            authorUID: post.author,
                                            description: post.description,
                                            codeSnippet: post.codeSnippet,
                                            published: formattedDate(from: post.creationDate),
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
                                .padding(.top, 20)
                                .padding(.leading, 3)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 3) {
                                    ForEach(componentPosts) { post in
                                        DesignCards(
                                            id: post.id,
                                            media: post.media,
                                            title: post.title,
                                            authorUID: post.author,
                                            description: post.description,
                                            codeSnippet: post.codeSnippet,
                                            published: formattedDate(from: post.creationDate),
                                            type: post.type,
                                            tags: post.tags
                                        )
                                    }
                                }
                            }
                            .scrollClipDisabled()
                        }
                        
                        if !communityPosts.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Community")
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .padding(.top, 20)
                                    .padding(.leading, 3)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 3) {
                                        ForEach(communityPosts) { post in
                                            DesignCards(
                                                id: post.id,
                                                media: post.media,
                                                title: post.title,
                                                authorUID: post.author,
                                                description: post.description,
                                                codeSnippet: post.codeSnippet,
                                                published: formattedDate(from: post.creationDate),
                                                type: post.type,
                                                tags: post.tags
                                            )
                                        }
                                        if !isLoading {
                                            Button(action: {
                                                Task {
                                                    await fetchCommunityPosts()
                                                }
                                            }) {
                                                Text("Show More")
                                                    .padding()
                                                    .frame(maxWidth: .infinity)
                                                    .background(Color.blue)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(10)
                                            }
                                            .padding(.top, 10)
                                            .padding(.horizontal, 3)
                                        } else {
                                            ProgressView()
                                                .padding(.top, 10)
                                                .padding(.horizontal, 3)
                                        }
                                    }
                                }
                                .scrollClipDisabled()
                            }
                        }
                        
                        Text("Version 1.0")
                            .padding()
                            .foregroundStyle(Color.gray)
                            .font(.caption)
                    }
                    .padding(.leading, 10)
                }
                .navigationTitle("Dock UI")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: HStack {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
            }
            .accentColor(.none)
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
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ProfileTemplate",
                        title: "Profile Template",
                        author: teamName,
                        description: "Simple template for a profile. Includes 5 views to organize profile info",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "SettingsTemplate",
                        title: "Settings Template",
                        author: teamName,
                        description: "Simple settings menu view. Used to showcase settings within an app",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "LoginScreen",
                        title: "Login Screen",
                        author: teamName,
                        description: "Basic Login Screen with Sign In With Apple Button, other options button and cover image.",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "WhatsNew",
                        title: "What's New",
                        author: teamName,
                        description: "Basic Login Screen with Sign In With Apple Button, other options button and cover image.",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "NavigationBar",
                        title: "Navigation Bar",
                        author: teamName,
                        description: "Simple template for a profile. Includes 5 views to organize profile info",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
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
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "Counter",
                        title: "Counter",
                        author: teamName,
                        description: "Counter with ",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ColorPicker",
                        title: "Color Picker",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "OptionPicker",
                        title: "Option Picker",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ProgressBar",
                        title: "Progress Bar",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "FieldLimit",
                        title: "Text Field w/ Limit",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ToggleSwitch",
                        title: "Toggle Switch",
                        author: teamName,
                        description: " ",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: nil
                    ),
                ]
                addNewAnims(newComp)
                addNewDesigns(newDesigns)
                isNewDesignsLoaded = true
            }
            
            Task {
                await fetchCommunityPosts()
            }
        }
    }
    
    var sortedDesignPosts: [DesignPost] {
        designPosts.sorted(by: { $0.creationDate.dateValue() < $1.creationDate.dateValue() })
    }
    
    func formattedDate(from timestamp: Timestamp) -> String {
        let date = timestamp.dateValue()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func fetchCommunityPosts() async {
        let db = Firestore.firestore()
        
        guard !isLoading else { return }
        
        isLoading = true
        
        do {
            var query = db.collection("posts").order(by: "creationDate", descending: true).limit(to: postsLimit)
            
            if let lastDocument = lastFetchedDocument {
                query = query.start(afterDocument: lastDocument)
            }
            
            let querySnapshot = try await query.getDocuments()
            if querySnapshot.documents.isEmpty {
                isLoading = false
                return
            }
            
            DispatchQueue.main.async {
                self.lastFetchedDocument = querySnapshot.documents.last
                self.communityPosts.append(contentsOf: querySnapshot.documents.compactMap { document in
                    try? document.data(as: DesignPost.self)
                })
            }
        } catch {
            print("Error getting documents: \(error)")
        }
        
        isLoading = false
    }
    
    func addNewDesigns(_ newDesigns: [DesignPost]) {
        designPosts.append(contentsOf: newDesigns)
    }
    
    func addNewAnims(_ newComp: [DesignPost]) {
        componentPosts.append(contentsOf: newComp)
    }
}

#Preview{
    let store = Store()
    return ContentView()
        .environmentObject(store)
}
