//
//  SettingsView.swift
//  CluoGames
//
//  Created by Assistant on 10/01/25.
//

import SwiftUI
import StoreKit
import RevenueCatUI
#if os(iOS)
import MessageUI
import UIKit
#elseif os(macOS)
import AppKit
#endif

#if os(iOS)
struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var result: Result<MFMailComposeResult, Error>?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        @Binding var presentationMode: PresentationMode
        @Binding var result: Result<MFMailComposeResult, Error>?

        init(presentationMode: Binding<PresentationMode>, result: Binding<Result<MFMailComposeResult, Error>?>) {
            _presentationMode = presentationMode
            _result = result
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                $presentationMode.wrappedValue.dismiss()
            }
            guard error == nil else {
                self.result = .failure(error!)
                return
            }
            self.result = .success(result)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(presentationMode: presentationMode, result: $result)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["support@aivirx.com"])
        vc.setSubject("DockUI")
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: UIViewControllerRepresentableContext<MailView>) {}
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            presentationMode.wrappedValue.dismiss()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

struct SettingsView: View {
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @StateObject private var purchases = PurchasesService.shared
    @State private var showPaywall = false
#if os(iOS)
    @State private var result: Result<MFMailComposeResult, Error>? = nil
    @State private var showShareSheet = false
#endif
    @State private var isShowingMailView = false
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"
    
    // App Store URL - Update with your actual App Store ID
    private var appStoreURL: String {
        // Replace with your actual App Store URL
        // Format: https://apps.apple.com/app/id[APP_ID]
        return "https://apps.apple.com/us/app/dock-ui-swiftui-snippets/id6496860953"
    }
    
    private var shareText: String {
        "Check out DockUI - A great app for SwiftUI templates and components!"
    }
    
    var body: some View {
#if os(macOS)
        // macOS: Modern card-style layout
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Subscription Card
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .foregroundColor(purchases.hasPremium ? .green : .red)
                        Text("Premium")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if !purchases.hasPremium {
                        Button("Subscribe") { showPaywall = true }
                            .buttonStyle(.borderedProminent)
                    } else {
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("You have access to all premium features")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
#if os(iOS)
                            Button("Change Plan") {
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    Task {
                                        try? await AppStore.showManageSubscriptions(in: windowScene)
                                    }
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
#endif
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Appearance Card
                HStack {
                    Text("Appearance")
                        .font(.headline)
                    Spacer()
                    
                    Picker("Color Scheme", selection: $colorSchemeManager.currentScheme) {
                        ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                            Text(scheme.displayName).tag(scheme)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // App Actions Card
                HStack{
                    Text("Support Us")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        if let url = URL(string: appStoreURL) { NSWorkspace.shared.open(url) }
                    } label: {
                        Text("Rate us")
                    }
                    
                    Button {
                        let picker = NSSharingServicePicker(items: [shareText, appStoreURL])
                        if let window = NSApplication.shared.keyWindow {
                            picker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
                        }
                    } label: {
                        Text("Share App")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Legal Card (macOS): Removed Send Feedback per platform constraints
                HStack{
                    Text("Legal")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        if let url = URL(string: "https://dockui.com/privacy") { NSWorkspace.shared.open(url) }
                    } label: {
                        Text("Privacy Policy")
                    }
                    
                    Button {
                        if let url = URL(string: "https://dockui.com/terms") { NSWorkspace.shared.open(url) }
                    } label: {
                        Text("Terms of Service")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Version
                HStack {
                    Spacer()
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5.0.0")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(24)
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showPaywall) {
            CustomPaywallView()
        }
#elseif os(macOS)
        .sheet(isPresented: $showPaywall) {
            CustomPaywallView()
                .frame(minWidth: 760, minHeight: 560)
        }
#endif
        .onAppear {
            Task { await purchases.loadCustomerInfo() }
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
                    .pickerStyle(.menu)
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
                
                // Other Apps Section
                Section("More Apps") {
                    Button {
                        if let url = URL(string: "https://apps.apple.com/us/app/stock-profit-calculator-2025/id6479931561") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image("stockscalc")
                                .resizable()
                                .frame(width: 30, height:30)
                                .cornerRadius(5)
                            Text("Stock Profit Calculator 2025")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
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
                                Circle()
                                    .fill(Color.yellow.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 16))
                            }
                            Text("Rate App")
                                .font(.body)
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
                    
                    Button(action: { showShareSheet = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16))
                            }
                            Text("Share App")
                                .font(.body)
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
}
