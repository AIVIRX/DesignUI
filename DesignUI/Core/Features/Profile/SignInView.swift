//
//  SignInView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 10/12/24.
//

import SwiftUI
import AuthenticationServices

class AuthorizationControllerDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var onCompletion: ((Result<ASAuthorization, Error>) -> Void)?
    var presentationAnchorProvider: (() -> ASPresentationAnchor)?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion?(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion?(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchorProvider?() ?? ASPresentationAnchor()
    }
}


struct SignInView: View {
    @State private var authorizationDelegate = AuthorizationControllerDelegate()
    @State private var signInAppleButtonId = UUID().uuidString
    @ObservedObject var authManager = AuthManager.shared
    @Environment(\.colorScheme) var colorScheme
    private var buttonStyle: SignInWithAppleButton.Style {
        @Environment(\.colorScheme) var colorScheme
        switch colorScheme {
        case .light: return .black
        case .dark: return .white
        @unknown default: return .black
        }
    }

    var body: some View {
        VStack{
            VStack(alignment: .center) {
                
                TitleView()
                
                InformationContainerView()
                
                SignInWithAppleButton(.signIn) { request in
                    let nonce = authManager.generateNonce()
                    request.requestedScopes = [.email, .fullName]
                    request.nonce = authManager.sha256(nonce)  
                } onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        Task {
                            do {
                                try await authManager.signInWithApple(authorization: authorization)
                                authManager.checkSession()
                            } catch {
                                print("Sign in failed: \(error.localizedDescription)")
                            }
                        }
                    case .failure(let error):
                        print("Apple sign in failed: \(error.localizedDescription)")
                    }
                }
                .id(signInAppleButtonId)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .onChange(of: colorScheme, { oldValue, newValue in
                    signInAppleButtonId = UUID().uuidString
                })
                .font(.system(size: 30))
                .clipShape(Capsule())
                .clipped()
#if os(iOS)
                .frame(width: UIDevice.current.userInterfaceIdiom == .phone ? 300 : 600, height: UIDevice.current.userInterfaceIdiom == .phone ? 50 : 50 )
#elseif os(macOS)
                .frame(width: 600, height: 60)
#endif
                
                .padding(.top, 20)
                .background(.clear)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .onAppear {
            print("User is not logged in or user data is not available")
        }
    }
}

#Preview {
    SignInView()
}


struct InformationDetailView: View {
    var title: String = "title"
    var subTitle: String = "subTitle"
    var imageName: String = "car"
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .foregroundColor(.mainColor)
                .frame(width: 40, height: 40)
                .padding()
                .accessibility(hidden: true)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibility(addTraits: .isHeader)

                Text(subTitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top)
    }
}

struct TitleView: View {
    var body: some View {
        VStack {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 90, height: 90, alignment: .center)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .accessibility(hidden: true)
            
            Text("Dock UI")
                .customTitleText()
            
            Text("Accounts")
                .customTitleText()
                .foregroundColor(.mainColor)
        }
        .padding(.top,8)
    }
}

struct InformationContainerView: View {
    var body: some View {
        VStack(alignment: .leading) {
            InformationDetailView(title: "Likes", subTitle: "Sign in to like posts and see the likes. View all your liked posts in your profile.", imageName: "heart")

            InformationDetailView(title: "Customization", subTitle: "Customize your profile with a display name, bio & profile image. Make your profile truly yours!", imageName: "person.fill")
        }
    }
}

struct ButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color.mainColor))
            .padding(.bottom)
    }
}

extension View {
    func customButton() -> ModifiedContent<Self, ButtonModifier> {
        return modifier(ButtonModifier())
    }
}

extension Text {
    func customTitleText() -> Text {
        self
            .fontWeight(.black)
            .font(.system(size: 36))
    }
}

extension Color {
    #if os(iOS)
    static let mainColor = Color(UIColor.systemIndigo)
    #endif
    
    #if os(macOS)
    static let mainColor = Color(NSColor.systemIndigo)
    #endif
}
