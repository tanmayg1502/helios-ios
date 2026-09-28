import Foundation

/// Runs the app's actual URLSession client and connection controller against the gateway fixture.
@main struct GatewayIntegrationCheck {
    @MainActor static func main() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let endpoint = environment["HELIOS_TEST_ENDPOINT"], let token = environment["HELIOS_GATEWAY_TOKEN"] else {
            fatalError("Set HELIOS_TEST_ENDPOINT and HELIOS_GATEWAY_TOKEN for the local fixture.")
        }
        let client = try GatewayClient(endpoint: endpoint, token: token, dataMode: .fixture)
        let snapshot = try await client.fetch()
        precondition(snapshot.apiVersion == 1 && snapshot.odometry.available && snapshot.scan.available)
        precondition(snapshot.odometry.x != nil && snapshot.scan.nearestM != nil)
        print("PASS: authenticated shared URLSession client in fixture mode decodes gateway odometry and scan")
        do {
            _ = try await GatewayClient(endpoint: endpoint, token: String(repeating: "x", count: 32), dataMode: .fixture).fetch()
            fatalError("Wrong token was accepted")
        } catch GatewayError.unauthorized { print("PASS: wrong token rejected") }

        let connection = LiveConnection()
        let access = DeveloperAccess()
        await access.verify()
        connection.setDeveloperMode(true, access: access)
        precondition(connection.developerMode)
        connection.connect(endpoint: endpoint, token: token)
        try await waitUntil { connection.status == .connected }
        precondition(connection.snapshot != nil && connection.useLive)
        connection.setActive(false)
        precondition(connection.status == .paused && connection.snapshot == nil)
        connection.setActive(true)
        try await waitUntil { connection.status == .connected }
        connection.disconnect()
        precondition(connection.snapshot == nil && connection.status == .disconnected && !connection.isEnabled)
        try await Task.sleep(for: .milliseconds(200))
        precondition(connection.snapshot == nil)
        connection.showDemo()
        precondition(!connection.useLive)
        print("PASS: live connect, background pause, resume, disconnect cancellation, demo transition")

        connection.connect(endpoint: endpoint, token: String(repeating: "x", count: 32))
        try await waitUntil { connection.status == .disconnected && connection.detail.contains("Authentication") }
        precondition(connection.snapshot == nil)
        connection.connect(endpoint: endpoint, token: token)
        try await waitUntil { connection.status == .connected && connection.operations.isConnected }
        precondition(!connection.operations.catalog.isEmpty)
        await connection.operations.acquireControl()
        precondition(connection.operations.hasControl)
        connection.setDeveloperMode(false, access: access)
        precondition(!connection.developerMode && connection.useLive && !connection.isEnabled)
        precondition(connection.snapshot == nil && connection.operations.catalog.isEmpty && connection.operations.jobs.isEmpty)
        precondition(!connection.operations.hasControl && !connection.operations.commandsEnabled)
        try await Task.sleep(for: .milliseconds(200))
        precondition(connection.snapshot == nil && connection.operations.catalog.isEmpty)
        connection.showDemo()
        precondition(connection.useLive)
        print("PASS: failed auth recovery; populated mode transition clears readings/catalog/jobs/control and rejects demo reentry")
    }

    @MainActor static func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<100 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        preconditionFailure("Timed out waiting for connection state")
    }
}
