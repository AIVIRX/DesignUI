import SwiftUI

struct StudioInspector: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Inspector")
                .font(.title2)
                .bold()
                .padding(.top)
            Divider()
            Text("Select a component to edit its properties.")
                .foregroundColor(.secondary)
                .padding(.top)
            Spacer()
        }
        .padding()
        .frame(minWidth: 220, idealWidth: 260, maxWidth: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct StudioInspector_Previews: PreviewProvider {
    static var previews: some View {
        StudioInspector()
    }
} 
