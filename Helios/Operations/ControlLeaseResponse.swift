struct ControlLeaseResponse: Decodable, Sendable {
    let apiVersion: Int
    let lease: ControlLease
    enum CodingKeys: String, CodingKey { case apiVersion = "api_version", lease }
}
