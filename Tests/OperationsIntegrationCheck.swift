import Foundation

/// This test refuses to acquire control unless the gateway explicitly identifies itself as a fixture.
@main struct OperationsIntegrationCheck {
    @MainActor static func main() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let endpoint = env["HELIOS_TEST_ENDPOINT"], let token = env["HELIOS_GATEWAY_TOKEN"] else {
            fatalError("Fixture endpoint and token are required")
        }
        let client = try GatewayClient(endpoint: endpoint, token: token)
        let initial: OperationCatalog = try await client.request(path: "v1/operations")
        precondition(initial.source == "fixture" && initial.commandsEnabled, "Only a simulated fixture may be tested")
        let session = OperationsSession()
        session.connect(client)
        try await waitUntil { session.isConnected && session.catalog.count >= 20 }
        await session.acquireControl()
        precondition(session.hasControl)
        let motors = try operation("motors", session)
        await session.run(motors, parameters: [:], confirmed: false)
        precondition(!session.jobs.contains { $0.operationID == "motors" && $0.isActive })
        await session.run(motors, parameters: [:], confirmed: true)
        precondition(session.jobs.contains { $0.operationID == "motors" && $0.isActive && $0.simulated })
        await session.run(try operation("sensors", session), parameters: [:], confirmed: true)
        await session.run(try operation("slam_mapping", session), parameters: [:], confirmed: true)
        await session.run(try operation("joystick", session), parameters: [:], confirmed: true)
        await session.run(try operation("navigation", session), parameters: [:], confirmed: true)
        precondition(!session.jobs.contains { $0.operationID == "navigation" && $0.isActive })
        precondition(session.commandOutcome?.contains("conflict") == true || session.commandOutcome?.contains("joystick") == true)
        let conflict = session.commandOutcome
        try await Task.sleep(for: .seconds(4))
        precondition(session.commandOutcome == conflict, "Heartbeat must not overwrite command outcome")
        guard let motorJob = session.jobs.first(where: { $0.operationID == "motors" && $0.isActive }) else { fatalError("Missing motor fixture job") }
        await session.stop(motorJob)
        precondition(session.jobs.contains { $0.id == motorJob.id && $0.isActive })
        await session.stopAll()
        try await waitUntil { !session.jobs.contains(where: \.isActive) }
        print("PASS: catalog, explicit lease, confirmation, simulated start, conflict/dependency rejection, durable outcome, ordered stop-all")
        await session.run(motors, parameters: [:], confirmed: true)
        precondition(session.jobs.contains { $0.operationID == "motors" && $0.isActive })
        session.setActive(false)
        precondition(!session.hasControl && !session.isConnected)
        try await Task.sleep(for: .seconds(12))
        let expired: OperationCatalog = try await client.request(path: "v1/operations")
        precondition(expired.lease.clientID == nil && !expired.jobs.contains(where: \.isActive))
        session.setActive(true)
        try await waitUntil { session.isConnected }
        precondition(!session.hasControl, "Foreground resume must not silently reacquire control")
        session.disconnect()
        print("PASS: backgrounding drops lease, gateway shuts down simulated jobs, resume requires explicit reacquisition")
    }

    @MainActor static func operation(_ id: String, _ session: OperationsSession) throws -> RobotOperation {
        guard let operation = session.catalog.first(where: { $0.id == id }) else { throw GatewayError.invalidData }
        return operation
    }

    @MainActor static func waitUntil(_ predicate: () -> Bool) async throws {
        for _ in 0..<150 {
            if predicate() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        preconditionFailure("Timed out waiting for operations state")
    }
}
