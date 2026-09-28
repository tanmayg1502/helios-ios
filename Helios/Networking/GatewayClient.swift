import Foundation

struct GatewayClient: Sendable {
    let endpoint: URL
    let baseURL: URL
    let token: String
    let dataMode: GatewayDataMode

    init(endpoint: String, token: String, dataMode: GatewayDataMode = .robot) throws {
        #if !DEBUG && !TESTFLIGHT_DEVELOPER_TOOLS
        guard dataMode == .robot else { throw GatewayError.developerToolsUnavailable }
        #endif
        guard let parts = URLComponents(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines)),
              let host = parts.host, !host.isEmpty,
              parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
              parts.path.isEmpty || parts.path == "/",
              parts.scheme == "https" || (dataMode == .fixture && parts.scheme == "http" && ["localhost", "127.0.0.1", "[::1]"].contains(host)),
              let url = parts.url else { throw GatewayError.invalidEndpoint }
        guard token.count >= 32, token.utf8.allSatisfy({ $0 < 128 }), !token.contains(where: { $0.isWhitespace || $0.isNewline }) else {
            throw GatewayError.missingToken
        }
        self.baseURL = url
        self.endpoint = url.appending(path: "v1/telemetry")
        self.token = token
        self.dataMode = dataMode
    }

    func fetch() async throws -> GatewaySnapshot {
        let value: GatewaySnapshot = try await request(path: "v1/telemetry", limit: 16_384)
        return try value.validated()
    }

    /// Mutating requests are sent once. A timeout is not proof that the server rejected a command.
    func request<Response: Decodable & Sendable>(
        path: String, method: String = "GET", body: Data? = nil, limit: Int = 262_144, scope: GatewayRequestScope? = nil
    ) async throws -> Response {
        // Verify identity before every mutation, including lease heartbeat/release whose
        // responses contain no source. Use the same cancellation scope as the mutation.
        // This protects accidental endpoint/mode mismatches; a dishonest or changing
        // server cannot be attested by this preflight (there is a TOCTOU boundary).
        if !["GET", "HEAD"].contains(method.uppercased()) {
            let _: OperationCatalog = try await request(path: "v1/operations", scope: scope)
        }
        try Task.checkCancellation()
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 6
        config.httpShouldSetCookies = false
        config.urlCache = nil
        let session = URLSession(configuration: config, delegate: NoRedirectDelegate(), delegateQueue: nil)
        let registration = scope?.register(session)
        if scope != nil && registration == nil {
            session.invalidateAndCancel()
            throw CancellationError()
        }
        defer {
            if let registration { scope?.remove(registration) }
            session.invalidateAndCancel()
        }
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = method
        request.httpBody = body
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        let (bytes, response) = try await session.bytes(for: request)
        guard let http = response as? HTTPURLResponse else { throw GatewayError.invalidData }
        if http.statusCode == 401 { throw GatewayError.unauthorized }
        var data = Data()
        for try await byte in bytes {
            guard data.count < limit else { throw GatewayError.responseTooLarge }
            data.append(byte)
        }
        guard (200...299).contains(http.statusCode) else {
            if let failure = try? JSONDecoder().decode(GatewayFailure.self, from: data) {
                throw GatewayError.rejected(http.statusCode, failure.message ?? failure.error)
            }
            throw GatewayError.httpStatus(http.statusCode)
        }
        let decoded: Response
        do { decoded = try JSONDecoder().decode(Response.self, from: data) }
        catch { throw GatewayError.invalidData }
        // Keep mode failures distinct from malformed JSON and ordinary API errors.
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let source = object["source"] {
            guard let source = source as? String, source == dataMode.expectedSource else {
                throw GatewayError.dataModeMismatch
            }
        }
        return try validate(decoded)
    }
    /// Validate all decoded gateway data before it can enter presentation/session state.
    func validate<Response>(_ response: Response) throws -> Response {
        switch response {
        case let snapshot as GatewaySnapshot:
            guard snapshot.source == dataMode.expectedSource else { throw GatewayError.dataModeMismatch }
            _ = try snapshot.validated()
        case let catalog as OperationCatalog:
            guard catalog.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            guard catalog.source == dataMode.expectedSource else { throw GatewayError.dataModeMismatch }
            try validateJobs(catalog.jobs)
        case let response as OperationJobResponse:
            guard response.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            try validateJobs([response.job])
        case let response as OperationJobsResponse:
            guard response.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            try validateJobs(response.jobs)
        case let job as OperationJob:
            try validateJobs([job])
        default:
            break
        }
        return response
    }

    private func validateJobs(_ jobs: [OperationJob]) throws {
        guard jobs.allSatisfy({ $0.simulated == dataMode.expectsSimulatedJobs }) else {
            throw GatewayError.dataModeMismatch
        }
    }
}
