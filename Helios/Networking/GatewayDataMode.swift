/// The expected gateway identity is fixed for the lifetime of a connection.
enum GatewayDataMode: Sendable {
    case robot
    case fixture

    var expectedSource: String { self == .robot ? "ros2" : "fixture" }
    var expectsSimulatedJobs: Bool { self == .fixture }
}
