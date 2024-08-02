//
//  Home.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//

import SwiftUI
import FirebaseFirestore
import StatefulTabView

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedIndex = 0
    var body: some View {
        
        StatefulTabView{
            Tab(title: "Home", systemImageName: "house.fill") {
                HomeView()
            }
            Tab(title: "Upload", systemImageName: "plus.square.dashed") {
                UploadDesignView()
            }
            Tab(title: "Profile", systemImageName: "person.crop.circle") {
                ProfileView()
            }
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
                        
                        VStack{
                            Text("v1.0")
                                .foregroundStyle(Color.gray)
                                .font(.body)
                            
                            Text("Made in New York City")
                                .foregroundStyle(Color.gray)
                                .font(.body)
                        }
                        .padding()
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
                        media: "LoginScreen",
                        title: "Login Screen",
                        author: teamName,
                        description: "Basic Login Screen with Sign In With Apple Button, other options button and cover image.",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
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
                        description: "Simple settings menu view. Used to showcase settings within an app",
                        codeSnippet: "",
                        creationDate: Timestamp(date: Date()),
                        type: "image",
                        tags: ["Template","SwiftUI"]
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
                        tags: ["Template","SwiftUI"]
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
                        description: "Counter with ",
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
                        description: "",
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
                        description: " ",
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
                        description: " ",
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
                        description: "",
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
                        description: " ",
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
