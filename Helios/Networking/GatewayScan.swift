import Foundation

struct GatewayScan: Decodable, Sendable {
    let available: Bool
    let ageSeconds: Double?
    let frameID: String?
    let nearestM: Double?

    enum CodingKeys: String, CodingKey {
        case available
        case ageSeconds = "age_seconds", frameID = "frame_id", nearestM = "nearest_m"
    }

    var isValid: Bool {
        guard available else { return true }
        return ageSeconds?.isFinite == true && (ageSeconds ?? -1) >= 0 && frameID != nil
            && (nearestM == nil || (nearestM?.isFinite == true && (nearestM ?? -1) >= 0))
    }

    func isFresh(receivedAt: ContinuousClock.Instant, now: ContinuousClock.Instant) -> Bool {
        guard available, let ageSeconds, ageSeconds.isFinite, (0...2).contains(ageSeconds) else { return false }
        return .seconds(ageSeconds) + max(.zero, receivedAt.duration(to: now)) <= .seconds(2)
    }
}
