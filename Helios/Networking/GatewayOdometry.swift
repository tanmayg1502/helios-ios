import Foundation

struct GatewayOdometry: Decodable, Sendable {
    let available: Bool
    let ageSeconds: Double?
    let frameID: String?
    let childFrameID: String?
    let x: Double?
    let y: Double?
    let heading: Double?
    let linearX: Double?
    let linearY: Double?
    let angularZ: Double?

    enum CodingKeys: String, CodingKey {
        case available, x, y, heading
        case ageSeconds = "age_seconds", frameID = "frame_id", childFrameID = "child_frame_id"
        case linearX = "linear_x", linearY = "linear_y", angularZ = "angular_z"
    }

    var isValid: Bool {
        guard available else { return true }
        return [ageSeconds, x, y, heading, linearX, linearY, angularZ].allSatisfy { $0?.isFinite == true }
            && (ageSeconds ?? -1) >= 0 && frameID != nil && childFrameID != nil
    }

    func isFresh(receivedAt: ContinuousClock.Instant, now: ContinuousClock.Instant) -> Bool {
        guard available, let ageSeconds, ageSeconds.isFinite, (0...2).contains(ageSeconds) else { return false }
        return .seconds(ageSeconds) + max(.zero, receivedAt.duration(to: now)) <= .seconds(2)
    }
}
