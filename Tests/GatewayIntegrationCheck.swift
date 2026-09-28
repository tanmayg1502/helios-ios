import Foundation

/// Runs the app's actual URLSession client and connection controller against the gateway fixture.
@main struct GatewayIntegrationCheck {
    @MainActor static func main() async throws {
        let environment = ProcessInfo.processInfo.environment
        guard let endpoint = environment["HELIOS_TEST_ENDPOINT"], let token = environment["HELIOS_GATEWAY_TOKEN"] else {
            fatalError("Set HELIOS_TEST_ENDPOINT and HELIOS_GATEWAY_TOKEN for the local fixture.")
        }
        let client = try GatewayClient(endpoint: endpoint, token: token)
        let snapshot = try await client.fetch()
        precondition(snapshot.apiVersion == 1 && snapshot.odometry.available && snapshot.scan.available)
        precondition(snapshot.odometry.x != nil && snapshot.scan.nearestM != nil)
        print("PASS: authenticated production URLSession client decodes gateway odometry and scan")
        do {
            _ = try await GatewayClient(endpoint: endpoint, token: String(repeating: "x", count: 32)).fetch()
            fatalError("Wrong token was accepted")
        } catch GatewayError.unauthorized { print("PASS: wrong token rejected") }

        let connection = LiveConnection()
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
        try await waitUntil { connection.status == .connected }
        connection.disconnect()
        print("PASS: failed auth clears readings; corrected credentials reconnect")
    }

    @MainActor static func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<100 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        preconditionFailure("Timed out waiting for connection state")
    }
}
