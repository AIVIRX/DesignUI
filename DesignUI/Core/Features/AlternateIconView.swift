import SwiftUI

struct AlternateIconView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIcon: String?
    
    private let icons = [
        ("Default", nil, "AppLogo"),
        ("Blue", "AppIcon2", "AppLogoBlue")
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(icons, id: \.0) { name, iconName, preview in
                    HStack {
                        Image(preview)
                            .resizable()
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                        
                        Text(name)
                            .padding(.leading)
                        
                        Spacer()
                        
                        if selectedIcon == iconName {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        UIApplication.shared.setAlternateIconName(iconName) { _ in
                            selectedIcon = iconName
                        }
                    }
                }
            }
            .navigationTitle("App Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") {
                    dismiss()
                }
            }
            .onAppear {
                selectedIcon = UIApplication.shared.alternateIconName
            }
        }
    }
}

#Preview {
    AlternateIconView()
} 