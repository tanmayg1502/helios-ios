import Foundation

/// Synthetic local samples, expressed in ROS SI units. Not received from hardware.
struct Telemetry: Sendable {
    let x: Double
    let y: Double
    let heading: Double
    let speed: Double
    let yawRate: Double

    static func demo(at time: Double) -> Self {
        let angle = time * 0.12
        return Self(x: 2 * cos(angle), y: 2 * sin(angle),
                    heading: angle + .pi / 2, speed: 0.24, yawRate: 0.12)
    }
}
