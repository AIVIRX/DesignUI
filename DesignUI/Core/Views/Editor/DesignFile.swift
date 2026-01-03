//
//  DesignFile.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import Foundation

// MARK: - Design File Model
class DesignFile: ObservableObject, Identifiable {
    let id = UUID()
    @Published var name: String
    @Published var components: [UIComponent]
    @Published var lastModified: Date
    @Published var thumbnail: Data?
    @Published var devicePreset: String? // Store device preset name for thumbnail styling
    @Published var selectedDevicePreset: String? // Store selected device preset for canvas
    @Published var canvasColorScheme: String? // Store canvas color scheme (light/dark)
    @Published var statusBarVisible: Bool = true // Store status bar visibility
    let fileURL: URL
    
    // Serial queue for saving operations to prevent race conditions and UI blocking
    private static let saveQueue = DispatchQueue(label: "com.designui.saveQueue", qos: .background)
    
    init(name: String, components: [UIComponent] = [], fileURL: URL) {
        self.name = name
        self.components = components
        self.lastModified = Date()
        self.fileURL = fileURL
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
    
    // MARK: - Auto-save functionality
    func save() {
        // Update modification date immediately on main thread
        self.lastModified = Date()
        
        do {
            print("💾 Saving design: \(name) to \(fileURL.path)")
            
            // Encode data on calling thread (usually Main) to ensure thread safety of accessing @Published properties [Snapshotting]
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                name: name,
                components: components,
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
                do {
                    print("💾 [Background] Starting write for: \(name) (\(data.count) bytes)")
                    
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
            print("📂 Components count: \(designData.components.count)")
            
            // Debug: Print loaded component properties and modifiers
            for (index, component) in designData.components.enumerated() {
                print("📂 Component \(index): \(component.type.rawValue) with \(component.properties.count) properties and \(component.modifiers.count) modifiers")
                for property in component.properties {
                    print("📂   - Property \(property.key): \(property.value) (type: \(property.type))")
                }
                for (modIndex, modifier) in component.modifiers.enumerated() {
                    print("📂   - Modifier \(modIndex): \(modifier.type.rawValue) with properties: \(modifier.properties)")
                }
            }
            
            let designFile = DesignFile(name: designData.name, components: designData.components, fileURL: url)
            designFile.lastModified = designData.lastModified
            designFile.thumbnail = designData.thumbnail
            designFile.devicePreset = designData.devicePreset
            designFile.selectedDevicePreset = designData.selectedDevicePreset
            designFile.canvasColorScheme = designData.canvasColorScheme
            designFile.statusBarVisible = designData.statusBarVisible ?? true
            return designFile
        } catch {
            print("❌ Failed to load design file: \(error)")
            print("📄 File path: \(url.path)")
            let fileSize = (try? Data(contentsOf: url).count) ?? 0
            print("📄 File size: \(fileSize) bytes")
            
            // Try to create a basic design file with the filename
            let filename = url.deletingPathExtension().lastPathComponent
            print("🔄 Creating fallback design file: \(filename)")
            return DesignFile(name: filename, components: [], fileURL: url)
        }
    }
}

// MARK: - Design File Data (for JSON encoding/decoding)
struct DesignFileData: Codable {
    let name: String
    let components: [UIComponent]
    let lastModified: Date
    let thumbnail: Data?
    let devicePreset: String?
    let selectedDevicePreset: String?
    let canvasColorScheme: String?
    let statusBarVisible: Bool?
    
    init(name: String, components: [UIComponent], lastModified: Date, thumbnail: Data? = nil, devicePreset: String? = nil, selectedDevicePreset: String? = nil, canvasColorScheme: String? = nil, statusBarVisible: Bool = true) {
        self.name = name
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
        
        // Check if iCloud is available
        if let ubiquityIdentityToken = FileManager.default.ubiquityIdentityToken {
            print("☁️ iCloud identity token found: \(ubiquityIdentityToken)")
        } else {
            print("⚠️ No iCloud identity token - user may not be signed in to iCloud")
        }
        
        let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
            .appendingPathComponent("Documents/DockUI")
        
        let finalDesignsDirectory: URL
        let finalStorageStatus: String
        
        if let ubiquityURL = ubiquityURL {
            // Ensure directory exists
            do {
                try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
                print("☁️ iCloud directory created/verified: \(ubiquityURL.path)")
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
        
        print("🚀 DesignManager initialized")
        print("📁 Designs Directory: \(designsDirectory.path)")
        print("📊 Storage Status: \(storageStatus)")
        
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
                
                print("☁️ iCloud became available on retry!")
                
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
                        
                        print("☁️ iCloud became available on second retry!")
                        
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
            print("☁️ iCloud query already running")
            return
        }
        
        print("☁️ Starting iCloud metadata query...")
        
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
        
        if isQueryRunning {
            print("☁️ iCloud metadata query started successfully")
        } else {
            print("⚠️ Failed to start iCloud metadata query")
        }
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
        print("☁️ Processing iCloud query results: \(query.resultCount) items found")
        
        var foundNewFiles = false
        
        for item in query.results {
            guard let metadataItem = item as? NSMetadataItem,
                  let fileURL = metadataItem.value(forAttribute: NSMetadataItemURLKey) as? URL else {
                continue
            }
            
            let fileName = fileURL.lastPathComponent
            print("☁️ Found iCloud file: \(fileName)")
            
            // Check download status
            let downloadStatus = metadataItem.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String
            let isDownloaded = downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent
            
            if !isDownloaded {
                print("☁️ File not downloaded locally, initiating download: \(fileName)")
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
                                print("✅ Added iCloud design: \(designFile.name)")
                            }
                        }
                    }
                }
            }
        }
        
        // If there were downloads initiated, reload after a delay
        if foundNewFiles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("☁️ Reloading design files after iCloud downloads...")
                self.loadDesignFiles()
            }
        }
    }
    
    func stopICloudQuery() {
        metadataQuery?.stop()
        metadataQuery = nil
        isQueryRunning = false
        print("☁️ iCloud metadata query stopped")
    }
    
    func loadDesignFiles() {
        do {
            print("🔍 Loading design files from: \(designsDirectory.path)")
            print("🔍 Directory exists: \(FileManager.default.fileExists(atPath: designsDirectory.path))")
            
            // Ensure directory exists before trying to read from it
            if !FileManager.default.fileExists(atPath: designsDirectory.path) {
                print("📁 Directory doesn't exist, creating it...")
                try FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            print("🔍 Found \(fileURLs.count) files in directory")
            print("🔍 All files: \(fileURLs.map { $0.lastPathComponent })")
            
            // Load regular design files
            let regularFiles = fileURLs
                .filter { $0.pathExtension == "dockui" }
                .compactMap { DesignFile.load(from: $0) }
            
            print("🔍 Loaded \(regularFiles.count) regular design files")
            
            // Try to recover from backup files if regular files are corrupted
            let backupFiles = fileURLs
                .filter { $0.pathExtension == "dockui.backup" }
                .compactMap { DesignFile.load(from: $0) }
            
            print("🔍 Found \(backupFiles.count) backup files")
            
            // Combine and deduplicate
            var allFiles = regularFiles
            for backupFile in backupFiles {
                if !allFiles.contains(where: { $0.name == backupFile.name }) {
                    allFiles.append(backupFile)
                    print("🔄 Recovered design from backup: \(backupFile.name)")
                }
            }
            
            designFiles = allFiles.sorted { $0.lastModified > $1.lastModified }
            print("📁 Loaded \(designFiles.count) design files total")
            
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
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    print("🔍 [Async] Loading design files from: \(self.designsDirectory.path)")
                    
                    // Ensure directory exists
                    if !FileManager.default.fileExists(atPath: self.designsDirectory.path) {
                        try FileManager.default.createDirectory(at: self.designsDirectory, withIntermediateDirectories: true)
                    }
                    
                    let fileURLs = try FileManager.default.contentsOfDirectory(
                        at: self.designsDirectory,
                        includingPropertiesForKeys: [.contentModificationDateKey]
                    )
                    
                    // Filter to only .dockui files
                    let designFileURLs = fileURLs.filter { $0.pathExtension == "dockui" }
                    let backupFileURLs = fileURLs.filter { $0.pathExtension == "dockui.backup" }
                    let totalFiles = designFileURLs.count + backupFileURLs.count
                    
                    print("🔍 [Async] Found \(designFileURLs.count) design files, \(backupFileURLs.count) backup files")
                    
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
                                print("🔄 [Async] Recovered design from backup: \(backupFile.name)")
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
                        self.designFiles = sortedFiles
                        print("📁 [Async] Loaded \(sortedFiles.count) design files total")
                        progressHandler(totalFiles, totalFiles)
                        continuation.resume()
                    }
                    
                } catch {
                    print("❌ [Async] Failed to load design files: \(error)")
                    self.createDesignsDirectoryIfNeeded()
                    
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
        try? FileManager.default.removeItem(at: designFile.fileURL)
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
        print("🔄 Design marked as changed")
        hasUnsavedChanges = true
        // Save immediately when changes are detected
        performAutoSave()
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
            print("💾 Components to save: \(currentDesign.components.count)")
            
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
        print("🔄 Refreshing design files...")
        
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
            print("☁️ Switched to iCloud: \(ubiquityURL.path)")
        }
    }
    
    func getStorageInfo() -> String {
        var info = "📁 Directory: \(designsDirectory.path)\n"
        info += "📊 Designs found: \(designFiles.count)\n"
        info += "🔄 Status: \(storageStatus)"
        return info
    }
    
    func showInFinder() {
        #if os(macOS)
        NSWorkspace.shared.selectFile(designsDirectory.path, inFileViewerRootedAtPath: "")
        print("📁 Opening Finder to: \(designsDirectory.path)")
        #else
        print("📁 Finder not available on iOS. Directory: \(designsDirectory.path)")
        #endif
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
                    
                    print("✅ Renamed and reloaded design: \(displayName)")
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
        print("🔄 Checking for existing files to migrate...")
        
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
                    print("📄 Found \(designFiles.count) design files in user Documents/DockUI folder")
                    print("📄 Files: \(designFiles.map { $0.lastPathComponent }.joined(separator: ", "))")
                    
                    // Create the Documents/DockUI directory if it doesn't exist
                    try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
                    
                    // Copy files to Documents folder with unique names
                    for file in designFiles {
                        let baseName = file.deletingPathExtension().lastPathComponent
                        let uniqueFileName = generateUniqueFileName(baseName: baseName)
                        let destination = designsDirectory.appendingPathComponent(uniqueFileName)
                        
                        do {
                            try FileManager.default.copyItem(at: file, to: destination)
                            print("✅ Copied \(file.lastPathComponent) as \(uniqueFileName)")
                        } catch {
                            print("❌ Failed to copy \(file.lastPathComponent): \(error)")
                        }
                    }
                    
                    // Refresh the design files
                    refreshDesignFiles()
                    print("✅ Migration completed. Found \(designFiles.count) files in Documents folder.")
                } else {
                    print("📄 No design files found in user Documents/DockUI folder")
                }
            } else {
                print("📄 No user Documents/DockUI folder found")
            }
        } catch {
            print("❌ Error accessing user Documents folder: \(error)")
        }
    }
    
}
