import Foundation

enum GatewayError: Error, LocalizedError {
    case invalidEndpoint, missingToken, unauthorized, unsupportedVersion, invalidData, responseTooLarge
    case developerToolsUnavailable
    case dataModeMismatch
    case httpStatus(Int)
    case rejected(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: "Use an HTTPS gateway URL without credentials, query, fragment or path. HTTP is allowed only for explicitly selected localhost fixture testing."
        case .developerToolsUnavailable: "Simulated gateway connections are unavailable in this build."
        case .dataModeMismatch: "Gateway data does not match the selected robot or simulated mode. Disconnect and check the endpoint."
        case .missingToken: "Enter the gateway bearer token (at least 32 characters)."
        case .unauthorized: "Authentication failed. Check the gateway token."
        case .unsupportedVersion: "The gateway API version is not supported by this app."
        case .invalidData: "The gateway returned incomplete or invalid telemetry."
        case .responseTooLarge: "The gateway response exceeded the telemetry size limit."
        case .rejected(_, let message): "Gateway rejected the request: \(message)"
        case .httpStatus(let status): "Gateway returned HTTP \(status)."
        }
    }
}
