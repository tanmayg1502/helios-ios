import SwiftUI

struct OperationsView: View {
    let session: OperationsSession
    @State private var showStopConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeliosSectionHeading(title: "Operations", eyebrow: "ROVER CONTROL")
                OperationsStatusView(session: session)
                if session.jobs.contains(where: \.isActive) {
                    HeliosSectionHeading(title: "Running now", eyebrow: "GATEWAY-MANAGED JOBS")
                    ForEach(session.jobs.filter(\.isActive)) { job in
                        OperationJobView(job: job, session: session)
                    }
                    Button("Stop managed processes", systemImage: "stop.circle", role: .destructive, action: requestStop)
                        .buttonStyle(.bordered)
                        .disabled(!session.isConnected || !session.hasControl || session.isBusy || !session.jobs.contains(where: \.isActive))
                        .confirmationDialog("Stop gateway-managed processes?", isPresented: $showStopConfirmation, titleVisibility: .visible) {
                            Button("Stop managed processes", role: .destructive, action: stopAll)
                        } message: {
                            Text("This requests orderly shutdown of processes owned by this gateway. It is not an emergency stop and cannot stop software launched elsewhere.")
                        }
                }
                if !session.catalog.isEmpty {
                    HeliosSectionHeading(title: "Command library", eyebrow: "GATEWAY CATALOG")
                    ForEach(session.catalog) { operation in
                        NavigationLink(value: operation.id) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(operation.title).font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right").accessibilityHidden(true)
                                }
                                Text(operation.description).font(.subheadline).foregroundStyle(HeliosTheme.muted)
                                Label(operation.requiresConfirmation ? "Confirmation required · May move rover" : operation.kind.capitalized,
                                      systemImage: operation.requiresConfirmation ? "exclamationmark.triangle" : "terminal")
                                    .font(.caption).foregroundStyle(operation.requiresConfirmation ? HeliosTheme.orange : HeliosTheme.cyan)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .heliosCard()
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("operation-\(operation.id)")
                    }
                }
                if session.jobs.contains(where: { !$0.isActive }) {
                    DisclosureGroup("Completed job history") {
                        VStack(spacing: 12) {
                            ForEach(session.jobs.filter { !$0.isActive }) { job in
                                OperationJobView(job: job, session: session)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .font(.headline)
                    .accessibilityIdentifier("completedJobHistory")
                }
            }
            .padding()
        }
        .heliosScreen()
        .navigationTitle("Operations")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: String.self) { id in
            if let operation = session.catalog.first(where: { $0.id == id }) {
                OperationDetailView(operation: operation, session: session)
            } else {
                ContentUnavailableView("Operation unavailable", systemImage: "network.slash", description: Text("Reconnect to load the gateway catalog."))
            }
        }
        .refreshable { await session.refresh() }
    }

    private func requestStop() { showStopConfirmation = true }
    private func stopAll() { Task { await session.stopAll() } }
}
