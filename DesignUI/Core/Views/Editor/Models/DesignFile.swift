
import SwiftUI
import Foundation
import CryptoKit
import ImageIO

extension Notification.Name {
    static let imageDownloadsCompleted = Notification.Name("imageDownloadsCompleted")
}

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
    
    private static let saveQueue = DispatchQueue(label: "com.designui.saveQueue", qos: .background)

    /// Only value snapshots cross to the serial save queue, never live pages/components.
    private struct SaveSnapshot: Encodable {
        let id: UUID
        let name: String
        let pages: [DesignPage.PersistenceSnapshot]
        let currentPageIndex: Int
        let lastModified: Date
        let thumbnail: Data?
        let devicePreset: String?
        let selectedDevicePreset: String?
        let canvasColorScheme: String?
        let statusBarVisible: Bool
        let statusBarTopSafeArea: Bool
    }
    
    private var autoSaveTimer: Timer?
    private var hasUnsavedChanges = false
    @Published var isAutoSaving = false
    
    deinit {
        stopAutoSave()
    }
    
    var components: [UIComponent] {
        get { currentPage?.components ?? [] }
        set { currentPage?.components = newValue }
    }
    
    var currentPage: DesignPage? {
        guard currentPageIndex >= 0 && currentPageIndex < pages.count else { return nil }
        return pages[currentPageIndex]
    }
    
    var totalComponentCount: Int {
        pages.reduce(0) { $0 + $1.components.count }
    }
    
    init(name: String, components: [UIComponent] = [], fileURL: URL, id: UUID? = nil, devicePreset: String? = nil, colorScheme: String? = nil) {
        self.id = id ?? UUID()
        self.name = name
        let initialPreset = devicePreset ?? "iPhone 17 Pro Max"
        let initialScheme = colorScheme ?? "light"
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
    
    func addPage(name: String? = nil) -> (page: DesignPage, index: Int) {
        let pageName = name ?? "Page \(pages.count + 1)"
        let newPage = DesignPage(
            name: pageName,
            devicePreset: "iPhone 17 Pro Max",
            colorScheme: "light"
        )
        pages.append(newPage)
        let newIndex = pages.count - 1
        return (newPage, newIndex)
    }
    
    func duplicatePage(at index: Int) -> (page: DesignPage, index: Int)? {
        guard index >= 0 && index < pages.count else { return nil }
        let duplicated = pages[index].clone()
        pages.insert(duplicated, at: index + 1)
        let newIndex = index + 1
        return (duplicated, newIndex)
    }
    
    func deletePage(at index: Int) -> Bool {
        guard pages.count > 1, index > 0, index < pages.count else { return false }
        pages.remove(at: index)
        if currentPageIndex >= pages.count {
            currentPageIndex = pages.count - 1
        }
        return true
    }
    
    func renamePage(at index: Int, to newName: String) {
        guard index >= 0 && index < pages.count else { return }
        pages[index].name = newName
    }
        
    func setThumbnail(_ thumbnailData: Data?, devicePreset: String? = nil) {
        self.thumbnail = nil
        self.thumbnail = thumbnailData
        self.devicePreset = devicePreset
    }
    
    func delete() {
        self.isDeleted = true
        
        let fileURL = self.fileURL
        let name = self.name
        
        DesignFile.saveQueue.async {
            do {
                debugLog("🗑️ [Background] Deleting file: \(name)")
                
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
    
    func markAsChanged() {
        hasUnsavedChanges = true
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
        if !hasUnsavedChanges {
            return
        }
        
        DispatchQueue.main.async {
            self.isAutoSaving = true
            debugLog("💾 Auto-saving design: \(self.name)")
            
            self.save()
            
            self.hasUnsavedChanges = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAutoSaving = false
            }
        }
    }

    func save() {
        // Capture published state on the UI thread before background serialization.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [self] in save() }
            return
        }
        if isDeleted {
            debugLog("🛑 Skipping save for deleted file: \(name)")
            return
        }
        
        self.lastModified = Date()
        
            debugLog("💾 Saving design to \(fileURL.path)")

            let snapshot = SaveSnapshot(
                id: id,
                name: name,
                pages: pages.map { $0.persistenceSnapshot() },
                currentPageIndex: currentPageIndex,
                lastModified: lastModified,
                thumbnail: thumbnail,
                devicePreset: devicePreset,
                selectedDevicePreset: selectedDevicePreset,
                canvasColorScheme: canvasColorScheme,
                statusBarVisible: statusBarVisible,
                statusBarTopSafeArea: statusBarTopSafeArea
            )
            
            let fileURL = self.fileURL
            let name = self.name
            
            DesignFile.saveQueue.async {
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try encoder.encode(snapshot)
                    let isiCloudFile = fileURL.path.contains("Mobile Documents") || fileURL.path.contains("iCloud~")
                    
                    if isiCloudFile {
                        let coordinator = NSFileCoordinator()
                        var coordinationError: NSError?
                        var writeError: Error?
                        
                        coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinationError) { (writingURL) in
                            do {
                                try data.write(to: writingURL, options: .atomic)
                                debugLog("✅ [Background] Saved to iCloud: \(name)")
                                
                                try? (writingURL as NSURL).setResourceValue(true, forKey: .isUbiquitousItemKey)
                            } catch {
                                debugLog("❌ [Background] Failed to write iCloud file: \(error)")
                                writeError = error
                            }
                        }
                        
                        if let error = coordinationError { throw error }
                        if let error = writeError { throw error }
                        
                    } else {
                        try data.write(to: fileURL, options: .atomic)
                        debugLog("✅ [Background] Saved locally: \(name)")
                    }
                    
                    try? FileManager.default.setAttributes([.extensionHidden: true], ofItemAtPath: fileURL.path)
                    
                } catch {
                    debugLog("❌ [Background] Failed to save design file: \(error)")
                }
            }
            
    }
    
    static func load(from url: URL) -> DesignFile? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let designData = try decoder.decode(DesignFileData.self, from: data)
            
            debugLog("📂 Loading design: \(designData.name)")
            
            let designFile: DesignFile
            if let pages = designData.pages, !pages.isEmpty {
                designFile = DesignFile(name: designData.name, pages: pages, fileURL: url, id: designData.id)
                designFile.currentPageIndex = min(designData.currentPageIndex ?? 0, pages.count - 1)
            } else {
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
            debugLog("❌ Failed to decode design file '\(url.lastPathComponent)': \(error)")
            
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                debugLog("📄 File size: \(attributes[.size] ?? 0) bytes")
                debugLog("📄 Permissions: \(attributes[.posixPermissions] ?? "unknown")")
            }

            if !FileManager.default.fileExists(atPath: url.path) {
                debugLog("🗑️ File does not exist (likely deleted), skipping recovery: \(url.path)")
                return nil
            }
            
            let fileSize = (try? Data(contentsOf: url).count) ?? 0
            if fileSize > 0 {
                debugLog("⚠️ File is not empty (\(fileSize) bytes) but failed to decode. Skipping fallback to prevent data loss.")
                return nil
            }
            
            let filename = url.deletingPathExtension().lastPathComponent
            return DesignFile(name: filename, components: [], fileURL: url)
        }
    }
}

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
        if let container = try? decoder.singleValueContainer(),
           let jsonString = try? container.decode(String.self),
           let data = jsonString.data(using: .utf8) {
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
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        pages = try container.decodeIfPresent([DesignPage].self, forKey: .pages)
        currentPageIndex = try container.decodeIfPresent(Int.self, forKey: .currentPageIndex)
        components = try container.decodeIfPresent([UIComponent].self, forKey: .components)
        
        lastModified = try? container.decodeIfPresent(Date.self, forKey: .lastModified)
        
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

@MainActor
class DesignManager: ObservableObject {
    static let shared = DesignManager()
    
    @Published var designFiles: [DesignFile] = []
    @Published var currentDesign: DesignFile?
    @Published var designsDirectory: URL
    
    @Published var storageStatus: String = "Using Documents folder"
    
    private var metadataQuery: NSMetadataQuery?
    private var isQueryRunning = false
    private var hasInitialized = false
    
    private init() {
        let localDocuments = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.designsDirectory = localDocuments.appendingPathComponent("DockUI")
        self.storageStatus = "📁 Local Only"
    }

    private func initializeIfNeeded() {
        guard !hasInitialized else { return }
        hasInitialized = true

        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        
        debugLog("🔍 Checking iCloud availability...")
        debugLog("🔍 Container identifier: \(containerIdentifier)")
        
        let ubiquityURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier)?
            .appendingPathComponent("Documents/DockUI")
        
        let finalDesignsDirectory: URL
        let finalStorageStatus: String
        
        if let ubiquityURL = ubiquityURL {
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
        
        self.designsDirectory = finalDesignsDirectory
        self.storageStatus = finalStorageStatus
        debugLog("📁 Designs Directory: \(designsDirectory.path)")
        
        createDesignsDirectoryIfNeeded()
        migrateFromUserDocuments()
        loadDesignFiles()
        
        if storageStatus.contains("iCloud") {
            startICloudQuery()
        } else {
            retryICloudConnection()
        }
    }
    
    private func retryICloudConnection() {
        #if os(iOS)
        debugLog("☁️ Scheduling iCloud retry for iOS...")
        
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2.0) {
            let containerIdentifier = "iCloud.com.Maicol.Dockui"
            
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
                    debugLog("☁️ Switched to iCloud: \(ubiquityURL.path)")
                    
                    self.loadDesignFiles()
                    
                    self.startICloudQuery()
                }
            } else {
                debugLog("⚠️ iCloud still not available after retry")
                
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
        if !FileManager.default.fileExists(atPath: designsDirectory.path) {
            try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
            debugLog("📁 Created designs directory: \(designsDirectory.path)")
        }
    }
    
    private func startICloudQuery() {
        guard !isQueryRunning else {
            return
        }
                
        metadataQuery?.stop()
        
        let query = NSMetadataQuery()
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        query.predicate = NSPredicate(format: "%K LIKE '*.dockui'", NSMetadataItemFSNameKey)
        
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
                let alreadyLoaded = designFiles.contains { $0.fileURL == fileURL }
                if !alreadyLoaded {
                    debugLog("☁️ Loading newly discovered iCloud file: \(fileName)")
                    if let designFile = DesignFile.load(from: fileURL) {
                        DispatchQueue.main.async {
                            if !self.designFiles.contains(where: { $0.fileURL == fileURL }) {
                                self.designFiles.append(designFile)
                                self.designFiles.sort { $0.lastModified > $1.lastModified }
                            }
                        }
                    }
                }
            }
        }
        
        if foundNewFiles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.loadDesignFiles()
            }
        }
    }
    
    func loadDesignFiles() {
        do {
            if !FileManager.default.fileExists(atPath: designsDirectory.path) {
                debugLog("📁 Directory doesn't exist, creating it...")
                try FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
            }
            
            let fileURLs = try FileManager.default.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            let regularFiles = fileURLs
                .filter { $0.pathExtension == "dockui" }
                .compactMap { DesignFile.load(from: $0) }
                        
            let backupFiles = fileURLs
                .filter { $0.pathExtension == "dockui.backup" }
                .compactMap { DesignFile.load(from: $0) }
            
            var allFiles = regularFiles
            for backupFile in backupFiles {
                if !allFiles.contains(where: { $0.name == backupFile.name }) {
                    allFiles.append(backupFile)
                }
            }
            
            designFiles = allFiles.sorted { $0.lastModified > $1.lastModified }
            
            for design in designFiles {
                debugLog("  - \(design.name) (modified: \(design.lastModified))")
            }
            
        } catch {
            debugLog("❌ Failed to load design files: \(error)")
            createDesignsDirectoryIfNeeded()
        }
    }
    
    func createNewDesign(name: String) -> DesignFile {
        initializeIfNeeded()
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        let designFile = DesignFile(name: displayName, fileURL: fileURL)
        designFile.save()
        
        designFiles.insert(designFile, at: 0)
        return designFile
    }
    
    func createDesignFromTemplate(template: DesignTemplate, name: String) -> DesignFile {
        initializeIfNeeded()
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        let copiedComponents = deepCopyComponents(template.components)
        
        let designFile = DesignFile(name: displayName, components: copiedComponents, fileURL: fileURL)
        
        if let preset = template.devicePreset {
            designFile.selectedDevicePreset = preset
        }
        
        if let scheme = template.canvasColorScheme {
            designFile.canvasColorScheme = scheme
        }

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
        guard let designData = post.getDesignData() else { return nil }
        
        let uniqueFileName = generateUniqueFileName(baseName: name)
        let fileURL = designsDirectory.appendingPathComponent(uniqueFileName)
        let displayName = uniqueFileName.replacingOccurrences(of: ".dockui", with: "")
        
        let newDesign: DesignFile
        
        if let pages = designData.pages, !pages.isEmpty {
            newDesign = DesignFile(name: displayName, pages: pages, fileURL: fileURL)
            newDesign.currentPageIndex = min(designData.currentPageIndex ?? 0, pages.count - 1)
        } else {
            newDesign = DesignFile(
                name: displayName,
                components: designData.components ?? [],
                fileURL: fileURL,
                devicePreset: designData.selectedDevicePreset ?? designData.devicePreset,
                colorScheme: designData.canvasColorScheme
            )
        }
        
        newDesign.canvasColorScheme = designData.canvasColorScheme ?? "light"
        newDesign.selectedDevicePreset = designData.selectedDevicePreset ?? designData.devicePreset ?? "iPhone 17 Pro Max"
        newDesign.devicePreset = designData.devicePreset ?? newDesign.selectedDevicePreset
        newDesign.statusBarVisible = designData.statusBarVisible ?? true
        newDesign.statusBarTopSafeArea = designData.statusBarTopSafeArea ?? true

        if let page = newDesign.currentPage {
            page.statusBarVisible = newDesign.statusBarVisible
            page.statusBarTopSafeArea = newDesign.statusBarTopSafeArea
            if page.statusBarComponent == nil {
                var props = UIComponent.defaultProperties(for: .statusBar)
                for index in props.indices {
                    switch props[index].key {
                    case "showStatusBar":
                        let prop = props[index]
                        props[index] = ComponentProperty(
                            key: prop.key,
                            displayName: prop.displayName,
                            type: prop.type,
                            value: newDesign.statusBarVisible,
                            defaultValue: newDesign.statusBarVisible,
                            options: prop.options
                        )
                    case "topSafeArea":
                        let prop = props[index]
                        props[index] = ComponentProperty(
                            key: prop.key,
                            displayName: prop.displayName,
                            type: prop.type,
                            value: newDesign.statusBarTopSafeArea,
                            defaultValue: newDesign.statusBarTopSafeArea,
                            options: prop.options
                        )
                    default:
                        break
                    }
                }
                page.statusBarComponent = UIComponent(type: .statusBar, properties: props)
            }
        }
        
        await hydrateRemoteImagesIfNeeded(in: newDesign)
        
        newDesign.save()
        
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
            // Deduplicate by actual image content, not URL string, so reopened
            // community posts with different URL variants don't create duplicates.
            let hash = sha256Hex(data)
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

    private func sha256Hex(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    private func deepCopyComponents(_ components: [UIComponent]) -> [UIComponent] {
        return components.map { $0.clone() }
    }
    
    func deleteDesign(_ designFile: DesignFile) {
        designFile.delete()

        removeDesignFromList(designId: designFile.id)
        clearCurrentDesignIfNeeded(deletedDesignId: designFile.id)
    }

    private func removeDesignFromList(designId: UUID) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
            designFiles.removeAll(where: { existing in
                existing.id == designId
            })
        }
    }

    private func clearCurrentDesignIfNeeded(deletedDesignId: UUID) {
        guard currentDesign?.id == deletedDesignId else { return }
        currentDesign = nil
    }
    
    #if os(iOS)
    func openDesign(_ designFile: DesignFile) {
        currentDesign = designFile
    }
    
    func closeCurrentDesign() {
        if let currentDesign = currentDesign {
            currentDesign.save()
        }
        currentDesign = nil
    }
    #endif
    
    func refreshDesignFiles() {
        initializeIfNeeded()
        
        if storageStatus.contains("Local") {
            checkAndSwitchToICloud()
        }
        
        loadDesignFiles()
        
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
            
            do {
                try FileManager.default.createDirectory(at: ubiquityURL, withIntermediateDirectories: true)
            } catch {
                debugLog("⚠️ Failed to create iCloud directory: \(error)")
            }
            
            self.designsDirectory = ubiquityURL
            self.storageStatus = "☁️ iCloud Drive"
        }
    }
    
    func generateUniqueFileName(baseName: String) -> String {
        let fileExtension = "dockui"
        var fileName = baseName
        var counter = 1
        
        let cleanBaseName = baseName.replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        if cleanBaseName.isEmpty {
            fileName = "Untitled"
        } else {
            fileName = cleanBaseName
        }
        
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
            try FileManager.default.moveItem(at: design.fileURL, to: newFileURL)
            
            if let index = designFiles.firstIndex(where: { $0.id == design.id }) {
                if let reloadedDesign = DesignFile.load(from: newFileURL) {
                    reloadedDesign.name = displayName
                    
                    reloadedDesign.save()
                    
                    designFiles[index] = reloadedDesign
                    
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
        guard url.isFileURL else {
            completion(nil)
            return
        }
        
        let standardURL = url.resolvingSymlinksInPath()
        let standardDesignsDir = designsDirectory.resolvingSymlinksInPath()
        
        let isInternalFile = standardURL.path.hasPrefix(standardDesignsDir.path)
        
        if isInternalFile {
            debugLog("📂 Opening existing internal file: \(url.lastPathComponent)")
            
            if let existingDesign = designFiles.first(where: { $0.fileURL.resolvingSymlinksInPath() == standardURL }) {
                completion(existingDesign)
                return
            }
            
            if let loadedDesign = DesignFile.load(from: url) {
                DispatchQueue.main.async {
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
            debugLog("📥 Importing external file: \(url.lastPathComponent)")
            
            let originalName = url.deletingPathExtension().lastPathComponent
            let uniqueFileName = generateUniqueFileName(baseName: originalName)
            let destinationURL = designsDirectory.appendingPathComponent(uniqueFileName)
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.copyItem(at: url, to: destinationURL)
                debugLog("✅ Imported design to: \(destinationURL.path)")
                
                if let importedDesign = DesignFile.load(from: destinationURL) {
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
        
        let userDocumentsPath = "/Users/\(NSUserName())/Documents"
        let userDocumentsURL = URL(fileURLWithPath: userDocumentsPath)
        let userDockUIDirectory = userDocumentsURL.appendingPathComponent("DockUI")
        
        do {
            if FileManager.default.fileExists(atPath: userDockUIDirectory.path) {
                let userFiles = try FileManager.default.contentsOfDirectory(at: userDockUIDirectory, includingPropertiesForKeys: nil)
                let designFiles = userFiles.filter { $0.pathExtension == "dockui" }
                
                if !designFiles.isEmpty {
                    debugLog("Found \(designFiles.count) design files in user Documents/DockUI folder")
                    
                    try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
                    
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
    private let manifestFileName = "gallery-manifest.json"
    
    private var imagesDirectory: URL? {
        let containerIdentifier = "iCloud.com.Maicol.Dockui"
        if let ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: containerIdentifier) {
            return ubiquityURL.appendingPathComponent("Documents/\(galleryFolderName)")
        }
        
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent(galleryFolderName)
    }
    
    private let bundledAssets: [String] = []
    private let memoryCache = NSCache<NSString, PlatformImage>()
    private let thumbnailCache = NSCache<NSString, PlatformImage>()
    private let ioQueue = DispatchQueue(label: "com.designui.imagegallery.io", qos: .userInitiated)
    private var cachedFilenames: [String] = []
    private var hasLoadedFilenameCache = false
    
    private var manifestURL: URL? {
        imagesDirectory?.appendingPathComponent(manifestFileName)
    }
    
    private var thumbnailCacheDirectory: URL? {
        guard let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cachesDirectory
            .appendingPathComponent("DesignUI")
            .appendingPathComponent("ImageGalleryThumbnails", isDirectory: true)
    }
    
    init() {
        createGalleryDirectoryIfNeeded()
        createThumbnailCacheDirectoryIfNeeded()
        memoryCache.countLimit = 300
        thumbnailCache.countLimit = 500
        cachedFilenames = loadFilenameManifest()
        hasLoadedFilenameCache = !cachedFilenames.isEmpty
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
    
    private func createThumbnailCacheDirectoryIfNeeded() {
        guard let thumbnailCacheDirectory else { return }
        
        if !fileManager.fileExists(atPath: thumbnailCacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: thumbnailCacheDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                debugLog("❌ ImageGalleryManager: Failed to create thumbnail cache directory: \(error)")
            }
        }
    }
    
    func saveImage(data: Data, originalFilename: String? = nil) -> String? {
        guard let imagesDirectory = imagesDirectory else { return nil }
        
        guard let optimizedData = ImageGalleryManager.compressAndResizeImage(data: data) else {
            debugLog("ImageGalleryManager: Failed to optimize image, falling back to original data")
            return saveRawData(data: data, originalFilename: originalFilename)
        }
        
        let filename = "\(UUID().uuidString).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        do {
            try optimizedData.write(to: fileURL)
            debugLog("ImageGalleryManager: Saved optimized image")
            didSaveImage(named: filename)
            return filename
        } catch {
            debugLog("ImageGalleryManager: Failed to save image: \(error)")
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
            didSaveImage(named: preferredFilename)
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
            didSaveImage(named: filename)
            return filename
        } catch {
            return nil
        }
    }
    
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
        
        if newSize.width > maxDimension || newSize.height > maxDimension {
            let aspectRatio = newSize.width / newSize.height
            if newSize.width > newSize.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        }
        
        let newImage = NSImage(size: newSize)
        
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        
        guard let tiffRepresentation = newImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        
        return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.3])
    }
    #else
    private static func optimizeImageiOS(_ image: UIImage) -> Data? {
        var newSize = image.size
        let maxDimension: CGFloat = 512
        
        if newSize.width > maxDimension || newSize.height > maxDimension {
            let aspectRatio = newSize.width / newSize.height
            if newSize.width > newSize.height {
                newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
            } else {
                newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
            }
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true  // ← KEY FIX: Explicitly set opaque to true for images without transparency
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let resizedImage = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: newSize))
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage.jpegData(compressionQuality: 0.3)
    }
    #endif
    
    func loadImage(filename: String) -> PlatformImage? {
        if let cached = memoryCache.object(forKey: filename as NSString) {
            return cached
        }

        if bundledAssets.contains(filename) {
            debugLog("🎨 Loading bundled asset: \(filename)")
            
            #if os(macOS)
            if let image = NSImage(named: filename) {
                debugLog("✅ Successfully loaded bundled asset from default bundle: \(filename)")
                memoryCache.setObject(image, forKey: filename as NSString)
                return image
            }
            
            for bundle in Bundle.allBundles {
                if let image = bundle.image(forResource: filename) {
                    debugLog("✅ Found bundled asset in bundle \(bundle.bundleIdentifier ?? "unknown"): \(filename)")
                    memoryCache.setObject(image, forKey: filename as NSString)
                    return image
                }
            }
            #else
            if let image = UIImage(named: filename) {
                debugLog("✅ Successfully loaded bundled asset from default bundle: \(filename)")
                memoryCache.setObject(image, forKey: filename as NSString)
                return image
            }
            
            for bundle in Bundle.allBundles {
                if let image = UIImage(named: filename, in: bundle, compatibleWith: nil) {
                    debugLog("✅ Found bundled asset in bundle \(bundle.bundleIdentifier ?? "unknown"): \(filename)")
                    memoryCache.setObject(image, forKey: filename as NSString)
                    return image
                }
            }
            #endif
            
            debugLog("❌ Failed to load bundled asset: \(filename)")
            return nil
        }
        
        guard let imagesDirectory = imagesDirectory else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        
        if let data = try? Data(contentsOf: fileURL) {
            #if os(macOS)
            if let image = NSImage(data: data) {
                memoryCache.setObject(image, forKey: filename as NSString)
                return image
            }
            #else
            if let image = UIImage(data: data) {
                memoryCache.setObject(image, forKey: filename as NSString)
                return image
            }
            #endif
        }
        return nil
    }

    func loadImageAsync(filename: String, completion: @escaping (PlatformImage?) -> Void) {
        if let cached = memoryCache.object(forKey: filename as NSString) {
            completion(cached)
            return
        }

        ioQueue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let image = self.loadImage(filename: filename)
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }

    func loadThumbnailAsync(filename: String, maxPixelSize: Int = 220, displayScale: CGFloat, completion: @escaping (PlatformImage?) -> Void) {
        let cacheKey = "\(filename)#\(maxPixelSize)" as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            completion(cached)
            return
        }

        ioQueue.async { [weak self] in
            guard let self else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            if let bundled = self.loadImage(filename: filename) {
                self.thumbnailCache.setObject(bundled, forKey: cacheKey)
                DispatchQueue.main.async { completion(bundled) }
                return
            }

            guard let fileURL = self.getImageUrl(filename: filename),
                  self.fileManager.fileExists(atPath: fileURL.path) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            if let cachedThumbnail = self.loadCachedThumbnail(filename: filename, maxPixelSize: maxPixelSize, sourceURL: fileURL) {
                self.thumbnailCache.setObject(cachedThumbnail, forKey: cacheKey)
                DispatchQueue.main.async {
                    completion(cachedThumbnail)
                }
                return
            }

            let thumbnail = self.downsampleImage(at: fileURL, maxPixelSize: maxPixelSize, displayScale: displayScale) ?? self.loadImage(filename: filename)
            if let thumbnail {
                self.thumbnailCache.setObject(thumbnail, forKey: cacheKey)
                self.persistThumbnailToDisk(thumbnail, filename: filename, maxPixelSize: maxPixelSize)
            }
            DispatchQueue.main.async {
                completion(thumbnail)
            }
        }
    }
    
    func cachedThumbnail(filename: String, maxPixelSize: Int = 220) -> PlatformImage? {
        let cacheKey = "\(filename)#\(maxPixelSize)" as NSString
        if let cached = thumbnailCache.object(forKey: cacheKey) {
            return cached
        }
        
        if let bundled = memoryCache.object(forKey: filename as NSString) {
            thumbnailCache.setObject(bundled, forKey: cacheKey)
            return bundled
        }
        
        guard let fileURL = getImageUrl(filename: filename),
              fileManager.fileExists(atPath: fileURL.path),
              let cachedThumbnail = loadCachedThumbnail(filename: filename, maxPixelSize: maxPixelSize, sourceURL: fileURL) else {
            return nil
        }
        
        thumbnailCache.setObject(cachedThumbnail, forKey: cacheKey)
        return cachedThumbnail
    }

    private func downsampleImage(at url: URL, maxPixelSize: Int, displayScale: CGFloat) -> PlatformImage? {
        let sourceOptions: CFDictionary = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }

        let downsampleOptions: CFDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
            return nil
        }

        #if os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        #else
        return UIImage(cgImage: cgImage, scale: displayScale, orientation: .up)
        #endif
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
    
    func getAllImageFilenames() -> [String] {
        if !hasLoadedFilenameCache {
            cachedFilenames = loadFilenameManifest()
            hasLoadedFilenameCache = true
        }

        let localImages = validatedCachedFilenames()
        if localImages != cachedFilenames {
            cachedFilenames = localImages
            saveFilenameManifest(localImages)
        }

        return localImages + bundledAssets
    }
            
    func deleteImage(filename: String) {
        if bundledAssets.contains(filename) {
            debugLog("⚠️ Cannot delete bundled asset: \(filename)")
            return
        }
        
        guard let imagesDirectory = imagesDirectory else { return }
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
            memoryCache.removeObject(forKey: filename as NSString)
            removeThumbnailCaches(for: filename)
            cachedFilenames.removeAll { $0 == filename }
            hasLoadedFilenameCache = true
            saveFilenameManifest(cachedFilenames)
            debugLog("🗑️ ImageGalleryManager: Deleted \(filename)")
        }
    }
    
    private func didSaveImage(named filename: String) {
        memoryCache.removeObject(forKey: filename as NSString)
        removeThumbnailCaches(for: filename)
        cachedFilenames.removeAll { $0 == filename }
        cachedFilenames.insert(filename, at: 0)
        hasLoadedFilenameCache = true
        saveFilenameManifest(cachedFilenames)
    }
    
    private func validatedCachedFilenames() -> [String] {
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "webp"]
        let existingCached = cachedFilenames.filter { filename in
            let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
            return imageExtensions.contains(ext) && imageExists(filename: filename)
        }
        
        if !existingCached.isEmpty || hasLoadedFilenameCache {
            return existingCached
        }
        
        let scanned = scanImagesFromDisk()
        if scanned != cachedFilenames {
            saveFilenameManifest(scanned)
        }
        return scanned
    }
    
    private func scanImagesFromDisk() -> [String] {
        guard let imagesDirectory else { return [] }
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(
                at: imagesDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: .skipsHiddenFiles
            )
            
            let imageExtensions = ["jpg", "jpeg", "png", "heic", "webp"]
            let localImages = fileURLs.filter { url in
                imageExtensions.contains(url.pathExtension.lowercased())
            }
            
            let sortedLocalImages = localImages.sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
                return date1 > date2
            }
            
            return sortedLocalImages.map(\.lastPathComponent)
        } catch {
            debugLog("❌ ImageGalleryManager: Failed to list images: \(error)")
            return []
        }
    }
    
    private func loadFilenameManifest() -> [String] {
        guard let manifestURL,
              let data = try? Data(contentsOf: manifestURL),
              let filenames = try? JSONDecoder().decode([String].self, from: data) else {
            return scanImagesFromDisk()
        }
        return filenames
    }
    
    private func saveFilenameManifest(_ filenames: [String]) {
        guard let manifestURL,
              let data = try? JSONEncoder().encode(filenames) else { return }
        try? data.write(to: manifestURL, options: .atomic)
    }
    
    private func thumbnailDiskURL(filename: String, maxPixelSize: Int) -> URL? {
        guard let thumbnailCacheDirectory else { return nil }
        return thumbnailCacheDirectory.appendingPathComponent("\(filename)#\(maxPixelSize).jpg")
    }
    
    private func loadCachedThumbnail(filename: String, maxPixelSize: Int, sourceURL: URL) -> PlatformImage? {
        guard let thumbnailURL = thumbnailDiskURL(filename: filename, maxPixelSize: maxPixelSize),
              fileManager.fileExists(atPath: thumbnailURL.path) else {
            return nil
        }
        
        let sourceDate = (try? sourceURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
        let thumbnailDate = (try? thumbnailURL.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
        guard thumbnailDate >= sourceDate else { return nil }
        
        if let data = try? Data(contentsOf: thumbnailURL) {
            #if os(macOS)
            return NSImage(data: data)
            #else
            return UIImage(data: data)
            #endif
        }
        
        return nil
    }
    
    private func persistThumbnailToDisk(_ image: PlatformImage, filename: String, maxPixelSize: Int) {
        guard let thumbnailURL = thumbnailDiskURL(filename: filename, maxPixelSize: maxPixelSize),
              let data = thumbnailData(from: image) else {
            return
        }
        
        try? data.write(to: thumbnailURL, options: .atomic)
    }
    
    private func removeThumbnailCaches(for filename: String) {
        thumbnailCache.removeAllObjects()
        
        guard let thumbnailCacheDirectory,
              let urls = try? fileManager.contentsOfDirectory(
                at: thumbnailCacheDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
              ) else { return }
        
        for url in urls where url.lastPathComponent.hasPrefix("\(filename)#") {
            try? fileManager.removeItem(at: url)
        }
    }
    
    private func thumbnailData(from image: PlatformImage) -> Data? {
        #if os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
        #else
        return image.jpegData(compressionQuality: 0.7)
        #endif
    }
}
