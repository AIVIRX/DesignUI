import SwiftUI

struct StudioCanvas: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(radius: 8)
            Text("Canvas Preview")
                .font(.title)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(minWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StudioCanvas_Previews: PreviewProvider {
    static var previews: some View {
        StudioCanvas()
            .frame(width: 800, height: 600)
    }
} 
