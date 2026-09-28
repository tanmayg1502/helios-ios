struct ControlRequest: Encodable, Sendable {
    let clientID: String
    enum CodingKeys: String, CodingKey { case clientID = "client_id" }
}
