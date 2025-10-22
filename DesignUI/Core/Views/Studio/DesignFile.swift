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
    let fileURL: URL
    
    init(name: String, components: [UIComponent] = [], fileURL: URL) {
        self.name = name
        self.components = components
        self.lastModified = Date()
        self.fileURL = fileURL
    }
    
    // MARK: - Auto-save functionality
    func save() {
        do {
            print("💾 Saving design: \(name) to \(fileURL.path)")
            
            // Ensure parent directory exists
            let parentDir = fileURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: parentDir.path) {
                try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
                print("📁 Created parent directory: \(parentDir.path)")
            }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                name: name,
                components: components,
                lastModified: lastModified
            ))
            
            print("💾 Encoded data size: \(data.count) bytes")
            
            // Create backup before saving
            createBackup()
            
            // Write file
            try data.write(to: fileURL)
            self.lastModified = Date()
            print("✅ Design saved successfully: \(name)")
            
            // Verify the file was written
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
                print("✅ File verified: \(fileSize) bytes at \(fileURL.path)")
            } else {
                print("❌ File verification failed - file not found after save")
            }
            
        } catch {
            print("❌ Failed to save design file: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            // Try to save to backup location
            saveToBackup()
        }
    }
    
    private func createBackup() {
        let backupURL = fileURL.appendingPathExtension("backup")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.copyItem(at: fileURL, to: backupURL)
        }
    }
    
    private func saveToBackup() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                name: name,
                components: components,
                lastModified: lastModified
            ))
            let backupURL = fileURL.appendingPathExtension("backup")
            try data.write(to: backupURL)
            print("⚠️ Saved to backup location: \(backupURL.path)")
        } catch {
            print("❌ Failed to save even to backup: \(error)")
        }
    }
    
    static func load(from url: URL) -> DesignFile? {
        do {
            // Load file with iCloud download support
            let data = try loadFileWithiCloudSupport(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let designData = try decoder.decode(DesignFileData.self, from: data)
            
            let designFile = DesignFile(name: designData.name, components: designData.components, fileURL: url)
            designFile.lastModified = designData.lastModified
            return designFile
        } catch {
            print("Failed to load design file from iCloud: \(error)")
            return nil
        }
    }
    
    // MARK: - iCloud Helper Methods
    private static func loadFileWithiCloudSupport(from url: URL) throws -> Data {
        // For iCloud files, try to start downloading if needed
        if url.path.contains("iCloud") {
            print("☁️ Loading file from iCloud: \(url.lastPathComponent)")
            do {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
                // Wait a bit for download to start
                Thread.sleep(forTimeInterval: 0.5)
            } catch {
                print("⚠️ Failed to start download: \(error)")
            }
        }
        
        return try Data(contentsOf: url)
    }
}

// MARK: - Design File Data (for JSON encoding/decoding)
struct DesignFileData: Codable {
    let name: String
    let components: [UIComponent]
    let lastModified: Date
}

// MARK: - Design Manager
class DesignManager: ObservableObject {
    static let shared = DesignManager()
    
    @Published var designFiles: [DesignFile] = []
    @Published var currentDesign: DesignFile?
    @Published var isAutoSaving = false
    @Published var designsDirectory: URL
    @Published var showingDirectoryPicker = false
    
    private let documentsDirectory: URL
    private var autoSaveTimer: Timer?
    private var lastSavedComponents: [UIComponent] = []
    private var hasUnsavedChanges = false
    
    private init() {
        // Use the app's Documents directory (sandboxed) as fallback
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Try to use iCloud Documents first, fallback to local storage
        if let iCloudURL = Self.getiCloudDocumentsURL() {
            self.designsDirectory = iCloudURL.appendingPathComponent("Designs")
            print("☁️ Using iCloud Documents directory: \(designsDirectory.path)")
        } else {
            // Check if user has previously selected a directory
            if let savedDirectoryPath = UserDefaults.standard.string(forKey: "designsDirectory"),
               let savedDirectory = URL(string: savedDirectoryPath),
               FileManager.default.fileExists(atPath: savedDirectory.path) {
                self.designsDirectory = savedDirectory
                print("📁 Using saved designs directory: \(designsDirectory.path)")
            } else {
                // Use default sandboxed directory
                self.designsDirectory = documentsDirectory.appendingPathComponent("Designs")
                print("📁 Using default designs directory: \(designsDirectory.path)")
            }
        }
        
        print("🚀 DesignManager singleton initialized")
        print("📁 Documents Directory: \(documentsDirectory.path)")
        
        createDesignsDirectoryIfNeeded()
        loadDesignFiles()
    }
    
    private func createDesignsDirectoryIfNeeded() {
        print("📁 Checking if directory exists: \(designsDirectory.path)")
        if !FileManager.default.fileExists(atPath: designsDirectory.path) {
            print("📁 Directory doesn't exist, creating it...")
            do {
                try FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
                print("✅ Directory created successfully: \(designsDirectory.path)")
            } catch {
                print("❌ Failed to create directory: \(error)")
            }
        } else {
            print("✅ Directory already exists: \(designsDirectory.path)")
        }
    }
    
    func loadDesignFiles() {
        do {
            print("🔍 Loading design files from: \(designsDirectory.path)")
            print("🔍 Directory exists: \(FileManager.default.fileExists(atPath: designsDirectory.path))")
            
            // Ensure directory exists before loading
            createDesignsDirectoryIfNeeded()
            
            // Load files from directory
            let fileURLs = try FileManager.default.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            print("☁️ Found \(fileURLs.count) files in directory")
            
            // Load regular design files
            let regularFiles = fileURLs
                .filter { $0.pathExtension == "design" }
                .compactMap { DesignFile.load(from: $0) }
            
            print("☁️ Loaded \(regularFiles.count) regular design files")
            
            // Try to recover from backup files if regular files are corrupted
            let backupFiles = fileURLs
                .filter { $0.pathExtension == "design.backup" }
                .compactMap { DesignFile.load(from: $0) }
            
            print("☁️ Found \(backupFiles.count) backup files")
            
            // Combine and deduplicate
            var allFiles = regularFiles
            for backupFile in backupFiles {
                if !allFiles.contains(where: { $0.name == backupFile.name }) {
                    allFiles.append(backupFile)
                    print("🔄 Recovered design from backup: \(backupFile.name)")
                }
            }
            
            designFiles = allFiles.sorted { $0.lastModified > $1.lastModified }
            print("☁️ Loaded \(designFiles.count) design files total")
            
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
    
    func createNewDesign(name: String) -> DesignFile {
        print("🆕 Creating new design: \(name)")
        print("🆕 Designs directory: \(designsDirectory.path)")
        
        // Ensure directory exists
        createDesignsDirectoryIfNeeded()
        
        let fileName = "\(name.replacingOccurrences(of: " ", with: "_")).design"
        let fileURL = designsDirectory.appendingPathComponent(fileName)
        
        print("🆕 File URL: \(fileURL.path)")
        
        let designFile = DesignFile(name: name, fileURL: fileURL)
        designFile.save()
        
        designFiles.insert(designFile, at: 0)
        print("✅ Design created and added to list: \(name)")
        return designFile
    }
    
    func deleteDesign(_ designFile: DesignFile) {
        do {
            try FileManager.default.removeItem(at: designFile.fileURL)
        } catch {
            print("❌ Failed to delete design file: \(error)")
        }
        
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
        let defaultDirectory = documentsDirectory.appendingPathComponent("Designs")
        setDesignsDirectory(defaultDirectory)
    }
    
    // MARK: - iCloud Management
    func refreshiCloudStatus() {
        // Simple status refresh - could be enhanced later
        print("☁️ iCloud status: \(isUsingiCloud ? "Using iCloud" : "Using local storage")")
    }
    
    func switchToiCloud() {
        if let iCloudURL = Self.getiCloudDocumentsURL() {
            let iCloudDesignsURL = iCloudURL.appendingPathComponent("Designs")
            setDesignsDirectory(iCloudDesignsURL)
            print("☁️ Switched to iCloud Documents")
        } else {
            print("❌ iCloud not available")
        }
    }
    
    func switchToLocal() {
        let localDirectory = documentsDirectory.appendingPathComponent("Designs")
        setDesignsDirectory(localDirectory)
        print("📁 Switched to local storage")
    }
    
    var isUsingiCloud: Bool {
        return designsDirectory.path.contains("iCloud")
    }
    
    // MARK: - iCloud Helper Methods
    private static func getiCloudDocumentsURL() -> URL? {
        // Check if iCloud is available
        guard FileManager.default.ubiquityIdentityToken != nil else {
            print("❌ iCloud not available - user not signed in")
            return nil
        }
        
        // Get iCloud Documents directory
        guard let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") else {
            print("❌ Failed to access iCloud Documents directory")
            return nil
        }
        
        // Create the directory if it doesn't exist
        do {
            try FileManager.default.createDirectory(at: iCloudURL, withIntermediateDirectories: true, attributes: nil)
            print("☁️ iCloud Documents directory ready: \(iCloudURL.path)")
            return iCloudURL
        } catch {
            print("❌ Failed to create iCloud Documents directory: \(error)")
            return nil
        }
    }
}
