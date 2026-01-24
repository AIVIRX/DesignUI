//
//  DesignFile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation
#if os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#else
import UIKit
public typealias PlatformImage = UIImage
#endif

// MARK: - Notifications
extension Notification.Name {
    static let imageDownloadsCompleted = Notification.Name("imageDownloadsCompleted")
}

// MARK: - Design File Model
class DesignFile: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var pages: [DesignPage]
    @Published var currentPageIndex: Int = 0
    @Published var lastModified: Date
    @Published var thumbnail: Data?
    @Published var devicePreset: String? // Store device preset name for thumbnail styling
    @Published var selectedDevicePreset: String? // Store selected device preset for canvas
    @Published var canvasColorScheme: String? // Store canvas color scheme (light/dark)
    @Published var statusBarVisible: Bool = true // Store status bar visibility
    @Published var isDeleted: Bool = false // Flag to prevent saving after deletion
    let fileURL: URL
    
    // Serial queue for saving operations to prevent race conditions and UI blocking
    private static let saveQueue = DispatchQueue(label: "com.designui.saveQueue", qos: .background)
    
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
    
    init(name: String, components: [UIComponent] = [], fileURL: URL) {
        self.name = name
        // Create default page with provided components
        self.pages = [DesignPage(name: "Page 1", components: components, devicePreset: "iPhone 17 Pro Max", colorScheme: "light")]
        self.canvasColorScheme = "light"
        self.selectedDevicePreset = "iPhone 17 Pro Max"
        self.lastModified = Date()
        self.fileURL = fileURL
    }
    
    init(name: String, pages: [DesignPage], fileURL: URL) {
        self.name = name
        self.pages = pages.isEmpty ? [DesignPage(name: "Page 1")] : pages
        self.canvasColorScheme = "light"
        self.selectedDevicePreset = "iPhone 17 Pro Max"
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
    
    /// Delete a page at index (cannot delete the last page)
    func deletePage(at index: Int) -> Bool {
        guard pages.count > 1, index >= 0 && index < pages.count else { return false }
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
    
    /// Move a page from one index to another
    func movePage(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0 && sourceIndex < pages.count,
              destinationIndex >= 0 && destinationIndex < pages.count else { return }
        
        let page = pages.remove(at: sourceIndex)
        pages.insert(page, at: destinationIndex)
        
        // Update current page index if the current page was moved
        if currentPageIndex == sourceIndex {
            currentPageIndex = destinationIndex
        } else if sourceIndex < currentPageIndex && destinationIndex >= currentPageIndex {
            currentPageIndex -= 1
        } else if sourceIndex > currentPageIndex && destinationIndex <= currentPageIndex {
            currentPageIndex += 1
        }
    }
    
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
                print("🗑️ [Background] Deleting file: \(name)")
                
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
                                 print("✅ [Background] Deleted from iCloud: \(name)")
                             } else {
                                 print("⚠️ [Background] File already gone from iCloud: \(name)")
                             }
                         } catch {
                             print("❌ [Background] Failed to delete iCloud file: \(error)")
                             deleteError = error
                         }
                     }
                     
                     if let error = coordinationError { print("❌ [Background] Coordination error during delete: \(error)") }
                     if let error = deleteError { print("❌ [Background] Delete error: \(error)") }
                } else {
                    // Local deletion
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        try FileManager.default.removeItem(at: fileURL)
                        print("✅ [Background] Deleted locally: \(name)")
                    }
                }
            } catch {
                print("❌ [Background] Failed to delete file: \(error)")
            }
        }
    }
    
    // MARK: - Auto-save functionality
    func save() {
        // Don't save if marked for deletion
        if isDeleted {
            print("🛑 Skipping save for deleted file: \(name)")
            return
        }
        
        // Update modification date immediately on main thread
        self.lastModified = Date()
        
        do {
            print("💾 Saving design to \(fileURL.path)")
            
            // Encode data on calling thread (usually Main) to ensure thread safety of accessing @Published properties [Snapshotting]
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                name: name,
                pages: pages,
                currentPageIndex: currentPageIndex,
                lastModified: lastModified,
                thumbnail: thumbnail,
                devicePreset: devicePreset,
                selectedDevicePreset: selectedDevicePreset,
                canvasColorScheme: canvasColorScheme,
                statusBarVisible: statusBarVisible
            ))
            
            // Capture immutable values for background block
            let fileURL = self.fileURL
            let name = self.name
            
            // Perform file writing on background serial queue
            DesignFile.saveQueue.async {
                // Check deletion flag again in background (though order should handle it)
                // We can't access self.isDeleted safely here if we don't capture it or trust the queue order.
                // Since we rely on queue order (save queued -> delete queued), the deletion will happen last.
                // However, checking a flag if we could would be nice, but accessing self across threads is tricky.
                // We'll rely on the main thread check above and the queue ordering.
                
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
                                print("✅ [Background] Saved to iCloud: \(name)")
                                
                                // Mark for iCloud upload
                                try? (writingURL as NSURL).setResourceValue(true, forKey: .isUbiquitousItemKey)
                            } catch {
                                print("❌ [Background] Failed to write iCloud file: \(error)")
                                writeError = error
                            }
                        }
                        
                        if let error = coordinationError { throw error }
                        if let error = writeError { throw error }
                        
                    } else {
                        // Local file write
                        try data.write(to: fileURL, options: .atomic)
                        print("✅ [Background] Saved locally: \(name)")
                    }
                    
                    // Hide extension (safely ignore error)
                    try? FileManager.default.setAttributes([.extensionHidden: true], ofItemAtPath: fileURL.path)
                    
                } catch {
                    print("❌ [Background] Failed to save design file: \(error)")
                }
            }
            
        } catch {
            print("❌ Failed to encode design file: \(error)")
        }
    }
    
    
    static func load(from url: URL) -> DesignFile? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let designData = try decoder.decode(DesignFileData.self, from: data)
            
            print("📂 Loading design: \(designData.name)")
            
            // Handle migration: use pages if available, otherwise create from legacy components
            let designFile: DesignFile
            if let pages = designData.pages, !pages.isEmpty {
                // New format with pages
                designFile = DesignFile(name: designData.name, pages: pages, fileURL: url)
                designFile.currentPageIndex = min(designData.currentPageIndex ?? 0, pages.count - 1)
            } else {
                // Legacy format: migrate components to single page
                designFile = DesignFile(name: designData.name, components: designData.components ?? [], fileURL: url)
            }
            designFile.lastModified = designData.lastModified
            designFile.thumbnail = designData.thumbnail
            designFile.devicePreset = designData.devicePreset
            designFile.selectedDevicePreset = designData.selectedDevicePreset
            designFile.canvasColorScheme = designData.canvasColorScheme ?? "light"
            designFile.statusBarVisible = designData.statusBarVisible ?? true
            return designFile
        } catch {
            // Catch decoding errors specific to data corruption or schema mismatch
            print("❌ Failed to decode design file '\(url.lastPathComponent)': \(error)")
            
            // Log file attributes for debugging
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                print("📄 File size: \(attributes[.size] ?? 0) bytes")
                print("📄 Permissions: \(attributes[.posixPermissions] ?? "unknown")")
            }

            // Check if file actually exists before creating fallback
            // If file doesn't exist, it was likely deleted, so don't resurrect it
            if !FileManager.default.fileExists(atPath: url.path) {
                print("🗑️ File does not exist (likely deleted), skipping recovery: \(url.path)")
                return nil
            }
            
            // Only create fallback if file is empty (0 bytes), otherwise it might be a valid file with decoding issues
            // Creating a fallback for a non-empty file risks data loss if the user overwrites it
            let fileSize = (try? Data(contentsOf: url).count) ?? 0
            if fileSize > 0 {
                print("⚠️ File is not empty (\(fileSize) bytes) but failed to decode. Skipping fallback to prevent data loss.")
                return nil
            }
            
            // Try to create a basic design file with the filename ONLY if file is 0 bytes
            let filename = url.deletingPathExtension().lastPathComponent
            return DesignFile(name: filename, components: [], fileURL: url)
        }
    }
}

// MARK: - Design File Data (for JSON encoding/decoding)
struct DesignFileData: Codable {
    let name: String
    let pages: [DesignPage]?  // New: array of pages
    let currentPageIndex: Int?  // New: current page index
    let components: [UIComponent]?  // Legacy: kept for migration
    let lastModified: Date
    let thumbnail: Data?
    let devicePreset: String?
    let selectedDevicePreset: String?
    let canvasColorScheme: String?
    let statusBarVisible: Bool?
    
    // New format initializer (with pages)
    init(name: String, pages: [DesignPage], currentPageIndex: Int, lastModified: Date, thumbnail: Data? = nil, devicePreset: String? = nil, selectedDevicePreset: String? = nil, canvasColorScheme: String? = nil, statusBarVisible: Bool = true) {
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
    }
    
    // Legacy format initializer (for backwards compatibility when decoding)
    init(name: String, components: [UIComponent], lastModified: Date, thumbnail: Data? = nil, devicePreset: String? = nil, selectedDevicePreset: String? = nil, canvasColorScheme: String? = nil, statusBarVisible: Bool = true) {
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
    }
}

// MARK: - Design Manager
@MainActor
class DesignManager: ObservableObject {
    static let shared = DesignManager()
    
    @Published var designFiles: [DesignFile] = []
    @Published var currentDesign: DesignFile?
    @Published var isAutoSaving = false
    @Published var designsDirectory: URL
    @Published var showingDirectoryPicker = false
    
    // Storage status
    @Published var storageStatus: String = "Using Documents folder"
    
    private let documentsDirectory: URL
    private var autoSaveTimer: Timer?
    private var lastSavedComponents: [UIComponent] = []
    private var hasUnsavedChanges = false
    
    // iCloud file discovery
    private var metadataQuery: NSMetadataQuery?
    private var isQueryRunning = false
    
    private init() {
        // Try iCloud Documents first, fallback to local Documents
        // Use the specific container identifier for better reliability
        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        
        print("🔍 Checking iCloud availability...")
        print("🔍 Container identifier: \(containerIdentifier)")
        
        let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
            .appendingPathComponent("Documents/DockUI")
        
        let finalDesignsDirectory: URL
        let finalStorageStatus: String
        
        if let ubiquityURL = ubiquityURL {
            // Ensure directory exists
            do {
                try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
            } catch {
                print("⚠️ Failed to create iCloud directory: \(error)")
            }
            
            finalDesignsDirectory = ubiquityURL
            finalStorageStatus = "☁️ iCloud Drive"
            print("☁️ Using iCloud container: \(ubiquityURL.path)")
        } else {
            print("⚠️ iCloud container not available")
            print("⚠️ This could be because:")
            print("   - User is not signed in to iCloud")
            print("   - iCloud Drive is not enabled")
            print("   - App is not properly provisioned for iCloud")
            print("   - Running in simulator without iCloud configured")
            
            let localDocuments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            finalDesignsDirectory = localDocuments.appendingPathComponent("DockUI")
            finalStorageStatus = "📁 Local Only"
            print("📁 Falling back to local Documents: \(finalDesignsDirectory.path)")
        }
        
        // Initialize all stored properties
        self.designsDirectory = finalDesignsDirectory
        self.storageStatus = finalStorageStatus
        self.documentsDirectory = finalDesignsDirectory.deletingLastPathComponent()
        
        print("📁 Designs Directory: \(designsDirectory.path)")
        
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
        print("☁️ Scheduling iCloud retry for iOS...")
        
        // Retry iCloud connection after a delay (iCloud may not be ready immediately on iOS)
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
            let containerIdentifier = "iCloud.com.Maicol.Dockui"
            
            if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
                .appendingPathComponent("Documents/DockUI") {
                
                
                // Create directory if needed
                do {
                    try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
                } catch {
                    print("⚠️ Failed to create iCloud directory: \(error)")
                }
                
                DispatchQueue.main.async {
                    self.designsDirectory = ubiquityURL
                    self.storageStatus = "☁️ iCloud Drive"
                    print("☁️ Switched to iCloud: \(ubiquityURL.path)")
                    
                    // Reload design files from iCloud
                    self.loadDesignFiles()
                    
                    // Start iCloud query
                    self.startICloudQuery()
                }
            } else {
                print("⚠️ iCloud still not available after retry")
                
                // Try one more time after additional delay
                DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 3.0) {
                    if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
                        .appendingPathComponent("Documents/DockUI") {
                                                
                        do {
                            try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
                        } catch {
                            print("⚠️ Failed to create iCloud directory: \(error)")
                        }
                        
                        DispatchQueue.main.async {
                            self.designsDirectory = ubiquityURL
                            self.storageStatus = "☁️ iCloud Drive"
                            self.loadDesignFiles()
                            self.startICloudQuery()
                        }
                    } else {
                        print("⚠️ iCloud not available after multiple retries - staying local")
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
            print("📁 Created designs directory: \(designsDirectory.path)")
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
                    print("❌ Failed to start download for \(fileName): \(error)")
                }
            } else {
                // File is downloaded, check if we already have it in our list
                let alreadyLoaded = designFiles.contains { $0.fileURL == fileURL }
                if !alreadyLoaded {
                    print("☁️ Loading newly discovered iCloud file: \(fileName)")
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
    
    func stopICloudQuery() {
        metadataQuery?.stop()
        metadataQuery = nil
        isQueryRunning = false
    }
    
    func loadDesignFiles() {
        do {
            // Ensure directory exists before trying to read from it
            if !FileManager.default.fileExists(atPath: designsDirectory.path) {
                print("📁 Directory doesn't exist, creating it...")
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
                print("  - \(design.name) (modified: \(design.lastModified))")
            }
            
        } catch {
            print("❌ Failed to load design files: \(error)")
            // Try to create the directory if it doesn't exist
            createDesignsDirectoryIfNeeded()
        }
    }
    
    /// Async version of loadDesignFiles with progress callbacks for loading screen
    /// - Parameter progressHandler: Called with (completedCount, totalCount) as files are loaded
    func loadDesignFilesAsync(progressHandler: @escaping (Int, Int) -> Void) async {
        await withCheckedContinuation { continuation in
            let designsDir = self.designsDirectory
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                do {
                    // Ensure directory exists
                    if !FileManager.default.fileExists(atPath: designsDir.path) {
                        try FileManager.default.createDirectory(at: designsDir, withIntermediateDirectories: true)
                    }
                    
                    let fileURLs = try FileManager.default.contentsOfDirectory(
                        at: designsDir,
                        includingPropertiesForKeys: [.contentModificationDateKey]
                    )
                    
                    // Filter to only .dockui files
                    let designFileURLs = fileURLs.filter { $0.pathExtension == "dockui" }
                    let backupFileURLs = fileURLs.filter { $0.pathExtension == "dockui.backup" }
                    let totalFiles = designFileURLs.count + backupFileURLs.count
                    
                    // Report initial progress
                    DispatchQueue.main.async {
                        progressHandler(0, max(1, totalFiles))
                    }
                    
                    var loadedFiles: [DesignFile] = []
                    var loadedCount = 0
                    
                    // Load regular design files
                    for (index, url) in designFileURLs.enumerated() {
                        if let designFile = DesignFile.load(from: url) {
                            loadedFiles.append(designFile)
                        }
                        loadedCount = index + 1
                        
                        // Report progress
                        DispatchQueue.main.async {
                            progressHandler(loadedCount, totalFiles)
                        }
                        
                        // Small delay to make progress visible for fast loads
                        if totalFiles <= 5 {
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                    }
                    
                    // Load backup files
                    for (index, url) in backupFileURLs.enumerated() {
                        if let backupFile = DesignFile.load(from: url) {
                            // Only add if not already loaded
                            if !loadedFiles.contains(where: { $0.name == backupFile.name }) {
                                loadedFiles.append(backupFile)
                            }
                        }
                        loadedCount = designFileURLs.count + index + 1
                        
                        DispatchQueue.main.async {
                            progressHandler(loadedCount, totalFiles)
                        }
                    }
                    
                    // Sort by modification date and update on main thread
                    let sortedFiles = loadedFiles.sorted { $0.lastModified > $1.lastModified }
                    
                    DispatchQueue.main.async {
                        guard let self = self else { return }
                        self.designFiles = sortedFiles
                        print("📁 [Async] Loaded \(sortedFiles.count) design files total")
                        progressHandler(totalFiles, totalFiles)
                        continuation.resume()
                    }
                    
                } catch {
                    print("❌ [Async] Failed to load design files: \(error)")
                    
                    // Try to create directory if needed (using local var)
                    try? FileManager.default.createDirectory(at: designsDir, withIntermediateDirectories: true)
                    
                    DispatchQueue.main.async {
                        progressHandler(1, 1)
                        continuation.resume()
                    }
                }
            }
        }
        
        // Start iCloud query after initial load
        if storageStatus.contains("iCloud") && !isQueryRunning {
            startICloudQuery()
        }
    }
    
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
        
        designFile.save()
        
        designFiles.insert(designFile, at: 0)
        return designFile
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
    
    func openDesign(_ designFile: DesignFile) {
        // Stop any existing auto-save timer
        stopAutoSave()
        
        currentDesign = designFile
        // Store the initial state for change detection
        lastSavedComponents = designFile.components
        hasUnsavedChanges = false
    }
    
    func closeCurrentDesign() {
        // Save any unsaved changes before closing
        if hasUnsavedChanges {
            performAutoSave()
        }
        stopAutoSave()
        currentDesign = nil
        lastSavedComponents = []
        hasUnsavedChanges = false
    }
    
    // MARK: - Change Detection and Auto-save
    func markAsChanged() {
        hasUnsavedChanges = true
        // Debounce auto-save to prevent UI freezing on every change/switch
        // This stops the main thread from being blocked by JSON encoding immediately after value changes
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
        guard let currentDesign = currentDesign else { 
            print("⚠️ No current design to auto-save")
            return 
        }
        
        // Check if there are actual changes
        if !hasUnsavedChanges {
            print("ℹ️ No changes to save")
            return
        }
        
        DispatchQueue.main.async {
            self.isAutoSaving = true
            print("💾 Auto-saving design: \(currentDesign.name)")
            
            // Save the design
            currentDesign.save()
            
            // Update the saved state
            self.lastSavedComponents = currentDesign.components
            self.hasUnsavedChanges = false
            
            // Update the design files list to reflect the new lastModified date
            if let index = self.designFiles.firstIndex(where: { $0.id == currentDesign.id }) {
                self.designFiles[index] = currentDesign
                self.designFiles.sort { $0.lastModified > $1.lastModified }
                print("✅ Design list updated: \(currentDesign.name)")
            } else {
                print("⚠️ Design not found in list: \(currentDesign.name)")
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAutoSaving = false
            }
        }
    }
    
    // Manual save method for immediate saves
    func saveCurrentDesign() {
        guard currentDesign != nil else { return }
        performAutoSave()
    }
    
    // MARK: - Directory Management
    func selectDesignsDirectory() {
        showingDirectoryPicker = true
    }
    
    func setDesignsDirectory(_ url: URL) {
        designsDirectory = url
        UserDefaults.standard.set(url.absoluteString, forKey: "designsDirectory")
        print("📁 Designs directory changed to: \(url.path)")
        
        // Reload design files from new directory
        loadDesignFiles()
    }
    
    func resetToDefaultDirectory() {
        let defaultDirectory = documentsDirectory.appendingPathComponent("DockUI")
        setDesignsDirectory(defaultDirectory)
    }
    
    func presentDocumentPicker() {
        // This would present a document picker for importing designs
        // For now, just print a message
        print("📄 Document picker requested")
    }
    
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
        
        print("📊 Loaded \(designFiles.count) design files")
    }
    
    private func checkAndSwitchToICloud() {
        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        
        if let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
            .appendingPathComponent("Documents/DockUI") {
            
            print("☁️ iCloud now available! Switching from local storage...")
            
            // Create directory if needed
            do {
                try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
            } catch {
                print("⚠️ Failed to create iCloud directory: \(error)")
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
    
    func createUniqueDesignFile(name: String) -> DesignFile {
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        print("📄 Creating unique design file: \(uniqueFileName)")
        return DesignFile(name: displayName, fileURL: fileURL)
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
                    print("⚠️ Failed to reload design after rename, but file was moved")
                }
            }
            
            print("✅ Renamed design to: \(displayName)")
        } catch {
            print("❌ Failed to rename design: \(error)")
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
                    print("Found \(designFiles.count) design files in user Documents/DockUI folder")
                    
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
                            print("❌ Failed to copy \(file.lastPathComponent): \(error)")
                        }
                    }
                    
                    // Refresh the design files
                    refreshDesignFiles()
                    print("Migration completed. Found files in Documents folder.")
                } else {
                    print("No design files found in user Documents/DockUI folder")
                }
            } else {
                print("No user Documents/DockUI folder found")
            }
        } catch {
            print("Error accessing user Documents folder: \(error)")
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
                print("✅ ImageGalleryManager: Created gallery directory")
            } catch {
                print("❌ ImageGalleryManager: Failed to create gallery directory: \(error)")
            }
        }
    }
    
    func saveImage(data: Data, originalFilename: String? = nil) -> String? {
        guard let imagesDirectory = imagesDirectory else { return nil }
        
        // Optimize the image data (Resize + Compress)
        guard let optimizedData = ImageGalleryManager.compressAndResizeImage(data: data) else {
            print("ImageGalleryManager: Failed to optimize image, falling back to original data")
            return saveRawData(data: data, originalFilename: originalFilename)
        }
        
        // Force JPG extension since we are converting to JPEG
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        do {
            try optimizedData.write(to: fileURL)
            print("ImageGalleryManager: Saved optimized image")
            return filename
        } catch {
            print("ImageGalleryManager: Failed to save image: \(error)")
            // Fallback to raw if optimized write fails (unlikely, but safe)
            return saveRawData(data: data, originalFilename: originalFilename)
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
            print("🎨 Loading bundled asset: \(filename)")
            
            #if os(macOS)
            if let image = NSImage(named: filename) {
                print("✅ Successfully loaded bundled asset from default bundle: \(filename)")
                return image
            }
            
            // Fallback: Search all bundles
            for bundle in Bundle.allBundles {
                if let image = bundle.image(forResource: filename) {
                    print("✅ Found bundled asset in bundle \(bundle.bundleIdentifier ?? "unknown"): \(filename)")
                    return image
                }
            }
            #else
            if let image = UIImage(named: filename) {
                print("✅ Successfully loaded bundled asset from default bundle: \(filename)")
                return image
            }
            
            // Fallback: Search all bundles
            for bundle in Bundle.allBundles {
                if let image = UIImage(named: filename, in: bundle, compatibleWith: nil) {
                    print("✅ Found bundled asset in bundle \(bundle.bundleIdentifier ?? "unknown"): \(filename)")
                    return image
                }
            }
            #endif
            
            print("❌ Failed to load bundled asset: \(filename)")
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
                    print("❌ ImageGalleryManager: Failed to list images: \(error)")
                }
            }
            
            // Append bundled assets at the end (so newest user images are first)
            allImages.append(contentsOf: bundledAssets)
            
            return allImages
        }
            
    func deleteImage(filename: String) {
        // Prevent deletion of bundled assets
        if bundledAssets.contains(filename) {
            print("⚠️ Cannot delete bundled asset: \(filename)")
            return
        }
        
        guard let imagesDirectory = imagesDirectory else { return }
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            print("🗑️ ImageGalleryManager: Deleted \(filename)")
        }
    }
}
