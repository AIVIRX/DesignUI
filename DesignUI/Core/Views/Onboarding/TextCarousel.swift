//
//  TextCarousel.swift
//  FuseAppOnboarding
//
//  Created by George on 04/11/2025.
//

import SwiftUI
import Combine

struct Carousel: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let image: String
}

struct TextCarousel: View {
    @State var items: [Carousel]
    
    @State private var window: [Carousel] = []
    @State private var index = 0
    
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var highlightID: UUID? {
        window.indices.contains(2) ? window[2].id : nil
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading) {
                ForEach(window) { item in
                    row(for: item, rowHeight: proxy.size.height / 3)
                }
            }
            .frame(height: proxy.size.height, alignment: .leading)
        }
        .mask(gradientMask)
        .onReceive(timer) { _ in
            tick()
        }
        .onAppear {
            setupWindowIfNeeded()
        }
    }

    private func row(for item: Carousel, rowHeight: CGFloat) -> some View {
        let isHighlighted = item.id == highlightID

        return HStack(spacing: 16) {
            if isHighlighted {
                Image(item.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 38)
                    .font(.system(size: 48))
                    .transition(
                        .move(edge: .leading).combined(with: .opacity).combined(with: .scale)
                    )
            }

            Text(item.text)
                .foregroundStyle(isHighlighted ? .black : .black.opacity(0.2))
                .font(.system(size: 40, weight: .medium))
        }
        .drawingGroup()
        .frame(height: rowHeight)
        .transaction { transaction in
            if item.id == window.first?.id {
                transaction.animation = nil
            }
        }
    }

    private var gradientMask: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.3),
                .init(color: .black, location: 0.7),
                .init(color: .clear, location: 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func tick() {
        guard !items.isEmpty else { return }
        withAnimation {
            if !window.isEmpty {
                window.removeLast()
            }
            window.insert(Carousel(text: items[index].text, image: items[index].image), at: 0)
            index = ((index - 1) + items.count) % items.count
        }
    }

    private func setupWindowIfNeeded() {
        guard window.isEmpty, !items.isEmpty else { return }
        for i in 0..<5 {
            let index = i % items.count
            window.append(Carousel(text: items[index].text, image: items[index].image))
        }
        index = items.count - 1
    }
}
