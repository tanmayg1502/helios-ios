import Foundation
import Testing
@testable import Helios

struct OperationsTests {
    @Test func parametersKeepWireTypes() throws {
        let input: [String: OperationValue] = ["camera": .bool(false), "x": .number(2.5), "map": .string("lab_map"), "unset": .null]
        let body = try JSONEncoder().encode(OperationStartRequest(clientID: "test", requestID: "intent", parameters: input, confirm: true))
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let parameters = try #require(json["parameters"] as? [String: Any])
        #expect(parameters["camera"] as? Bool == false)
        #expect(parameters["x"] as? Double == 2.5)
        #expect(parameters["map"] as? String == "lab_map")
        #expect(parameters["unset"] is NSNull)
        #expect(json["confirm"] as? Bool == true)
        #expect(json["request_id"] as? String == "intent")
    }

    @Test func cancelledScopeRejectsLaterRequests() async throws {
        let scope = GatewayRequestScope()
        scope.cancel()
        let client = try GatewayClient(endpoint: "https://localhost:1", token: String(repeating: "a", count: 32))
        do {
            let _: ControlLeaseResponse = try await client.request(path: "v1/control/heartbeat", method: "POST", scope: scope)
            Issue.record("Cancelled scope sent a request")
        } catch is CancellationError {
            // Request was rejected before transport, without a connection attempt.
        } catch {
            Issue.record("Unexpected error instead of immediate cancellation: \(error)")
        }
    }

    @Test @MainActor func disconnectedSessionCannotAcquireOrMutate() async {
        let session = OperationsSession()
        await session.acquireControl()
        await session.stopAll()
        #expect(!session.hasControl)
        #expect(!session.isBusy)
        #expect(session.jobs.isEmpty)
        #expect(!session.commandsEnabled)
    }
}
