import SwiftUI

struct OperationJobView: View {
    let job: OperationJob
    let session: OperationsSession
    @State private var detailOutput: String?
    @State private var outputMessage: String?
    @State private var isLoadingOutput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(session.catalog.first(where: { $0.id == job.operationID })?.title ?? job.operationID)
                .font(.headline)
            Label(job.state.capitalized, systemImage: job.isActive ? "circle.dotted" : "circle")
                .foregroundStyle(job.isActive ? HeliosTheme.lime : HeliosTheme.muted)
            if job.simulated { Text("Simulated job").font(.caption).foregroundStyle(HeliosTheme.cyan) }
            if let exitCode = job.exitCode { Text("Exit code: \(exitCode)").font(.caption) }
            if let error = job.error, !error.isEmpty { Text(error).foregroundStyle(HeliosTheme.orange) }
            DisclosureGroup("Process output") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(detailOutput ?? job.output).font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    Text(detailOutput == nil ? "Catalog preview · Refresh for the latest 1,024-byte output tail." : "Last fetched output · Up to 1,024 bytes from the end of the log.")
                        .font(.caption).foregroundStyle(HeliosTheme.muted)
                    Button("Refresh output", systemImage: "arrow.clockwise", action: refreshOutput)
                        .buttonStyle(.bordered)
                        .disabled(!session.isConnected || isLoadingOutput)
                        .accessibilityIdentifier("refreshOutput-\(job.operationID)")
                    if isLoadingOutput { ProgressView("Loading output") }
                    if let outputMessage { Text(outputMessage).font(.caption).foregroundStyle(HeliosTheme.orange) }
                }
            }
            if job.isActive {
                Button("Stop this job", systemImage: "stop.circle", action: stop)
                    .buttonStyle(.bordered)
                    .disabled(!session.isConnected || !session.hasControl || session.isBusy)
                    .accessibilityIdentifier("stopJob-\(job.operationID)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .heliosCard()
    }

    private func refreshOutput() {
        guard !isLoadingOutput, session.isConnected else { return }
        isLoadingOutput = true
        outputMessage = nil
        Task {
            if let details = await session.details(for: job) {
                detailOutput = details.output
            } else {
                outputMessage = session.message
            }
            isLoadingOutput = false
        }
    }

    private func stop() { Task { await session.stop(job) } }
}
