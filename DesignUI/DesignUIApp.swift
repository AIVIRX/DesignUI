//
//  DesignUIApp.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 6/12/24.
//

import SwiftUI
import Supabase
import UniformTypeIdentifiers

// MARK: - Custom UTType Extension
extension UTType {
    static var dockui: UTType {
        UTType(importedAs: "com.designui.dockui")
    }
}

#if os(iOS)

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
                UserDefaults.standard.set(0, forKey: "selectedIndex")
        
        return true
    }
}

@main
struct DesignUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let client = SupabaseManager.shared.client
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var designManager = DesignManager.shared
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    init() {
        hasRequestedReview = false // Reset at the start of every app session
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .environmentObject(designManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .onAppear {
                    print("App launched with color scheme: \(colorSchemeManager.currentScheme.displayName)")
                }
        }
    }
}
#endif

#if os(macOS)

// MARK: - Document Model
struct DockUIDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.dockui] }
    
    var designFile: DesignFile
    
    init(designFile: DesignFile) {
        self.designFile = designFile
    }
    
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let designData = try decoder.decode(DesignFileData.self, from: data)
        
        // Create a temporary URL for the design file
        // The actual file URL will be set when the document is saved
        let tempURL = URL(fileURLWithPath: "/tmp/\(designData.name).dockui")
        
        self.designFile = DesignFile(
            name: designData.name,
            components: designData.components,
            fileURL: tempURL
        )
        self.designFile.lastModified = designData.lastModified
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(DesignFileData(
            name: designFile.name,
            components: designFile.components,
            lastModified: designFile.lastModified
        ))
        
        return .init(regularFileWithContents: data)
    }
}

@main
struct DesignUIApp: App {
    @StateObject private var colorSchemeManager = ColorSchemeManager()
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var designManager = DesignManager.shared
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false
    
    init() {
        hasRequestedReview = false // Reset at the start of every app session
        UserDefaults.standard.set(0, forKey: "selectedIndex")
    }
    
    var body: some Scene {
        // Main app window - this opens by default
        WindowGroup("DesignUI") {
            ContentView()
                .environmentObject(colorSchemeManager)
                .environmentObject(toastManager)
                .environmentObject(designManager)
                .preferredColorScheme(colorSchemeManager.currentScheme.colorScheme)
                .frame(minWidth: 1000, minHeight: 600)
                .onAppear {
                    print("🚀 App launched with color scheme: \(colorSchemeManager.currentScheme.displayName)")
                    print("📁 Designs directory: \(designManager.designsDirectory.path)")
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    print("🛑 App terminating - saving current design")
                    designManager.saveCurrentDesign()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    print("🔄 App became active - refreshing design list")
                    designManager.loadDesignFiles()
                }
        }
        .windowStyle(DefaultWindowStyle())
        .windowResizability(.automatic)
    }
}
#endif
