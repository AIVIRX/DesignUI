//
//  SettingsView.swift
//  CluoGames
//
//  Created by Assistant on 10/01/25.
//

import SwiftUI
import StoreKit
import RevenueCatUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @StateObject private var purchases = PurchasesService.shared
    @State private var showPaywall = false
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    @Environment(\.openURL) var openURL

    let email = "support@dockui.com"
        let subject = "App Feedback"
        let emailText = "Hello, "
    
    // App Store URL - Update with your actual App Store ID
    private var appStoreURL: String {
        return "https://apps.apple.com/us/app/dock-ui-swiftui-snippets/id6496860953"
    }
    
    private var shareText: String {
        "DockUI - Design For SwiftUI"
    }
    
    var body: some View {
#if os(macOS)
        // macOS: Modifier-style layout
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Subscription Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUBSCRIPTION")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        HStack(spacing: 10) {
                            Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "xmark.seal.fill")
                                .foregroundColor(purchases.hasPremium ? .green : .red)
                            Text("Premium")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        if !purchases.hasPremium {
                            NavigationLink(destination: CustomPaywallView()) {
                                Text("Subscribe")
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Active")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Appearance Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("APPEARANCE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Theme")
                        
                        Spacer()
                        
                        Picker("Color Scheme", selection: $colorSchemeManager.currentScheme) {
                            ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                                Text(scheme.displayName).tag(scheme)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Features Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("FEATURES")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        NavigationLink(destination: SFIconsView()) {
                            HStack {
                                Text("SF Symbols")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Community Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMMUNITY")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        Button {
                            if let url = URL(string: "https://dockui.com") { NSWorkspace.shared.open(url) }
                        } label: {
                            HStack {
                                Text("Website")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 12)
                        
                        Button {
                            if let url = URL(string: "https://www.threads.net/@dockui") { NSWorkspace.shared.open(url) }
                        } label: {
                            HStack {
                                Text("Threads")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 12)
                        
                        Button {
                            if let url = URL(string: "https://twitter.com/dockui") { NSWorkspace.shared.open(url) }
                        } label: {
                            HStack {
                                Text("X")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Support Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("SUPPORT")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        Button {
                            if let url = URL(string: appStoreURL) { NSWorkspace.shared.open(url) }
                        } label: {
                            HStack {
                                Text("Rate Us")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "star")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 12)
                        
                        Button(action: sendEmail) {
                            HStack {
                                Text("Send Feedback")
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 12)
                        
                        Button {
                            let picker = NSSharingServicePicker(items: [shareText, appStoreURL])
                            if let window = NSApplication.shared.keyWindow {
                                picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                            }
                        } label: {
                            HStack {
                                Text("Share App")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Legal Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("LEGAL")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 0) {
                        Button {
                            if let url = URL(string: "https://dockui.com/privacy") { NSWorkspace.shared.open(url) }
                        } label: {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 12)
                        
                        Button {
                            if let url = URL(string: "https://dockui.com/terms") { NSWorkspace.shared.open(url) }
                        } label: {
                            HStack {
                                Text("Terms of Service")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.secondary.opacity(0.1)))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                // Version
                HStack {
                    Spacer()
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5.0.0")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
        }

#if os(iOS)
        .fullScreenCover(isPresented: $showPaywall) {
            CustomPaywallView()
        }
#endif
        .onAppear {
            Task { await purchases.loadCustomerInfo() }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { dismiss() }) {
                    Text("Done")
                        .fontWeight(.semibold)
                }
            }
        }
#else
        // iOS: Keep List-based layout
        NavigationStack {
            List {
                // Subscription status
                Section("Subscription") {
                    HStack {
                        Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .foregroundColor(purchases.hasPremium ? .green : .red)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Premium")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                        if !purchases.hasPremium {
                            Button("Subscribe") {
                                showPaywall = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    if purchases.hasPremium {
                        Button {
#if os(iOS)
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                Task {
                                    try? await AppStore.showManageSubscriptions(in: windowScene)
                                }
                            }
#endif
                        } label: {
                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                Text("Change Plan")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .foregroundColor(.primary)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Appearance Section
                Section("Appearance") {
                    Picker("Color Scheme", selection: $colorSchemeManager.currentScheme) {
                        ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.displayName).tag(scheme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Community Section
                Section("Community") {
                    Button {
                        if let url = URL(string: "https://www.threads.net/@dockui") { UIApplication.shared.open(url) }
                    } label: {
                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(.primary)
                                .frame(width: 24)
                            Text("Threads")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        if let url = URL(string: "https://twitter.com/dockui") { UIApplication.shared.open(url) }
                    } label: {
                        HStack {
                            Image(systemName: "bird")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Twitter")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                         if let url = URL(string: "https://dockui.com") { UIApplication.shared.open(url) }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("Website")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // Features Section
                Section("Features") {
                    NavigationLink(destination: SFIconsView()) {
                        HStack {
                            Image(systemName: "plus.square.dashed")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            Text("SF Symbols")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // App Section
                Section("App") {
                    Button {
                        if let url = URL(string: appStoreURL) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.indigo)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 16))
                            }
                            Text("Rate App")
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .foregroundColor(.primary)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: { showShareSheet = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                                    .frame(width: 30, height: 30)
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            }
                            Text("Share App")
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .foregroundColor(.primary)
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Support Section
                Section("Support") {
                    Button(action: { isShowingMailView.toggle() }) {
                        HStack {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                Text("Send Feedback")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!MFMailComposeViewController.canSendMail())
                }
                
                // Legal Section
                Section("Legal") {
                    Button {
                        if let url = URL(string: "https://dockui.com/privacy") { UIApplication.shared.open(url) }
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.purple)
                                .frame(width: 24)
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button {
                        if let url = URL(string: "https://dockui.com/terms") { UIApplication.shared.open(url) }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.gray)
                                .frame(width: 24)
                            Text("Terms of Service")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // Version Section
                Section {
                    HStack {
                        Spacer()
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5.0.0")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showPaywall) {
            CustomPaywallView()
        }
#endif
        .onAppear {
            Task { await purchases.loadCustomerInfo() }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText, appStoreURL])
        }
#endif
    }
    
    func sendEmail() {
            // Construct the mailto URL with encoded parameters
            let mailtoString = "mailto:\(email)?subject=\(subject)&body=\(emailText)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: mailtoString) {
                openURL(url)
            }
        }
}

