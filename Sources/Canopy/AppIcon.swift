import SwiftUI

/// The Canopy app icon — a dark scalloped rosette ("canopy" silhouette) on a
/// warm cream squircle, drawn from scratch.
struct AppIconView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 224, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.94, blue: 0.89),
                            Color(red: 0.92, green: 0.87, blue: 0.80)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            Rosette(petals: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.16, green: 0.13, blue: 0.11),
                            Color(red: 0.05, green: 0.04, blue: 0.04)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 560, height: 560)
                .shadow(color: .black.opacity(0.28), radius: 26, y: 16)
        }
        .frame(width: 1024, height: 1024)
    }
}

/// A scalloped flower/seal silhouette: a ring of overlapping petal circles
/// around a solid core, which unions into one shape when filled.
struct Rosette: Shape {
    var petals: Int = 8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let petalRadius = radius * 0.38
        let orbit = radius - petalRadius

        // Core.
        path.addEllipse(in: CGRect(
            x: center.x - orbit, y: center.y - orbit,
            width: orbit * 2, height: orbit * 2
        ))
        // Petals.
        for i in 0..<petals {
            let angle = (Double(i) / Double(petals)) * 2 * .pi
            let cx = center.x + cos(angle) * orbit
            let cy = center.y + sin(angle) * orbit
            path.addEllipse(in: CGRect(
                x: cx - petalRadius, y: cy - petalRadius,
                width: petalRadius * 2, height: petalRadius * 2
            ))
        }
        return path
    }
}

@MainActor
enum IconRenderer {
    static func render(to path: String) {
        NotchSnapshotter.write(AppIconView(), to: path)
    }
}
