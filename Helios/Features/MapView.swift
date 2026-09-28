import SwiftUI

struct MapView: View {
    @Bindable var session: DemoSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                DemoBanner()
                HeliosSectionHeading(title: "An indoor expedition.", eyebrow: "Helios / Mapping")
                MapCanvas(telemetry: session.telemetry)
                    .aspectRatio(1, contentMode: .fit)
                Text("Illustrative room and circular route • 8 × 8 meters")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Play sample route", isOn: $session.isPlaying)
                Button("Reset sample", systemImage: "arrow.counterclockwise", action: session.reset)
                Text("This is a generated preview, not a captured map. A live view needs occupancy-grid data and the map-to-robot transform from an approved gateway.")
                    .foregroundStyle(.secondary)
            }.padding(HeliosTheme.spacing)
        }
        .heliosScreen()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Mapping")
    }
}
