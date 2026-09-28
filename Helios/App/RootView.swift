import SwiftUI

struct RootView: View {
    @State private var session = DemoSession()
    @State private var connection = LiveConnection()
    @State private var developerAccess = DeveloperAccess()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            if connection.developerMode {
                Label("DEVELOPER MODE • Simulation only", systemImage: "testtube.2")
                    .font(.footnote.bold())
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(HeliosTheme.orange.opacity(0.2))
            }
            TabView {
                Tab("Overview", systemImage: "antenna.radiowaves.left.and.right") {
                    NavigationStack {
                        if !connection.developerMode || connection.useLive { LiveDashboardView(connection: connection) }
                        else { DashboardView(session: session) }
                    }
                }
                Tab("Operations", systemImage: "switch.2") {
                    NavigationStack { OperationsView(session: connection.operations) }
                }
                Tab("Map", systemImage: "map") {
                    NavigationStack {
                        if connection.developerMode { MapView(session: session) }
                        else {
                            ContentUnavailableView("Live map unavailable", systemImage: "map",
                                description: Text("The gateway does not provide a captured map yet. No map is being displayed."))
                                .navigationTitle("Map")
                                .heliosScreen()
                        }
                    }
                }
                Tab("Connect", systemImage: "network") {
                    NavigationStack { ConnectionView(connection: connection, developerAccess: developerAccess) }
                }
                Tab("Robot", systemImage: "shippingbox") {
                    NavigationStack { RobotView() }
                }
            }
        }
        .tint(HeliosTheme.lime)
        .preferredColorScheme(.dark)
        .task { await developerAccess.verify() }
        .task(id: connection.developerMode) {
            session.reset()
            if connection.developerMode { await session.run() }
        }
        .onChange(of: connection.developerMode) { _, _ in session.reset() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                session.reset()
                if connection.developerMode {
                    connection.setDeveloperMode(false, access: developerAccess)
                }
            }
            connection.setActive(phase == .active)
        }
    }
}
