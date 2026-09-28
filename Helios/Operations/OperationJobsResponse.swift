struct OperationJobsResponse: Decodable, Sendable {
    let apiVersion: Int
    let jobs: [OperationJob]
    enum CodingKeys: String, CodingKey { case apiVersion = "api_version", jobs }
}
