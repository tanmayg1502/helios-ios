struct GatewayFailure: Decodable, Sendable {
    let error: String
    let message: String?
}
