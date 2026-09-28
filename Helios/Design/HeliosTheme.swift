import SwiftUI

/// A restrained, original instrument-panel palette shared by every feature.
enum HeliosTheme {
    static let background = Color(red: 0.055, green: 0.065, blue: 0.07)
    static let surface = Color(red: 0.10, green: 0.115, blue: 0.12)
    static let lime = Color(red: 0.79, green: 0.96, blue: 0.36)
    static let cyan = Color(red: 0.40, green: 0.85, blue: 0.91)
    static let orange = Color(red: 1, green: 0.70, blue: 0.40)
    static let muted = Color(red: 0.66, green: 0.71, blue: 0.72)
    static let spacing: CGFloat = 20
    static let radius: CGFloat = 22
}

extension View {
    func heliosScreen() -> some View {
        scrollContentBackground(.hidden)
            .background(HeliosTheme.background)
            .tint(HeliosTheme.lime)
            .preferredColorScheme(.dark)
    }

    func heliosCard() -> some View {
        padding(HeliosTheme.spacing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(HeliosTheme.surface, in: .rect(cornerRadius: HeliosTheme.radius))
    }
}
