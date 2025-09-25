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
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(DesignFileData(
                name: name,
                components: components,
                lastModified: lastModified
            ))
            try data.write(to: fileURL)
            self.lastModified = Date()
        } catch {
            print("Failed to save design file: \(error)")
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
            print("Failed to load design file: \(error)")
            return nil
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
    @Published var designFiles: [DesignFile] = []
    @Published var currentDesign: DesignFile?
    @Published var isAutoSaving = false
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let designsDirectory: URL
    
    init() {
        self.designsDirectory = documentsDirectory.appendingPathComponent("Designs")
        createDesignsDirectoryIfNeeded()
        loadDesignFiles()
    }
    
    private func createDesignsDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: designsDirectory.path) {
            try? FileManager.default.createDirectory(at: designsDirectory, withIntermediateDirectories: true)
        }
    }
    
    func loadDesignFiles() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: designsDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            designFiles = fileURLs
                .filter { $0.pathExtension == "design" }
                .compactMap { DesignFile.load(from: $0) }
                .sorted { $0.lastModified > $1.lastModified }
        } catch {
            print("Failed to load design files: \(error)")
        }
    }
    
    func createNewDesign(name: String) -> DesignFile {
        let fileName = "\(name.replacingOccurrences(of: " ", with: "_")).design"
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
        currentDesign = designFile
    }
    
    func closeCurrentDesign() {
        currentDesign = nil
    }
    
    // MARK: - Auto-save functionality
    func startAutoSave(for designFile: DesignFile) {
        // Auto-save every 2 seconds when there are changes
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if self.currentDesign?.id == designFile.id {
                self.autoSave(designFile)
            }
        }
    }
    
    private func autoSave(_ designFile: DesignFile) {
        DispatchQueue.main.async {
            self.isAutoSaving = true
            designFile.save()
            
            // Update the design files list to reflect the new lastModified date
            if let index = self.designFiles.firstIndex(where: { $0.id == designFile.id }) {
                self.designFiles[index] = designFile
                self.designFiles.sort { $0.lastModified > $1.lastModified }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.isAutoSaving = false
            }
        }
    }
}
