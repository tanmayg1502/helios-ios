import SwiftUI

struct ConnectionView: View {
    @Bindable var connection: LiveConnection
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
            Section("Offline preview") {
                Button("Use demo mode", systemImage: "play.rectangle", action: connection.showDemo)
                Text("Map illustrations remain demo-only. Operations require a connected gateway; this local preview never sends commands.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .heliosScreen()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Connect")
    }

    private func connect() {
        focusedField = nil
        connection.connect(endpoint: endpoint, token: token)
    }
}
