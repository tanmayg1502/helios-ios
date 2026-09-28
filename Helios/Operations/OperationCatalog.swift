struct OperationCatalog: Decodable, Sendable {
    let apiVersion: Int
    let source: String
    let commandsEnabled: Bool
    let lease: ControlLease
    let operations: [RobotOperation]
    let jobs: [OperationJob]

    enum CodingKeys: String, CodingKey {
        case source, lease, operations, jobs
        case apiVersion = "api_version", commandsEnabled = "commands_enabled"
    }
}
