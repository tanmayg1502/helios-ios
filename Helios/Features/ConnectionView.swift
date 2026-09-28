import SwiftUI

struct ConnectionView: View {
    @Bindable var connection: LiveConnection
    let developerAccess: DeveloperAccess
    @State private var showDeveloperConfirmation = false
    @State private var endpoint = ""
    @State private var token = ""
    @FocusState private var focusedField: ConnectionField?

    var body: some View {
        Form {
            Section("Gateway") {
                TextField("https://helios.example.com", text: $endpoint)
                    .textContentType(.URL).keyboardType(.URL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityLabel("Gateway URL")
                    .focused($focusedField, equals: .endpoint)
                SecureField("Bearer token", text: $token)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .accessibilityLabel("Gateway bearer token")
                    .focused($focusedField, equals: .token)
                Text("Use the address and token configured on the Jetson. Credentials stay in memory for this session.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Connect", systemImage: "antenna.radiowaves.left.and.right", action: connect)
                    .accessibilityIdentifier("connectGateway")
                Button("Disconnect", systemImage: "xmark.circle", action: connection.disconnect)
                    .disabled(!connection.isEnabled)
            }
            Section("Connection") {
                Text(connection.status.rawValue).font(.headline)
                Text(connection.detail).foregroundStyle(.secondary)
                Text("Telemetry connects here. Open Operations to acquire control and run supported robot commands.")
            }
            if developerAccess.isAvailable {
                Section("Developer tools") {
                    if connection.developerMode {
                        Text("Simulation only. Only a fixture gateway can connect. Real robot controls are unavailable.")
                        Button("Use local sample", systemImage: "play.rectangle", action: connection.showDemo)
                        Button("Return to real robot mode", systemImage: "antenna.radiowaves.left.and.right", action: leaveDeveloperMode)
                    } else {
                        Button("Enable developer mode", systemImage: "testtube.2", action: requestDeveloperMode)
                            .confirmationDialog("Enable simulation tools?", isPresented: $showDeveloperConfirmation, titleVisibility: .visible) {
                                Button("Enable simulation", action: enterDeveloperMode)
                            } message: {
                                Text("This disconnects the robot. Samples and fixture commands are simulated. Verify any previous robot work has stopped; this is not an emergency stop.")
                            }
                    }
                    Text("Opt in for this foreground session. Switching modes disconnects the gateway and drops local control; an existing lease may take time to expire. Verify the robot has stopped before switching.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .heliosScreen()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Connect")
    }

    private func requestDeveloperMode() { showDeveloperConfirmation = true }
    private func enterDeveloperMode() { connection.setDeveloperMode(true, access: developerAccess) }
    private func leaveDeveloperMode() { connection.setDeveloperMode(false, access: developerAccess) }

    private func connect() {
        focusedField = nil
        connection.connect(endpoint: endpoint, token: token)
    }
}
