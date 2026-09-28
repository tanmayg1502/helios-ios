import Testing
@testable import Helios

struct DemoSessionTests {
    @Test @MainActor func playbackRequiresExplicitStartAndResetPauses() {
        let session = DemoSession()
        session.advance()
        #expect(session.elapsed == 0)
        session.isPlaying = true
        session.advance()
        #expect(session.elapsed == 0.1)
        session.reset()
        #expect(session.elapsed == 0)
        #expect(!session.isPlaying)
    }

    @Test func syntheticTrajectoryHasConsistentUnits() {
        let first = Telemetry.demo(at: 0)
        let second = Telemetry.demo(at: 0.001)
        #expect(abs(first.x - 2) < 0.00001)
        #expect(abs(first.y) < 0.00001)
        #expect(abs((second.y - first.y) / 0.001 - first.speed) < 0.00001)
        #expect(abs(second.heading - first.heading - first.yawRate * 0.001) < 0.00001)
    }
}
