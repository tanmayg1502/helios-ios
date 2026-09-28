import SwiftUI

struct TelemetryRow: View {
    let title: String
    let value: Double?
    let unit: String

    var body: some View {
        LabeledContent(title) {
            if let value {
                Text("\(value.formatted(.number.precision(.fractionLength(2)))) \(unit)")
            } else {
                Text("No valid return")
            }
        }
    }
}
