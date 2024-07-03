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
    @State private var isNewDesignsLoaded = false
    @State private var teamName = "Dock UI Team"
    @State private var selectedPost: DesignPost?
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @Environment(\.colorScheme) var colorScheme
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
                    VStack{
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
                                .padding(.top, 20)
                                .padding(.leading, 3)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 3) {
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
                    }.padding(.leading,10)
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
                
                //                if !store.completedPurchases.isEmpty {
                //                    AdView(adUnitID: "nil").frame(width: 320, height: 50)
                //                } else {
                //                    AdView(adUnitID: AdUnitID.testAds).frame(width: 320, height: 50)
                //                }
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
                        creationDate: "April 30, 2024",
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
                        creationDate: "May 1, 2023",
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
                        creationDate: "May 1, 2024",
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
                        creationDate: "May 1, 2024",
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
                        creationDate: "May 1, 2024",
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
                        creationDate: "May 1, 2023",
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
                        creationDate: "May 2, 2024",
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
                        creationDate: "May 2, 2024",
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
                        creationDate: "May 2, 2024",
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
                        creationDate: "May 2, 2024",
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
                        creationDate: "May 2, 2024",
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
                        creationDate: "May 2, 2024",
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
                        creationDate: "May 2, 2024",
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
    
    private func fetchCommunityPosts() async {
        let db = Firestore.firestore()
        do {
            let querySnapshot = try await db.collection("CommunityPosts").getDocuments()
            print("Fetched \(querySnapshot.documents.count) community posts")
            for document in querySnapshot.documents {
                print("Document ID: \(document.documentID)")
                if let post = try? document.data(as: DesignPost.self) {
                    DispatchQueue.main.async {
                        print("Appending post: \(post.title)")
                        self.communityPosts.append(post)
                    }
                } else {
                                    print("Failed to decode document with ID: \(document.documentID)")
                }
            }
        } catch {
            print("Error getting documents: \(error)")
        }
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
