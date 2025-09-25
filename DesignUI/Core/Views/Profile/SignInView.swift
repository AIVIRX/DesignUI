//
//  InfiniteBackground.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 2/17/25.
//

import SwiftUI
import AuthenticationServices

struct Card: Identifiable, Hashable {
    var id: String = UUID().uuidString
    var image: String
}

let cards: [Card] = [
    .init(image: "image1"),
    .init(image: "image2"),
    .init(image: "image3"),
    .init(image: "image4"),
]

struct SignInView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var signInAppleButtonId = UUID().uuidString
    @State private var activeCard: Card? = cards.first
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .default).autoconnect()
    @State private var initialAnimation: Bool = false
    @State private var titleProgress: CGFloat = 0
    #if os(iOS)
    @State private var scrollView: UIScrollView?
    #endif
    var body: some View {
        NavigationStack {
            ZStack {
                #if os(macOS)
                // macOS modern sign-in layout
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image("AppLogo")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .padding()
                        Text("Dock UI Accounts")
                            .font(.system(size: 28, weight: .bold))
                        Text("Sign in to sync favorites and access exclusive features.")
                            .foregroundStyle(.secondary)
                    }
                    
                    SignInWithAppleButton { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        Task {
                            await authViewModel.handleSignInWithApple(result)
                        }
                    }
                    .id(signInAppleButtonId)
                    .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                    .onChange(of: colorScheme, { _, _ in
                        signInAppleButtonId = UUID().uuidString
                    })
                    .frame(height: 44)
                    .frame(maxWidth: 360)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(32)
                .frame(maxWidth: 520)
                .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 8)
                #else
                // iOS layout
                AmbientBackground()
                    .animation(.easeInOut(duration: 1), value: activeCard)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        ZStack {
                            VStack(spacing: 40) {
                                InfiniteScrollView(collection: cards) { card in
                                    CarouselCardView(card)
                                } uiScrollView: {
                                    scrollView = $0
                                } onScroll: {
                                    updateActiveCard()
                                }
                                .scrollIndicators(.hidden)
                                .scrollClipDisabled()
                                .containerRelativeFrame(.vertical) { value, _ in
                                    value * 0.45
                                }
                                .visualEffect { [initialAnimation] content, proxy in
                                    content
                                        .offset(y: !initialAnimation ? -(proxy.size.height + 200) : 0)
                                }
                                
                                // title & description
                                VStack(spacing: 4) {
                                    Text("Introducing")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                        .blurOpacityEffect(initialAnimation)
                                    
                                    Text("Dock UI Accounts")
                                        .font(.largeTitle.bold())
                                        .foregroundStyle(.white)
                                        .padding(.bottom)
                                    
                                    Text("Create your account to save favorites,\nsync across devices, and access\nexclusive features.")
                                        .multilineTextAlignment(.center)
                                        .foregroundStyle(.secondary)
                                        .blurOpacityEffect(initialAnimation)
                                    
                                    Spacer()
                                    
                                    // Sign in with Apple button
                                    VStack(spacing: 16) {
                                        SignInWithAppleButton { request in
                                            request.requestedScopes = [.email, .fullName]
                                        } onCompletion: { result in
                                            Task {
                                                await authViewModel.handleSignInWithApple(result)
                                            }
                                        }
                                        .id(signInAppleButtonId)
                                        .signInWithAppleButtonStyle(colorScheme == .light ? .black : .white)
                                        .onChange(of: colorScheme, { _, _ in
                                            signInAppleButtonId = UUID().uuidString
                                        })
                                        .frame(height: 50)
                                        .frame(maxWidth: 500)
                                        .cornerRadius(12)
                                    }
                                    .padding()
                                }
                                .padding()
                                
                                Spacer()
                            }
                        }
                        .onReceive(timer) { _ in
                            if let scrollView = scrollView {
                                scrollView.contentOffset.x += 0.35
                            }
                        }
                        .task {
                            try? await Task.sleep(for: .seconds(0.35))
                            
                            withAnimation(.smooth(duration: 0.75, extraBounce: 0)) {
                                initialAnimation = true
                            }
                            
                            withAnimation(.smooth(duration: 2.5, extraBounce: 0).delay(0.3)) {
                                titleProgress = 1
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                #endif
            }
        }
        .alert("Error", isPresented: $authViewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(authViewModel.errorMessage)
        }
    }
    
    #if os(iOS)
    func updateActiveCard() {
        if let currentScrollOffset = scrollView?.contentOffset.x {
            let activeIndex = Int((currentScrollOffset / 200).rounded()) % cards.count
            guard activeCard?.id != cards[activeIndex].id else { return }
            activeCard = cards[activeIndex]
        }
    }
    #endif
    @ViewBuilder
    private func AmbientBackground() -> some View {
        GeometryReader {
            let size = $0.size
            
            ZStack {
                ForEach(cards) { card in
                    /// Programmatically downsized for better performance
                    Image(card.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                        .frame(width: size.width, height: size.height)
                        .opacity(activeCard?.id == card.id ? 1 : 0)
                }
                
                Rectangle()
                    .fill(.black.opacity(0.45))
                    .ignoresSafeArea()
            }
            .compositingGroup()
            .blur(radius: 90, opaque: true)
            .ignoresSafeArea()
        }
    }
    
    /// Carousel Card View
    @ViewBuilder
    private func CarouselCardView(_ card: Card) -> some View {
        GeometryReader {_ in
            Image(card.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 160,height: 360)
                .clipShape(.rect(cornerRadius: 20))
                .shadow(color: .black.opacity(0.4), radius: 10, x: 1, y: 0)
        }
        .frame(width: 160) // Match image width
        .scrollTransition(.interactive.threshold(.centered), axis: .horizontal) { content, phase in
            content
                .offset(y: phase == .identity ? -10 : 0)
                .rotationEffect(.degrees(phase.value * 5), anchor: .bottom)
        }
    }
}

extension View {
    func blurOpacityEffect(_ show: Bool) -> some View {
        self
            .blur(radius: show ? 0 : 2)
            .opacity(show ? 1 : 0)
            .scaleEffect(show ? 1 : 0.9)
    }
}

fileprivate extension View {
    @ViewBuilder
    func blurOpacity(_ status: Bool) -> some View {
        self
            .compositingGroup()
            .opacity(status ? 1 : 0)
            .blur(radius: status ? 0 : 10)
    }
}
