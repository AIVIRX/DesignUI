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
    @State private var isRateUsHovered: Bool = false
    @State private var isPolicyHovered: Bool = false
    @State private var isContactHovered: Bool = false
    var body: some View {
        
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            StatefulTabView{
                Tab(systemImageName: "house.fill") {
                    HomeView()
                }
                
//                Tab(systemImageName: "plus.app") {
//                    UploadDesignView()
//                }
                
                Tab(systemImageName: "person.crop.circle") {
                    ProfileView()
                }
            }
            .accentColor(colorScheme == .dark ? .white : .black)
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                VStack(alignment: .leading, spacing: 5) {
                    // Home Link
                    navigationLinkButton(viewType: .home, label: "Home", systemImage: "house", isHovered: $isHomeHovered)
                    
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
        }
#endif
        
#if os(macOS)
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 5) {
                // Home Link
                navigationLinkButton(viewType: .home, label: "Home", systemImage: "house", isHovered: $isHomeHovered)
                
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
        let isSelected = selectedView == viewType
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
                Label(label, systemImage: systemImage)
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
            if selectedView != viewType {
                // Reset all hover states
                isHomeHovered = false
                isProfileHovered = false
                isSFIconsHovered = false
                isShopHovered = false
                
                selectedView = viewType  // Switches to the selected view
            }
        })
    }

    private func getDestinationView(for viewType: ViewType) -> some View {
        switch viewType {
        case .home:
            return AnyView(HomeView())
        case .profile:
            return AnyView(ProfileView())
        case .sfIcons:
            return AnyView(SFIconsView())
        case .shop:
            return AnyView(OldStoreView())
        }
    }
}

#Preview {
    ContentView()
}
