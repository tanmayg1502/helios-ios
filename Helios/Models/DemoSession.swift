import Foundation
import Observation

@MainActor @Observable
final class DemoSession {
    var isPlaying = false
    private(set) var elapsed = 0.0
    var telemetry: Telemetry { .demo(at: elapsed) }

    func reset() {
        isPlaying = false
        elapsed = 0
    }

    func advance() {
        guard isPlaying else { return }
        elapsed += 0.1
    }

    func run() async {
        while !Task.isCancelled {
            do { try await Task.sleep(for: .milliseconds(100)) }
            catch { return }
            advance()
        }
    }
}
