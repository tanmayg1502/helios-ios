struct OperationParameter: Decodable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let type: String
    let required: Bool
    let defaultValue: OperationValue?
    let options: [OperationValue]?
    let min: Double?
    let max: Double?

    enum CodingKeys: String, CodingKey {
        case name, type, required, options, min, max
        case defaultValue = "default"
    }
}
