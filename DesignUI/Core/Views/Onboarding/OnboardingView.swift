//
//  OnboardingView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 9/16/25.
//

import SwiftUI
import UserNotifications

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

struct OnboardingView: View {
    /// View Properties
    @State private var activeCard: Card? = cards.first
    @State private var scrollView: UIScrollView?
    @State private var timer = Timer.publish(every: 0.01, on: .current, in: .default).autoconnect()
    @State private var initialAnimation: Bool = false
    @State private var titleProgress: CGFloat = 0
    @State private var currentPage: Int = 0
    @State private var askPermission: Bool = false
    let onComplete: () -> Void
    let config = NotificationOnBoardingConfig(
        title: "Stay Connected with\nPush Notifications",
        content: "We will send you push notifications to keep you updated on the latest templates.",
        notificationTitle: "New!",
        notificationContent: "New templates are now available for you to view.",
        primaryButtonTitle: "Continue",
        secondaryButtonTitle: "Ask Me Later"
    )
    var body: some View {
        ZStack {
            /// Ambient Background View
            AmbientBackground()
                .animation(.easeInOut(duration: 1), value: activeCard)
            
            VStack(spacing: 40) {
                // Page Content
                TabView(selection: $currentPage) {
                    // Page 1 - Welcome
                    VStack(spacing: 40) {
                        Spacer()
                        if currentPage == 0 {
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
                                
                                Group {
                                    if #available(iOS 18, *) {
                                        Text("Dock UI: Snippets")
                                            .font(.largeTitle.bold())
                                            .foregroundStyle(.white)
                                            .textRenderer(TitleTextRenderer(progress: titleProgress))
                                    } else {
                                        Text("Dock UI")
                                            .font(.largeTitle.bold())
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding(.bottom, 12)
                                
                                Text("Discover beautiful UI templates, design resources,\nand inspiration for your next project.\nEverything you need in one place.")
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                                    .blurOpacityEffect(initialAnimation)
                            }
                            
                            Spacer()
                            
                            // Action Buttons
                            HStack(spacing: 16) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentPage = 1
                                    }
                                } label: {
                                    Text("Next")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 25)
                                        .padding(.vertical, 12)
                                        .background(.white.opacity(0.2), in: .capsule)
                                }
                                .blurOpacityEffect(initialAnimation)
                            }
                        }
                    }
                    .tag(0)
                    
                    // Page 2 - Features
                    NotificationOnBoarding(config: config) {
                        /// Your App Logo!
                        Image("AppLogo")
                            .resizable()
                            .foregroundStyle(.background)
                            .frame(width: 40, height: 40)
                            .background(.primary)
                            .clipShape(.rect(cornerRadius: 10))
                    } onPermissionChange: { isApproved in
                        print(isApproved)
                    } onPrimaryButtonTap: {
                        askPermission = false
                    } onSecondaryButtonTap: {
                        onComplete()
                    }
                    .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
    
    func updateActiveCard() {
        if let currentScrollOffset = scrollView?.contentOffset.x {
            let activeIndex = Int((currentScrollOffset / 200).rounded()) % cards.count
            guard activeCard?.id != cards[activeIndex].id else { return }
            activeCard = cards[activeIndex]
        }
    }
    
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

struct NotificationOnBoardingConfig {
    var title: String
    var content: String
    var notificationTitle: String
    var notificationContent: String
    var primaryButtonTitle: String
    var secondaryButtonTitle: String
}

struct NotificationOnBoarding<NotificationLogo: View>: View {
    var config: NotificationOnBoardingConfig
    @ViewBuilder var notificationLogo: NotificationLogo
    var onPermissionChange: (_ isApproved: Bool) -> ()
    var onPrimaryButtonTap: () -> ()
    var onSecondaryButtonTap: () -> ()

    @State private var animateNotification: Bool = false
    @State private var loopContinues: Bool = true
    @State private var askPermission: Bool = false
    @State private var authorization: UNAuthorizationStatus = .notDetermined
    @State private var currentTime = Date()
    @State private var timer: Timer?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    var body: some View {
        ZStack {
            /// Animated Mobile Like Notification UI
            VStack(spacing: 0) {
                iPhonePreview()
                    .padding(.top, 15)
                
                VStack(spacing: 20) {
                    Text(config.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(config.content)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                    
                    /// Primary & Secondary Button's
                    VStack(spacing: 12) {
                        Button {
                            if authorization == .authorized {
                                onPrimaryButtonTap()
                            } else if authorization == .denied {
                                /// Visit Settings
                                if let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    openURL(settingsURL)
                                }
                            } else {
                                askNotificationPermission()
                            }
                        } label: {
                            Text(authorization == .authorized ? "You're All Set!" : authorization == .denied ? "Go to Settings" : config.primaryButtonTitle)
                                .fontWeight(.medium)
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(foregroundColor)
                                .frame(height: 55)
                                .background(.white, in: .rect(cornerRadius: 20))
                        }
                        .geometryGroup()
                        
                        // Secondary button - show for not determined OR denied
                        if authorization == .notDetermined || authorization == .denied {
                            Button {
                                onSecondaryButtonTap()
                            } label: {
                                Text(authorization == .denied ? "Remind Me Later" : config.secondaryButtonTitle)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 15)
                .padding(.bottom, 20)
            }
            .blurOpacity(!askPermission)
        }
        .onDisappear {
            loopContinues = false
            timer?.invalidate()
        }
        .onAppear {
            startTimer()
        }
        .task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            let authorization = settings.authorizationStatus
            self.authorization = authorization
            
            if authorization == .authorized {
                onPermissionChange(true)
            }
            
            if authorization == .denied {
                onPermissionChange(false)
            }
        }
        .interactiveDismissDisabled()
    }
    
    @ViewBuilder
    private func iPhonePreview() -> some View {
        GeometryReader {
            let size = $0.size
            /// You can increase the value 340 to more to have more scaling!
            let scale = min(size.height / 340, 1)
            let width: CGFloat = 300
            let cornerRadius: CGFloat = 30
            
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.white.opacity(0.06))
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.gray.opacity(0.5), lineWidth: 1.5)
                
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        RoundedRectangle(cornerRadius: 20)
                        
                        RoundedRectangle(cornerRadius: 20)
                    }
                    .frame(height: 130)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: 15), count: 4), spacing: 15) {
                        ForEach(1...12, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 55)
                        }
                    }
                }
                .padding(20)
                .padding(.top, 20)
                .foregroundStyle(.white.opacity(0.2))
                
                /// Status Bar
                HStack(spacing: 4) {
                    Text(currentTime, style: .time)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Image(systemName: "cellularbars")
                    
                    Image(systemName: "wifi")
                    
                    Image(systemName: "battery.50percent")
                }
                .foregroundStyle(.white)
                .font(.caption2)
                .padding(.horizontal, 20)
                .padding(.top, 15)
                
                /// Notification View
                NotificationView()
            }
            .frame(width: width)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            /// Gradient Mask
            .mask {
                LinearGradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: .clear, location: 0.9)
                ], startPoint: .top, endPoint: .bottom)
                /// For the visibility of the border!
                .padding(-1)
            }
            .scaleEffect(scale, anchor: .top)
        }
    }
    
    @ViewBuilder
    private func NotificationView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            notificationLogo
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(config.notificationTitle)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    Text("Now")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.gray)
                }
                
                Text(config.notificationContent)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .gray.opacity(0.5), radius: 1.5)
        .padding(.horizontal, 12)
        .padding(.top, 40)
        .offset(y: animateNotification ? 0 : -200)
        .clipped()
        .task {
            await loopAnimation()
        }
    }
    
    private func loopAnimation() async {
        try? await Task.sleep(for: .seconds(0.5))
        
        withAnimation(.smooth(duration: 1)) {
            animateNotification = true
        }
        
        try? await Task.sleep(for: .seconds(4))
        
        withAnimation(.smooth(duration: 1)) {
            animateNotification = false
        }
        
        guard loopContinues else { return }
        try? await Task.sleep(for: .seconds(1.3))
        await loopAnimation()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func askNotificationPermission() {
        Task { @MainActor in
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                askPermission = true
            }
            
            try? await Task.sleep(for: .seconds(0.3))
            
            /// Asking Notification Permission!
            let status = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            let authorization = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
            onPermissionChange(status)
            
            /// Removing dark background and arrow view!
            withAnimation(.smooth(duration: 0.3, extraBounce: 0)) {
                askPermission = false
                self.authorization = authorization
            }
        }
    }
    
    var foregroundColor: Color {
        colorScheme != .dark ? .white : .black
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
    
    var isiOS26: Bool {
        if #available(iOS 26, *) {
            return true
        }
        
        return false
    }
}

