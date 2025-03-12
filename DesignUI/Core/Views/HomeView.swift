import SwiftUI

struct HomeView: View {
    @Namespace private var animation
    // ... your other properties ...

    var body: some View {
        ScrollView {
            LazyVGrid(columns: /* your grid items */) {
                ForEach(/* your data source */) { design in
                    DesignCards(
                        id: design.id,
                        media: design.media,
                        title: design.title,
                        authorName: design.authorName,
                        isVerified: design.isVerified,
                        description: design.description,
                        codeSnippet: design.codeSnippet,
                        published: design.published,
                        likesCount: design.likesCount,
                        isLiked: design.isLiked,
                        namespace: animation
                    )
                }
            }
        }
    }
} 