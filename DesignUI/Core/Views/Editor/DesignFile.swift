//
//  DesignFile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation
import CryptoKit
#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformImage = UIImage
#endif

// MARK: - Notifications
extension Notification.Name {
    static let imageDownloadsCompleted = Notification.Name("imageDownloadsCompleted")
}

// MARK: - Design File Model
class DesignFile: ObservableObject, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var pages: [DesignPage]
    @Published var currentPageIndex: Int = 0
    @Published var lastModified: Date
    @Published var thumbnail: Data?
    @Published var devicePreset: String? // Store device preset name for thumbnail styling
    @Published var selectedDevicePreset: String? // Store selected device preset for canvas
    @Published var canvasColorScheme: String? // Store canvas color scheme (light/dark)
    @Published var statusBarVisible: Bool = true // Store status bar visibility
    @Published var statusBarTopSafeArea: Bool = true // Store top safe area setting
    @Published var isDeleted: Bool = false // Flag to prevent saving after deletion
    let fileURL: URL
    
    // Serial queue for saving operations to prevent race conditions and UI blocking
    private static let saveQueue = DispatchQueue(label: "com.designui.saveQueue", qos: .background)
    
    // Auto-save state
    private var autoSaveTimer: Timer?
    private var hasUnsavedChanges = false
    @Published var isAutoSaving = false
    
    deinit {
        stopAutoSave()
    }
    
    /// Computed property for backwards compatibility - delegates to current page
    var components: [UIComponent] {
        get { currentPage?.components ?? [] }
        set { currentPage?.components = newValue }
    }
    
    /// The currently active page
    var currentPage: DesignPage? {
        guard currentPageIndex >= 0 && currentPageIndex < pages.count else { return nil }
        return pages[currentPageIndex]
    }
    
    /// Total component count across all pages (for display purposes)
    var totalComponentCount: Int {
        pages.reduce(0) { $0 + $1.components.count }
    }
    
    init(name: String, components: [UIComponent] = [], fileURL: URL, id: UUID? = nil, devicePreset: String? = nil, colorScheme: String? = nil) {
        self.id = id ?? UUID()
        self.name = name
        let initialPreset = devicePreset ?? "iPhone 17 Pro Max"
        let initialScheme = colorScheme ?? "light"
        // Create default page with provided components
        self.pages = [DesignPage(name: "Page 1", components: components, devicePreset: initialPreset, colorScheme: initialScheme)]
        self.canvasColorScheme = initialScheme
        self.selectedDevicePreset = initialPreset
        self.devicePreset = initialPreset
        self.lastModified = Date()
        self.fileURL = fileURL
    }
    
    init(name: String, pages: [DesignPage], fileURL: URL, id: UUID? = nil, devicePreset: String? = nil, colorScheme: String? = nil) {
        self.id = id ?? UUID()
        self.name = name
        self.pages = pages.isEmpty ? [DesignPage(name: "Page 1")] : pages
        self.canvasColorScheme = colorScheme ?? "light"
        self.selectedDevicePreset = devicePreset ?? "iPhone 17 Pro Max"
        self.devicePreset = devicePreset ?? "iPhone 17 Pro Max"
        self.lastModified = Date()
        self.fileURL = fileURL
    }
    
    // MARK: - Page Management
    
    /// Add a new page with optional name. Does NOT switch to the new page automatically.
    /// Returns a tuple of (new page, new page index)
    func addPage(name: String? = nil) -> (page: DesignPage, index: Int) {
        let pageName = name ?? "Page \(pages.count + 1)"
        // Default to iPhone 17 Pro Max and Light Mode as requested
        let newPage = DesignPage(
            name: pageName,
            devicePreset: "iPhone 17 Pro Max",
            colorScheme: "light"
        )
        pages.append(newPage)
        let newIndex = pages.count - 1
        // Don't update currentPageIndex here - let caller handle the switch
        return (newPage, newIndex)
    }
    
    /// Duplicate an existing page. Does NOT switch to the new page automatically.
    /// Returns a tuple of (duplicated page, new page index) or nil if invalid
    func duplicatePage(at index: Int) -> (page: DesignPage, index: Int)? {
        guard index >= 0 && index < pages.count else { return nil }
        let duplicated = pages[index].clone()
        pages.insert(duplicated, at: index + 1)
        let newIndex = index + 1
        // Don't update currentPageIndex here - let caller handle the switch
        return (duplicated, newIndex)
    }
    
    /// Delete a page at index (cannot delete the first page or the last page)
    func deletePage(at index: Int) -> Bool {
        // Cannot delete first page (index 0) - it's the home page
        // Cannot delete if it's the only page
        guard pages.count > 1, index > 0, index < pages.count else { return false }
        pages.remove(at: index)
        // Adjust current index if needed
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
        return true
    }
    
    /// Rename a page
    func renamePage(at index: Int, to newName: String) {
        guard index >= 0 && index < pages.count else { return }
        pages[index].name = newName
    }
    
    // (Removed unused movePage method)
    
    // MARK: - Thumbnail Management
    func setThumbnail(_ thumbnailData: Data?, devicePreset: String? = nil) {
        // Explicitly clear old thumbnail data to free memory before setting new one
        self.thumbnail = nil
        // Set new thumbnail (this overwrites any previous thumbnail)
        self.thumbnail = thumbnailData
        // Store device preset for proper styling
        self.devicePreset = devicePreset
    }
    
    // MARK: - Deletion
    func delete() {
        // Mark as deleted immediately on main thread to block future saves
        self.isDeleted = true
        
        let fileURL = self.fileURL
        let name = self.name
        
        // Perform deletion on the save queue to ensure it runs AFTER any pending saves
        DesignFile.saveQueue.async {
            do {
                debugLog("🗑️ [Background] Deleting file: \(name)")
                
                // Use file coordination for iCloud files
                let isiCloudFile = fileURL.path.contains("Mobile Documents") || fileURL.path.contains("iCloud~")
                
                if isiCloudFile {
                     let coordinator = NSFileCoordinator()
                     var coordinationError: NSError?
                     var deleteError: Error?
                     
                     coordinator.coordinate(writingItemAt: fileURL, options: .forDeleting, error: &coordinationError) { (writingURL) in
                         do {
                             if FileManager.default.fileExists(atPath: writingURL.path) {
                                 try FileManager.default.removeItem(at: writingURL)
                                 debugLog("✅ [Background] Deleted from iCloud: \(name)")
                             } else {
                                 debugLog("⚠️ [Background] File already gone from iCloud: \(name)")
                             }
                         } catch {
                             debugLog("❌ [Background] Failed to delete iCloud file: \(error)")
                             deleteError = error
                         }
                     }
                     
                     if let error = coordinationError { debugLog("❌ [Background] Coordination error during delete: \(error)") }
                     if let error = deleteError { debugLog("❌ [Background] Delete error: \(error)") }
                } else {
                    // Local deletion
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                        debugLog("✅ [Background] Deleted locally: \(name)")
                    }
                }
            } catch {
                debugLog("❌ [Background] Failed to delete file: \(error)")
            }
        }
    }
    
    // MARK: - Auto-save functionality
    
    func markAsChanged() {
        hasUnsavedChanges = true
        // Debounce auto-save to prevent UI freezing on every change/switch
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.performAutoSave()
            }
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func performAutoSave() {
        // Check if there are actual changes
        if !hasUnsavedChanges {
            return
        }
        
        DispatchQueue.main.async {
            self.isAutoSaving = true
            debugLog("💾 Auto-saving design: \(self.name)")
            
            // Save the design
            self.save()
            
            // Update the saved state
            self.hasUnsavedChanges = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAutoSaving = false
            }
        }
    }

    func save() {
        // Don't save if marked for deletion
        if isDeleted {
            debugLog("🛑 Skipping save for deleted file: \(name)")
            return
        }
        
        // Update modification date immediately on main thread
        self.lastModified = Date()
        
        do {
            debugLog("💾 Saving design to \(fileURL.path)")
            
            // Encode data on calling thread (usually Main) to ensure thread safety of accessing @Published properties [Snapshotting]
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                id: id,
                name: name,
                pages: pages,
                currentPageIndex: currentPageIndex,
                lastModified: lastModified,
                thumbnail: thumbnail,
                devicePreset: devicePreset,
                selectedDevicePreset: selectedDevicePreset,
                canvasColorScheme: canvasColorScheme,
                statusBarVisible: statusBarVisible,
                statusBarTopSafeArea: statusBarTopSafeArea
            ))
            
            // Capture immutable values for background block
            let fileURL = self.fileURL
            let name = self.name
            
            // Perform file writing on background serial queue
            DesignFile.saveQueue.async {
                do {
                    // Use file coordination for iCloud files
                    let isiCloudFile = fileURL.path.contains("Mobile Documents") || fileURL.path.contains("iCloud~")
                    
                    if isiCloudFile {
                        let coordinator = NSFileCoordinator()
                        var coordinationError: NSError?
                        var writeError: Error?
                        
                        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { (writingURL) in
                            do {
                                try data.write(to: writingURL, options: .atomic)
                                debugLog("✅ [Background] Saved to iCloud: \(name)")
                                
                                // Mark for iCloud upload
                                try? (writingURL as NSURL).setResourceValue(true, forKey: .isUbiquitousItemKey)
                            } catch {
                                debugLog("❌ [Background] Failed to write iCloud file: \(error)")
                                writeError = error
                            }
                        }
                        
                        if let error = coordinationError { throw error }
                        if let error = writeError { throw error }
                        
                    } else {
                        // Local file write
                        try data.write(to: fileURL, options: .atomic)
                        debugLog("✅ [Background] Saved locally: \(name)")
                    }
                    
                    // Hide extension (safely ignore error)
                    try? FileManager.default.setAttributes([.extensionHidden: true], ofItemAtPath: fileURL.path)
                    
                } catch {
                    debugLog("❌ [Background] Failed to save design file: \(error)")
                }
            }
            
        } catch {
            debugLog("❌ Failed to encode design file: \(error)")
        }
    }
    
    
    static func load(from url: URL) -> DesignFile? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let designData = try decoder.decode(DesignFileData.self, from: data)
            
            debugLog("📂 Loading design: \(designData.name)")
            
            // Handle migration: use pages if available, otherwise create from legacy components
            let designFile: DesignFile
            if let pages = designData.pages, !pages.isEmpty {
                // New format with pages
                designFile = DesignFile(name: designData.name, pages: pages, fileURL: url, id: designData.id)
                designFile.currentPageIndex = min(designData.currentPageIndex ?? 0, pages.count - 1)
            } else {
                // Legacy format: migrate components to single page
                // Legacy files won't have an ID, so a new one is generated (acceptable for first migration)
                designFile = DesignFile(
                    name: designData.name,
                    components: designData.components ?? [],
                    fileURL: url,
                    devicePreset: designData.selectedDevicePreset ?? designData.devicePreset,
                    colorScheme: designData.canvasColorScheme
                )
            }
            designFile.lastModified = designData.lastModified ?? Date()
            designFile.thumbnail = designData.thumbnail
            designFile.devicePreset = designData.devicePreset ?? designFile.selectedDevicePreset
            designFile.selectedDevicePreset = designData.selectedDevicePreset ?? designData.devicePreset ?? designFile.selectedDevicePreset
            designFile.canvasColorScheme = designData.canvasColorScheme ?? "light"
            designFile.statusBarVisible = designData.statusBarVisible ?? true
            designFile.statusBarTopSafeArea = designData.statusBarTopSafeArea ?? true
            return designFile
        } catch {
            // Catch decoding errors specific to data corruption or schema mismatch
            debugLog("❌ Failed to decode design file '\(url.lastPathComponent)': \(error)")
            
            // Log file attributes for debugging
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                debugLog("📄 File size: \(attributes[.size] ?? 0) bytes")
                debugLog("📄 Permissions: \(attributes[.posixPermissions] ?? "unknown")")
            }

            // Check if file actually exists before creating fallback
            // If file doesn't exist, it was likely deleted, so don't resurrect it
            if !FileManager.default.fileExists(atPath: url.path) {
                debugLog("🗑️ File does not exist (likely deleted), skipping recovery: \(url.path)")
                return nil
            }
            
            // Only create fallback if file is empty (0 bytes), otherwise it might be a valid file with decoding issues
            // Creating a fallback for a non-empty file risks data loss if the user overwrites it
            let fileSize = (try? Data(contentsOf: url).count) ?? 0
            if fileSize > 0 {
                debugLog("⚠️ File is not empty (\(fileSize) bytes) but failed to decode. Skipping fallback to prevent data loss.")
                return nil
            }
            
            // Try to create a basic design file with the filename ONLY if file is 0 bytes
            let filename = url.deletingPathExtension().lastPathComponent
            return DesignFile(name: filename, components: [], fileURL: url)
        }
    }
}

// MARK: - Design File Data (for JSON encoding/decoding)
struct DesignFileData: Codable, Equatable {
    let id: UUID? // New: persisted ID
    let name: String
    let pages: [DesignPage]?  // New: array of pages
    let currentPageIndex: Int?  // New: current page index
    let components: [UIComponent]?  // Legacy: kept for migration
    let lastModified: Date? // Now optional for robustness
    let thumbnail: Data?
    let devicePreset: String?
    let selectedDevicePreset: String?
    let canvasColorScheme: String?
    let statusBarVisible: Bool?
    let statusBarTopSafeArea: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, pages, currentPageIndex, components, lastModified, thumbnail, devicePreset, selectedDevicePreset, canvasColorScheme, statusBarVisible, statusBarTopSafeArea
    }
    
    init(from decoder: Decoder) throws {
        // CASE 1: Decoded from a JSON String (common in double-encoded JSONB)
        if let container = try? decoder.singleValueContainer(),
           let jsonString = try? container.decode(String.self),
           let data = jsonString.data(using: .utf8) {
            // Check for placeholder
            if jsonString == "__exists__" || jsonString == "blank" {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Placeholder value")
            }
            
            let subDecoder = JSONDecoder()
            subDecoder.dateDecodingStrategy = .iso8601
            let decoded = try subDecoder.decode(DesignFileData.self, from: data)
            self.id = decoded.id
            self.name = decoded.name
            self.pages = decoded.pages
            self.currentPageIndex = decoded.currentPageIndex
            self.components = decoded.components
            self.lastModified = decoded.lastModified
            self.thumbnail = decoded.thumbnail
            self.devicePreset = decoded.devicePreset
            self.selectedDevicePreset = decoded.selectedDevicePreset
            self.canvasColorScheme = decoded.canvasColorScheme
            self.statusBarVisible = decoded.statusBarVisible
            self.statusBarTopSafeArea = decoded.statusBarTopSafeArea
            return
        }
        
        // CASE 2: Decoded from a Dictionary (standard format)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        pages = try container.decodeIfPresent([DesignPage].self, forKey: .pages)
        currentPageIndex = try container.decodeIfPresent(Int.self, forKey: .currentPageIndex)
        components = try container.decodeIfPresent([UIComponent].self, forKey: .components)
        
        // Lenient date decoding
        lastModified = try? container.decodeIfPresent(Date.self, forKey: .lastModified)
        
        // Robust thumbnail decoding (handles string placeholders like "blank")
        if let data = try? container.decodeIfPresent(Data.self, forKey: .thumbnail) {
            thumbnail = data
        } else {
            thumbnail = nil
        }
        
        devicePreset = try container.decodeIfPresent(String.self, forKey: .devicePreset)
        selectedDevicePreset = try container.decodeIfPresent(String.self, forKey: .selectedDevicePreset)
        canvasColorScheme = try container.decodeIfPresent(String.self, forKey: .canvasColorScheme)
        statusBarVisible = try container.decodeIfPresent(Bool.self, forKey: .statusBarVisible)
        statusBarTopSafeArea = try container.decodeIfPresent(Bool.self, forKey: .statusBarTopSafeArea)
    }
    
    // New format initializer (with pages)
    init(id: UUID? = nil, name: String, pages: [DesignPage], currentPageIndex: Int, lastModified: Date, thumbnail: Data? = nil, devicePreset: String? = nil, selectedDevicePreset: String? = nil, canvasColorScheme: String? = nil, statusBarVisible: Bool = true, statusBarTopSafeArea: Bool = true) {
        self.id = id
        self.name = name
        self.pages = pages
        self.currentPageIndex = currentPageIndex
        self.components = nil  // Don't save legacy format
        self.lastModified = lastModified
        self.thumbnail = thumbnail
        self.devicePreset = devicePreset
        self.selectedDevicePreset = selectedDevicePreset
        self.canvasColorScheme = canvasColorScheme
        self.statusBarVisible = statusBarVisible
        self.statusBarTopSafeArea = statusBarTopSafeArea
    }
    
    // Legacy format initializer (for backwards compatibility)
    init(name: String, components: [UIComponent], lastModified: Date, thumbnail: Data? = nil, devicePreset: String? = nil, selectedDevicePreset: String? = nil, canvasColorScheme: String? = nil, statusBarVisible: Bool = true, statusBarTopSafeArea: Bool = true) {
        self.id = nil
        self.name = name
        self.pages = nil
        self.currentPageIndex = nil
        self.components = components
        self.lastModified = lastModified
        self.thumbnail = thumbnail
        self.devicePreset = devicePreset
        self.selectedDevicePreset = selectedDevicePreset
        self.canvasColorScheme = canvasColorScheme
        self.statusBarVisible = statusBarVisible
        self.statusBarTopSafeArea = statusBarTopSafeArea
    }
}

// MARK: - Design Manager
@MainActor
class DesignManager: ObservableObject {
    static let shared = DesignManager()
    
    @Published var designFiles: [DesignFile] = []
    @Published var currentDesign: DesignFile?
    @Published var designsDirectory: URL
    
    // Storage status
    @Published var storageStatus: String = "Using Documents folder"
    
    // iCloud file discovery
    private var metadataQuery: NSMetadataQuery?
    private var isQueryRunning = false
    
    private init() {
        // Try iCloud Documents first, fallback to local Documents
        // Use the specific container identifier for better reliability
        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        
        debugLog("🔍 Checking iCloud availability...")
        debugLog("🔍 Container identifier: \(containerIdentifier)")
        
        let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
            .appendingPathComponent("Documents/DockUI")
        
        let finalDesignsDirectory: URL
        let finalStorageStatus: String
        
        if let ubiquityURL = ubiquityURL {
            // Ensure directory exists
            do {
                try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
            } catch {
                debugLog("⚠️ Failed to create iCloud directory: \(error)")
            }
            
            finalDesignsDirectory = ubiquityURL
            finalStorageStatus = "☁️ iCloud Drive"
            debugLog("☁️ Using iCloud container: \(ubiquityURL.path)")
        } else {
            debugLog("⚠️ iCloud container not available")
            debugLog("⚠️ This could be because:")
            debugLog("   - User is not signed in to iCloud")
            debugLog("   - iCloud Drive is not enabled")
            debugLog("   - App is not properly provisioned for iCloud")
            debugLog("   - Running in simulator without iCloud configured")
            
            let localDocuments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            finalDesignsDirectory = localDocuments.appendingPathComponent("DockUI")
            finalStorageStatus = "📁 Local Only"
            debugLog("📁 Falling back to local Documents: \(finalDesignsDirectory.path)")
        }
        
        // Initialize all stored properties
        self.designsDirectory = finalDesignsDirectory
        self.storageStatus = finalStorageStatus
        debugLog("📁 Designs Directory: \(designsDirectory.path)")
        
        createDesignsDirectoryIfNeeded()
        migrateFromUserDocuments()
        loadDesignFiles()
        
        // Start iCloud file discovery query (especially important for iOS)
        if storageStatus.contains("iCloud") {
            startICloudQuery()
        } else {
            // If iCloud wasn't available immediately, retry after a delay
            // This is common on iOS where iCloud may not be ready at launch
            retryICloudConnection()
        }
    }
    
    // MARK: - iCloud Retry
    private func retryICloudConnection() {
        #if os(iOS)
        debugLog("☁️ Scheduling iCloud retry for iOS...")
        
        // Retry iCloud connection after a delay (iCloud may not be ready immediately on iOS)
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
            let containerIdentifier = "iCloud.com.Maicol.Dockui"
            
            if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
                .appendingPathComponent("Documents/DockUI") {
                
                
                // Create directory if needed
                do {
                    try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
                } catch {
                    debugLog("⚠️ Failed to create iCloud directory: \(error)")
                }
                
                DispatchQueue.main.async {
                    self.designsDirectory = ubiquityURL
                    self.storageStatus = "☁️ iCloud Drive"
                    debugLog("☁️ Switched to iCloud: \(ubiquityURL.path)")
                    
                    // Reload design files from iCloud
                    self.loadDesignFiles()
                    
                    // Start iCloud query
                    self.startICloudQuery()
                }
            } else {
                debugLog("⚠️ iCloud still not available after retry")
                
                // Try one more time after additional delay
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0) {
                    if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
                        .appendingPathComponent("Documents/DockUI") {
                                                
                        do {
                            try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
                        } catch {
                            debugLog("⚠️ Failed to create iCloud directory: \(error)")
                        }
                        
                        DispatchQueue.main.async {
                            self.designsDirectory = ubiquityURL
                            self.storageStatus = "☁️ iCloud Drive"
                            self.loadDesignFiles()
                            self.startICloudQuery()
                        }
                    } else {
                        debugLog("⚠️ iCloud not available after multiple retries - staying local")
                    }
                }
            }
        }
        #endif
    }
    
    private func createDesignsDirectoryIfNeeded() {
        // Directory is already created in init, but ensure it exists
        if !FileManager.default.fileExists(atPath: designsDirectory.path) {
            try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
            debugLog("📁 Created designs directory: \(designsDirectory.path)")
        }
    }
    
    // MARK: - iCloud File Discovery
    private func startICloudQuery() {
        guard !isQueryRunning else {
            return
        }
                
        // Stop any existing query
        metadataQuery?.stop()
        
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        // Search for .dockui files
        query.predicate = NSPredicate(format: "%K LIKE '*.dockui'", NSMetadataItemFSNameKey)
        
        // Observe query notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleICloudQueryDidFinishGathering(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleICloudQueryDidUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )
        
        metadataQuery = query
        isQueryRunning = query.start()
    }
    
    @objc private func handleICloudQueryDidFinishGathering(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        
        query.disableUpdates()
        processICloudQueryResults(query)
        query.enableUpdates()
    }
    
    @objc private func handleICloudQueryDidUpdate(_ notification: Notification) {
        guard let query = notification.object as? NSMetadataQuery else { return }
        
        query.disableUpdates()
        processICloudQueryResults(query)
        query.enableUpdates()
    }
    
    private func processICloudQueryResults(_ query: NSMetadataQuery) {
        
        var foundNewFiles = false
        
        for item in query.results {
            guard let metadataItem = item as? NSMetadataItem,
                  let fileURL = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL else {
                continue
            }
            
            let fileName = fileURL.lastPathComponent
            
            // Check download status
            let downloadStatus = metadataItem.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
            let isDownloaded = downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent
            
            if !isDownloaded {
                do {
                    try FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
                    foundNewFiles = true
                } catch {
                    debugLog("❌ Failed to start download for \(fileName): \(error)")
                }
            } else {
                // File is downloaded, check if we already have it in our list
                let alreadyLoaded = designFiles.contains { $0.fileURL == fileURL }
                if !alreadyLoaded {
                    debugLog("☁️ Loading newly discovered iCloud file: \(fileName)")
                    if let designFile = DesignFile.load(from: fileURL) {
                        DispatchQueue.main.async {
                            // Check again on main thread to avoid duplicates
                            if !self.designFiles.contains(where: { $0.fileURL == fileURL }) {
                                self.designFiles.append(designFile)
                                self.designFiles.sort { $0.lastModified > $1.lastModified }
                            }
                        }
                    }
                }
            }
        }
        
        // If there were downloads initiated, reload after a delay
        if foundNewFiles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.loadDesignFiles()
            }
        }
    }
    
    // (Removed unused stopICloudQuery)
    
    func loadDesignFiles() {
        do {
            // Ensure directory exists before trying to read from it
            if !FileManager.default.fileExists(atPath: designsDirectory.path) {
                debugLog("📁 Directory doesn't exist, creating it...")
                try FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            // Load regular design files
            let regularFiles = fileURLs
                .filter { $0.pathExtension == "dockui" }
                .compactMap { DesignFile.load(from: $0) }
                        
            // Try to recover from backup files if regular files are corrupted
            let backupFiles = fileURLs
                .filter { $0.pathExtension == "dockui.backup" }
                .compactMap { DesignFile.load(from: $0) }
            
            // Combine and deduplicate
            var allFiles = regularFiles
            for backupFile in backupFiles {
                if !allFiles.contains(where: { $0.name == backupFile.name }) {
                    allFiles.append(backupFile)
                }
            }
            
            designFiles = allFiles.sorted { $0.lastModified > $1.lastModified }
            
            // Print each design file name
            for design in designFiles {
                debugLog("  - \(design.name) (modified: \(design.lastModified))")
            }
            
        } catch {
            debugLog("❌ Failed to load design files: \(error)")
            // Try to create the directory if it doesn't exist
            createDesignsDirectoryIfNeeded()
        }
    }
    
    /// Async version of loadDesignFiles with progress callbacks for loading screen
    /// - Parameter progressHandler: Called with (completedCount, totalCount) as files are loaded
    // (Removed unused loadDesignFilesAsync)
    
    func createNewDesign(name: String) -> DesignFile {
        // Use unique file name generation to preventing overwriting
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        
        // Use the clean name (without extension) as the display name
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        let designFile = DesignFile(name: displayName, fileURL: fileURL)
        designFile.save()
        
        designFiles.insert(designFile, at: 0)
        return designFile
    }
    
    func createDesignFromTemplate(template: DesignTemplate, name: String) -> DesignFile {
        // Generate unique file name
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        // Deep copy all components from template
        let copiedComponents = deepCopyComponents(template.components)
        
        // Create new design file with copied components
        let designFile = DesignFile(name: displayName, components: copiedComponents, fileURL: fileURL)
        
        // Apply template device preset if available
        if let preset = template.devicePreset {
            designFile.selectedDevicePreset = preset
        }
        
        // Apply template color scheme if available
        if let scheme = template.canvasColorScheme {
            designFile.canvasColorScheme = scheme
        }

        // Apply template status bar settings if available
        if let statusBarVisible = template.statusBarVisible {
            designFile.statusBarVisible = statusBarVisible
            designFile.currentPage?.statusBarVisible = statusBarVisible
        }
        if let statusBarTopSafeArea = template.statusBarTopSafeArea {
            designFile.statusBarTopSafeArea = statusBarTopSafeArea
            designFile.currentPage?.statusBarTopSafeArea = statusBarTopSafeArea
        }
        if template.statusBarVisible != nil || template.statusBarTopSafeArea != nil {
            var props = UIComponent.defaultProperties(for: .statusBar)
            for index in props.indices {
                switch props[index].key {
                case "showStatusBar":
                    if let statusBarVisible = template.statusBarVisible {
                        let prop = props[index]
                        props[index] = ComponentProperty(
                            key: prop.key,
                            displayName: prop.displayName,
                            type: prop.type,
                            value: statusBarVisible,
                            defaultValue: statusBarVisible,
                            options: prop.options
                        )
                    }
                case "topSafeArea":
                    if let statusBarTopSafeArea = template.statusBarTopSafeArea {
                        let prop = props[index]
                        props[index] = ComponentProperty(
                            key: prop.key,
                            displayName: prop.displayName,
                            type: prop.type,
                            value: statusBarTopSafeArea,
                            defaultValue: statusBarTopSafeArea,
                            options: prop.options
                        )
                    }
                default:
                    break
                }
            }
            designFile.currentPage?.statusBarComponent = UIComponent(type: .statusBar, properties: props)
        }
        
        designFile.save()
        
        designFiles.insert(designFile, at: 0)
        return designFile
    }

    func createDesignFromPost(post: DesignPost, name: String) async -> DesignFile? {
        // Ensure we have design data and convert from AnyCodable to DesignFileData
        guard let designData = post.getDesignData() else { return nil }
        
        // Generate unique file name
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        let newDesign: DesignFile
        
        // Use pages if available (new format), else legacy components
        if let pages = designData.pages, !pages.isEmpty {
            newDesign = DesignFile(name: displayName, pages: pages, fileURL: fileURL)
            newDesign.currentPageIndex = min(designData.currentPageIndex ?? 0, pages.count - 1)
        } else {
            // Legacy fallback using the preset from DesignFileData
            newDesign = DesignFile(
                name: displayName,
                components: designData.components ?? [],
                fileURL: fileURL,
                devicePreset: designData.selectedDevicePreset ?? designData.devicePreset,
                colorScheme: designData.canvasColorScheme
            )
        }
        
        // Restore meta-settings with fallbacks
        newDesign.canvasColorScheme = designData.canvasColorScheme ?? "light"
        newDesign.selectedDevicePreset = designData.selectedDevicePreset ?? designData.devicePreset ?? "iPhone 17 Pro Max"
        newDesign.devicePreset = designData.devicePreset ?? newDesign.selectedDevicePreset
        newDesign.statusBarVisible = designData.statusBarVisible ?? true
        newDesign.statusBarTopSafeArea = designData.statusBarTopSafeArea ?? true
        
        // Download any remote image assets referenced by the design JSON
        await hydrateRemoteImagesIfNeeded(in: newDesign)
        
        // Save to disk
        newDesign.save()
        
        // Add to manager
        designFiles.insert(newDesign, at: 0)
        return newDesign
    }

    private func hydrateRemoteImagesIfNeeded(in design: DesignFile) async {
        var urlCache: [String: String] = [:]
        var didUpdate = false
        
        func isRemoteURL(_ value: String) -> Bool {
            let lower = value.lowercased()
            return lower.hasPrefix("http://") || lower.hasPrefix("https://")
        }
        
        func processComponents(_ components: [UIComponent]) async {
            for component in components {
                if component.type == .image {
                    let imageName = component.getProperty(key: "imageName") as? String ?? ""
                    let imageDataString = component.getProperty(key: "imageData") as? String ?? ""
                    
                    // Prefer imageName if it is a remote URL
                    if isRemoteURL(imageName) {
                        if let cached = urlCache[imageName] {
                            await MainActor.run {
                                component.setProperty(key: "imageName", value: cached)
                                component.setProperty(key: "imageData", value: "")
                            }
                            didUpdate = true
                        } else if let filename = await downloadAndStoreRemoteImage(urlString: imageName) {
                            urlCache[imageName] = filename
                            await MainActor.run {
                                component.setProperty(key: "imageName", value: filename)
                                component.setProperty(key: "imageData", value: "")
                            }
                            didUpdate = true
                        }
                    } else if isRemoteURL(imageDataString) {
                        if let cached = urlCache[imageDataString] {
                            await MainActor.run {
                                component.setProperty(key: "imageName", value: cached)
                                component.setProperty(key: "imageData", value: "")
                            }
                            didUpdate = true
                        } else if let filename = await downloadAndStoreRemoteImage(urlString: imageDataString) {
                            urlCache[imageDataString] = filename
                            await MainActor.run {
                                component.setProperty(key: "imageName", value: filename)
                                component.setProperty(key: "imageData", value: "")
                            }
                            didUpdate = true
                        }
                    }
                }
                
                if !component.children.isEmpty {
                    await processComponents(component.children)
                }
            }
        }
        
        if !design.pages.isEmpty {
            for page in design.pages {
                await processComponents(page.components)
            }
        } else {
            await processComponents(design.components)
        }
        
        if didUpdate {
            await MainActor.run {
                design.markAsChanged()
            }
        }
    }

    private func downloadAndStoreRemoteImage(urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let hash = sha256Hex(urlString)
            let preferredFilename = "remote-\(hash).jpg"
            return ImageGalleryManager.shared.saveImage(data: data, preferredFilename: preferredFilename)
        } catch {
            debugLog("❌ Failed to download remote image: \(error)")
            return nil
        }
    }

    private func sha256Hex(_ input: String) -> String {
        let data = Data(input.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func deepCopyComponents(_ components: [UIComponent]) -> [UIComponent] {
        // Use native clone method for efficient deep copying
        // This avoids the overhead of JSON encoding/decoding
        return components.map { $0.clone() }
    }
    
    func deleteDesign(_ designFile: DesignFile) {
        // Use the thread-safe delete method which coordinates with the save queue
        designFile.delete()
        
        designFiles.removeAll { $0.id == designFile.id }
        
        if currentDesign?.id == designFile.id {
            currentDesign = nil
        }
    }
    
    #if os(iOS)
    func openDesign(_ designFile: DesignFile) {
        currentDesign = designFile
    }
    
    func closeCurrentDesign() {
        if let currentDesign = currentDesign {
            // Save before closing if needed - now handled by DesignFile but we can force it
            currentDesign.save()
        }
        currentDesign = nil
    }
    #endif
    
    // MARK: - Directory Management
    func refreshDesignFiles() {
        
        // If currently local, try to connect to iCloud again
        if storageStatus.contains("Local") {
            checkAndSwitchToICloud()
        }
        
        loadDesignFiles()
        
        // Also start/restart iCloud query if using iCloud
        if storageStatus.contains("iCloud") && !isQueryRunning {
            startICloudQuery()
        }
        
        debugLog("📊 Loaded \(designFiles.count) design files")
    }
    
    private func checkAndSwitchToICloud() {
        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        
        if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
            .appendingPathComponent("Documents/DockUI") {
            
            debugLog("☁️ iCloud now available! Switching from local storage...")
            
            // Create directory if needed
            do {
                try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
            } catch {
                debugLog("⚠️ Failed to create iCloud directory: \(error)")
            }
            
            self.designsDirectory = ubiquityURL
            self.storageStatus = "☁️ iCloud Drive"
        }
    }
    
    // MARK: - Unique Name Generation
    func generateUniqueFileName(baseName: String) -> String {
        let fileExtension = "dockui"
        var fileName = baseName
        var counter = 1
        
        // Clean the base name (remove invalid characters)
        let cleanBaseName = baseName.replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        if cleanBaseName.isEmpty {
            fileName = "Untitled"
        } else {
            fileName = cleanBaseName
        }
        
        // Check if file already exists and generate unique name
        while FileManager.default.fileExists(atPath: designsDirectory.appendingPathComponent("\(fileName).\(fileExtension)").path) {
            fileName = "\(cleanBaseName) (\(counter))"
            counter += 1
        }
        
        return "\(fileName).\(fileExtension)"
    }
    
    func renameDesign(_ design: DesignFile, to newName: String) {
        let uniqueFileName = generateUniqueFileName(baseName: newName)
        let newFileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        do {
            // Move the file to the new name
            try FileManager.default.moveItem(at: design.fileURL, to: newFileURL)
            
            // Reload the design from the new location to get the correct fileURL
            // Since fileURL is let, we need to replace the object in the array
            if let index = designFiles.firstIndex(where: { $0.id == design.id }) {
                if let reloadedDesign = DesignFile.load(from: newFileURL) {
                    // Update the name on the reloaded design
                    reloadedDesign.name = displayName
                    
                    // Save the file to persist the new name in the JSON
                    reloadedDesign.save()
                    
                    // Replace in array
                    designFiles[index] = reloadedDesign
                    
                    // Update currentDesign if this is the currently open design
                    if currentDesign?.id == design.id {
                        currentDesign = reloadedDesign
                    }
                    
                } else {
                    debugLog("⚠️ Failed to reload design after rename, but file was moved")
                }
            }
            
            debugLog("✅ Renamed design to: \(displayName)")
        } catch {
            debugLog("❌ Failed to rename design: \(error)")
        }
    }

    func handleOpenURL(_ url: URL, completion: @escaping (DesignFile?) -> Void) {
        // Ensure it's a file URL
        guard url.isFileURL else {
            completion(nil)
            return
        }
        
        // Check if the file is already in our designs directory
        // Resolve symlinks to be sure we are comparing canonical paths
        let standardURL = url.resolvingSymlinksInPath()
        let standardDesignsDir = designsDirectory.resolvingSymlinksInPath()
        
        let isInternalFile = standardURL.path.hasPrefix(standardDesignsDir.path)
        
        if isInternalFile {
            debugLog("📂 Opening existing internal file: \(url.lastPathComponent)")
            
            // It's already our file, just find or load it
            // 1. Check if already loaded in memory
            if let existingDesign = designFiles.first(where: { $0.fileURL.resolvingSymlinksInPath() == standardURL }) {
                completion(existingDesign)
                return
            }
            
            // 2. Not in memory, try to load it
            if let loadedDesign = DesignFile.load(from: url) {
                DispatchQueue.main.async {
                    // Check duplicate again in case of race
                    if let existing = self.designFiles.first(where: { $0.fileURL.path == loadedDesign.fileURL.path }) {
                        completion(existing)
                    } else {
                        self.designFiles.insert(loadedDesign, at: 0)
                        self.designFiles.sort { $0.lastModified > $1.lastModified }
                        completion(loadedDesign)
                    }
                }
            } else {
                 debugLog("❌ Failed to load existing internal file")
                 completion(nil)
            }
            
        } else {
            // It's an external file - IMPORT IT
            debugLog("📥 Importing external file: \(url.lastPathComponent)")
            
            // 1. Generate unique filename in our container
            let originalName = url.deletingPathExtension().lastPathComponent
            let uniqueFileName = generateUniqueFileName(baseName: originalName)
            let destinationURL = designsDirectory.appendingPathComponent(uniqueFileName)
            
            do {
                // 2. secure copy
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: url, to: destinationURL)
                debugLog("✅ Imported design to: \(destinationURL.path)")
                
                // 3. Load the new design
                if let importedDesign = DesignFile.load(from: destinationURL) {
                    // 4. Update UI
                    DispatchQueue.main.async {
                        self.designFiles.insert(importedDesign, at: 0)
                        self.designFiles.sort { $0.lastModified > $1.lastModified }
                        completion(importedDesign)
                    }
                } else {
                    debugLog("❌ Failed to load imported design")
                    try? FileManager.default.removeItem(at: destinationURL)
                    completion(nil)
                }
                
            } catch {
                debugLog("❌ Failed to import design: \(error)")
                completion(nil)
            }
        }
    }
    
    func migrateFromUserDocuments() {
        
        // Check if there are files in the user's Documents/DockUI folder
        let userDocumentsPath = "/Users/\(NSUserName())/Documents"
        let userDocumentsURL = URL(fileURLWithPath: userDocumentsPath)
        let userDockUIDirectory = userDocumentsURL.appendingPathComponent("DockUI")
        
        do {
            // Check if user Documents/DockUI folder exists
            if FileManager.default.fileExists(atPath: userDockUIDirectory.path) {
                let userFiles = try FileManager.default.contentsOfDirectory(at: userDockUIDirectory, includingPropertiesForKeys: nil)
                let designFiles = userFiles.filter { $0.pathExtension == "dockui" }
                
                if !designFiles.isEmpty {
                    debugLog("Found \(designFiles.count) design files in user Documents/DockUI folder")
                    
                    // Create the Documents/DockUI directory if it doesn't exist
                    try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
                    
                    // Copy files to Documents folder with unique names
                    for file in designFiles {
                        let baseName = file.deletingPathExtension().lastPathComponent
                        let uniqueFileName = generateUniqueFileName(baseName: baseName)
                        let destination = designsDirectory.appendingPathComponent(uniqueFileName)
                        
                        do {
                            try FileManager.default.copyItem(at: file, to: destination)
                        } catch {
                            debugLog("❌ Failed to copy \(file.lastPathComponent): \(error)")
                        }
                    }
                    
                    // Refresh the design files
                    refreshDesignFiles()
                    debugLog("Migration completed. Found files in Documents folder.")
                } else {
                    debugLog("No design files found in user Documents/DockUI folder")
                }
            } else {
                debugLog("No user Documents/DockUI folder found")
            }
        } catch {
            debugLog("Error accessing user Documents folder: \(error)")
        }
    }
    
}

class ImageGalleryManager: ObservableObject {
    static let shared = ImageGalleryManager()
    
    private let fileManager = FileManager.default
    private let galleryFolderName = "DesignImages"
    
    private var imagesDirectory: URL? {
        // Try iCloud first
        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        if let ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier) {
            return ubiquityURL.appendingPathComponent("Documents/\(galleryFolderName)")
        }
        
        // Fallback to local
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(galleryFolderName)
    }
    
    // Bundled assets that should appear in the gallery
    private let bundledAssets: [String] = []
    
    init() {
        createGalleryDirectoryIfNeeded()
    }
    
    private func createGalleryDirectoryIfNeeded() {
        guard let imagesDirectory = imagesDirectory else { return }
        
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true, attributes: nil)
                debugLog("✅ ImageGalleryManager: Created gallery directory")
            } catch {
                debugLog("❌ ImageGalleryManager: Failed to create gallery directory: \(error)")
            }
        }
    }
    
    func saveImage(data: Data, originalFilename: String? = nil) -> String? {
        guard let imagesDirectory = imagesDirectory else { return nil }
        
        // Optimize the image data (Resize + Compress)
        guard let optimizedData = ImageGalleryManager.compressAndResizeImage(data: data) else {
            debugLog("ImageGalleryManager: Failed to optimize image, falling back to original data")
            return saveRawData(data: data, originalFilename: originalFilename)
        }
        
        // Force JPG extension since we are converting to JPEG
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        do {
            try optimizedData.write(to: fileURL)
            debugLog("ImageGalleryManager: Saved optimized image")
            return filename
        } catch {
            debugLog("ImageGalleryManager: Failed to save image: \(error)")
            // Fallback to raw if optimized write fails (unlikely, but safe)
            return saveRawData(data: data, originalFilename: originalFilename)
        }
    }

    func saveImage(data: Data, preferredFilename: String) -> String? {
        guard let imagesDirectory = imagesDirectory else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent(preferredFilename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            return preferredFilename
        }
        
        guard let optimizedData = ImageGalleryManager.compressAndResizeImage(data: data) else {
            debugLog("ImageGalleryManager: Failed to optimize image, falling back to original data")
            return saveRawData(data: data, originalFilename: preferredFilename)
        }
        
        do {
            try optimizedData.write(to: fileURL)
            debugLog("ImageGalleryManager: Saved optimized image (preferred filename)")
            return preferredFilename
        } catch {
            debugLog("ImageGalleryManager: Failed to save image: \(error)")
            return saveRawData(data: data, originalFilename: preferredFilename)
        }
    }
    
    private func saveRawData(data: Data, originalFilename: String?) -> String? {
        guard let imagesDirectory = imagesDirectory else { return nil }
        let ext = (originalFilename as NSString?)?.pathExtension ?? "jpg"
        let fileExtension = ext.isEmpty ? "jpg" : ext
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return filename
        } catch {
            return nil
        }
    }
    
    // MARK: - Compression Helpers
    
    static func compressAndResizeImage(data: Data) -> Data? {
        #if os(macOS)
            guard let image = NSImage(data: data) else { return nil }
            return optimizeImageMacOS(image)
        #else
            guard let image = UIImage(data: data) else { return nil }
            return optimizeImageiOS(image)
        #endif
    }
    
    #if os(macOS)
    private static func optimizeImageMacOS(_ image: NSImage) -> Data? {
        var newSize = image.size
        let maxDimension: CGFloat = 512
        
        // Resize if needed
        if newSize.width > maxDimension || newSize.height > maxDimension {
            let aspectRatio = newSize.width / newSize.height
            if newSize.width > newSize.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        }
        
        // Create new image with target size
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        // Draw ensuring high quality interpolation downscaling if possible, but default is usually fine
        image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        
        guard let tiffRepresentation = newImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        
        // Compress to JPEG 0.3 (Aggressive)
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.3])
    }
    #else
    private static func optimizeImageiOS(_ image: UIImage) -> Data? {
        var newSize = image.size
        let maxDimension: CGFloat = 512
        
        // Resize if needed
        if newSize.width > maxDimension || newSize.height > maxDimension {
            let aspectRatio = newSize.width / newSize.height
            if newSize.width > newSize.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        }
        
        // Create an opaque renderer format to avoid "opaque image with alpha" warnings
        // This prevents unnecessary memory usage (double memory when decoding!)
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = true  // ← KEY FIX: Explicitly set opaque to true for images without transparency
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { context in
            // Fill with white background to ensure opacity
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: newSize))
            // Draw the image on top
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        // Compress to JPEG 0.3 (Aggressive)
        return resizedImage.jpegData(compressionQuality: 0.3)
    }
    #endif
    
    // MARK: - Load
    
    func loadImage(filename: String) -> PlatformImage? {
        if bundledAssets.contains(filename) {
            debugLog("🎨 Loading bundled asset: \(filename)")
            
            #if os(macOS)
            if let image = NSImage(named: filename) {
                debugLog("✅ Successfully loaded bundled asset from default bundle: \(filename)")
                return image
            }
            
            // Fallback: Search all bundles
            for bundle in Bundle.allBundles {
                if let image = bundle.image(forResource: filename) {
                    debugLog("✅ Found bundled asset in bundle \(bundle.bundleIdentifier ?? "unknown"): \(filename)")
                    return image
                }
            }
            #else
            if let image = UIImage(named: filename) {
                debugLog("✅ Successfully loaded bundled asset from default bundle: \(filename)")
                return image
            }
            
            // Fallback: Search all bundles
            for bundle in Bundle.allBundles {
                if let image = UIImage(named: filename, in: bundle, compatibleWith: nil) {
                    debugLog("✅ Found bundled asset in bundle \(bundle.bundleIdentifier ?? "unknown"): \(filename)")
                    return image
                }
            }
            #endif
            
            debugLog("❌ Failed to load bundled asset: \(filename)")
            return nil
        }
        
        // 2. Check Local Directory
        guard let imagesDirectory = imagesDirectory else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        // Ensure file exists
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        if let data = try? Data(contentsOf: fileURL) {
            #if os(macOS)
            return NSImage(data: data)
            #else
            return UIImage(data: data)
            #endif
        }
        return nil
    }
    
    func getImageUrl(filename: String) -> URL? {
        guard let imagesDirectory = imagesDirectory else { return nil }
        return imagesDirectory.appendingPathComponent(filename)
    }
    
    func imageExists(filename: String) -> Bool {
        guard let imagesDirectory = imagesDirectory else { return false }
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Get all image filenames in the gallery, sorted by creation date (newest first)
        func getAllImageFilenames() -> [String] {
            var allImages: [String] = []
            
            // 1. Add Bundled Assets first (or last, depending on preference. Let's add them at the end or mix them?)
            // We'll add them to the list.
            
            // 2. Add Local Images
            if let imagesDirectory = imagesDirectory {
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
                    
                    // Filter only images (basic extension check)
                    let imageExtensions = ["jpg", "jpeg", "png", "heic", "webp"]
                    let localImages = fileURLs.filter { url in
                        imageExtensions.contains(url.pathExtension.lowercased())
                    }
                    
                    // Sort by creation date descending
                    let sortedLocalImages = localImages.sorted { url1, url2 in
                        let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                        let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                        return date1 > date2
                    }
                    
                    allImages.append(contentsOf: sortedLocalImages.map { $0.lastPathComponent })
                } catch {
                    debugLog("❌ ImageGalleryManager: Failed to list images: \(error)")
                }
            }
            
            // Append bundled assets at the end (so newest user images are first)
            allImages.append(contentsOf: bundledAssets)
            
            return allImages
        }
            
    func deleteImage(filename: String) {
        // Prevent deletion of bundled assets
        if bundledAssets.contains(filename) {
            debugLog("⚠️ Cannot delete bundled asset: \(filename)")
            return
        }
        
        guard let imagesDirectory = imagesDirectory else { return }
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            debugLog("🗑️ ImageGalleryManager: Deleted \(filename)")
        }
    }
}
