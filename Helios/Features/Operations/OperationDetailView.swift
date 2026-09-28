import SwiftUI

struct OperationDetailView: View {
    let operation: RobotOperation
    let session: OperationsSession
    @State private var inputs: [String: String]
    @State private var validationMessage: String?
    @State private var showConfirmation = false
    @State private var pendingParameters: [String: OperationValue] = [:]

    init(operation: RobotOperation, session: OperationsSession) {
        self.operation = operation
        self.session = session
        _inputs = State(initialValue: Dictionary(uniqueKeysWithValues: operation.parameters.map {
            ($0.name, Self.initialInput($0))
        }))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HeliosSectionHeading(title: operation.title, eyebrow: operation.kind.uppercased())
                Text(operation.description).foregroundStyle(HeliosTheme.muted)
                OperationsStatusView(session: session)
                if operation.requiresConfirmation {
                    Label("Motion-capable operation. Confirm the area is clear before running.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(HeliosTheme.orange).heliosCard()
                }
                if !operation.requires.isEmpty { Text("Requires: \(names(operation.requires))").font(.footnote) }
                if !operation.requiresAny.isEmpty { Text("Requires one of: \(names(operation.requiresAny))").font(.footnote) }
                if !operation.conflicts.isEmpty { Text("Cannot run with: \(names(operation.conflicts))").font(.footnote) }
                ForEach(operation.parameters) { parameter in
                    OperationParameterView(parameter: parameter) { inputs[parameter.name] = $0 }
                        .heliosCard()
                }
                if let validationMessage { Text(validationMessage).foregroundStyle(HeliosTheme.orange) }
                Button(operation.kind == "service" ? "Start service" : "Run operation", systemImage: "play.fill", action: prepareRun)
                    .buttonStyle(.borderedProminent).tint(HeliosTheme.lime).foregroundStyle(.black)
                    .disabled(!session.isConnected || !session.hasControl || !session.commandsEnabled || session.isBusy)
                    .accessibilityIdentifier("runOperation")
                    .confirmationDialog("Allow \(operation.title)?", isPresented: $showConfirmation, titleVisibility: .visible) {
                        Button("Confirm and run", role: .destructive, action: confirmedRun)
                    } message: {
                        Text(session.source == "fixture" ? "This is a simulated gateway. No hardware will move." : "This operation can enable or cause rover motion. Confirm that the area is clear and you can stop the rover physically.")
                    }
                ForEach(session.jobs.filter { $0.operationID == operation.id }) { job in
                    OperationJobView(job: job, session: session)
                }
            }.padding()
        }
        .heliosScreen()
        .navigationTitle(operation.title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private static func initialInput(_ parameter: OperationParameter) -> String {
        if parameter.options?.isEmpty != false, case let .number(value) = parameter.defaultValue {
            return String(value)
        }
        return parameter.defaultValue?.displayText ?? (parameter.type == "boolean" ? "false" : "")
    }

    private func names(_ ids: [String]) -> String {
        ids.map { id in session.catalog.first(where: { $0.id == id })?.title ?? id }.joined(separator: ", ")
    }

    private func prepareRun() {
        validationMessage = nil
        var values: [String: OperationValue] = [:]
        for parameter in operation.parameters {
            guard ["string", "boolean", "number", "integer"].contains(parameter.type) else {
                validationMessage = "Unsupported parameter type for \(parameter.name). Update the app before using this operation."; return
            }
            let text = (inputs[parameter.name] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.isEmpty {
                if parameter.required { validationMessage = "Enter \(parameter.name)."; return }
                continue
            }
            let value: OperationValue
            if let options = parameter.options, !options.isEmpty {
                guard let selection = options.first(where: { $0.displayText == text }) else {
                    validationMessage = "Choose an allowed value for \(parameter.name)."; return
                }
                values[parameter.name] = selection
                continue
            }
            switch parameter.type {
            case "boolean": value = .bool(text == "true")
            case "number", "integer":
                guard let number = Double(text), number.isFinite,
                      parameter.type != "integer" || number.rounded() == number,
                      parameter.min.map({ number >= $0 }) ?? true,
                      parameter.max.map({ number <= $0 }) ?? true else {
                    validationMessage = "Enter a valid \(parameter.type) within the allowed range for \(parameter.name)."; return
                }
                value = .number(number)
            case "string": value = .string(text)
            default:
                validationMessage = "Unsupported parameter type for \(parameter.name). Update the app before using this operation."; return
            }
            if let options = parameter.options, !options.contains(value) {
                validationMessage = "Choose an allowed value for \(parameter.name)."; return
            }
            values[parameter.name] = value
        }
        pendingParameters = values
        if operation.requiresConfirmation { showConfirmation = true }
        else { run(confirmed: false) }
    }

    private func confirmedRun() { run(confirmed: true) }
    private func run(confirmed: Bool) {
        guard session.isConnected, session.hasControl, !session.isBusy else { return }
        let values = pendingParameters
        Task { await session.run(operation, parameters: values, confirmed: confirmed) }
    }
}
