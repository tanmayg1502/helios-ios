import SwiftUI

struct HeliosMetric: View {
    let title: String
    let value: String
    let unit: String
    var accent: Color = HeliosTheme.lime

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline).foregroundStyle(HeliosTheme.muted)
            Text(value).font(.largeTitle.bold()).fontDesign(.rounded)
                .monospacedDigit().foregroundStyle(accent)
            Text(unit).font(.subheadline).foregroundStyle(HeliosTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .heliosCard()
        .accessibilityElement(children: .combine)
    }
}
