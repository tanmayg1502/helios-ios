import SwiftUI

struct MapCanvas: View {
    let telemetry: Telemetry

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 8
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            var grid = Path()
            for index in 0...8 {
                let offset = Double(index) * scale
                grid.move(to: CGPoint(x: offset, y: 0))
                grid.addLine(to: CGPoint(x: offset, y: size.height))
                grid.move(to: CGPoint(x: 0, y: offset))
                grid.addLine(to: CGPoint(x: size.width, y: offset))
            }
            context.stroke(grid, with: .color(HeliosTheme.cyan.opacity(0.12)), lineWidth: 1)
            let room = CGRect(x: scale * 0.5, y: scale * 0.5, width: scale * 7, height: scale * 7)
            context.stroke(Path(roundedRect: room, cornerRadius: scale * 0.3), with: .color(HeliosTheme.muted), lineWidth: 5)
            let route = CGRect(x: center.x - 2 * scale, y: center.y - 2 * scale, width: 4 * scale, height: 4 * scale)
            context.stroke(Path(ellipseIn: route), with: .color(HeliosTheme.lime.opacity(0.6)), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
            let robot = CGPoint(x: center.x + telemetry.x * scale, y: center.y - telemetry.y * scale)
            context.fill(Path(ellipseIn: CGRect(x: robot.x - 9, y: robot.y - 9, width: 18, height: 18)), with: .color(HeliosTheme.lime))
            var arrow = Path()
            arrow.move(to: robot)
            arrow.addLine(to: CGPoint(x: robot.x + 23 * cos(telemetry.heading), y: robot.y - 23 * sin(telemetry.heading)))
            context.stroke(arrow, with: .color(.primary), lineWidth: 3)
        }
        .background(HeliosTheme.surface, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Demo room map. Circular sample route, two meter radius.")
        .accessibilityValue("Robot X \(telemetry.x.formatted(.number.precision(.fractionLength(1)))) meters, Y \(telemetry.y.formatted(.number.precision(.fractionLength(1)))) meters")
    }
}
