//
//  iCloudSyncIndicator.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 12/19/24.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct iCloudSyncIndicator: View {
#if os(iOS)
    let documentState: UIDocument.State
#elseif os(macOS)
    let documentState: NSDocument.State
#endif
    let isDownloading: Bool
    let downloadProgress: Float
    
    var body: some View {
        HStack(spacing: 4) {
            // Main status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.caption)
            
            // Download progress indicator
            if isDownloading {
                ProgressView(value: downloadProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(width: 20, height: 4)
            }
        }
    }
    
    private var statusIcon: String {
#if os(iOS)
        switch documentState {
        case .normal:
            return "icloud.fill"
        case .inConflict:
            return "exclamationmark.triangle.fill"
        case .savingError:
            return "exclamationmark.icloud.fill"
        case .editingDisabled:
            return "icloud.slash.fill"
        case .progressAvailable:
            return isDownloading ? "icloud.and.arrow.down" : "icloud.fill"
        default:
            return "icloud.fill"
        }
#elseif os(macOS)
        switch documentState {
        case .normal:
            return "icloud.fill"
        case .inConflict:
            return "exclamationmark.triangle.fill"
        case .savingError:
            return "exclamationmark.icloud.fill"
        case .editingDisabled:
            return "icloud.slash.fill"
        case .progressAvailable:
            return isDownloading ? "icloud.and.arrow.down" : "icloud.fill"
        default:
            return "icloud.fill"
        }
#endif
    }
    
    private var statusColor: Color {
#if os(iOS)
        switch documentState {
        case .normal:
            return .blue
        case .inConflict:
            return .orange
        case .savingError:
            return .red
        case .editingDisabled:
            return .gray
        case .progressAvailable:
            return isDownloading ? .blue : .green
        default:
            return .blue
        }
#elseif os(macOS)
        switch documentState {
        case .normal:
            return .blue
        case .inConflict:
            return .orange
        case .savingError:
            return .red
        case .editingDisabled:
            return .gray
        case .progressAvailable:
            return isDownloading ? .blue : .green
        default:
            return .blue
        }
#endif
    }
}

struct iCloudSyncStatusView: View {
    @ObservedObject var designManager: DesignManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: designManager.isUsingiCloud ? "icloud.fill" : "icloud.slash")
                    .foregroundColor(designManager.isUsingiCloud ? .blue : .gray)
                
                Text("iCloud Sync")
                    .font(.headline)
                
                Spacer()
                
                if designManager.isUsingiCloud {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Text(designManager.iCloudSyncStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if designManager.isUsingiCloud {
                HStack {
                    Text("Your files are securely stored in iCloud and sync across all your devices.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    VStack(spacing: 20) {
        iCloudSyncIndicator(
            documentState: .normal,
            isDownloading: false,
            downloadProgress: 0.0
        )
        
        iCloudSyncIndicator(
            documentState: .progressAvailable,
            isDownloading: true,
            downloadProgress: 0.6
        )
        
        iCloudSyncIndicator(
            documentState: .inConflict,
            isDownloading: false,
            downloadProgress: 0.0
        )
        
        iCloudSyncStatusView(designManager: DesignManager.shared)
    }
    .padding()
}
