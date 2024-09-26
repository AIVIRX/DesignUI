//
//  ContentView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 8/18/24.
//

import SwiftUI
#if os(iOS)
import StatefulTabView
#endif

enum ViewType: Hashable {
    case home, explore, upload, profile, sfIcons, shop
}

struct ContentView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @State private var isHomeHovered: Bool = false
    @State private var isExploreHovered: Bool = false
    @State private var isProfileHovered: Bool = false
    @State private var isSFIconsHovered: Bool = false
    @State private var isShopHovered: Bool = false
    @State private var startAnimation: Bool = false
    @State private var isRateUsHovered: Bool = false
    @State private var isPolicyHovered: Bool = false
    @State private var isContactHovered: Bool = false
    @State private var isIGHovered: Bool = false
    @State private var isDiscordHovered: Bool = false
    @State private var isEditorHovered: Bool = false
    @AppStorage("selectedIndex") var selectedIndex: Int = 0
    var body: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack{
                if store.completedPurchases.isEmpty {
                    AdView(adUnitID: AdUnitID.finalAd)
                        .frame(width: 320, height: 50)
                        .padding(3)
                }
                
                StatefulTabView(selectedIndex: $selectedIndex){
                    Tab(systemImageName: "house.fill") {
                        HomeView() //Home Page
                    }
                    
                    Tab(systemImageName: "magnifyingglass") {
                        ExploreView() //Explore Page
                    }
                    
//                    Tab(systemImageName: "plus.app.fill") {
//                        UploadDesignView() // Upload Page
//                    }
                    
                    Tab(systemImageName: "person.crop.circle") {
                        ProfileView() //Profile Page
                    }
                }
                .accentColor(colorScheme == .dark ? .white : .black)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                VStack(alignment: .leading, spacing: 5) {
                    // Home Tab
                    navigationLinkButton(viewType: .home, label: "Home", systemImage: "house", isHovered: $isHomeHovered, selectedIndex: $selectedIndex, currentIndex: 0)
                    
                    // Search Tab
                    navigationLinkButton(viewType: .explore, label: "Explore", systemImage: "magnifyingglass", isHovered: $isExploreHovered, selectedIndex: $selectedIndex, currentIndex: 1)
                    
                    // Profile Tab
                    navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.circle", isHovered: $isProfileHovered, selectedIndex: $selectedIndex, currentIndex: 2)
                    
                    Divider().padding(.vertical)
                    
                    // SF Symbols Link
                    navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", isHovered: $isSFIconsHovered, selectedIndex: $selectedIndex, currentIndex: 3)
                    
                    // Shop Link
                    navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", isHovered: $isShopHovered, selectedIndex: $selectedIndex, currentIndex: 4)
                    
                    Divider().padding(.vertical)
                    
                    // Rate Us Text
                    Text("Rate Us")
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(isRateUsHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))
                        .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            requestReview()
                        }
                        .onHover { hovering in
                            isRateUsHovered = hovering
                        }
                    
                    Link("Instagram", destination: URL(string: "https://www.instagram.com/dockui")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(isRateUsHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))
                        .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isIGHovered = hovering
                        }
                    
                    Link("Discord", destination: URL(string: "https://discord.gg/9aq3c2MF3m")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(isDiscordHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))
                        .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isDiscordHovered = hovering
                        }
                    
                    // Privacy Policy Link
                    Link("Privacy Policy", destination: URL(string: "https://www.aivirx.com/dockui/privacy-policy")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(isPolicyHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))                    .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isPolicyHovered = hovering
                        }
                    
                    // Contact Us Link
                    Link("Contact Us", destination: URL(string: "https://www.aivirx.com/contact")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(isContactHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))                    .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            isContactHovered = hovering
                        }
                    
                    Spacer()
                    
                    HStack{
                        Spacer()
                        VStack{
                            Text("v\(Bundle.main.releaseVersionNumber ?? "")" )
                                .foregroundStyle(Color.gray)
                                .font(.body)
                            
                            Text("Made in New York City")
                                .foregroundStyle(Color.gray)
                                .font(.body)
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color.clear)
                .navigationSplitViewColumnWidth(230)
            }
            detail: {
                NavigationStack() {
                    switch selectedIndex {
                    case 0:
                        HomeView()
                    case 1:
                        ExploreView()
                    case 2:
                        ProfileView()
                    case 3:
                        SFIconsView()
                    case 4:
                        OldStoreView()
                    default:
                        Text("Select a view")
                    }
                }
            }
        }
#endif
        
#if os(macOS)
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 5) {
                // Home Link
                navigationLinkButton(viewType: .home, label: "Home", systemImage: "house", isHovered: $isHomeHovered,selectedIndex: $selectedIndex, currentIndex: 0)
                
                // Search Tab
                navigationLinkButton(viewType: .explore, label: "Explore", systemImage: "magnifyingglass", isHovered: $isExploreHovered, selectedIndex: $selectedIndex, currentIndex: 1)
                
                // Profile Link
                navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.circle", isHovered: $isProfileHovered, selectedIndex: $selectedIndex, currentIndex: 2)
                
                Divider().padding(.vertical)
                
                // SF Symbols Link
                navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", isHovered: $isSFIconsHovered, selectedIndex: $selectedIndex, currentIndex: 3)
                
                // Shop Link
                navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", isHovered: $isShopHovered, selectedIndex: $selectedIndex, currentIndex: 4)
                
                Divider().padding(.vertical)
                
                // Rate Us Text
                Text("Rate Us")
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(isRateUsHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        requestReview()
                    }
                    .onHover { hovering in
                        isRateUsHovered = hovering
                    }
                
                Link("Instagram", destination: URL(string: "https://www.instagram.com/dockui")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(isIGHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isIGHovered = hovering
                    }
                
                Link("Discord", destination: URL(string: "https://discord.gg/9aq3c2MF3m")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(isDiscordHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isDiscordHovered = hovering
                    }
                
                // Privacy Policy Link
                Link("Privacy Policy", destination: URL(string: "https://www.aivirx.com/dockui/privacy-policy")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(isPolicyHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isPolicyHovered = hovering
                    }
                
                // Contact Us Link
                Link("Contact Us", destination: URL(string: "https://www.aivirx.com/contact")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(isContactHovered ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .gray : .gray))                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isContactHovered = hovering
                    }
                
                Spacer()
                
                HStack{
                    Spacer()
                    VStack{
                        Text("v\(Bundle.main.releaseVersionNumber ?? "")" )
                            .foregroundStyle(Color.gray)
                            .font(.body)
                        
                        Text("Made in New York City")
                            .foregroundStyle(Color.gray)
                            .font(.body)
                    }
                    Spacer()
                }
            }
            .padding()
            .background(Color.clear)
            .navigationSplitViewColumnWidth(230)
        }
        detail: {
            NavigationStack() {
                switch selectedIndex {
                case 0:
                    HomeView()
                case 1:
                    ExploreView()
                case 2:
                    ProfileView()
                case 3:
                    SFIconsView()
                case 4:
                    OldStoreView()
                default:
                    Text("Select a view")
                }
            }
        }
#endif
    }
    
    private func navigationLinkButton(viewType: ViewType, label: String, systemImage: String, isHovered: Binding<Bool>, selectedIndex: Binding<Int>, currentIndex: Int) -> some View {
        let isSelected = $selectedIndex.wrappedValue == currentIndex
        let backgroundColor: Color
        let textColor: Color
        
        if isSelected {
            // Colors when the view is selected
            backgroundColor = colorScheme == .dark ? .white : .black
            textColor = colorScheme == .dark ? .black : .white
        } else if isHovered.wrappedValue {
            // Colors when the view is hovered but not selected
            backgroundColor = colorScheme == .dark ? Color.gray.opacity(0.2) : Color.black.opacity(0.2)
            textColor = colorScheme == .dark ? .white : .black
        } else {
            // Default colors when neither selected nor hovered
            backgroundColor = .clear
            textColor = colorScheme == .dark ? .white : .black
        }
        
        return NavigationLink(destination: getDestinationView(for: viewType)) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 15)).bold()
                    .foregroundColor(textColor)
                    .frame(width: 30)
                Text(label)
                    .font(.system(size: 15)).bold()
                    .foregroundColor(textColor)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(backgroundColor)
            .cornerRadius(8)
            .onHover { hovering in
                if !isSelected {
                    isHovered.wrappedValue = hovering
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(TapGesture().onEnded {
            // Reset hover state when switching views
            if selectedIndex.wrappedValue != currentIndex {
                // Reset all hover states when switching views
                isHomeHovered = false
                isProfileHovered = false
                isSFIconsHovered = false
                isShopHovered = false
                
                // Update selected index and view
                selectedIndex.wrappedValue = currentIndex
            }
        })
    }
    
    private func getDestinationView(for viewType: ViewType) -> some View {
        switch viewType {
        case .home:
            return AnyView(HomeView())
        case .explore:
            return AnyView(ExploreView())
        case .upload:
            return AnyView(UploadDesignView())
        case . shop:
            return AnyView(OldStoreView())
        case .profile:
            return AnyView(ProfileView())
        case .sfIcons:
            return AnyView(SFIconsView())
        }
    }
}
