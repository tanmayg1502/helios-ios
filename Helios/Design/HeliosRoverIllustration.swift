import SwiftUI

/// Decorative schematic, not a camera feed or a hardware-state indicator.
struct HeliosRoverIllustration: View {
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 320, size.height / 170)
            context.translateBy(x: size.width / 2, y: size.height / 2)
            context.scaleBy(x: scale, y: scale)
            let halo = CGRect(x: -140, y: -68, width: 280, height: 136)
            context.stroke(Path(ellipseIn: halo), with: .color(HeliosTheme.cyan.opacity(0.20)), style: StrokeStyle(lineWidth: 1, dash: [4, 7]))
            for x in [-68.0, 48.0] {
                for y in [-48.0, 17.0] {
                    let wheel = CGRect(x: x, y: y, width: 20, height: 31)
                    context.fill(Path(roundedRect: wheel, cornerRadius: 6), with: .color(HeliosTheme.muted))
                    for offset in stride(from: 4.0, through: 24.0, by: 7.0) {
                        var tread = Path()
                        tread.move(to: CGPoint(x: x + 3, y: y + offset + 3))
                        tread.addLine(to: CGPoint(x: x + 17, y: y + offset - 3))
                        context.stroke(tread, with: .color(HeliosTheme.background), lineWidth: 2)
                    }
                }
            }
            let body = Path(roundedRect: CGRect(x: -45, y: -56, width: 90, height: 112), cornerRadius: 22)
            context.fill(body, with: .color(HeliosTheme.surface))
            context.stroke(body, with: .color(HeliosTheme.cyan), lineWidth: 1.5)
            context.fill(Path(roundedRect: CGRect(x: -22, y: -41, width: 44, height: 8), cornerRadius: 4), with: .color(HeliosTheme.lime))
            context.stroke(Path(ellipseIn: CGRect(x: -17, y: -12, width: 34, height: 34)), with: .color(HeliosTheme.muted), lineWidth: 2)
            context.fill(Path(ellipseIn: CGRect(x: -5, y: 0, width: 10, height: 10)), with: .color(HeliosTheme.cyan))
        }
        .aspectRatio(2, contentMode: .fit)
        .accessibilityHidden(true)
    }
}
