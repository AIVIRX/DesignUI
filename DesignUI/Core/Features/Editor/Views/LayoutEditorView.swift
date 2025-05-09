import SwiftUI

struct LayoutEditorView: View {
    @StateObject private var viewModel = LayoutEditorViewModel(rootComponent: LayoutEditorViewModel.exampleLayout)
    @State private var showJSONPreview = false
    
    var body: some View {
        VStack {
            HStack {
                Button("Show JSON") {
                    showJSONPreview.toggle()
                }
                .padding()
                
                Spacer()
            }
            
            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                
                ComponentRenderer(component: viewModel.rootComponent)
            }
        }
        .sheet(isPresented: $showJSONPreview) {
            if let jsonString = try? viewModel.saveToJSON() {
                ScrollView {
                    Text(jsonString)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
            }
        }
    }
}

struct LayoutEditorView_Previews: PreviewProvider {
    static var previews: some View {
        LayoutEditorView()
    }
} 