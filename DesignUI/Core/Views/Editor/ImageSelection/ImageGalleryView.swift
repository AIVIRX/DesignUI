//
//  ImageGalleryView.swift
//  DesignUI
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
    @State private var importError: String?
    
    // Multi-select & Import state
    @State private var isEditing = false
    @State private var selectionToDelete = Set<String>()
    @State private var showFileImporter = false
    @State private var showPhotosPicker = false
    @State private var showPhotosPickerScreen = false
    @State private var showLegacyImagePicker = false
    
    @State private var showUnsplashGallery = false
    @State private var searchText = ""
    
    // Grid layout
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                #if os(macOS)
                // Custom Header for macOS (to force top placement)
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
                        Button(action: {
                            dismiss()
                        }) {
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
                        // Select button to enter multi-selection mode
                        Button(action: {
                            isEditing = true
                        }) {
                            Text("Select")
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        
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
                                .fontWeight(.semibold)
                                .frame(width: 30, height: 30)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                        .menuIndicator(.hidden)
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
                
                Divider()
                #endif
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(imageFilenames, id: \.self) { filename in
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
                    }
                    .padding()
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: imageFilenames)
                }
            }
            #if os(macOS)
            .background(Color(nsColor: .windowBackgroundColor))
            #else
            .background(Color(uiColor: .systemBackground))
            .navigationTitle(isEditing ? "\(selectionToDelete.count) Selected" : "Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Trailing Items
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
                            
                            #if os(iOS)
                            if UIDevice.current.userInterfaceIdiom == .pad {
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
                            } else {
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
                            #else
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
                            #endif
                        }
                    }
                }
            }
            #endif
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                handleFileImport(result)
            }
#if os(iOS)
            .photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
#endif
#if os(iOS)
            .navigationDestination(isPresented: $showPhotosPickerScreen) {
                PhotosPickerScreen { data in
                    if let data {
                        saveAndReload(data: data)
                    }
                }
            }
#endif
#if os(iOS)
            .fullScreenCover(isPresented: $showLegacyImagePicker) {
                LegacyImagePicker { data in
                    if let data {
                        saveAndReload(data: data)
                    }
                    showLegacyImagePicker = false
                }
            }
#endif
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
            .navigationDestination(isPresented: $showUnsplashGallery) {
                UnsplashGalleryView(onImageSelected: { filename in
                    showUnsplashGallery = false
                    loadImages()
                    selectedImageName = filename
                    dismiss()
                })
            }
        }
        #if os(macOS)
        .frame(width: 500, height: 600)
        #endif
    }
    
    // MARK: - Actions
    
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
        showLegacyImagePicker = true
#endif
    }
}

#if os(iOS)
private struct PhotosPickerScreen: View {
    @Environment(\.dismiss) private var dismiss
    let onComplete: (Data?) -> Void
    
    var body: some View {
        SystemPhotosPicker { data in
            onComplete(data)
            dismiss()
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SystemPhotosPicker: UIViewControllerRepresentable {
    let onComplete: (Data?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onComplete: (Data?) -> Void
        
        init(onComplete: @escaping (Data?) -> Void) {
            self.onComplete = onComplete
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let itemProvider = results.first?.itemProvider else {
                onComplete(nil)
                return
            }
            
            let imageIdentifier = UTType.image.identifier
            if itemProvider.hasItemConformingToTypeIdentifier(imageIdentifier) {
                itemProvider.loadDataRepresentation(forTypeIdentifier: imageIdentifier) { data, _ in
                    DispatchQueue.main.async {
                        self.onComplete(data)
                    }
                }
            } else {
                itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    let data = (object as? UIImage)?.jpegData(compressionQuality: 0.9)
                    DispatchQueue.main.async {
                        self.onComplete(data)
                    }
                }
            }
        }
    }
}

private struct LegacyImagePicker: UIViewControllerRepresentable {
    let onComplete: (Data?) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.modalPresentationStyle = .formSheet
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onComplete: (Data?) -> Void
        
        init(onComplete: @escaping (Data?) -> Void) {
            self.onComplete = onComplete
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onComplete(nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            let data = image?.jpegData(compressionQuality: 0.9)
            onComplete(data)
        }
    }
}
#endif

// Helper View for individual cells
private struct GalleryImageCell: View {
    let filename: String
    let isSelected: Bool
    let isEditing: Bool
    
    @State private var image: PlatformImage?
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            if let image = image {
                #if os(macOS)
                Image(nsImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .padding()
                #else
                Image(uiImage: image)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .padding()
                #endif
            } else {
                Color.gray.opacity(0.1)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(ProgressView())
            }
            
            // Edit Mode Overlay
            if isEditing {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .background(Circle().fill(Color.white))
                            .padding(6)
                    }
                    Spacer()
                }
                .background(Color.black.opacity(isSelected ? 0.0 : 0.05)) // Touch target hint
            } else if isSelected {
                // Standard Selection (Blue Border)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 3)
                
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .background(Circle().fill(Color.white))
                            .padding(6)
                    }
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle()) // Hit testing
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                .opacity(isHovering && !isSelected && !isEditing ? 1 : 0)
        )
        .onHover { isHovering = $0 }
        .task {
            // Load image asynchronously to prevent scrolling hitches?
            // ImageGalleryManager loads from disk (sync-ish but fast for SSD).
            // Could wrap in Task.
            if let loaded = ImageGalleryManager.shared.loadImage(filename: filename) {
                await MainActor.run {
                    self.image = loaded
                }
            }
        }
    }
}
