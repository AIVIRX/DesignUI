//
//  DocumentEditorView.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct DocumentEditorView: View {
    @Binding var document: DockUIDocument
    @EnvironmentObject private var designManager: DesignManager
    @State private var isLoaded = false
    
    var body: some View {
        Group {
            if isLoaded {
                UIBuilderView(designFile: document.designFile)
            } else {
                ProgressView("Loading document...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadDocument()
        }
        .onChange(of: document.designFile.components) {
            // Auto-save when components change
            saveDocument()
        }
    }
    
    private func loadDocument() {
        // Set the design file as current in the design manager
        designManager.openDesign(document.designFile)
        isLoaded = true
    }
    
    private func saveDocument() {
        // Save the document using the design manager
        designManager.saveCurrentDesign()
        print("💾 Document saved: \(document.designFile.name)")
    }
}

// MARK: - UTType Extension
extension UTType {
    static var dockui: UTType {
        UTType(exportedAs: "com.maicol.dockui")
    }
}
