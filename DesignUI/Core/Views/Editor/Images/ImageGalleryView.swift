//
//  ImageGalleryView.swift
//
//  Created for Local Image Gallery architecture.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ImageGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedImageName: String
    
    @State private var imageFilenames: [String] = []
    @State private var selectedPhotoItem: PhotosPickerItem?
    // Multi-select & Import state
    @State private var isEditing = false
    @State private var selectionToDelete = Set<String>()
    @State private var showFileImporter = false
    @State private var showPhotosPicker = false
    @State private var showUnsplashGallery = false
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            applyPhotosPicker(mainContent)
        }
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(uiColor: .systemBackground))
        .navigationTitle(isEditing ? "\(selectionToDelete.count) Selected" : "Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { iOSToolbarContent }
        #endif
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            handleFileImport(result)
        }
        .onAppear {
            loadImages()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self) {
                    saveAndReload(data: data)
                }
            }
        }
        .sheet(isPresented: $showUnsplashGallery) {
            NavigationStack {
                UnsplashGalleryView(isPresented: $showUnsplashGallery, onImageSelected: { filename in
                    showUnsplashGallery = false
                    loadImages()
                    selectedImageName = filename
                })
            }
        }
        #if os(macOS)
        .frame(width: 500, height: 600)
        #endif
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
#if os(macOS)
            macOSHeader
            Divider()
#endif
            galleryGrid
        }
    }

    #if os(macOS)
    private var macOSHeader: some View {
        HStack {
            if isEditing {
                Button("Done") {
                    isEditing = false
                    selectionToDelete.removeAll()
                }
                .buttonStyle(.plain)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
            } else {
                Button(action: dismiss.callAsFunction) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.medium)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Text(isEditing ? "\(selectionToDelete.count) Selected" : "Gallery")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if isEditing {
                Button(role: .destructive) {
                    deleteSelectedItems()
                } label: {
                    Image(systemName: "trash")
                        .fontWeight(.semibold)
                        .frame(width: 30, height: 30)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(selectionToDelete.isEmpty)
            } else {
                Button(action: { isEditing = true }) {
                    Text("Select")
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .buttonStyle(.plain)

                addMenu
                    .menuIndicator(.hidden)
                    .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor))
    }
    #endif

    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(imageFilenames, id: \.self) { filename in
                    galleryItemButton(filename: filename)
                }
            }
            .padding()
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: imageFilenames)
        }
    }

    private func galleryItemButton(filename: String) -> some View {
        Button(action: {
            if isEditing {
                toggleSelection(filename)
            } else {
                selectedImageName = filename
                dismiss()
            }
        }) {
            GalleryImageCell(
                filename: filename,
                isSelected: isEditing ? selectionToDelete.contains(filename) : selectedImageName == filename,
                isEditing: isEditing
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !isEditing {
                Button(role: .destructive) {
                    deleteImage(filename: filename)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    @ToolbarContentBuilder
    private var iOSToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            HStack {
                if isEditing {
                    Button(role: .destructive) {
                        deleteSelectedItems()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(selectionToDelete.isEmpty)
                } else {
                    Button("Select") {
                        isEditing = true
                    }
                    addMenu
                }
            }
        }
    }

    private var addMenu: some View {
        Menu {
            Button {
                presentPhotosPicker()
            } label: {
                Label("From Photos", systemImage: "photo")
            }

            Button {
                showFileImporter = true
            } label: {
                Label("Select File", systemImage: "folder")
            }

            Button {
                showUnsplashGallery = true
            } label: {
                Label("Unsplash", systemImage: "globe")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
        
    private func loadImages() {
        imageFilenames = ImageGalleryManager.shared.getAllImageFilenames()
    }
    
    private func deleteImage(filename: String) {
        ImageGalleryManager.shared.deleteImage(filename: filename)
        loadImages()
        if selectedImageName == filename { selectedImageName = "" }
    }
    
    private func deleteSelectedItems() {
        for filename in selectionToDelete {
            ImageGalleryManager.shared.deleteImage(filename: filename)
        }
        selectionToDelete.removeAll()
        loadImages()
        isEditing = false
    }
    
    private func toggleSelection(_ filename: String) {
        if selectionToDelete.contains(filename) {
            selectionToDelete.remove(filename)
        } else {
            selectionToDelete.insert(filename)
        }
    }
    
    private func saveAndReload(data: Data) {
        if ImageGalleryManager.shared.saveImage(data: data) != nil {
            Task { @MainActor in
                loadImages()
                selectedPhotoItem = nil
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            for url in urls {
                // Access security scoped resource
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }
                
                if let data = try? Data(contentsOf: url) {
                    saveAndReload(data: data)
                }
            }
        case .failure(let error):
            debugLog("File import error: \(error.localizedDescription)")
        }
    }

    private func presentPhotosPicker() {
#if os(iOS)
        showPhotosPicker = true
#elseif os(macOS)
        if #available(macOS 13.0, *) {
            showPhotosPicker = true
        } else {
            showFileImporter = true
        }
#endif
    }

    @ViewBuilder
    private func applyPhotosPicker<Content: View>(_ content: Content) -> some View {
#if os(iOS) || os(macOS)
        if #available(iOS 16.0, macOS 13.0, *) {
            content.photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
        } else {
            content
        }
#else
        content
#endif
    }
}

// Helper View for individual cells
private struct GalleryImageCell: View {
    let filename: String
    let isSelected: Bool
    let isEditing: Bool
    
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            imageContent
            selectionOverlay
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .overlay(hoverBorderOverlay)
        .onHover { isHovering = $0 }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let fileURL = ImageGalleryManager.shared.getImageUrl(filename: filename),
           FileManager.default.fileExists(atPath: fileURL.path) {
            AsyncImage(url: fileURL) { phase in
                switch phase {
                case .success(let image):
                    chartCellImage(image: image)
                case .empty:
                    placeholderView
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    @ViewBuilder
    private var selectionOverlay: some View {
        if isEditing {
            editingSelectionOverlay
        } else if isSelected {
            standardSelectionOverlay
        }
    }

    private var editingSelectionOverlay: some View {
        VStack {
            HStack {
                Spacer()
                selectionIcon(
                    systemName: isSelected ? "checkmark.circle.fill" : "circle",
                    color: isSelected ? .accentColor : .secondary
                )
            }
            Spacer()
        }
        .background(Color.black.opacity(isSelected ? 0.0 : 0.05))
    }

    private var standardSelectionOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor, lineWidth: 3)

            VStack {
                HStack {
                    Spacer()
                    selectionIcon(systemName: "checkmark.circle.fill", color: .accentColor)
                }
                Spacer()
            }
        }
    }

    private func selectionIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .foregroundColor(color)
            .background(Circle().fill(Color.white))
            .padding(6)
    }

    private var shouldShowHoverBorder: Bool {
        isHovering && !isSelected && !isEditing
    }

    private var hoverBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.primary.opacity(0.2), lineWidth: 2)
            .opacity(shouldShowHoverBorder ? 1 : 0)
    }

    private func chartCellImage(image: Image) -> some View {
        image
            .renderingMode(.original)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .padding()
    }

    private var placeholderView: some View {
        Color.gray.opacity(0.1)
            .aspectRatio(1, contentMode: .fit)
            .overlay(ProgressView())
    }
}
