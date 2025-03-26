//
//  AlternateIcon.swift
//  DesignUI
//
//  Created by Maicol Cabreja on 3/6/25.
//

import SwiftUI

enum AppIcon: String, CaseIterable {
    case appIcon = "Default"
    case appIcon2 = "AppIcon2"
    case appIcon3 = "AppIcon3"
    case appIcon4 = "AppIcon4"
    case appIcon5 = "AppIcon5"
    case appIcon6 = "AppIcon6"
    case appIcon7 = "AppIcon7"
    case appIcon8 = "AppIcon8"
    case appIcon9 = "AppIcon9"
    
    var iconValue: String?{
        if self == .appIcon{
            return nil
        } else {
            return rawValue
        }
    }
    
    var previewImage: String {
        switch self {
        case .appIcon: "AppLogo"
        case .appIcon2: "AppLogo2"
        case .appIcon3: "AppLogo3"
        case .appIcon4: "AppLogo4"
        case .appIcon5: "AppLogo5"
        case .appIcon6: "AppLogo6"
        case .appIcon7: "AppLogo7"
        case .appIcon8: "AppLogo8"
        case .appIcon9: "AppLogo9"
        }
    }
    
    var displayName: String {
        switch self {
        case .appIcon: return "Default"
        case .appIcon2: return "Black"
        case .appIcon3: return "Purple"
        case .appIcon4: return "Red"
        case .appIcon5: return "Green"
        case .appIcon6: return "Orange"
        case .appIcon7: return "Yellow"
        case .appIcon8: return "Pink"
        case .appIcon9: return "Silver"
        }
    }
}

struct AlternateIconView: View {
    @State private var currentAppIcon: AppIcon = .appIcon
    var body: some View{
        NavigationStack{
            List {
                ForEach(AppIcon.allCases, id: \.rawValue) { icon in
                    HStack(spacing: 15){
                        Image(icon.previewImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height:  60)
                            .clipShape(.rect(cornerRadius: 10))
                        
                        Text(icon.displayName)
                            .fontWeight(.semibold)
                        
                        Spacer(minLength: 0)
                        
                        Image(systemName: currentAppIcon == icon ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(currentAppIcon == icon ? .green : Color.primary)
                    }
                    .contentShape(.rect)
                    .onTapGesture{
                        currentAppIcon = icon
#if os(iOS)
                        HapticManager.shared.triggerImpact(style: .medium)
                        UIApplication.shared.setAlternateIconName(icon.iconValue)
#endif
                    }
                }
            }
            .navigationTitle("App Icons")
        }
        .onAppear {
#if os(iOS)
            if let alternateAppIcon = UIApplication.shared.alternateIconName, let appIcon = AppIcon.allCases.first(where: { $0.rawValue == alternateAppIcon }){
                currentAppIcon = appIcon
            }
            else {
                currentAppIcon = .appIcon
            }
#endif
            
        }
    }
}
