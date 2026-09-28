import Foundation

struct GatewaySnapshot: Decodable, Sendable {
    let source: String?
    let apiVersion: Int
    let odometry: GatewayOdometry
    let scan: GatewayScan

    enum CodingKeys: String, CodingKey {
        case apiVersion = "api_version", odometry, scan, source
    }

    func validated() throws -> Self {
        guard apiVersion == 1 else { throw GatewayError.unsupportedVersion }
        guard odometry.isValid, scan.isValid else { throw GatewayError.invalidData }
        return self
    }
}
