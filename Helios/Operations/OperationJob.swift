struct OperationJob: Decodable, Identifiable, Sendable {
    let id: String
    let operationID: String
    let state: String
    let exitCode: Int?
    let output: String
    let error: String?
    let simulated: Bool
    var isActive: Bool { ["running", "stopping", "stop_failed"].contains(state) }

    enum CodingKeys: String, CodingKey {
        case id, state, output, error, simulated
        case operationID = "operation_id", exitCode = "exit_code"
    }
}
