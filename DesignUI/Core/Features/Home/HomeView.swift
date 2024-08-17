//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import FirebaseFirestore
#if os(iOS)
import StatefulTabView
#endif
import SDWebImage
import SDWebImageSwiftUI

enum ViewType: Hashable {
    case home, profile, sfIcons, shop
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    
    @State private var selectedView: ViewType? = .home
    @State private var isHomeHovered: Bool = false
    @State private var isProfileHovered: Bool = false
    @State private var isSFIconsHovered: Bool = false
    @State private var isShopHovered: Bool = false
    @State private var startAnimation: Bool = false
    
    var body: some View {
        
#if os(iOS)
        StatefulTabView{
            Tab(systemImageName: "house.fill") {
                HomeView()
            }
            
            Tab(systemImageName: "person.crop.circle") {
                ProfileView()
            }
        }
        .accentColor(colorScheme == .dark ? .white : .black)
#endif
        
#if os(macOS)
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 5) {
                // Home Link
                navigationLinkButton(viewType: .home, label: "Home", systemImage: "house", isHovered: $isHomeHovered)
                
                NavigationLink("LOL", destination: HomeView())
                    .buttonStyle(.plain)
                NavigationLink("LOyL", destination: ProfileView())
                // Profile Link
                navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.circle", isHovered: $isProfileHovered)
                
                Divider().padding(.vertical)
                
                // SF Symbols Link
                navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", isHovered: $isSFIconsHovered)
                
                // Shop Link
                navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", isHovered: $isShopHovered)
                
                Divider().padding(.vertical)
                
                // Rate Us Text
                Text("Rate Us")
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(.gray)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        requestReview()
                    }
                
                // Privacy Policy Link
                Link("Privacy Policy", destination: URL(string: "https://www.aivirx.com/dockui/privacy-policy")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(.gray)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                
                // Contact Us Link
                Link("Contact Us", destination: URL(string: "https://www.aivirx.com/contact")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(.gray)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                
                Spacer()
            }
            .padding()
            .background(Color.clear)
        } detail: {
            NavigationStack() {
                switch selectedView {
                case .home:
                    HomeView()
                case .profile:
                    ProfileView()
                case .sfIcons:
                    SFIconsView()
                case .shop:
                    OldStoreView()
                default:
                    Text("Select a view")
                }
            }
        }
#endif
        
    }
    
    private func navigationLinkButton(viewType: ViewType, label: String, systemImage: String, isHovered: Binding<Bool>) -> some View {
        Button(action: {
            // Reset navigation path to pop to root before switching views
            if selectedView != viewType {
                selectedView = viewType            // Switches to the selected view
            }
        }) {
            HStack {
                Label(label, systemImage: systemImage)
                    .font(.system(size: 15)).bold()
                    .foregroundColor(selectedView == viewType ? .black : .white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity) // Ensures the button takes up the full width
            .contentShape(Rectangle())
            .background(
                selectedView == viewType
                    ? Color.white
                    : (isHovered.wrappedValue ? Color.gray.opacity(0.2) : Color.clear)
            )
            .cornerRadius(8)
            .onHover { hovering in
                if selectedView != viewType {
                    isHovered.wrappedValue = hovering
                } else {
                    isHovered.wrappedValue = false
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}


struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var designPosts: [DesignPost] = []
    @State private var componentPosts: [DesignPost] = []
    @State private var communityPosts: [DesignPost] = []
    @State private var lastFetchedDocument: DocumentSnapshot?
    @State private var isNewDesignsLoaded = false
    @State private var hasMoreCommunityPosts = false
    @State private var teamName = "Dock UI"
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var searchText = ""
    @State private var showSearchResults = false
    @Environment(\.colorScheme) var colorScheme
    @State private var startAnimation: Bool = false
    @State private var opacity: Double = 0.0
    private let postsLimit = 10
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack {
                        VStack(alignment: .leading) {
                            
#if os(iOS)
                            QuickActionCard()
#endif
                            
                            Text("Featured")
                            
#if os(iOS)
                                .font(.title2)
#endif
                            
#if os(macOS)
                                .font(.title)
#endif
                                .fontWeight(.heavy)
                                .padding(.top, 10)
                                .padding(.leading, 3)
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 3) {
                                    ForEach(designPosts){ post in
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
#if os(iOS)
                                .font(.title2)
#endif
                            
#if os(macOS)
                                .font(.title)
#endif
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
#if os(iOS)
                                    .font(.title2)
#endif
                                
#if os(macOS)
                                    .font(.title)
#endif
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
                                        // Show More Button
                                        if hasMoreCommunityPosts {
                                            Button(action: {
                                                Task {
                                                    await fetchCommunityPosts()
                                                }
                                            }) {
                                                VStack{
                                                    Image(systemName: "arrowshape.right.circle")
                                                        .font(.title3)
                                                    
                                                    Text("Show More")
                                                        .foregroundColor(.blue)
                                                        .padding(.vertical, 10)
                                                        .frame(maxWidth: .infinity)
                                                }
                                                .frame(width: 139, height: 150)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.gray, lineWidth: 0.8)
                                                )
                                            }
                                        }
                                    }
                                }
                                .scrollClipDisabled()
                            }
                        }
#if os(iOS)
                        VStack{
                            Text("v\(Bundle.main.releaseVersionNumber ?? "")" )
                                .foregroundStyle(Color.gray)
                                .font(.body)
                            
                            Text("Made in New York City")
                                .foregroundStyle(Color.gray)
                                .font(.body)
                        }
                        .padding(.top, 15)
#endif
                    }
                    .padding(.leading, 10)
                    .offset(y: startAnimation ? 0 : 50)
                    .opacity(opacity)
                    
                }
                .navigationTitle("Dock UI Home")
#if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: HStack {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                    }
                })
#endif
            }
            .accentColor(.none)
        }
        .navigationViewStyle(DefaultNavigationViewStyle())
        
#if os(iOS)
        .navigationViewStyle(StackNavigationViewStyle())
#endif
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                startAnimation = true
                opacity = 1.0
            }
            store.loadStoredPurchases()
            if !isNewDesignsLoaded {
                let newDesigns = [
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "LoginScreen",
                        title: "Login Screen",
                        author: teamName,
                        description: "Basic Login Screen with Sign In With Apple Button, other options button, and background image.",
                        codeSnippet: """
                        //Login Template
                        struct LoginView: View {
                            
                            @Environment(\\.colorScheme) var colorScheme
                            
                            var body: some View {
                                GeometryReader { geo in
                                ZStack(alignment: .bottom){
                                    
                                    //background Image
                                        Image("IMG_1027_Original")
                                            .resizable()
                                            .offset(y: -100)
                                            .aspectRatio (contentMode: .fill)
                                            .frame(width: geo.size.width, height: geo.size.height)
                                    }
                                    
                                    //Gradient Masking
                                    .mask{
                                        Rectangle()
                                            .fill(LinearGradient(
                                                colors: [.gray, .gray, .gray, .gray, .gray.opacity(1.0), .gray.opacity(0.7), .gray.opacity(0.3), .clear, .clear
                                                        ],
                                                startPoint: .top,
                                                endPoint: .bottom))
                                    }
                                    .ignoresSafeArea()
                                    
                                    VStack(alignment: .leading){
                                        Spacer()
                                        //Tagline
                                        Text("Discover New York City! Beyond Limits!")
                                            .font(.title).bold()
                                        
                                        // Sign Up with Apple button
                                        Button(action: {
                                            // Handle Sign Up with Apple action
                                        }) {
                                            HStack {
                                                Image(systemName: "applelogo")
                                                    .foregroundColor(buttonTextColor)
                                                Text("Sign in with Apple")
                                                    .foregroundColor(buttonTextColor)
                                            }
                                            .frame(width: geo.size.width - 80)
                                            .padding()
                                            .background(buttonBackgroundColor)
                                            .cornerRadius(5)
                                        }
                                        .clipShape(.capsule)
                                        .padding(.top,  10)
                                        
                                        Button(action: {
                                            // Handle Sign Up with Apple action
                                        }) {
                                            HStack {
                                                Text("Other Options")
                                                    .foregroundColor(buttonTextColor)
                                            }
                                            .frame(width: geo.size.width - 80)
                                            .padding()
                                            .background(buttonBackgroundColor)
                                            .cornerRadius(5)
                                        }
                                        .clipShape(.capsule)
                                        .padding(.top,  10)
                                        
                                    }
                                    .frame(maxWidth: geo.size.width, alignment: .leading)
                                    .padding(20)
                                }
                            }
                            
                            var buttonBackgroundColor: Color {
                                    colorScheme == .dark ? .white : .black
                                }
                                
                                var buttonTextColor: Color {
                                    colorScheme == .dark ? .black : .white
                                }
                        }
""",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "WhatsNew",
                        title: "What's New",
                        author: teamName,
                        description: "Showcases new changes and features to your users.",
                        codeSnippet: """
                        //Whats New View
                        struct WhatsNewView: View {
                            var body: some View {
                                VStack{
                                    VStack(alignment: .center) {
                                        
                                        Text("What's New")
                                            .font(.title).bold()
                                        
                                        VStack(alignment: .leading) {
                                            InformationDetailView(title: "Travel", subTitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. ", imageName: "airplane.departure")
                                            
                                            InformationDetailView(title: "Transit", subTitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit.", imageName: "lightrail.fill")
                                            
                                            InformationDetailView(title: "Store ", subTitle: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", imageName: "folder.fill.badge.person.crop")
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            print("Continue button tapped")
                                        }) {
                                            Text("Continue")
                                                .frame(width: 300)
                                                .bold()
                                                .padding()
                                                .foregroundColor(.white)
                                                .background(Color.blue)
                                                .cornerRadius(15)
                                        }
                                        
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(20)
                                }
                            }
                            
                            struct InformationDetailView: View {
                                var title: String = "title"
                                var subTitle: String = "subTitle"
                                var imageName: String = "car"

                                var body: some View {
                                    HStack(alignment: .center) {
                                        Image(systemName: imageName)
                                            .font(.largeTitle)
                                            .foregroundColor(.indigo)
                                            .frame(width: 40, height: 40)
                                            .padding()
                                            .accessibility(hidden: true)

                                        VStack(alignment: .leading) {
                                            Text(title)
                                                .font(.headline).bold()
                                                .foregroundColor(.primary)
                                                .accessibility(addTraits: .isHeader)

                                            Text(subTitle)
                                                .font(.body)
                                                .foregroundColor(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    .padding(.top)
                                }
                            }
                        }
""",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ArticleTemplate",
                        title: "Article Template",
                        author: teamName,
                        description: "This provides a simple and modern Article template, perfect for showcasing articles or blog content in your app. The template includes a title, publication date, cover image, subheadings, and body text.",
                        codeSnippet: """
                        //Article Template
                        struct ArticleView: View {
                            var body: some View {
                                ScrollView {
                                    VStack(alignment: .leading) {
                                        // Title
                                        Text("Best Places To Visit In New York City")
                                            .font(.system(size: 36))
                                            .fontWeight(.heavy)
                                            .foregroundStyle(.primary)
                                        
                                        // Publish Date
                                        Text("Published: April 1, 2024")
                                            .font(.system(size: 20))
                                            .fontWeight(.heavy)
                                            .foregroundStyle(.secondary)
                                        
                                        // Cover Image
                                        Image("IMG_1027_Original")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 250)
                                            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                                            .clipped()
                                        
                                        // Introduction
                                        Text("New York City offers a plethora of iconic and captivating destinations for travelers in 2024. Here are the top must-visit places that should be on your list!")
                                            .font(.system(size: 22))
                                            .padding(.top, 10)
                                        
                                        // Subheading
                                        Text("Times Square:")
                                            .font(.system(size: 30))
                                            .fontWeight(.heavy)
                                            .padding(.top, 10)
                                        
                                        // Body
                                        Text("Known for its dazzling lights, Broadway theaters, and vibrant atmosphere, Times Square is the epitome of New York City's energy. From shopping to dining and entertainment, this hub has something for everyone.")
                                            .font(.system(size: 22))
                                    }
                                    .padding(10)
                                }
                            }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "SettingsTemplate",
                        title: "Settings Template",
                        author: teamName,
                        description: "Simple settings menu. Used to showcase settings within an app.",
                        codeSnippet: """
                        //Settings Template
                        struct SettingsView: View {
                            var body: some View {
                                NavigationView {
                                    List {
                                        Section(header: Text("Account")) {
                                            SettingsItem(symbolName: "person.circle", title: "Profile")
                                            SettingsItem(symbolName: "lock.circle", title: "Change Password")
                                            SettingsItem(symbolName: "creditcard.circle", title: "Payment Methods")
                                        }
                                        
                                        Section(header: Text("App Settings")) {
                                            SettingsItem(symbolName: "gearshape", title: "General")
                                            SettingsItem(symbolName: "bell", title: "Notifications")
                                            SettingsItem(symbolName: "paintbrush", title: "Appearance")
                                        }
                                        
                                        Section(header: Text("Legal")) {
                                            SettingsItem(symbolName: "message.circle", title: "Contact Us")
                                            SettingsItem(symbolName: "shield.lefthalf.fill", title: "Privacy Policy")
                                            SettingsItem(symbolName: "doc.plaintext", title: "Terms of Service")
                                        }
                                    }
                                    .listStyle(GroupedListStyle())
                                    .navigationBarTitle("Settings")
                                }
                            }
                        }
                        struct SettingsItem: View {
                            let symbolName: String
                            let title: String
                            var body: some View {
                                NavigationLink(destination: Text(title)) {
                                    Label(title, systemImage: symbolName)
                                        .font(.headline)
                                }
                            }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ProfileTemplate",
                        title: "Profile Template",
                        author: teamName,
                        description: "Simple template for a profile. Includes 3 views to organize a profile's information.",
                        codeSnippet: """
                        //profile Template
                        struct ProfileView: View {
                            var body: some View {
                                ScrollView{
                                    VStack(spacing: 20) {
                                        ProfileHeaderView()
                                        ProfileDetailsView()
                                        Divider()
                                        PostsView()
                                        Spacer()
                                    }
                                    .padding(8)
                                }
                            }
                        }
                        
                        struct ProfileHeaderView: View {
                            var body: some View {
                                VStack(spacing: 10) {
                                    //profile image
                                    Image("profilepfp")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .shadow(radius: 10)
                                    //display name
                                    Text("John Doe")
                                        .font(.title)
                                        .fontWeight(.bold)
                                    //username
                                    Text("@johndoe")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        struct ProfileDetailsView: View {
                            var body: some View {
                                VStack(alignment: .center, spacing: 20) {
                                    
                                    HStack(spacing:20){
                                        Spacer()
                                        //posts
                                        VStack{
                                            Text("590").bold()
                                            Text("Posts")
                                        }
                                        
                                        .frame(width: 80)
                                        //followers
                                        VStack{
                                            Text("420").bold()
                                            Text("Followers")
                                        }
                                        .frame(width: 80)
                                        
                                        //following
                                        VStack{
                                            Text("269").bold()
                                            Text("Following")
                                        }
                                        .frame(width: 80)
                                        
                                        Spacer()
                                    }
                                    
                                    //biography
                                    HStack(alignment: .center){
                                        Text("Making it easier for people to be insipred and design iOS apps. Discover Designs Today!")
                                            .font(.body).fontWeight(.regular)
                                            .multilineTextAlignment(.center)
                                    }
                                    
                                    //location
                                    HStack {
                                        //website
                                        VStack(alignment: .center, spacing: 5) {
                                            Text("www.aivirx.com")
                                                .font(.headline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        struct PostsView: View {
                            var body: some View {
                                VStack(alignment: .leading, spacing: 10) {
                                    ForEach(0..<5) { index in
                                        PostRow(index: index)
                                    }
                                }
                            }
                        }
                        
                        struct PostRow: View {
                            let index: Int
                            var body: some View {
                                //post image
                                
                                VStack(alignment: .leading){
                                    Image("IMG_1027_Original")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 380, height: 240)
                                        .cornerRadius(10)
                                    //post title
                                    VStack(alignment: .leading) {
                                        Text("A Day In The City")
                                            .font(.headline)
                                        //post description
                                        Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit.")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.bottom, 20)
                            }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "NavigationBar",
                        title: "Navigation Bar",
                        author: teamName,
                        description: "Organize your important views by having them in a navigation menu.",
                        codeSnippet: """
                        struct NavigationBar: View {
                            var body: some View {
                                TabView() {
                                    //First Tab
                                    ViewOne()
                                        .tabItem {
                                            Label("Home", systemImage: "house")
                                        }
                                    
                                    //Second tab
                                    ViewTwo()
                                        .tabItem {
                                            Label("Discover", systemImage: "magnifyingglass")
                                        }
                                    
                                    //Second tab
                                    ViewThree()
                                        .tabItem {
                                            Label("Activity", systemImage: "bell")
                                        }
                                    
                                    //Third Tab
                                    ViewFour()
                                        .tabItem {
                                            Label("Settings", systemImage: "gear")
                                        }
                                }
                            }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
                    ),
                ]
                
                let newComp = [
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "LikeAnim",
                        title: "Like Button",
                        author: teamName,
                        description: "Like button with bouncing effect.",
                        codeSnippet: """
                        //Like Button w Animation
                        struct LikeAnim: View {
                            @State var isLiked = false
                            var body: some View {
                                
                                    Button{
                                        self.isLiked.toggle()
                                    } label: {
                                        ZStack {
                                            like(image: Image(systemName: "heart.fill"), show: isLiked)
                                            like(image: Image(systemName: "heart"), show: !isLiked)
                                        }
                                }
                            }
                            func like(image: Image, show: Bool) -> some View {
                                    image
                                        .foregroundColor(isLiked ? .red : .gray)
                                        .font(.system(size: 60))
                                        .scaleEffect(show ? 1 : 0)
                                        .opacity(show ? 1 : 0)
                                        .animation(.interpolatingSpring(stiffness: 1000, damping: 20), value: show)
                                }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component", "Animation","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "Counter",
                        title: "Counter",
                        author: teamName,
                        description: "Counter with with incrementing and decrementing buttons",
                        codeSnippet: """
//Counter
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        HStack {
            Button(action: {
                count -= 1
            }) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(Color.primary)
            }
            
            Text("\\(count)")
                .padding(5)
            
            Button(action: {
                count += 1
            }) {
                Image(systemName: "plus.circle")
                    .foregroundStyle(Color.primary)
            }
        }
        //font size
        .font(.system(size: 35)).bold()
    }
}
""",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component", "SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ColorPicker",
                        title: "Color Picker",
                        author: teamName,
                        description: "Color Picker with checkmark showing the currently picked color",
                        codeSnippet: """
                        //Color Picker
                        struct ColorPickerView: View {
                            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .indigo, .cyan, .gray, .black]
                            
                            @State private var selectedColor: Color?
                            
                            var body: some View {
                                VStack {
                                    Text("Color Picker")
                                        .font(.title).bold()
                                        .padding()
                                    
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                                        ForEach(colors, id: \\.self) { color in
                                            Circle()
                                                .fill(color)
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    selectedColor == color ?
                                                    Image(systemName: "checkmark.circle")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 30, weight: .bold)) :
                                                        nil
                                                )
                                                .onTapGesture {
                                                    selectedColor = color
                                                }
                                        }
                                    }
                                    
                                      Text("Selected Color: \\(selectedColor?.description ?? "None")")
                                        .font(.title3).bold()
                                        .padding()
                                    
                                }
                                .frame(width: 300)
                            }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "FieldLimit",
                        title: "Text Field w/ Limit",
                        author: teamName,
                        description: "A text field with a character counter and a character limit.",
                        codeSnippet: """
//Textfield with counter
struct TextFieldView: View {
    @State private var inputText = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            //Textfield with counter
            TextFieldWithCounter(placehold: "Enter a Username", text: $inputText, maxLength: 50)
                .padding()
        }
        .padding()
        .navigationBarTitle("Custom TextField", displayMode: .inline)
    }
    
    // Custom TextField with character counter
    struct TextFieldWithCounter: View {
        let placehold: String
        @Binding var text: String
        let maxLength: Int
        
        var body: some View {
            VStack(alignment: .leading) {
                TextField(placehold, text: $text)
                    .padding()
                    .bold()
                    .frame(height: 50)
                    .overlay(RoundedRectangle(cornerRadius: 10.0).strokeBorder(Color.black, style: StrokeStyle(lineWidth: 2.0)))
                HStack{
                    Spacer()
                    Text("\\(text.count)/\\(maxLength)")
                        .font(.system(size: 15)).bold()
                        .foregroundColor(text.count > maxLength ? .red : .primary)
                }
            }
            .onChange(of: text) {
                if text.count > maxLength {
                    text = String(text.prefix(maxLength))
                }
            }
        }
    }
}
"""
                        ,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ProgressBar",
                        title: "Progress Bar",
                        author: teamName,
                        description: "Progress bar with increase and decrease buttons that change the progress",
                        codeSnippet: """
//Progress Bar
struct ProgressView: View {
    @State private var progressValue = 0.5

    var body: some View {
        VStack {
            Text("Progress Bar")
                .font(.title).bold()
                .padding()
            
            ProgressBar(progress: progressValue, barColor: .blue)
                .frame(height: 20)
                .padding()
            
            HStack {
                // Decrease progress
                Button(action: {
                    withAnimation {
                        progressValue = max(progressValue - 0.1, 0)
                    }
                }) {
                    Text("Decrease")
                }
                .padding()
                
                Spacer()
                
                // Increase progress
                Button(action: {
                    withAnimation {
                        progressValue = min(progressValue + 0.1, 1)
                    }
                }) {
                    Text("Increase")
                }
                .padding()
            }
        }
    }
    
    // Progress bar
    struct ProgressBar: View {
        var progress: Double
        var barColor: Color
        var barHeight: CGFloat = 10

        var body: some View {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: barHeight)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: barHeight)
                        .foregroundColor(barColor)
                        .cornerRadius(barHeight / 2)
                        .animation(.linear, value: progress)
                }
                .cornerRadius(barHeight / 2)
            }
        }
    }
}
""",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "OptionPicker",
                        title: "Option Picker",
                        author: teamName,
                        description: "Allow users to pick between options",
                        codeSnippet: """
                        //Option Picker
                        struct PickerView: View {
                            @State private var selectedOption = 0
                            let options = ["Option 1", "Option 2"]
                        
                            var body: some View {
                                VStack {
                                    Text("Select an Option")
                                        .font(.title).bold()
                                        .padding()
                                    
                                    Picker("Select an option", selection: $selectedOption) {
                                        ForEach(options.indices, id: \\.self) { index in
                                            Text(options[index]).tag(index)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    Text("Selected: \\(options[selectedOption])")
                                        .font(.title3).bold()
                                        .padding()
                                }
                                .padding()
                            }
                        }
                        """,
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component","SwiftUI"]
                    ),
                    DesignPost(
                        id:  UUID().uuidString,
                        media: "ToggleSwitch",
                        title: "Toggle Switch",
                        author: teamName,
                        description: "Can be used to allow users to enable or disable things.",
                        codeSnippet: """
//Button Switch
struct SwitchView: View {
    @State private var isSwitchOn = false

    var body: some View {
        VStack {
            Text("Toggle Switch")
                .font(.title).bold()
                .padding()
            
            Toggle(isOn: $isSwitchOn) {
                Text("Switch").bold()
            }
            .padding()
            
            Text("Switch is \\(isSwitchOn ? "On" : "Off")")
                .font(.title3).bold()
                .padding()
        }
        .padding()
        .navigationBarTitle("Toggle Switch", displayMode: .inline)
    }
}
""",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Component","SwiftUI"]
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
    
    struct SearchResultsView: View {
        @Binding var searchText: String
        var designPosts: [DesignPost]
        var componentPosts: [DesignPost]
        var communityPosts: [DesignPost]
        var body: some View {
            ScrollView{
                ForEach(filteredPosts(posts: communityPosts)) { post in
                    NavigationLink(destination: SearchResultCard(
                        id: post.id,
                        media: post.media,
                        title: post.title,
                        authorUID: post.author,
                        description: post.description,
                        codeSnippet: post.codeSnippet,
                        published: formattedDate(from: post.creationDate),
                        type: post.type,
                        tags: post.tags
                    )) {
                        HStack {
                            Image(post.media)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 130, height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary, lineWidth: 0.2)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(post.title)
                                    .font(.title3).bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                                Text(post.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                
                                Spacer()
                            }
                            .padding(5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding([.vertical, .horizontal], 5)
                    }
                }
                
                ForEach(filteredPosts(posts: designPosts)) { post in
                    SearchResultCard(
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
                
                
                
                ForEach(filteredPosts(posts: componentPosts)) { post in
                    NavigationLink(destination: SearchResultCard(
                        id: post.id,
                        media: post.media,
                        title: post.title,
                        authorUID: post.author,
                        description: post.description,
                        codeSnippet: post.codeSnippet,
                        published: formattedDate(from: post.creationDate),
                        type: post.type,
                        tags: post.tags
                    )) {
                        HStack {
                            Image(post.media)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 130, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.secondary, lineWidth: 0.2)
                                )
                            
                            VStack(alignment: .leading) {
                                Text(post.title)
                                    .font(.title3).bold()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(1)
                                Text(post.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)
                                
                                Spacer()
                            }
                            .padding(5)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding([.vertical, .horizontal], 5)
                    }
                }
            }
            .navigationTitle("Search Results")
        }
        
        private func filteredPosts(posts: [DesignPost]) -> [DesignPost] {
            guard !searchText.isEmpty else {
                return posts
            }
            return posts.filter { post in
                post.title.localizedCaseInsensitiveContains(searchText) ||
                post.description.localizedCaseInsensitiveContains(searchText) ||
                post.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
    }
    
    var sortedDesignPosts: [DesignPost] {
        designPosts.sorted(by: { $0.creationDate.dateValue() < $1.creationDate.dateValue() })
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
                DispatchQueue.main.async {
                    self.hasMoreCommunityPosts = false
                }
                isLoading = false
                return
            }
            
            DispatchQueue.main.async {
                self.lastFetchedDocument = querySnapshot.documents.last
                self.communityPosts.append(contentsOf: querySnapshot.documents.compactMap { document in
                    try? document.data(as: DesignPost.self)
                })
                
                // Check if more posts are available
                self.hasMoreCommunityPosts = querySnapshot.documents.count == postsLimit
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

extension Bundle {
    /// Retrieves the build version number from the app's Info.plist.
    /// - Returns: A string representing the build version number, or nil if not found.
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

func formattedDate(from timestamp: Timestamp) -> String {
    let date = timestamp.dateValue()
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter.string(from: date)
}

#Preview{
    let store = Store()
    return ContentView()
        .environmentObject(store)
}
