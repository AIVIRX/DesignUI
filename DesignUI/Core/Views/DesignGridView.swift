import SwiftUI

struct DesignGridView: View {
    @Namespace private var animation
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(designs) { design in
                    DesignCard(
                        id: design.id,
                        mediaURL: design.mediaURL,
                        title: design.title,
                        author: design.author,
                        isAuthorVerified: design.isAuthorVerified,
                        namespace: animation
                    )
                }
            }
            .padding()
        }
    }
} 