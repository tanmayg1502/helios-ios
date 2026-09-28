import SwiftUI

struct DemoBanner: View {
    var body: some View {
        Label("DEMO • Simulated data", systemImage: "play.rectangle")
            .font(.subheadline.bold())
            .foregroundStyle(HeliosTheme.orange)
            .padding(.vertical, 10).padding(.horizontal, 14)
            .background(HeliosTheme.orange.opacity(0.10), in: .capsule)
            .accessibilityLabel("Demo content. All readings and geometry on this screen are simulated.")
    }
}
