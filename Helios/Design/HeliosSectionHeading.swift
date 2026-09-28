import SwiftUI

struct HeliosSectionHeading: View {
    let title: String
    var eyebrow: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.caption.bold()).tracking(2)
                    .foregroundStyle(HeliosTheme.muted)
            }
            Text(title).font(.largeTitle.bold()).fontDesign(.rounded)
        }
        .accessibilityAddTraits(.isHeader)
    }
}
