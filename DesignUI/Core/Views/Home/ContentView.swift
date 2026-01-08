//
//  ContentView.swift
//  DockUI
//
//  Created by Maicol Cabreja on 8/18/24.
//

import SwiftUI
import RevenueCat
import RevenueCatUI
#if os(iOS)
import StatefulTabView
#endif

enum ViewType: Hashable {
    case explore, news, profile, sfIcons, settings, studio
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @EnvironmentObject private var toastManager: ToastManager
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @EnvironmentObject private var paywallManager: PaywallManager
    @EnvironmentObject private var designManager: DesignManager
    @State private var hoveredItem: MenuItem?
    @StateObject private var authViewModel = AuthViewModel()
    let client = SupabaseManager.shared.client
    @AppStorage("selectedIndex") var selectedIndex: Int = 0
    
    enum MenuItem {
        case explore
        case news
        case profile
        case templates
        case sfIcons
        case settings
        case studio
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
        VStack{
#if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
                StatefulTabView(selectedIndex: $selectedIndex){
                    Tab(title: "Explore", systemImageName: "house.fill") {
                        ExploreView()
                    }
                    
                    Tab(title: "Studio", systemImageName: "folder.fill.badge.plus") {
                        DesignBrowserView()
                    }
                    
                    Tab(title: "News", systemImageName: "newspaper.fill") {
                        NewsListView()
                    }
                    
                    Tab(title: "Profile", systemImageName: "person.fill") {
                        ProfileContainerView()
                            .environmentObject(authViewModel)
                    }
                }
            } else {
            NavigationSplitView {
                VStack(alignment: .leading, spacing: 5) {
                    SidebarProfileSection(authViewModel: authViewModel, selectedIndex: $selectedIndex, hoveredItem: $hoveredItem, effectiveColorScheme: effectiveColorScheme)
                    
                    Divider().padding(.vertical,5).opacity(0.5)
                    
                    navigationLinkButton(viewType: .explore, label: "Explore", systemImage: "house.fill", menuItem: .explore, selectedIndex: $selectedIndex, currentIndex: 0)
                    
                    // Studio Link
                    navigationLinkButton(viewType: .studio, label: "Studio", systemImage: "folder.fill.badge.plus", menuItem: .studio, selectedIndex: $selectedIndex, currentIndex: 5)
                    
                    navigationLinkButton(viewType: .news, label: "News", systemImage: "newspaper", menuItem: .news, selectedIndex: $selectedIndex, currentIndex: 1)
                    
                    Divider().padding(.vertical).opacity(0.5)
                                        
                    // SF Symbols Link
                    navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 2)
                    
                    
                    Divider().padding(.vertical).opacity(0.5)
                    
                    Spacer()
                
                // SF Symbols Link
                navigationLinkButton(viewType: .settings, label: "Settings", systemImage: "gear", menuItem: .settings, selectedIndex: $selectedIndex, currentIndex: 4)
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
                        SFIconsView()
                    case 3:
                        ProfileContainerView()
                    case 4:
                        SettingsView()
                    case 5:
                        DesignBrowserView()
                    default:
                        Text("Select a view")
                    }
                }
            }
        }
#endif
        
#if os(macOS)
        NavigationSplitView{
            VStack(alignment: .leading, spacing: 5) {
                // Profile Section
                SidebarProfileSection(authViewModel: authViewModel, selectedIndex: $selectedIndex, hoveredItem: $hoveredItem, effectiveColorScheme: effectiveColorScheme)
                
                Divider().padding(.vertical).opacity(0.5)
                
                navigationLinkButton(viewType: .explore, label: "Explore", systemImage: "house.fill", menuItem: .explore, selectedIndex: $selectedIndex, currentIndex: 0)
                
                // Studio Link
                navigationLinkButton(viewType: .studio, label: "Studio", systemImage: "folder.fill.badge.plus", menuItem: .studio, selectedIndex: $selectedIndex, currentIndex: 5)
                
                navigationLinkButton(viewType: .news, label: "News", systemImage: "newspaper", menuItem: .news, selectedIndex: $selectedIndex, currentIndex: 1)
                
                Divider().padding(.vertical).opacity(0.5)
                                
                // SF Symbols Link
                navigationLinkButton(viewType: .sfIcons, label: "SF Symbols", systemImage: "plus.square.dashed", menuItem: .sfIcons, selectedIndex: $selectedIndex, currentIndex: 2)
                                    
                    Spacer()
                
                // SF Symbols Link
                navigationLinkButton(viewType: .settings, label: "Settings", systemImage: "gear", menuItem: .settings, selectedIndex: $selectedIndex, currentIndex: 4)

            }
            .padding()
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
                    SFIconsView()
                case 3:
                    ProfileContainerView()
                case 4:
                    SettingsView()
                case 5:
                    DesignBrowserView()
                default:
                    Text("Select a view")
                }
            }
        }
#endif
        }
        .toast($toastManager.currentToast)
        .sheet(isPresented: $paywallManager.isPresenting) {
            CustomPaywallView()
#if os(macOS)
                .frame(minWidth: 760, minHeight: 560)
#endif
                .onDisappear {
                    subscriptionManager.checkSubscriptionStatus()
                }
        }
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
        case .explore:
            return AnyView(ExploreView())
        case .news:
            return AnyView(NewsListView())
        case .sfIcons:
            return AnyView(SFIconsView())
        case .profile:
            return AnyView(ExploreView())
        case .settings:
            return AnyView(SettingsView())
        case .studio:
            return AnyView(DesignBrowserView())
        }
    }
}

// MARK: - Sidebar Profile Section
struct SidebarProfileSection: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var selectedIndex: Int
    @Binding var hoveredItem: ContentView.MenuItem?
    let effectiveColorScheme: ColorScheme
    @Environment(\.colorScheme) var colorScheme
    @State private var showDeleteAlert = false
    private let profileIndex = 3
    
    private var isSelected: Bool {
        selectedIndex == profileIndex
    }
    
    private var isHovered: Bool {
        hoveredItem == .profile
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return effectiveColorScheme == .dark ? .white : .black
        } else if isHovered {
            return effectiveColorScheme == .dark ? Color.gray.opacity(0.2) : Color.black.opacity(0.2)
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return effectiveColorScheme == .dark ? .black : .white
        } else if isHovered {
            return effectiveColorScheme == .dark ? .white : .black
        } else {
            return effectiveColorScheme == .dark ? .white : .black
        }
    }
    
    var body: some View {
        if authViewModel.isAuthenticated, let profile = authViewModel.userProfile {
            HStack(spacing: 10) {
                // Clickable Profile Section
                NavigationLink(destination: ProfileContainerView()) {
                    HStack(spacing: 10) {
                        // Profile Picture - Text Letter Placeholder Only
                        Circle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(profile.display_name?.prefix(1).uppercased() ?? profile.username?.prefix(1).uppercased() ?? "?")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        // Name and Username
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.display_name ?? profile.username ?? "User")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(textColor)
                                .lineLimit(1)
                            
                            if let username = profile.username {
                                Text("@\(username)")
                                    .font(.system(size: 11))
                                    .foregroundColor(isSelected ? textColor.opacity(0.8) : .secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    .background(backgroundColor)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                .accentColor(.clear)
                .onHover { hovering in
                    if selectedIndex != profileIndex {
                        hoveredItem = hovering ? .profile : nil
                    }
                }
                .simultaneousGesture(TapGesture().onEnded {
                    if selectedIndex != profileIndex {
                        hoveredItem = nil
                        selectedIndex = profileIndex
                    }
                })
            }
            .alert("Are you sure you want to delete your account?",
                   isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await authViewModel.deleteAccount()
                    }
                }
            }
        } else {
            // Sign In Section (when logged out)
            NavigationLink(destination: ProfileContainerView()) {
                HStack(spacing: 10) {
                    // Sign In Icon
                    Circle()
                        .fill(Color.blue.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                    
                    // Sign In Text
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sign In")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        
                        Text("Access your profile")
                            .font(.system(size: 11))
                            .foregroundColor(isSelected ? textColor.opacity(0.8) : .secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .accentColor(.clear)
            .onHover { hovering in
                if selectedIndex != profileIndex {
                    hoveredItem = hovering ? .profile : nil
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                if selectedIndex != profileIndex {
                    hoveredItem = nil
                    selectedIndex = profileIndex
                }
            })
        }
    }
}
