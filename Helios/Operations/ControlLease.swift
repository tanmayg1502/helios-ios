struct ControlLease: Decodable, Sendable {
    let clientID: String?
    let remainingSeconds: Double

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id", remainingSeconds = "remaining_seconds"
    }
}
