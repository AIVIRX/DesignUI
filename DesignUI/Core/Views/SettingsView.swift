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
    private let metadataTranslatorURL = URL(string: "https://apps.apple.com/us/app/metadata-translator-aso/id6739471606")!
    private let websiteURL = URL(string: "https://dockui.com")!
    private let privacyURL = URL(string: "https://dockui.com/privacy")!
    private let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    let email = "support@dockui.com"
    let subject = "App Feedback"
    let emailText = ""

    var body: some View {
        NavigationStack {
            Form {
                subscriptionSection
                appearanceSection
                moreAppsSection
                appSection
                supportSection
                legalSection
                versionSection
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
#if os(macOS)
        .frame(width: 520, height: 650)
#endif
        .sheet(isPresented: $showPaywall) {
            CustomPaywallView()
        }
        .task {
            await purchases.loadCustomerInfo()
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            HStack(spacing: 12) {
                Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .foregroundStyle(purchases.hasPremium ? Color.green : Color.red)
                    .frame(width: 24)
                Text("Premium")
                Spacer()
                if !purchases.hasPremium {
                    Button("Subscribe") {
                        showPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("Active")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            HStack(spacing: 12) {
                Image(systemName: "circle.lefthalf.filled")
                    .foregroundStyle(.tint)
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
        Section("More Apps") {
            appPromoRow(
                title: "String Catalog Translator",
                subtitle: "Translate your app strings",
                imageAssetName: "StringCatLogo",
                url: stringCatalogTranslateURL
            )
            appPromoRow(
                title: "Metadata Translator: ASO",
                subtitle: "Localize App Store metadata",
                imageAssetName: "metadatatranslator",
                url: metadataTranslatorURL
            )
        }
    }

    private var appSection: some View {
        Section("More apps") {
            settingsLinkRow(title: "Rate App", icon: "star.fill") {
                openURL(appStoreURL)
            }

            ShareLink(item: appStoreURL) {
                settingsRow(title: "Share App", icon: "square.and.arrow.up")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
    }

    private var supportSection: some View {
        Section("Support") {
            settingsLinkRow(title: "Website", icon: "globe") {
                openURL(websiteURL)
            }
            settingsLinkRow(title: "Send Feedback", icon: "envelope.fill") {
                sendEmail()
            }
#if os(iOS)
            .disabled(!MFMailComposeViewController.canSendMail())
#endif
        }
    }

    private var legalSection: some View {
        Section("Legal") {
            settingsLinkRow(title: "Privacy Policy", icon: "hand.raised.fill") {
                openURL(privacyURL)
            }
            settingsLinkRow(title: "Terms of Service", icon: "doc.text.fill") {
                openURL(termsURL)
            }
        }
    }

    private var versionSection: some View {
        Section {
            LabeledContent("Version", value: versionString)
                .foregroundStyle(.secondary)
        }
    }

    private func appPromoRow(
        title: String,
        subtitle: String,
        imageAssetName: String,
        url: URL
    ) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 12) {
                Image(imageAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                Text("Get")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(.quaternary)
                    )
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsRow(title: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .frame(width: 24)
            Text(title)
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func settingsLinkRow(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            settingsRow(title: title, icon: icon)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
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
