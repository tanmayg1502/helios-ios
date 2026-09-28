import SwiftUI

struct RobotView: View {
    var body: some View {
        List {
            Section {
                HeliosSectionHeading(title: "Meet Helios.", eyebrow: "Robot / Hardware")
                Label("Gateway API v1", systemImage: "cable.connector")
                    .foregroundStyle(HeliosTheme.cyan)
                Text("Deploy the companion mobile_gateway package on the Jetson, then open Connect for authenticated odometry and lidar. Hardware commissioning is still required.")
            }
            Section("Helios hardware") {
                LabeledContent("Computer", value: "Jetson AGX Orin")
                LabeledContent("Platform", value: "ROS 2 Jazzy")
                LabeledContent("Drive", value: "4-wheel mecanum")
                LabeledContent("Laser", value: "Hokuyo UST-10LX")
                LabeledContent("Camera", value: "ZED 2i")
                LabeledContent("Motor controllers", value: "2 × RoboClaw")
            }
            Section("Integration reference") {
                LabeledContent("Fused pose", value: "/odometry/filtered")
                LabeledContent("Laser scan", value: "/scan")
                LabeledContent("Velocity command", value: "/cmd_vel")
                Text("These are ROS topic names, not web endpoints. API v1 relays odometry and a lidar summary over authenticated HTTPS. Live map transforms are not available. Operation controls use the gateway’s allowlisted catalog.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Project") {
                Link("Open Helios source", destination: URL(string: "https://github.com/pran99-git/helios_ws")!)
            }
        }
        .heliosScreen()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Robot")
    }
}
