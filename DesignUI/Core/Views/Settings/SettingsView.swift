//
//  SettingsView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/11/24.
//
//  SettingsView.swift
//  DesignUI

import SwiftUI
import StoreKit
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
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var colorSchemeManager: ColorSchemeManager
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false
#if os(iOS)
    @State private var result: Result<MFMailComposeResult, Error>? = nil
#endif
    @State private var isShowingMailView = false
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Premium Section - Better for macOS
                    NavigationLink(destination: StoreView()) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Premium")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Unlock Premium Features")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.trailing)
                        }
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.indigo.gradient))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Form {
                    Section(header: Text("Appearance")) {
                        // Color Scheme Picker
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .font(.system(size: 20)).bold()
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.white)
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            
                            Text("Color Scheme")
                            
                            Spacer()
                            
                            Picker("", selection: $colorSchemeManager.currentScheme) {
                                ForEach(AppColorScheme.allCases, id: \.self) { scheme in
                                    Text(scheme.displayName).tag(scheme)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
#if os(iOS)
                        if UIDevice.current.userInterfaceIdiom == .phone {
                            NavigationLink(destination: SFIconsView()) {
                                HStack {
                                    Image(systemName: "plus.square.dashed")
                                        .font(.system(size: 20)).bold()
                                        .frame(width: 30, height: 30)
                                        .foregroundStyle(.white)
                                        .background(Color.black)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                    Text("SF Icons")
                                }
                            }
                        }
#endif
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
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Link(destination: URL(string: "https://www.threads.com/dockui")!) {
                            HStack {
                                Image(systemName: "link")
                                    .font(.system(size: 20))
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.white)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("Threads")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                                        
                    Section(header: Text("Privacy & Support")) {
                        Link(destination: URL(string: "https://www.aivirx.com/dockui/privacy-policy")!) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 20))
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.white)
                                    .background(Color.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            isShowingMailView.toggle()
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 20))
                                    .frame(width: 30, height: 30)
                                    .foregroundStyle(.white)
                                    .background(Color.blue)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                Text("Contact Us")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
#if os(iOS)
                        .disabled(!MFMailComposeViewController.canSendMail())
#endif
                    }
                    }
                    .accentColor(colorScheme == .dark ? .white : .black)
                    .formStyle(.grouped)
                    
                }
                .padding(.horizontal)
            }
#if os(iOS)
            .navigationBarTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
#else
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
        }
    }

