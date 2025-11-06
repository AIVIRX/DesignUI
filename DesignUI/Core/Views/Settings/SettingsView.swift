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
#endif

struct SettingsView: View {
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @StateObject private var purchases = PurchasesService.shared
    @State private var showPaywall = false
#if os(iOS)
    @State private var result: Result<MFMailComposeResult, Error>? = nil
#endif
    @State private var isShowingMailView = false
    @AppStorage("appearanceMode") private var appearanceMode: String = "auto"

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
                            Button("Change Plan") {
                                #if os(iOS)
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    Task {
                                        try? await AppStore.showManageSubscriptions(in: windowScene)
                                    }
                                }
                                #endif
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
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

                // More Apps Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("More Apps")
                        .font(.headline)
                    Button {
                        if let url = URL(string: "https://apps.apple.com/us/app/stock-profit-calculator-2025/id6479931561") {
                            NSWorkspace.shared.open(url)
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
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Legal Card (macOS): Removed Send Feedback per platform constraints
                VStack(alignment: .leading, spacing: 8) {
                    Text("Legal")
                        .font(.headline)
                    HStack(spacing: 12) {
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
                        Spacer()
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
#endif
    }
}

//

// (No manageSubscriptionsSheet; Manage opens paywall instead on all platforms)
