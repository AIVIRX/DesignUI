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
    case explore, profile, sfIcons, shop
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @State private var hoveredItem: MenuItem?
    let client = SupabaseManager.shared.client
    @AppStorage("selectedIndex") var selectedIndex: Int = 0
    @EnvironmentObject private var entitlementManager: EntitlementManager

    private enum MenuItem {
        case explore
        case profile
        case sfIcons
        case shop
        case rateUs
        case instagram
        case policy
        case contact
    }
    
    var body: some View {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack{
                if !entitlementManager.hasPro{
                    AdView(adUnitID: AdUnitID.finalAd)
                        .frame(width: 320, height: 50)
                        .padding(5)
                }
                
                StatefulTabView(selectedIndex: $selectedIndex){
                    Tab(systemImageName: "house.fill") {
                        ExploreView()
                    }
                    
                    Tab(systemImageName: "person.crop.circle.fill") {
                        ProfileContainerView()
                    }
                }
                .accentColor(colorScheme == .dark ? .white : .black)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationSplitView {
                VStack(alignment: .leading, spacing: 5) {
                    // Search Tab
                    navigationLinkButton(viewType: .explore, label: "Explore", systemImage: "magnifyingglass", menuItem: .explore, selectedIndex: $selectedIndex, currentIndex: 0)
                    
                    navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.fill", menuItem: .profile, selectedIndex: $selectedIndex, currentIndex: 1)
                    
                    Divider().padding(.vertical)
                    
                    // SF Symbols Link
                    navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 2)
                    
                    // Shop Link
                    navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", menuItem: .shop, selectedIndex: $selectedIndex, currentIndex: 3)
                    
                    Divider().padding(.vertical)
                    
                    // Rate Us Text
                    Text("Rate Us")
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .rateUs ? (colorScheme == .dark ? .white : .black) : .yellow)
                        .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            requestReview()
                        }
                        .onHover { hovering in
                            hoveredItem = hovering ? .rateUs : nil
                        }
                    
                    Link("Instagram", destination: URL(string: "https://www.instagram.com/dockui")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .instagram ? (colorScheme == .dark ? .white : .black) : .gray)
                        .background(Color.clear)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItem = hovering ? .instagram : nil
                        }
                    
                    // Privacy Policy Link
                    Link("Privacy Policy", destination: URL(string: "https://dockui.com/privacy")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .policy ? (colorScheme == .dark ? .white : .black) : .gray)
                        .cornerRadius(8)
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
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItem = hovering ? .contact : nil
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
                        ExploreView()
                    case 1:
                        ProfileContainerView()
                    case 2:
                        SFIconsView()
                    case 3:
                        SubscriptionView()
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
                // Search Tab
                navigationLinkButton(viewType: .explore, label: "Explore", systemImage: "magnifyingglass", menuItem: .explore, selectedIndex: $selectedIndex, currentIndex: 0)
                
                navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.fill", menuItem: .profile, selectedIndex: $selectedIndex, currentIndex: 1)
                
                Divider().padding(.vertical)
                
                // SF Symbols Link
                navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 2)
                
                // Shop Link
                navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", menuItem: .shop, selectedIndex: $selectedIndex, currentIndex: 3)
                
                Divider().padding(.vertical)
                
                // Rate Us Text
                Text("Rate Us")
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .rateUs ? (colorScheme == .dark ? .white : .black) : .yellow)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        requestReview()
                    }
                    .onHover { hovering in
                        hoveredItem = hovering ? .rateUs : nil
                    }
                
                Link("Instagram", destination: URL(string: "https://www.instagram.com/dockui")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .instagram ? (colorScheme == .dark ? .white : .black) : .gray)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        hoveredItem = hovering ? .instagram : nil
                    }
                
                // Privacy Policy Link
                Link("Privacy Policy", destination: URL(string: "https://dockui.com/privacy")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .policy ? (colorScheme == .dark ? .white : .black) : .gray)
                    .cornerRadius(8)
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
                    .cornerRadius(8)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        hoveredItem = hovering ? .contact : nil
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
                    ExploreView()
                case 1:
                    ProfileContainerView()
                case 2:
                    SFIconsView()
                case 3:
                    SubscriptionView()
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
            .cornerRadius(8)
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
        case .explore:
            return AnyView(ExploreView())
        case .profile:
            return AnyView(ProfileContainerView())
        case . shop:
            return AnyView(SubscriptionView())
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
