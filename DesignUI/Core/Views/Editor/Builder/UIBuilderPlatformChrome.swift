import SwiftUI

#if os(iOS)
struct BuilderFloatingPanelsChrome<MainContent: View, SidebarContent: View, PropertiesContent: View>: View {
    let panelWidth: CGFloat
    let showSidebar: Bool
    let showProperties: Bool
    @ViewBuilder let mainContent: () -> MainContent
    @ViewBuilder let sidebarContent: () -> SidebarContent
    @ViewBuilder let propertiesContent: () -> PropertiesContent

    var body: some View {
        ZStack {
            mainContent()

            HStack(spacing: 0) {
                if showSidebar {
                    sidebarContent()
                        .frame(width: panelWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        .padding()
                }

                Spacer()

                if showProperties {
                    propertiesContent()
                        .frame(width: panelWidth)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                        .padding()
                }
            }
        }
    }
}

struct BuilderPhoneCanvasChrome<CanvasContent: View>: View {
    @ViewBuilder let canvasContent: () -> CanvasContent

    var body: some View {
        GeometryReader { _ in
            ZStack {
                canvasContent()
            }
        }
    }
}
#endif
