import SwiftUI

struct UnsplashGalleryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var unsplashService = UnsplashService.shared
    
    @State private var photos: [UnsplashPhoto] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var currentPage: Int = 1
    @State private var errorMessage: String?
    
    // Callback when an image is selected and downloaded
    var onImageSelected: (String) -> Void
    
    var body: some View {
        VStack {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            if isLoading && photos.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyMasonryView(
                        items: photos,
                        columns: {
#if os(macOS)
                            return 3
#else
                            return 2
#endif
                        }(),
                        spacing: 12,
                        hasMorePosts: true, // Infinite scroll
                        isLoading: isLoading,
                        loadMoreHandler: { _ in loadMore() }
                    ) { photo in
                        Button(action: {
                            downloadAndSelect(photo: photo)
                        }) {
                            UnsplashPhotoCell(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .padding(.top, 60) // Add top padding for overlay search bar
                }
            }
        }
        .navigationTitle("Unsplash")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText)
        .onSubmit(of: .search) {
            performSearch()
        }
#endif
#if os(macOS)
        .overlay(alignment: .top) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.primary)
                
                TextField("Search photos...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        performSearch()
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        resetAndLoadInitial()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .padding()
        }
#endif
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                resetAndLoadInitial()
            }
        }
        .onAppear {
            resetAndLoadInitial()
        }
    }
    
    private func resetAndLoadInitial() {
        currentPage = 1
        photos = []
        errorMessage = nil
        loadPhotos()
    }
    
    private func performSearch() {
        currentPage = 1
        photos = []
        errorMessage = nil
        loadPhotos()
    }
    
    private func loadMore() {
        guard !isLoading else { return }
        currentPage += 1
        loadPhotos()
    }
    
    private func loadPhotos() {
        isLoading = true
        
        Task {
            do {
                let newPhotos: [UnsplashPhoto]
                if searchText.isEmpty {
                    newPhotos = try await unsplashService.listPhotos(page: currentPage)
                } else {
                    newPhotos = try await unsplashService.searchPhotos(query: searchText, page: currentPage)
                }
                
                await MainActor.run {
                    let existingIds = Set(self.photos.map { $0.id })
                    let uniqueNewPhotos = newPhotos.filter { !existingIds.contains($0.id) }
                    self.photos.append(contentsOf: uniqueNewPhotos)
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load photos. Please check your API Key."
                    self.isLoading = false
                }
            }
        }
    }
    
    private func downloadAndSelect(photo: UnsplashPhoto) {
        isLoading = true
        Task {
            do {
                // 1. Trigger Attribution
                await unsplashService.triggerDownload(photo: photo)
                
                // 2. Download Data
                let data = try await unsplashService.downloadImage(from: photo.urls.regular)
                
                // 3. Save to Local Gallery
                await MainActor.run {
                    if let filename = ImageGalleryManager.shared.saveImage(data: data) {
                        onImageSelected(filename) // Return the local filename
                    } else {
                        errorMessage = "Failed to save image locally."
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to download image."
                    self.isLoading = false
                }
            }
        }
    }
}

struct UnsplashPhotoCell: View {
    let photo: UnsplashPhoto
    
    var body: some View {
        AsyncImage(url: URL(string: photo.urls.small)) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(Double(photo.width) / Double(photo.height), contentMode: .fit)
                    .overlay(ProgressView())
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8)
            case .failure:
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(Image(systemName: "wifi.slash"))
            @unknown default:
                EmptyView()
            }
        }
        .overlay(
            VStack {
                Spacer()
                HStack {
                    Link(destination: attributionURL(photo.user.links.html)) {
                        Text(photo.user.name)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .underline()
                    }
                    Spacer()
                }
                .padding(6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                .padding(6)
            }
            , alignment: .bottomLeading
        )
    }
    
    private func attributionURL(_ string: String) -> URL {
        let separator = string.contains("?") ? "&" : "?"
        return URL(string: "\(string)\(separator)utm_source=DesignUI&utm_medium=referral") ?? URL(string: "https://unsplash.com")!
    }
}
