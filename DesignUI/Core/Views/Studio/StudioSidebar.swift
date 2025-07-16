import SwiftUI

struct StudioSidebar: View {
    @State private var searchText = ""
    let components = ["Text", "Image", "Button", "VStack", "HStack"]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Components")
                .font(.title2)
                .bold()
                .padding(.top)
            TextField("Search components", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical)
            List {
                ForEach(components.filter { searchText.isEmpty ? true : $0.localizedCaseInsensitiveContains(searchText) }, id: \.self) { component in
                    Label(component, systemImage: "square.grid.2x2")
                        .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
            Spacer()
        }
        .padding()
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct StudioSidebar_Previews: PreviewProvider {
    static var previews: some View {
        StudioSidebar()
    }
} 
