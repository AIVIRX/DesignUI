import SwiftUI
import ImageIO

/// Static remote images backed entirely by Apple's networking and image APIs.
struct CachedRemoteImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: CGImage?
    @State private var loadedURL: URL?
    @State private var failed = false

    var body: some View {
        Group {
            if let image, loadedURL == url {
                content(Image(decorative: image, scale: 1))
                    .transition(.opacity)
            } else if failed {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Image unavailable")
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            image = nil
            loadedURL = nil
            failed = false
            guard let url else {
                failed = true
                return
            }
            do {
                let result = try await RemoteImageLoader.shared.image(for: url)
                try Task.checkCancellation()
                withAnimation(.easeInOut(duration: 0.2)) {
                    image = result
                    loadedURL = url
                }
            } catch {
                guard !Task.isCancelled else { return }
                failed = true
            }
        }
    }
}

actor RemoteImageLoader {
    static let shared = RemoteImageLoader()

    private let session: URLSession
    private let images = NSCache<NSURL, CGImage>()
    private var inFlight: [URL: Task<CGImage, Error>] = [:]

    init(session: URLSession? = nil) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.urlCache = URLCache(
                memoryCapacity: 15 * 1024 * 1024,
                diskCapacity: 200 * 1024 * 1024,
                directory: URL.cachesDirectory.appendingPathComponent("RemoteImages", isDirectory: true)
            )
            configuration.requestCachePolicy = .useProtocolCachePolicy
            configuration.timeoutIntervalForRequest = 30
            self.session = URLSession(configuration: configuration)
        }
        images.totalCostLimit = 15 * 1024 * 1024
        images.countLimit = 30
    }

    func image(for url: URL) async throws -> CGImage {
        if let cached = images.object(forKey: url as NSURL) { return cached }
        if let existing = inFlight[url] { return try await existing.value }

        // A disappearing card doesn't cancel a download other cards still need.
        let task = Task { [session] in
            let (data, response) = try await session.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode) else {
                throw URLError(.badServerResponse)
            }
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2048,
                    kCGImageSourceShouldCacheImmediately: true
                  ] as CFDictionary) else {
                throw URLError(.cannotDecodeContentData)
            }
            return image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }
        let image = try await task.value
        images.setObject(image, forKey: url as NSURL, cost: image.bytesPerRow * image.height)
        return image
    }
}
