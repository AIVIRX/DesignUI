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
    case templates, news, profile, sfIcons, shop
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var store: Store
    @State private var hoveredItem: MenuItem?
    let client = SupabaseManager.shared.client
    @State var selectedIndex: Int = 0

    private enum MenuItem {
        case explore
        case news
        case profile
        case templates
        case sfIcons
        case shop
        case threads
        case policy
        case contact
    }
    
    var body: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack{
                if !store.completedPurchases.isEmpty{
                } else {
                    AdView(adUnitID: AdUnitID.finalAd)
                        .frame(width: 320, height: 50)
                        .padding(5)
                }
                
                StatefulTabView(selectedIndex: $selectedIndex){
                    Tab(systemImageName: "house") {
                        ExploreView()
                    }
                    
                    Tab(systemImageName: "newspaper") {
                        NewsListView()
                    }
                    
                    Tab(systemImageName: "person.crop.circle") {
                        ProfileContainerView()
                    }
                    
                    
                }
                .accentColor(colorScheme == .dark ? .white : .black)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                VStack(alignment: .leading, spacing: 5) {
                    navigationLinkButton(viewType: .templates, label: "Templates", systemImage: "iphone.gen3", menuItem: .templates, selectedIndex: $selectedIndex, currentIndex: 0)
                    
                    navigationLinkButton(viewType: .news, label: "News", systemImage: "newspaper", menuItem: .news, selectedIndex: $selectedIndex, currentIndex: 1)
                    
                    navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.fill", menuItem: .profile, selectedIndex: $selectedIndex, currentIndex: 2)
                    
                    Divider().padding(.vertical).opacity(0.5)
                    
                    // SF Symbols Link
                    navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 4)
                    
                    // Shop Link
                    navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", menuItem: .shop, selectedIndex: $selectedIndex, currentIndex: 5)
                    
                    Divider().padding(.vertical).opacity(0.5)
                    
                    Link("Threads", destination: URL(string: "https://www.threads.com/@dockui")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .threads ? (colorScheme == .dark ? .white : .black) : .gray)
                        .background(Color.clear)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItem = hovering ? .threads : nil
                        }
                    
                    // Privacy Policy Link
                    Link("Privacy Policy", destination: URL(string: "https://dockui.com/privacy")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .policy ? (colorScheme == .dark ? .white : .black) : .gray)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItem = hovering ? .policy : nil
                        }
                    
                    // Contact Us Link
                    Link("Contact Us", destination: URL(string: "https://dockui.com/contact")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .contact ? (colorScheme == .dark ? .white : .black) : .gray)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItem = hovering ? .contact : nil
                        }
                    
                    Text("v\(Bundle.main.releaseVersionNumber ?? "")")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundStyle(Color.gray)
                        .font(.body)
                    
                    Spacer()
                }
                .padding()
                .background(Color.clear)
                .navigationSplitViewColumnWidth(230)
            }
            detail: {
                NavigationStack() {
                        switch selectedIndex {
                        case 0:
                            ExploreView()
                        case 1:
                            NewsListView()
                        case 2:
                            ProfileContainerView()
                        case 4:
                            SFIconsView()
                        case 5:
                            StoreView()
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
                navigationLinkButton(viewType: .templates, label: "Templates", systemImage: "iphone.gen3", menuItem: .templates, selectedIndex: $selectedIndex, currentIndex: 0)
                
                navigationLinkButton(viewType: .news, label: "News", systemImage: "newspaper", menuItem: .news, selectedIndex: $selectedIndex, currentIndex: 1)
                
                navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.fill", menuItem: .profile, selectedIndex: $selectedIndex, currentIndex: 2)
                
                Divider().padding(.vertical).opacity(0.5)
                
                
                // SF Symbols Link
                navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 4)
                
                // Shop Link
                navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", menuItem: .shop, selectedIndex: $selectedIndex, currentIndex: 5)
                
                Divider().padding(.vertical).opacity(0.5)
                
                Link("Threads", destination: URL(string: "https://www.threads.com/@dockui")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .threads ? (colorScheme == .dark ? .white : .black) : .gray)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        hoveredItem = hovering ? .threads : nil
                    }
                
                // Privacy Policy Link
                Link("Privacy Policy", destination: URL(string: "https://dockui.com/privacy")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .policy ? (colorScheme == .dark ? .white : .black) : .gray)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        hoveredItem = hovering ? .policy : nil
                    }
                
                // Contact Us Link
                Link("Contact Us", destination: URL(string: "https://dockui.com/contact")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .contact ? (colorScheme == .dark ? .white : .black) : .gray)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        hoveredItem = hovering ? .contact : nil
                    }
                
                Text("v\(Bundle.main.releaseVersionNumber ?? "")")
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundStyle(Color.gray)
                    .font(.body)
                
                Spacer()
            }
            .padding()
            .background(Color.clear)
            .toolbar(removing: .sidebarToggle)
            .navigationSplitViewColumnWidth(230)
        }
        detail: {
            NavigationStack() {
                switch selectedIndex {
                case 0:
                    ExploreView()
                case 1:
                    NewsListView()
                case 2:
                    ProfileContainerView()
                case 4:
                    SFIconsView()
                case 5:
                    StoreView()
                default:
                    Text("Select a view")
                }
            }
        }
#endif
    }
    
    private func navigationLinkButton(viewType: ViewType, label: String, systemImage: String, menuItem: MenuItem, selectedIndex: Binding<Int>, currentIndex: Int) -> some View {
        let isSelected = selectedIndex.wrappedValue == currentIndex
        let isHovered = hoveredItem == menuItem
        
        let backgroundColor: Color
        let textColor: Color
        
        if isSelected {
            backgroundColor = colorScheme == .dark ? .white : .black
            textColor = colorScheme == .dark ? .black : .white
        } else if isHovered {
            backgroundColor = colorScheme == .dark ? Color.gray.opacity(0.2) : Color.black.opacity(0.2)
            textColor = colorScheme == .dark ? .white : .black
        } else {
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
            .cornerRadius(12)
            .onHover { hovering in
                if !isSelected {
                    hoveredItem = hovering ? menuItem : nil
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(TapGesture().onEnded {
            if selectedIndex.wrappedValue != currentIndex {
                hoveredItem = nil
                selectedIndex.wrappedValue = currentIndex
            }
        })
    }
    
    private func getDestinationView(for viewType: ViewType) -> some View {
        switch viewType {
        case .templates:
            return AnyView(ExploreView())
        case .news:
            return AnyView(NewsListView())
        case .profile:
            return AnyView(ProfileContainerView())
        case .shop:
            return AnyView(StoreView())
        case .sfIcons:
            return AnyView(SFIconsView())
        }
    }
}

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
