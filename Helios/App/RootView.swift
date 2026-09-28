import SwiftUI

struct RootView: View {
    @State private var session = DemoSession()
    @State private var connection = LiveConnection()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            Tab("Overview", systemImage: "antenna.radiowaves.left.and.right") {
                NavigationStack {
                    if connection.useLive { LiveDashboardView(connection: connection) }
                    else { DashboardView(session: session) }
                }
            }
            Tab("Operations", systemImage: "switch.2") {
                NavigationStack { OperationsView(session: connection.operations) }
            }
            Tab("Map", systemImage: "map") {
                NavigationStack { MapView(session: session) }
            }
            Tab("Connect", systemImage: "network") {
                NavigationStack { ConnectionView(connection: connection) }
            }
            Tab("Robot", systemImage: "shippingbox") {
                NavigationStack { RobotView() }
            }
        }
        .tint(HeliosTheme.lime)
        .preferredColorScheme(.dark)
        .task { await session.run() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.isPlaying = false }
            connection.setActive(phase == .active)
        }
    }
}
