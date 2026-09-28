struct RobotOperation: Decodable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let kind: String
    let requiresConfirmation: Bool
    let requires: [String]
    let requiresAny: [String]
    let conflicts: [String]
    let parameters: [OperationParameter]

    enum CodingKeys: String, CodingKey {
        case id, title, description, kind, requires, conflicts, parameters
        case requiresConfirmation = "requires_confirmation", requiresAny = "requires_any"
    }
}
