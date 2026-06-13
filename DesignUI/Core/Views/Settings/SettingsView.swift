//
//  SettingsView.swift
//  CluoGames
//
//  Created by Assistant on 10/01/25.
//

import SwiftUI
import RevenueCatUI
#if os(iOS)
import MessageUI
import UIKit
#endif

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @StateObject private var purchases = PurchasesService.shared
    @State private var showPaywall = false
    @Environment(\.openURL) var openURL
    
    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/dock-ui-swiftui-snippets/id6496860953")!
    private let stringCatalogTranslateURL = URL(string: "https://apps.apple.com/us/app/string-catalog-translate/id6761640833?mt=12")!
    private let websiteURL = URL(string: "https://dockui.com")!
    private let privacyURL = URL(string: "https://dockui.com/privacy")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    let email = "support@dockui.com"
    let subject = "App Feedback"
    let emailText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    subscriptionSection
                    appearanceSection
                    moreAppsSection
                    appSection
                    supportSection
                    legalSection
                    versionSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 560, idealWidth: 640, minHeight: 620, idealHeight: 720)
#endif
#if os(iOS)
        .fullScreenCover(isPresented: $showPaywall) {
            CustomPaywallView()
        }
#else
        .sheet(isPresented: $showPaywall) {
            CustomPaywallView()
        }
#endif
        .task {
            await purchases.loadCustomerInfo()
        }
    }

    private var subscriptionSection: some View {
        section("Subscription") {
            HStack(spacing: 12) {
                Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .foregroundColor(purchases.hasPremium ? .green : .red)
                    .frame(width: 24)
                Text("Premium")
                    .fontWeight(.semibold)
                Spacer()
                if !purchases.hasPremium {
                    Button("Subscribe") {
                        showPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Text("Active")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        section("Appearance") {
            HStack(spacing: 12) {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundColor(.blue)
                    .frame(width: 24)
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
        }
    }

    private var moreAppsSection: some View {
        section("More Apps") {
            stringCatalogPromoRow
        }
    }

    private var appSection: some View {
        section("App") {
            VStack {
                Button {
                    openURL(appStoreURL)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .frame(width: 24)
                        Text("Rate App")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)

                rowDivider

                ShareLink(item: appStoreURL) {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        Text("Share App")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
        }
    }

    private var supportSection: some View {
        section("Support") {
            VStack {
                settingsLinkRow(title: "Website", icon: "globe", iconColor: .blue) {
                    openURL(websiteURL)
                }
                rowDivider
                Button(action: sendEmail) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Send Feedback")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
#if os(iOS)
                .disabled(!MFMailComposeViewController.canSendMail())
#endif
            }
        }
    }

    private var legalSection: some View {
        section("Legal") {
            VStack {
                settingsLinkRow(title: "Privacy Policy", icon: "hand.raised.fill", iconColor: .purple) {
                    openURL(privacyURL)
                }
                rowDivider
                settingsLinkRow(title: "Terms of Service", icon: "doc.text.fill", iconColor: .gray) {
                    openURL(termsURL)
                }
            }
        }
    }

    private var versionSection: some View {
        HStack {
            Spacer()
            Text("Version \(versionString)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.top, 4)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 36)
    }

    private var stringCatalogPromoRow: some View {
        Button {
            openURL(stringCatalogTranslateURL)
        } label: {
            HStack(spacing: 12) {
                Image("StringCatLogo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("String Catalog Translator")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Translate your app strings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer(minLength: 10)

                Text("Get")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.blue)
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        Group {
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)

            VStack(spacing: 0) {
                content()
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }

    @ViewBuilder
    private func settingsLinkRow(
        title: String,
        icon: String,
        iconColor: Color,
        imageAssetName: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let imageAssetName {
                    Image(imageAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .frame(width: 24)
                }
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(.primary)
    }
    
    private var versionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "5.0.0"
    }
    
    func sendEmail() {
        let mailtoString = "mailto:\(email)?subject=\(subject)&body=\(emailText)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: mailtoString) {
            openURL(url)
        }
    }
}
