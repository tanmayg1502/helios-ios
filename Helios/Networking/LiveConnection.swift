import Foundation
import Observation

@MainActor @Observable
final class LiveConnection {
    let operations = OperationsSession()
    private(set) var status = ConnectionStatus.disconnected
    private(set) var snapshot: GatewaySnapshot?
    private(set) var receivedAt: ContinuousClock.Instant?
    private(set) var detail = "Connect to a deployed Helios gateway."
    private(set) var isEnabled = false
    var useLive = false
    @ObservationIgnored private var client: GatewayClient?
    @ObservationIgnored private var polling: Task<Void, Never>?
    @ObservationIgnored private var generation = UUID()

    func connect(endpoint: String, token: String) {
        stopPolling()
        operations.disconnect()
        snapshot = nil
        receivedAt = nil
        useLive = true
        do {
            client = try GatewayClient(endpoint: endpoint, token: token)
            isEnabled = true
            if let client { operations.connect(client) }
            startPolling()
        } catch {
            client = nil
            isEnabled = false
            status = .disconnected
            detail = error.localizedDescription
        }
    }

    func disconnect() {
        operations.disconnect()
        isEnabled = false
        client = nil
        stopPolling()
        status = .disconnected
        snapshot = nil
        receivedAt = nil
        detail = "Disconnected. No telemetry is being received."
    }

    func showDemo() {
        disconnect()
        useLive = false
    }

    func setActive(_ active: Bool) {
        guard isEnabled else { return }
        operations.setActive(active)
        if active { startPolling() }
        else {
            stopPolling()
            status = .paused
            snapshot = nil
            receivedAt = nil
            detail = "Polling resumes when the app is active."
        }
    }

    private func stopPolling() {
        generation = UUID()
        polling?.cancel()
        polling = nil
    }

    private func startPolling() {
        guard let client else { return }
        stopPolling()
        let current = generation
        status = .connecting
        detail = "Waiting for the gateway…"
        polling = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    let requestStarted = ContinuousClock.now
                    let value = try await client.fetch()
                    guard let self, self.generation == current, !Task.isCancelled else { return }
                    self.snapshot = value
                    self.receivedAt = requestStarted
                    self.status = .connected
                    self.detail = "Authenticated gateway response. Sensor freshness is shown separately."
                } catch {
                    guard let self, self.generation == current, !Task.isCancelled else { return }
                    self.snapshot = nil
                    self.receivedAt = nil
                    self.status = .disconnected
                    self.detail = "\(error.localizedDescription) Retrying every 2 seconds."
                }
                do { try await Task.sleep(for: .seconds(self?.status == .connected ? 1 : 2)) }
                catch { return }
            }
        }
    }
}
