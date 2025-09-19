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
    case templates, news, profile, sfIcons, shop, uiBuilder
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @EnvironmentObject private var toastManager: ToastManager
    @State private var hoveredItem: MenuItem?
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showSidebarSettings = false
    let client = SupabaseManager.shared.client
    @AppStorage("selectedIndex") var selectedIndex: Int = 0
    
    private enum MenuItem {
        case explore
        case news
        case profile
        case templates
        case sfIcons
        case shop
        case uiBuilder
        case threads
        case policy
        case contact
    }
    
    // Computed property for effective color scheme
    private var effectiveColorScheme: ColorScheme {
        switch colorSchemeManager.currentScheme {
        case .system:
            return colorScheme // Use system color scheme
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    var body: some View {
        Group {
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            VStack{
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
                .accentColor(effectiveColorScheme == .dark ? .white : .black)
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
                    navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 3)
                    
                    // Shop Link
                    navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", menuItem: .shop, selectedIndex: $selectedIndex, currentIndex: 4)
                    
                    // UI Builder Link
                    navigationLinkButton(viewType: .uiBuilder, label: "UI Builder", systemImage: "hammer.fill", menuItem: .uiBuilder, selectedIndex: $selectedIndex, currentIndex: 5)
                    
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
                        .foregroundColor(hoveredItem == .policy ? (effectiveColorScheme == .dark ? .white : .black) : .gray)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            hoveredItem = hovering ? .policy : nil
                        }
                    
                    // Contact Us Link
                    Link("Contact Us", destination: URL(string: "https://dockui.com/contact")!)
                        .bold()
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .foregroundColor(hoveredItem == .contact ? (effectiveColorScheme == .dark ? .white : .black) : .gray)
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
                    case 3:
                        SFIconsView()
                    case 4:
                        StoreView()
                    case 5:
                        UIBuilderView()
                    default:
                        Text("Select a view")
                    }
                }
            }
        }
#endif
        
#if os(macOS)
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            VStack(alignment: .leading, spacing: 5) {
                navigationLinkButton(viewType: .templates, label: "Templates", systemImage: "iphone.gen3", menuItem: .templates, selectedIndex: $selectedIndex, currentIndex: 0)
                
                navigationLinkButton(viewType: .news, label: "News", systemImage: "newspaper", menuItem: .news, selectedIndex: $selectedIndex, currentIndex: 1)
                
                navigationLinkButton(viewType: .profile, label: "Profile", systemImage: "person.fill", menuItem: .profile, selectedIndex: $selectedIndex, currentIndex: 2)
                
                Divider().padding(.vertical).opacity(0.5)
                
                
                // SF Symbols Link
                navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 3)
                
                // Shop Link
                navigationLinkButton(viewType: .shop, label: "Shop", systemImage: "cart", menuItem: .shop, selectedIndex: $selectedIndex, currentIndex: 4)
                
                // UI Builder Link
                navigationLinkButton(viewType: .uiBuilder, label: "UI Builder", systemImage: "hammer.fill", menuItem: .uiBuilder, selectedIndex: $selectedIndex, currentIndex: 5)
                
                Divider().padding(.vertical).opacity(0.5)
                
                Link("Threads", destination: URL(string: "https://www.threads.com/@dockui")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .threads ? (effectiveColorScheme == .dark ? .white : .black) : .gray)
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
                    .foregroundColor(hoveredItem == .policy ? (effectiveColorScheme == .dark ? .white : .black) : .gray)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        hoveredItem = hovering ? .policy : nil
                    }
                
                // Contact Us Link
                Link("Contact Us", destination: URL(string: "https://dockui.com/contact")!)
                    .bold()
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .foregroundColor(hoveredItem == .contact ? (effectiveColorScheme == .dark ? .white : .black) : .gray)
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
#if os(macOS)
            .toolbar{
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showSidebarSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSidebarSettings) {
                SettingsView()
            }
#endif
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
                case 3:
                    SFIconsView()
                case 4:
                    StoreView()
                case 5:
                    UIBuilderView()
                default:
                    Text("Select a view")
                }
            }
        }
#endif
        }
        .toast($toastManager.currentToast)
    }
    
    private func navigationLinkButton(viewType: ViewType, label: String, systemImage: String, menuItem: MenuItem, selectedIndex: Binding<Int>, currentIndex: Int) -> some View {
        let isSelected = selectedIndex.wrappedValue == currentIndex
        let isHovered = hoveredItem == menuItem
        
        let backgroundColor: Color
        let textColor: Color
        
        if isSelected {
            backgroundColor = effectiveColorScheme == .dark ? .white : .black
            textColor = effectiveColorScheme == .dark ? .black : .white
        } else if isHovered {
            backgroundColor = effectiveColorScheme == .dark ? Color.gray.opacity(0.2) : Color.black.opacity(0.2)
            textColor = effectiveColorScheme == .dark ? .white : .black
        } else {
            backgroundColor = .clear
            textColor = effectiveColorScheme == .dark ? .white : .black
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
        case .uiBuilder:
            return AnyView(UIBuilderView())
        }
    }
}

// MARK: - Bundle Extension
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}
