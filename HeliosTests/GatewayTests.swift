import Foundation
import Testing
@testable import Helios

struct GatewayTests {
    @Test func endpointAndCredentialValidation() throws {
        let token = String(repeating: "a", count: 32)
        #expect(throws: GatewayError.self) { try GatewayClient(endpoint: "http://192.168.1.2:8080", token: token) }
        #expect(throws: GatewayError.self) { try GatewayClient(endpoint: "https://robot.example?token=secret", token: token) }
        #expect(throws: GatewayError.self) { try GatewayClient(endpoint: "https://user:secret@robot.example", token: token) }
        #expect(throws: GatewayError.self) { try GatewayClient(endpoint: "https://robot.example/path", token: token) }
        #expect(throws: GatewayError.self) { try GatewayClient(endpoint: "https://robot.example", token: "short") }
        let client = try GatewayClient(endpoint: "https://robot.example/", token: token)
        #expect(client.endpoint.absoluteString == "https://robot.example/v1/telemetry")
    }

    @Test func freshnessIncludesTimeSinceReception() throws {
        let data = Data("""
        {"api_version":1,"odometry":{"available":true,"age_seconds":0.5,"frame_id":"odom","child_frame_id":"base_link","x":1,"y":2,"heading":0,"linear_x":0.2,"linear_y":0,"angular_z":0},"scan":{"available":false}}
        """.utf8)
        let snapshot = try JSONDecoder().decode(GatewaySnapshot.self, from: data).validated()
        let received = ContinuousClock.now
        #expect(snapshot.odometry.isFresh(receivedAt: received, now: received.advanced(by: .seconds(1))))
        #expect(!snapshot.odometry.isFresh(receivedAt: received, now: received.advanced(by: .seconds(2))))
        #expect(!snapshot.scan.isFresh(receivedAt: received, now: received))
    }

    @Test func extremelyLargeAgeIsStaleWithoutDurationOverflow() throws {
        let data = Data("""
        {"available":true,"age_seconds":1e300,"frame_id":"laser","nearest_m":1.2}
        """.utf8)
        let scan = try JSONDecoder().decode(GatewayScan.self, from: data)
        let now = ContinuousClock.now
        #expect(!scan.isFresh(receivedAt: now, now: now))
    }

    @Test func incompleteAvailableDataAndVersionAreRejected() throws {
        for json in [
            "{\"api_version\":2,\"odometry\":{\"available\":false},\"scan\":{\"available\":false}}",
            "{\"api_version\":1,\"odometry\":{\"available\":true},\"scan\":{\"available\":false}}"
        ] {
            let snapshot = try JSONDecoder().decode(GatewaySnapshot.self, from: Data(json.utf8))
            #expect(throws: GatewayError.self) { try snapshot.validated() }
        }
    }

    @Test @MainActor func failedConfigurationAndDemoNeverShowLiveReadings() {
        let connection = LiveConnection()
        connection.connect(endpoint: "invalid", token: "short")
        #expect(connection.useLive)
        #expect(connection.status == .disconnected)
        #expect(connection.snapshot == nil)
        #expect(!connection.isEnabled)
        connection.showDemo()
        #expect(!connection.useLive)
        #expect(connection.snapshot == nil)
    }
}
