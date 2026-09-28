import Foundation
import Observation

@MainActor @Observable
final class OperationsSession {
    private(set) var catalog: [RobotOperation] = []
    private(set) var jobs: [OperationJob] = []
    private(set) var source: String?
    private(set) var commandsEnabled = false
    private(set) var isConnected = false
    private(set) var isBusy = false
    private(set) var commandOutcome: String?
    private(set) var message = "Connect to a gateway to view operations."
    private(set) var leaseDeadline: ContinuousClock.Instant?
    private(set) var lastRefresh: ContinuousClock.Instant?
    var hasControl: Bool {
        keepControl && isConnected && leaseDeadline.map { $0 > .now } == true
    }

    @ObservationIgnored private var requestScope = GatewayRequestScope()
    @ObservationIgnored private var client: GatewayClient?
    @ObservationIgnored private var generation = UUID()
    @ObservationIgnored private var polling: Task<Void, Never>?
    @ObservationIgnored private var heartbeat: Task<Void, Never>?
    @ObservationIgnored private var keepControl = false
    @ObservationIgnored private var lastLeaseAcquired: ContinuousClock.Instant?
    @ObservationIgnored private let clientID = UUID().uuidString

    func connect(_ client: GatewayClient) {
        disconnect()
        self.client = client
        message = "Loading gateway operations…"
        startPolling()
    }

    func disconnect() {
        stopTasks()
        client = nil
        commandOutcome = nil
        catalog = []
        jobs = []
        source = nil
        commandsEnabled = false
        message = "Disconnected. Any previous control lease will expire; verify robot status on reconnect."
    }

    func setActive(_ active: Bool) {
        guard client != nil else { return }
        if active {
            message = "Refreshing operations. Acquire control again before sending commands."
            startPolling()
        } else {
            stopTasks()
            message = "Backgrounded. The gateway will stop its managed work when the control lease expires."
        }
    }

    private func stopTasks() {
        requestScope.cancel()
        requestScope = GatewayRequestScope()
        generation = UUID()
        polling?.cancel()
        heartbeat?.cancel()
        polling = nil
        heartbeat = nil
        keepControl = false
        leaseDeadline = nil
        lastLeaseAcquired = nil
        lastRefresh = nil
        isConnected = false
        isBusy = false
    }

    private func startPolling() {
        polling?.cancel()
        let current = generation
        polling = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.generation == current else { return }
                await self.refresh()
                do { try await Task.sleep(for: .seconds(2)) }
                catch { return }
            }
        }
    }

    func refresh() async {
        guard let client else { return }
        let current = generation
        let requestStarted = ContinuousClock.now
        do {
            let response: OperationCatalog = try await client.request(path: "v1/operations", scope: requestScope)
            guard current == generation, !Task.isCancelled else { return }
            guard response.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            catalog = response.operations
            jobs = response.jobs
            source = response.source
            commandsEnabled = response.commandsEnabled
            isConnected = true
            lastRefresh = .now
            if !commandsEnabled { message = "Command execution is disabled on this gateway." }
            else if message == "Loading gateway operations…" { message = "Acquire control to run a documented operation." }
            if response.lease.clientID != clientID, lastLeaseAcquired.map({ requestStarted >= $0 }) ?? true {
                keepControl = false
                leaseDeadline = nil
                heartbeat?.cancel()
            }
        } catch {
            guard current == generation, !Task.isCancelled else { return }
            isConnected = false
            keepControl = false
            leaseDeadline = nil
            heartbeat?.cancel()
            message = "Operations unavailable: \(error.localizedDescription) Control must be acquired again after reconnect."
        }
    }

    func acquireControl() async {
        guard client != nil, isConnected, commandsEnabled, !isBusy else { return }
        keepControl = true
        let current = generation
        isBusy = true
        defer { if current == generation { isBusy = false } }
        guard await renewControl(current: current) else { return }
        message = "Commands enabled for this phone. Keep the app active."
        heartbeat?.cancel()
        heartbeat = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(3)) }
                catch { return }
                guard let self, current == self.generation, self.keepControl else { return }
                guard await self.renewControl(current: current) else { return }
            }
        }
    }

    private func renewControl(current: UUID) async -> Bool {
        guard let client else { return false }
        let started = ContinuousClock.now
        do {
            let body = try JSONEncoder().encode(ControlRequest(clientID: clientID))
            let response: ControlLeaseResponse = try await client.request(path: "v1/control/heartbeat", method: "POST", body: body, scope: requestScope)
            guard generation == current, !Task.isCancelled else { return false }
            guard response.apiVersion == 1, response.lease.clientID == clientID,
                  response.lease.remainingSeconds.isFinite,
                  (0...10).contains(response.lease.remainingSeconds) else { throw GatewayError.invalidData }
            lastLeaseAcquired = .now
            leaseDeadline = started.advanced(by: .seconds(response.lease.remainingSeconds))
            keepControl = true
            return true
        } catch {
            guard generation == current, !Task.isCancelled else { return false }
            keepControl = false
            leaseDeadline = nil
            message = "Control unavailable: \(error.localizedDescription)"
            return false
        }
    }

    func run(_ operation: RobotOperation, parameters: [String: OperationValue], confirmed: Bool) async {
        guard let client, hasControl, commandsEnabled, !isBusy else { return }
        guard !operation.requiresConfirmation || confirmed else {
            message = "Confirm this operation before sending it."
            return
        }
        let current = generation
        isBusy = true
        defer { if current == generation { isBusy = false } }
        do {
            let body = try JSONEncoder().encode(OperationStartRequest(clientID: clientID, requestID: UUID().uuidString,
                                                                     parameters: parameters, confirm: confirmed))
            let response: OperationJobResponse = try await client.request(path: "v1/operations/\(operation.id)/start", method: "POST", body: body, scope: requestScope)
            guard current == generation, !Task.isCancelled else { return }
            guard response.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            upsert(response.job)
            commandOutcome = "\(operation.title): \(response.job.state). Check the job output for completion."
        } catch {
            guard current == generation, !Task.isCancelled else { return }
            commandOutcome = "\(error.localizedDescription) If delivery was interrupted, the command may have been accepted. Inspect jobs before running it again."
        }
        await refresh()
    }

    func stop(_ job: OperationJob) async {
        guard let client, hasControl, !isBusy else { return }
        let current = generation
        isBusy = true
        defer { if current == generation { isBusy = false } }
        do {
            let body = try JSONEncoder().encode(ControlRequest(clientID: clientID))
            let response: OperationJobResponse = try await client.request(path: "v1/jobs/\(job.id)/stop", method: "POST", body: body, scope: requestScope)
            guard current == generation, !Task.isCancelled else { return }
            guard response.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            upsert(response.job)
            commandOutcome = "Stop requested. Verify the job reaches stopped; this is not an emergency stop."
        } catch {
            guard current == generation, !Task.isCancelled else { return }
            commandOutcome = "Stop not confirmed: \(error.localizedDescription)"
        }
        await refresh()
    }

    func stopAll() async {
        guard let client, hasControl, !isBusy else { return }
        let current = generation
        isBusy = true
        defer { if current == generation { isBusy = false } }
        do {
            let body = try JSONEncoder().encode(ControlRequest(clientID: clientID))
            let response: OperationJobsResponse = try await client.request(path: "v1/operations/stop-all", method: "POST", body: body, scope: requestScope)
            guard current == generation, !Task.isCancelled else { return }
            guard response.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            jobs = response.jobs
            commandOutcome = "Ordered shutdown requested. Watch job results; this is not an emergency stop."
        } catch {
            guard current == generation, !Task.isCancelled else { return }
            commandOutcome = "Shutdown not confirmed: \(error.localizedDescription)"
        }
        await refresh()
    }

    func details(for job: OperationJob) async -> OperationJob? {
        guard let client, isConnected else { return nil }
        let current = generation
        do {
            let result: OperationJobResponse = try await client.request(path: "v1/jobs/\(job.id)", scope: requestScope)
            guard current == generation, !Task.isCancelled else { return nil }
            guard result.apiVersion == 1 else { throw GatewayError.unsupportedVersion }
            return result.job
        } catch {
            guard current == generation, !Task.isCancelled else { return nil }
            message = "Could not load job output: \(error.localizedDescription)"
            return nil
        }
    }

    private func upsert(_ job: OperationJob) {
        if let index = jobs.firstIndex(where: { $0.id == job.id }) { jobs[index] = job }
        else { jobs.insert(job, at: 0) }
    }
}
