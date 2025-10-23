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
            print("💾 Components count: \(components.count)")
            
            // Debug: Print component properties and modifiers
            for (index, component) in components.enumerated() {
                print("💾 Component \(index): \(component.type.rawValue) with \(component.properties.count) properties and \(component.modifiers.count) modifiers")
                for property in component.properties {
                    print("💾   - Property \(property.key): \(property.value) (type: \(property.type))")
                }
                for (modIndex, modifier) in component.modifiers.enumerated() {
                    print("💾   - Modifier \(modIndex): \(modifier.type.rawValue) with properties: \(modifier.properties)")
                }
            }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                name: name,
                components: components,
                lastModified: lastModified
            ))
            
            print("💾 Encoded data size: \(data.count) bytes")
            
            try data.write(to: fileURL)
            self.lastModified = Date()
            print("✅ Design saved successfully: \(name)")
            print("📁 File saved to: \(fileURL.path)")
            
            // Hide the extension in Finder
            try FileManager.default.setAttributes([.extensionHidden: true], ofItemAtPath: fileURL.path)
            print("✅ File extension hidden: \(name)")
            
            // Also save to user Documents folder for persistence across rebuilds
            let userDocumentsPath = "/Users/\(NSUserName())/Documents"
            let userDocumentsURL = URL(fileURLWithPath: userDocumentsPath)
            let userDockUIDirectory = userDocumentsURL.appendingPathComponent("DockUI")
            
            // Create user Documents/DockUI directory if it doesn't exist
            try? FileManager.default.createDirectory(at: userDockUIDirectory, withIntermediateDirectories: true)
            
            let userFileURL = userDockUIDirectory.appendingPathComponent(fileURL.lastPathComponent)
            try data.write(to: userFileURL)
            print("✅ Design also saved to user Documents: \(userFileURL.path)")
            
            // Verify the file was written
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
                print("✅ File verified: \(fileSize) bytes")
                print("📁 File location: \(fileURL.path)")
            } else {
                print("❌ File verification failed - file not found after save")
            }
            
        } catch {
            print("❌ Failed to save design file: \(error)")
        }
    }
    
    
    static func load(from url: URL) -> DesignFile? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let designData = try decoder.decode(DesignFileData.self, from: data)
            
            let designFile = DesignFile(name: designData.name, components: designData.components, fileURL: url)
            designFile.lastModified = designData.lastModified
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
    
    private init() {
        // Use app's Documents directory (sandboxed)
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storageStatus = "Using app Documents folder"
        print("📁 Using app Documents folder: \(documentsDirectory.path)")
        
        // Use DockUI folder in app Documents
        self.designsDirectory = documentsDirectory.appendingPathComponent("DockUI")
        
        print("🚀 DesignManager singleton initialized")
        print("📁 Documents Directory: \(documentsDirectory.path)")
        print("📁 Designs Directory: \(designsDirectory.path)")
        print("📁 Storage Status: \(storageStatus)")
        
        createDesignsDirectoryIfNeeded()
        migrateFromUserDocuments()
        loadDesignFiles()
    }
    
    private func createDesignsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: designsDirectory.path) {
            try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
        }
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
    
    func createNewDesign(name: String) -> DesignFile {
        let fileName = "\(name.replacingOccurrences(of: " ", with: "_")).dockui"
        let fileURL = designsDirectory.appendingPathComponent(fileName)
        
        let designFile = DesignFile(name: name, fileURL: fileURL)
        designFile.save()
        
        designFiles.insert(designFile, at: 0)
        return designFile
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
        loadDesignFiles()
        print("📊 Loaded \(designFiles.count) design files")
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
            
            // Update the design file properties
            design.name = displayName
            // Note: We can't update fileURL directly since it's a let property
            // The design will need to be reloaded to get the new URL
            
            print("✅ Renamed design to: \(displayName)")
        } catch {
            print("❌ Failed to rename design: \(error)")
        }
    }
    
    func migrateFromUserDocuments() {
        print("🔄 Migrating files from user Documents folder...")
        
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
                    
                    // Create the app Documents/DockUI directory if it doesn't exist
                    try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
                    
                    // Copy files to app's Documents folder with unique names
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
                    print("✅ Migration completed. Found \(designFiles.count) files in app Documents folder.")
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
