import Foundation

/// Runs the shared transport compiled with DEBUG enabled against three local adversarial fixture servers.
@main struct GatewayModeCheck {
    static func main() async throws {
        let arguments = CommandLine.arguments
        precondition(arguments.count == 4, "Expected mismatch, delayed and dropped-response endpoints")
        let token = String(repeating: "a", count: 32)
        let mismatch = try GatewayClient(endpoint: arguments[1], token: token, dataMode: .fixture)
        do {
            let _: ControlLeaseResponse = try await mismatch.request(path: "v1/control/acquire", method: "POST")
            preconditionFailure("Mismatched gateway accepted mutation")
        } catch GatewayError.dataModeMismatch {
            print("PASS: source mismatch rejected before mutation")
        }

        let delayed = try GatewayClient(endpoint: arguments[2], token: token, dataMode: .fixture)
        let scope = GatewayRequestScope()
        let pending = Task {
            let _: ControlLeaseResponse = try await delayed.request(path: "v1/control/acquire", method: "POST", scope: scope)
        }
        // Wait for proof that the preflight is in flight, rather than timing cancellation.
        var started = false
        for _ in 0..<100 {
            let (data, _) = try await URLSession.shared.data(from: URL(string: arguments[2] + "/started")!)
            if String(decoding: data, as: UTF8.self) == "yes" { started = true; break }
            try await Task.sleep(for: .milliseconds(20))
        }
        precondition(started, "Delayed preflight never started")
        scope.cancel()
        // Release the delayed server response only after scope cancellation.
        _ = try await URLSession.shared.data(from: URL(string: arguments[2] + "/release")!)
        do {
            try await pending.value
            preconditionFailure("Cancelled request completed")
        } catch is CancellationError {
            print("PASS: cancelled preflight prevented mutation")
        } catch let error as URLError where error.code == .cancelled {
            print("PASS: cancelled preflight prevented mutation")
        }

        let dropped = try GatewayClient(endpoint: arguments[3], token: token, dataMode: .fixture)
        do {
            let _: ControlLeaseResponse = try await dropped.request(path: "v1/control/acquire", method: "POST", body: Data("{}".utf8))
            preconditionFailure("Dropped response unexpectedly succeeded")
        } catch is URLError {
            print("PASS: dropped mutation response preserved transport failure")
        }
    }
}
