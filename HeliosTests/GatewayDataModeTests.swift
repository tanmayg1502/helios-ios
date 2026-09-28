import Foundation
import Testing
@testable import Helios

struct GatewayDataModeTests {
    private var availableModes: [GatewayDataMode] {
        #if DEBUG || TESTFLIGHT_DEVELOPER_TOOLS
        [.robot, .fixture]
        #else
        [.robot]
        #endif
    }

    @Test func buildCapabilityGatesFixtureInitialization() throws {
        #if DEBUG || TESTFLIGHT_DEVELOPER_TOOLS
        _ = try client(.fixture)
        #else
        do {
            _ = try client(.fixture)
            Issue.record("Ordinary production build accepted fixture mode")
        } catch GatewayError.developerToolsUnavailable {
            // Build capability rejects fixtures before any endpoint can be used.
        }
        #endif
    }

    private func client(_ mode: GatewayDataMode = .robot) throws -> GatewayClient {
        try GatewayClient(endpoint: "https://robot.example", token: String(repeating: "a", count: 32), dataMode: mode)
    }

    private func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    @Test func robotModeRequiresHTTPSAndFixtureLocalhostIsExplicit() throws {
        let token = String(repeating: "a", count: 32)
        #expect(throws: GatewayError.self) { try GatewayClient(endpoint: "http://localhost:8080", token: token) }
        #if DEBUG || TESTFLIGHT_DEVELOPER_TOOLS
        _ = try GatewayClient(endpoint: "http://localhost:8080", token: token, dataMode: .fixture)
        #endif
        #expect(throws: GatewayError.self) {
            try GatewayClient(endpoint: "http://192.168.1.1:8080", token: token, dataMode: .fixture)
        }
    }

    @Test func telemetryRequiresExactModeIdentity() throws {
        for source in ["ros2", "fixture", "unknown", "ROS2", ""] {
            let snapshot = try decode("""
            {"api_version":1,"source":"\(source)","odometry":{"available":false},"scan":{"available":false}}
            """, as: GatewaySnapshot.self)
            for mode in availableModes {
                let gateway = try client(mode)
                if source == mode.expectedSource { _ = try gateway.validate(snapshot) }
                else { #expect(throws: GatewayError.self) { try gateway.validate(snapshot) } }
            }
        }
        let missing = try decode("""
        {"api_version":1,"odometry":{"available":false},"scan":{"available":false}}
        """, as: GatewaySnapshot.self)
        #expect(throws: GatewayError.self) { try client().validate(missing) }
        #if DEBUG || TESTFLIGHT_DEVELOPER_TOOLS
        #expect(throws: GatewayError.self) { try client(.fixture).validate(missing) }
        #endif
    }

    @Test func jobsAndMutationResultsCannotCrossModes() throws {
        for simulated in [false, true] {
            let job = """
            {"id":"job-1","operation_id":"mapping","state":"running","output":"","simulated":\(simulated)}
            """
            let single = try decode("{\"api_version\":1,\"job\":\(job)}", as: OperationJobResponse.self)
            let list = try decode("{\"api_version\":1,\"jobs\":[\(job)]}", as: OperationJobsResponse.self)
            for mode in availableModes {
                let gateway = try client(mode)
                if simulated == mode.expectsSimulatedJobs {
                    _ = try gateway.validate(single)
                    _ = try gateway.validate(list)
                } else {
                    #expect(throws: GatewayError.self) { try gateway.validate(single) }
                    #expect(throws: GatewayError.self) { try gateway.validate(list) }
                }
            }
        }
    }

    @Test func catalogIdentityAndEveryJobMustMatch() throws {
        for source in ["ros2", "fixture", "unknown"] {
            for simulated in [false, true] {
                let catalog = try decode("""
                {"api_version":1,"source":"\(source)","commands_enabled":true,
                 "lease":{"client_id":null,"remaining_seconds":0},"operations":[],
                 "jobs":[{"id":"job-1","operation_id":"mapping","state":"running","output":"","simulated":\(simulated)}]}
                """, as: OperationCatalog.self)
                for mode in availableModes {
                    let gateway = try client(mode)
                    if source == mode.expectedSource && simulated == mode.expectsSimulatedJobs {
                        _ = try gateway.validate(catalog)
                    } else {
                        #expect(throws: GatewayError.self) { try gateway.validate(catalog) }
                    }
                }
            }
        }
    }
}
