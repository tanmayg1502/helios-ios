import SwiftUI

struct OperationParameterView: View {
    let parameter: OperationParameter
    let onChange: (String) -> Void
    @State private var text: String
    @State private var enabled: Bool
    @State private var number: Double?

    init(parameter: OperationParameter, onChange: @escaping (String) -> Void) {
        self.parameter = parameter
        self.onChange = onChange
        _text = State(initialValue: parameter.defaultValue?.displayText ?? "")
        _enabled = State(initialValue: parameter.defaultValue == .bool(true))
        if case let .number(value) = parameter.defaultValue { _number = State(initialValue: value) }
        else { _number = State(initialValue: nil) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if parameter.type == "boolean" {
                Toggle(parameter.name, isOn: $enabled)
                    .onChange(of: enabled) { _, value in onChange(value ? "true" : "false") }
            } else if let options = parameter.options, !options.isEmpty {
                Picker(parameter.name, selection: $text) {
                    Text("Select…").tag("")
                    ForEach(options, id: \.self) { option in Text(option.displayText).tag(option.displayText) }
                }
                .onChange(of: text) { _, value in onChange(value) }
            } else if parameter.type == "number" || parameter.type == "integer" {
                TextField(parameter.name, value: $number, format: .number)
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(parameter.name)
                    .onChange(of: number) { _, value in onChange(value.map(String.init(describing:)) ?? "") }
            } else {
                TextField(parameter.name, text: $text)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(parameter.name)
                    .onChange(of: text) { _, value in onChange(value) }
            }
            Text(parameter.required ? "Required · \(parameter.type)" : "Optional · \(parameter.type)")
                .font(.caption).foregroundStyle(HeliosTheme.muted)
            if parameter.min != nil || parameter.max != nil {
                Text("Allowed: \(parameter.min.map { String($0) } ?? "any") to \(parameter.max.map { String($0) } ?? "any")")
                    .font(.caption).foregroundStyle(HeliosTheme.muted)
            }
        }
        .accessibilityIdentifier("parameter-\(parameter.name)")
    }
}
