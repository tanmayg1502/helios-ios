import SwiftUI

struct OperationsStatusView: View {
    let session: OperationsSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(session.source == "fixture" ? "SIMULATED GATEWAY" : "ROVER GATEWAY", systemImage: session.source == "fixture" ? "testtube.2" : "antenna.radiowaves.left.and.right")
                .font(.caption.bold()).foregroundStyle(HeliosTheme.cyan)
            Text(statusTitle).font(.title2.bold())
            Text(session.message).font(.subheadline).foregroundStyle(HeliosTheme.muted)
                .accessibilityIdentifier("operationsMessage")
            if let outcome = session.commandOutcome {
                Text("Latest command: \(outcome)")
                    .font(.subheadline).foregroundStyle(HeliosTheme.orange)
                    .accessibilityIdentifier("commandOutcome")
            }
            if session.source == "fixture" {
                Text("Simulation only. No hardware actions.")
                    .font(.footnote).foregroundStyle(HeliosTheme.cyan)
            }
            if !session.hasControl {
                Button("Acquire control session", systemImage: "hand.raised", action: acquire)
                    .buttonStyle(.borderedProminent).tint(HeliosTheme.lime).foregroundStyle(.black)
                    .disabled(!session.isConnected || !session.commandsEnabled || session.isBusy)
                    .accessibilityIdentifier("acquireControl")
            }
            DisclosureGroup("Control and shutdown behavior") {
                Text("Keep the app active while controlling the rover. Without a heartbeat, control expires after 10 seconds and the gateway requests orderly shutdown. Backgrounding or disconnecting stops heartbeats. Verify job results; this is not an emergency stop.")
                    .font(.footnote).foregroundStyle(HeliosTheme.muted)
                    .padding(.top, 8)
            }
            .font(.footnote)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .heliosCard()
    }

    private var statusTitle: String {
        if !session.isConnected { return "Connect to use operations" }
        if !session.commandsEnabled { return "Commands disabled on gateway" }
        return session.hasControl ? "Control session active" : "Ready to acquire control"
    }

    private func acquire() { Task { await session.acquireControl() } }
}
