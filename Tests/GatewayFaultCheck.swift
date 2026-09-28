import Foundation

@main struct GatewayFaultCheck {
    @MainActor static func main() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let delayed = env["HELIOS_DELAYED_ENDPOINT"], let retry = env["HELIOS_RETRY_ENDPOINT"],
              let token = env["HELIOS_GATEWAY_TOKEN"] else { fatalError("Fault fixture environment is required") }
        let connection = LiveConnection()
        let access = DeveloperAccess()
        await access.verify()
        connection.setDeveloperMode(true, access: access)
        precondition(connection.developerMode)
        connection.connect(endpoint: delayed, token: token)
        try await waitUntil { connection.status == .connected }
        guard let snapshot = connection.snapshot, let baseline = connection.receivedAt else { fatalError("No response") }
        precondition(!snapshot.odometry.isFresh(receivedAt: baseline, now: .now))
        precondition(!snapshot.scan.isFresh(receivedAt: baseline, now: .now))
        connection.disconnect()
        print("PASS: a three-second network delay cannot make expired samples look fresh")
        connection.connect(endpoint: retry, token: token)
        try await waitUntil { connection.status == .disconnected }
        precondition(connection.snapshot == nil && connection.isEnabled)
        try await waitUntil { connection.status == .connected }
        precondition(connection.snapshot != nil)
        connection.disconnect()
        print("PASS: unavailable gateway clears telemetry and reconnects automatically when it starts")
    }

    @MainActor static func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<250 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        preconditionFailure("Timed out waiting for fault-recovery state")
    }
}
