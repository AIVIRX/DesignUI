import SwiftUI

struct CustomBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    
    // Configuration
    private let heightRatio: CGFloat = 0.5 // 50% of screen height
    private let handleHeight: CGFloat = 5
    private let handleWidth: CGFloat = 40
    private let cornerRadius: CGFloat = 16
    
    @GestureState private var translation: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let sheetHeight = screenHeight * heightRatio
            
            ZStack(alignment: .bottom) {
                // Dimmed Background
                // Dimmed Background removed to allow interaction
                // if isPresented { ... }
                
                // Sheet Content
                if isPresented {
                    VStack(spacing: 0) {
                        // Drag Handle
                        VStack {
                            Capsule()
                                .fill(Color.secondary.opacity(0.5))
                                .frame(width: handleWidth, height: handleHeight)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(maxWidth: .infinity)
                        .background(backgroundColor)
                        
                        // Main Content
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: sheetHeight)
                    .frame(height: sheetHeight)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                    .offset(y: max(0, offset + translation))
                    .transition(.move(edge: .bottom))
                    .gesture(
                        DragGesture()
                            .updating($translation) { value, state, _ in
                                state = value.translation.height
                            }
                            .onEnded { value in
                                let snapDistance = sheetHeight * 0.25
                                if value.translation.height > snapDistance || value.velocity.height > 1000 {
                                    offset = value.translation.height // Capture current position
                                    withAnimation(.spring()) {
                                        isPresented = false
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        offset = 0
                                    }
                                }
                            }
                    )
                    .onAppear {
                        offset = 0
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var backgroundColor: Color {
        #if os(iOS)
        return Color(uiColor: .systemBackground)
        #else
        return Color(NSColor.windowBackgroundColor)
        #endif
    }
}
