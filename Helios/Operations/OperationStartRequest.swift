struct OperationStartRequest: Encodable, Sendable {
    let clientID: String
    let requestID: String
    let parameters: [String: OperationValue]
    let confirm: Bool
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id", requestID = "request_id", parameters, confirm
    }
}
