import SwiftUI

struct DashboardView: View {
    @Bindable var session: DemoSession
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: HeliosTheme.spacing) {
                DemoBanner()
                HeliosSectionHeading(title: "Built to explore.", eyebrow: "Helios / Overview")
                Text("Pranav’s indoor explorer. Four mecanum wheels, laser mapping, and stereo vision.")
                    .foregroundStyle(HeliosTheme.muted)
                HeliosRoverIllustration()
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), alignment: .top), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: 12) {
                    HeliosMetric(title: "Forward speed", value: formatted(session.telemetry.speed), unit: "m/s")
                    HeliosMetric(title: "Yaw rate", value: formatted(session.telemetry.yawRate), unit: "rad/s", accent: HeliosTheme.cyan)
                }
                VStack(alignment: .leading, spacing: 16) {
                    Label("SAMPLE POSITION", systemImage: "location.north.line")
                        .font(.caption.bold()).tracking(2).foregroundStyle(HeliosTheme.muted)
                    LabeledContent("X position", value: "\(formatted(session.telemetry.x)) m")
                    LabeledContent("Y position", value: "\(formatted(session.telemetry.y)) m")
                    Divider()
                    Text("Synthetic values in an illustrative odom frame. Pausing freezes the sample; it does not stop a robot.")
                        .font(.footnote).foregroundStyle(HeliosTheme.muted)
                }.heliosCard()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Explore the demo").font(.title3.bold())
                    Toggle("Play sample telemetry", isOn: $session.isPlaying)
                    LabeledContent("Sample time", value: "\(session.elapsed.formatted(.number.precision(.fractionLength(1)))) s")
                    Button("Reset sample", systemImage: "arrow.counterclockwise", action: session.reset)
                        .buttonStyle(.bordered).frame(minHeight: 44)
                }.heliosCard()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Onboard capabilities").font(.title3.bold())
                    Label("Wheel + camera + IMU fusion", systemImage: "sensor")
                    Label("2D laser mapping", systemImage: "map")
                    Label("Stereo depth perception", systemImage: "camera")
                    Text("Autonomous navigation is configured upstream, but a full drive to a goal has not been validated there.")
                        .font(.footnote).foregroundStyle(HeliosTheme.muted)
                }.heliosCard()
            }.padding(HeliosTheme.spacing)
        }
        .heliosScreen()
        .navigationTitle("Helios")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatted(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }
}
