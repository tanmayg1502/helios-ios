import Foundation

/// Cancels all requests belonging to a foreground operations session, including callers' unstructured tasks.
final class GatewayRequestScope: @unchecked Sendable {
    private let lock = NSLock()
    private var sessions: [UUID: URLSession] = [:]
    private var cancelled = false

    func register(_ session: URLSession) -> UUID? {
        lock.withLock {
            guard !cancelled else { return nil }
            let id = UUID()
            sessions[id] = session
            return id
        }
    }

    func remove(_ id: UUID) { _ = lock.withLock { sessions.removeValue(forKey: id) } }

    func cancel() {
        let active = lock.withLock {
            cancelled = true
            let values = Array(sessions.values)
            sessions.removeAll()
            return values
        }
        for session in active { session.invalidateAndCancel() }
    }
}
