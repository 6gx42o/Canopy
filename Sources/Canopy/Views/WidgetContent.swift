import SwiftUI

/// The desktop "lockscreen" widget content. Rendered over a Liquid Glass
/// background (see WidgetView) with a gradient tinted from album art.
struct WidgetContent: View {
    @ObservedObject var vm: NowPlayingModel
    var preset: WidgetPreset

    var body: some View {
        switch preset {
        case .lockscreen: lockscreen
        case .nowPlaying: nowPlaying
        case .lyrics:     lyricsLayout
        case .minimal:    minimal
        }
    }

    // MARK: Lockscreen (iOS style) — clock top, artwork + glass player card on
    // the left, big Apple-Music karaoke lyrics on the right.

    private var lockscreen: some View {
        VStack(spacing: 14) {
            ClockView()
                .padding(.top, 20)

            HStack(alignment: .top, spacing: 26) {
                VStack(spacing: 14) {
                    Artwork(image: vm.artwork, size: 168, corner: 16)
                        .shadow(color: .black.opacity(0.4), radius: 16, y: 8)

                    if vm.hasMedia {
                        PlayerCard(vm: vm)
                            .padding(14)
                            .liquidGlass(cornerRadius: 22, tint: vm.palette.first)
                            .frame(width: 240)
                    }
                }

                KaraokeLyrics(vm: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Now Playing (art-forward)

    private var nowPlaying: some View {
        VStack(spacing: 16) {
            Artwork(image: vm.artwork, size: 200, corner: 18)
                .shadow(color: .black.opacity(0.4), radius: 18, y: 10)
                .padding(.top, 26)

            VStack(spacing: 4) {
                Text(vm.hasMedia ? vm.title : "Nothing Playing")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(vm.hasMedia ? vm.artist : "Canopy")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)

            ScrubBar(vm: vm)
                .padding(.horizontal, 26)

            TransportControls(vm: vm)
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Lyrics-forward

    private var lyricsLayout: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Artwork(image: vm.artwork, size: 48, corner: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.hasMedia ? vm.title : "Nothing Playing")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(vm.hasMedia ? vm.artist : "Canopy")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            LyricsColumn(vm: vm)
                .frame(maxHeight: .infinity)

            TransportControls(vm: vm)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Minimal

    private var minimal: some View {
        ClockView(emphasizeSeconds: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Clock

struct ClockView: View {
    var emphasizeSeconds = false

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "h:mm"; return f
    }()
    private static let dateFmt: DateFormatter = {
        // Short iOS-lockscreen style, e.g. "Fri May 8".
        let f = DateFormatter(); f.dateFormat = "EEE MMM d"; return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            VStack(spacing: 0) {
                Text(Self.dateFmt.string(from: ctx.date))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.75))
                Text(Self.timeFmt.string(from: ctx.date))
                    .font(.system(size: 84, weight: .bold, design: .rounded))
                    // iOS-lockscreen translucent-white clock.
                    .foregroundStyle(.white.opacity(0.82))
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    .monospacedDigit()
            }
        }
    }
}

// MARK: - Karaoke lyrics (Apple Music style)

/// Large, centered-on-current-line lyrics: current line bold white, neighbours
/// dimmed. Lyric text is fetched at runtime from LRCLIB; nothing is bundled.
struct KaraokeLyrics: View {
    @ObservedObject var vm: NowPlayingModel

    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        if vm.lyrics.isEmpty {
                            Text(vm.hasMedia ? "No synced lyrics for this track" : "Nothing playing")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.top, 30)
                        }
                        ForEach(Array(vm.lyrics.enumerated()), id: \.element.id) { idx, line in
                            Button {
                                vm.seek(toTime: line.time)
                            } label: {
                                Text(line.text.isEmpty ? "♪" : line.text)
                                    .font(.system(size: isCurrent(idx) ? 26 : 22, weight: .bold))
                                    .foregroundStyle(opacity(idx))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(idx)
                            .animation(.easeInOut(duration: 0.3), value: vm.currentLyricIndex)
                        }
                    }
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .mask(
                    // Fade top/bottom edges like the real karaoke view.
                    LinearGradient(
                        colors: [.clear, .black, .black, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .onChange(of: vm.currentLyricIndex) { _, new in
                    guard let new else { return }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(new, anchor: .center)
                    }
                }
            }
        }
    }

    private func isCurrent(_ idx: Int) -> Bool { idx == vm.currentLyricIndex }

    private func opacity(_ idx: Int) -> Color {
        if isCurrent(idx) { return .white }
        if let cur = vm.currentLyricIndex, idx < cur { return .white.opacity(0.28) }
        return .white.opacity(0.45)
    }
}

// MARK: - Now Playing card (used in lockscreen)

struct NowPlayingCard: View {
    @ObservedObject var vm: NowPlayingModel

    var body: some View {
        VStack(spacing: 12) {
            // The current synced lyric line, tinted from the album palette.
            if let lyric = vm.currentLyric {
                Text(lyric)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: vm.palette.count >= 2 ? Array(vm.palette.prefix(2)) : [.white, .white],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .id(lyric)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            // Same compact player card as the island, on frosted glass.
            PlayerCard(vm: vm)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// MARK: - Transport controls

struct TransportControls: View {
    @ObservedObject var vm: NowPlayingModel
    var compact = false

    private var big: CGFloat { compact ? 22 : 30 }
    private var small: CGFloat { compact ? 15 : 20 }

    var body: some View {
        HStack(spacing: compact ? 30 : 40) {
            glyph("backward.fill", small) { vm.previous() }
            glyph(vm.isPlaying ? "pause.fill" : "play.fill", big) { vm.togglePlayPause() }
            glyph("forward.fill", small) { vm.next() }
        }
        .disabled(!vm.hasMedia)
        .opacity(vm.hasMedia ? 1 : 0.4)
    }

    private func glyph(_ name: String, _ size: CGFloat, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.white)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Lyrics column

struct LyricsColumn: View {
    @ObservedObject var vm: NowPlayingModel

    var body: some View {
        GeometryReader { _ in
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        if vm.lyrics.isEmpty {
                            Text(vm.hasMedia ? "Searching for synced lyrics…" : "Nothing playing")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.top, 20)
                        }
                        ForEach(Array(vm.lyrics.enumerated()), id: \.element.id) { idx, line in
                            Button {
                                vm.seek(toTime: line.time)
                            } label: {
                                Text(line.text.isEmpty ? "♪" : line.text)
                                    .font(.system(size: isCurrent(idx) ? 19 : 15,
                                                   weight: isCurrent(idx) ? .bold : .medium))
                                    .foregroundStyle(foreground(idx))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .id(idx)
                            .animation(.easeInOut(duration: 0.25), value: vm.currentLyricIndex)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                }
                .onChange(of: vm.currentLyricIndex) { _, new in
                    guard let new else { return }
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo(new, anchor: .center)
                    }
                }
            }
        }
    }

    private func isCurrent(_ idx: Int) -> Bool { idx == vm.currentLyricIndex }

    private func foreground(_ idx: Int) -> AnyShapeStyle {
        if isCurrent(idx) {
            let colors = vm.palette.count >= 2 ? Array(vm.palette.prefix(2)) : [.white, .white]
            return AnyShapeStyle(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing))
        }
        if let cur = vm.currentLyricIndex, idx < cur {
            return AnyShapeStyle(Color.white.opacity(0.35))
        }
        return AnyShapeStyle(Color.white.opacity(0.55))
    }
}
