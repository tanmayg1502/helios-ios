struct OperationJobResponse: Decodable, Sendable {
    let apiVersion: Int
    let job: OperationJob
    enum CodingKeys: String, CodingKey { case apiVersion = "api_version", job }
}
