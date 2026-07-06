import SwiftUI

extension View {
    /// Native macOS 26 "Liquid Glass" where available, falling back to a material
    /// blur on earlier systems. Used for the on-desktop cards so they read like
    /// real Apple glass rather than a flat translucent fill.
    @ViewBuilder
    func liquidGlass(cornerRadius: CGFloat, tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if #available(macOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint.opacity(0.22)), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(.white.opacity(0.14), lineWidth: 0.5))
        }
    }
}

/// A behind-window blur so the widget reads as real frosted glass over the
/// desktop wallpaper.
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blending
    }
}

/// The full desktop widget: Liquid Glass + album-art gradient + content.
struct WidgetView: View {
    @ObservedObject var vm: NowPlayingModel
    var preset: WidgetPreset
    /// When true, replaces the live blur with an opaque gradient (for offscreen snapshots).
    var snapshotMode = false

    private let corner: CGFloat = 38

    var body: some View {
        ZStack {
            background
            WidgetContent(vm: vm, preset: preset)
        }
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .overlay(glassEdge)
        .shadow(color: .black.opacity(0.35), radius: 30, y: 14)
        .padding(14) // room for the shadow inside the window
    }

    @ViewBuilder private var background: some View {
        ZStack {
            if snapshotMode {
                LinearGradient(colors: [Color(white: 0.11), Color(white: 0.05)],
                               startPoint: .top, endPoint: .bottom)
            } else {
                VisualEffectView(material: .hudWindow)
            }
            // A subtle album-art wash + a dark scrim, matching the real
            // lockscreen's dark, lightly-tinted backdrop.
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(snapshotMode ? 0.5 : 0.3)
                .blur(radius: 30)
            Color.black.opacity(0.28)
        }
    }

    private var gradientColors: [Color] {
        let p = vm.palette
        guard p.count >= 2 else { return ColorExtractor.fallback }
        return Array(p.prefix(3))
    }

    private var glassEdge: some View {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.45), .white.opacity(0.05), .white.opacity(0.18)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
