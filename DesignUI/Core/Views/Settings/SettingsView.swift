//
//  SettingsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
//  SettingsView.swift
//  DesignUI

import SwiftUI
#if os(iOS)
import MessageUI
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
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.requestReview) var requestReview
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
    @EnvironmentObject private var entitlementManager: EntitlementManager
#if os(iOS)
    @State private var result: Result<MFMailComposeResult, Error>? = nil
#endif
    @State private var isShowingMailView = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            VStack{
                NavigationLink(destination: SubscriptionView()) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Premium")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Unlock Premium Features")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.indigo.gradient))
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                Form {
                    Section() {
                        NavigationLink(destination: SubscriptionView()) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 20)).bold()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.yellow)
                                    .background(Color.indigo)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("Premium")
                            }
                        }
                    }
                    
                    Section(header: Text("Appearance")) {
                        NavigationLink(destination: AlternateIconView()) {
                            HStack {
                                Image(systemName: "square.stack.fill")
                                    .font(.system(size: 20)).bold()
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.white)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("App Icons")
                            }
                        }
                    }
                    
                    Section(header: Text("Support Us")) {
                        Button {
                            requestReview()
                        } label: {
                            HStack {
                                Image(systemName: "star.leadinghalf.filled")
                                    .font(.system(size: 20))
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.white)
                                    .background(Color.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("Rate Us")
                            }
                        }
                        
                        Link("Instagram", destination: URL(string: "https://www.instagram.com/dockui")!)
                            .bold()
                    }
                    
                    Section(header: Text("Our Apps")) {
                        Link(destination: URL(string: "https://apps.apple.com/us/app/crypto-profit-loss-calculator/id1638849680")!) {
                            HStack {
                                Image("CryptoProfitLogo")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(5)
                                Text("Crypto Profit Loss Calculator")
                            }
                        }
                        
                        Link(destination: URL(string: "https://apps.apple.com/us/app/tasknow-simple-to-do-list/id1639588217")!) {
                            HStack {
                                Image("TaskNowLogo")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .cornerRadius(5)
                                Text("TaskNow - Simple To Do List")
                            }
                        }
                    }
                    
                    Section("Privacy & Support") {
                        Link(destination: URL(string: "https://www.aivirx.com/dockui/privacy-policy")!) {
                            Text("Privacy Policy")
                        }
                        Button(action: {
                            isShowingMailView.toggle()
                        }) {
                            Text("Contact Us")
                        }
#if os(iOS)
                        .disabled(!MFMailComposeViewController.canSendMail())
#endif
                    }
                }
                .accentColor(colorScheme == .dark ? .white : .black)
#if os(iOS)
                .navigationBarTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
#endif
                .alert(isPresented: $showErrorAlert) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
#if os(iOS)
                .sheet(isPresented: $isShowingMailView) {
                    MailView(result: $result)
                }
#endif
            }
#if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                if !entitlementManager.hasPro {
                    AdView(adUnitID: AdUnitID.finalAd)
                        .frame(width: 468, height: 60)
                        .padding(3)
                }
            }
#endif
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
