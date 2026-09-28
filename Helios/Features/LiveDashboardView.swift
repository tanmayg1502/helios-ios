import SwiftUI

struct LiveDashboardView: View {
    let connection: LiveConnection

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            ScrollView {
                VStack(alignment: .leading, spacing: HeliosTheme.spacing) {
                VStack(alignment: .leading, spacing: 14) {
                    HeliosSectionHeading(title: "Rover overview", eyebrow: "Helios / Telemetry")
                    Label(connection.snapshot?.source == "fixture" ? "FIXTURE • Simulated data" : "GATEWAY DATA • Read-only", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.subheadline.bold()).foregroundStyle(HeliosTheme.cyan)
                    HeliosRoverIllustration()
                        .frame(maxHeight: 120)
                    Text(connection.status.rawValue).font(.headline)
                    Text(connection.detail).font(.caption).foregroundStyle(HeliosTheme.muted)
                }.heliosCard()
                if let snapshot = connection.snapshot, let received = connection.receivedAt {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Fused odometry", systemImage: "location.north.line").font(.title3.bold())
                        if snapshot.odometry.isFresh(receivedAt: received, now: .now) {
                            LabeledContent("Frame", value: snapshot.odometry.frameID ?? "Unknown")
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Odometry frame")
                                .accessibilityValue(snapshot.odometry.frameID ?? "Unknown")
                                .accessibilityIdentifier("odometryFrame")
                            LabeledContent("Body frame", value: snapshot.odometry.childFrameID ?? "Unknown")
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Odometry body frame")
                                .accessibilityValue(snapshot.odometry.childFrameID ?? "Unknown")
                                .accessibilityIdentifier("odometryBodyFrame")
                            TelemetryRow(title: "X", value: snapshot.odometry.x, unit: "m")
                            TelemetryRow(title: "Y", value: snapshot.odometry.y, unit: "m")
                            TelemetryRow(title: "Heading", value: snapshot.odometry.heading, unit: "rad")
                            TelemetryRow(title: "Forward velocity", value: snapshot.odometry.linearX, unit: "m/s")
                            TelemetryRow(title: "Lateral velocity", value: snapshot.odometry.linearY, unit: "m/s")
                            TelemetryRow(title: "Yaw rate", value: snapshot.odometry.angularZ, unit: "rad/s")
                        } else {
                            Label("Odometry unavailable or stale", systemImage: "clock.badge.exclamationmark")
                        }
                    }.heliosCard()
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Lidar", systemImage: "sensor").font(.title3.bold())
                        if snapshot.scan.isFresh(receivedAt: received, now: .now) {
                            LabeledContent("Frame", value: snapshot.scan.frameID ?? "Unknown")
                            TelemetryRow(title: "Nearest valid return", value: snapshot.scan.nearestM, unit: "m")
                            Text("A laser-plane reading, not a collision-clearance guarantee.")
                                .font(.footnote).foregroundStyle(.secondary)
                        } else {
                            Label("Lidar unavailable or stale", systemImage: "clock.badge.exclamationmark")
                        }
                    }.heliosCard()
                } else {
                    ContentUnavailableView("No live readings", systemImage: "antenna.radiowaves.left.and.right.slash", description: Text("Open Connect to configure or retry the gateway."))
                }
                }.padding(HeliosTheme.spacing)
            }.heliosScreen()
        }
        .navigationTitle("Helios")
        .navigationBarTitleDisplayMode(.inline)
    }
}
