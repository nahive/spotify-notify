import SwiftUI

/// Pill content for screens without a physical notch: everything can sit in
/// one centered row since there is no camera housing to avoid.
@available(macOS 26.0, *)
struct CenteredPill: View {
    @ObservedObject var notch: NotchInteractor
    var inline: Bool
    var accent: Color

    var body: some View {
        if inline {
            HStack(spacing: 10) {
                if let track = notch.track {
                    ArtworkThumb(image: track.artwork, size: 30, cornerRadius: 7)
                    VStack(alignment: .leading, spacing: 1) {
                        NotchMarqueeText(
                            text: track.title,
                            font: .system(size: 11.5, weight: .semibold),
                            maxWidth: 170
                        )
                        .id("title-\(track.id)")
                        if let artist = track.artist {
                            NotchMarqueeText(
                                text: artist,
                                font: .system(size: 9.5),
                                maxWidth: 170
                            )
                            .foregroundStyle(.white.opacity(0.55))
                            .id("artist-\(track.id)")
                        }
                    }
                    Spacer(minLength: 6)
                    MediaButton(icon: "backward.fill", size: 10) { notch.previousTrack() }
                    MediaButton(icon: track.isPlaying ? "pause.fill" : "play.fill", size: 13) {
                        notch.togglePlayPause()
                    }
                    MediaButton(icon: "forward.fill", size: 10) { notch.nextTrack() }
                    WaveformIcon(color: accent, isPlaying: track.isPlaying, size: 13)
                } else {
                    Text("Nothing playing")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 14)
        } else if let track = notch.track {
            HStack(spacing: 8) {
                NotchMarqueeText(
                    text: track.artist.map { "\(track.title) — \($0)" } ?? track.title,
                    font: .system(size: 11, weight: .medium),
                    maxWidth: 270
                )
                .foregroundStyle(.white.opacity(0.85))
                .id("mini-\(track.id)")
                WaveformIcon(color: accent, isPlaying: track.isPlaying, size: 11)
            }
        }
    }
}

/// Pill content for screens with a physical notch: wings on either side of
/// the camera housing.
@available(macOS 26.0, *)
struct PillWings: View {
    @ObservedObject var notch: NotchInteractor
    var metrics: NotchMetrics
    var wingWidth: CGFloat
    var inline: Bool
    var accent: Color

    var body: some View {
        let height = metrics.notchSize.height
        HStack(spacing: 0) {
            leftWing(height: height)
                .frame(width: wingWidth, height: height)
            Color.clear
                .frame(width: metrics.notchSize.width, height: height)
            rightWing(height: height)
                .frame(width: wingWidth, height: height)
        }
    }

    @ViewBuilder
    private func leftWing(height: CGFloat) -> some View {
        let artSize = height - 8
        HStack(spacing: 7) {
            if let track = notch.track {
                if inline {
                    ArtworkThumb(image: track.artwork, size: artSize)
                    VStack(alignment: .leading, spacing: 0) {
                        NotchMarqueeText(
                            text: track.title,
                            font: .system(size: 11, weight: .semibold),
                            maxWidth: wingWidth - artSize - 30
                        )
                        .id("title-\(track.id)")
                        if let artist = track.artist, height >= 30 {
                            NotchMarqueeText(
                                text: artist,
                                font: .system(size: 9.5),
                                maxWidth: wingWidth - artSize - 30
                            )
                            .foregroundStyle(.white.opacity(0.6))
                            .id("artist-\(track.id)")
                        }
                    }
                } else {
                    NotchMarqueeText(
                        text: track.artist.map { "\(track.title) — \($0)" } ?? track.title,
                        font: .system(size: 10.5, weight: .medium),
                        maxWidth: wingWidth - 20
                    )
                    .foregroundStyle(.white.opacity(0.85))
                    .id("mini-\(track.id)")
                }
            } else if inline {
                Text("Nothing playing")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.leading, 9)
    }

    @ViewBuilder
    private func rightWing(height: CGFloat) -> some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            if inline, let track = notch.track {
                MediaButton(icon: "backward.fill", size: 10) { notch.previousTrack() }
                MediaButton(icon: track.isPlaying ? "pause.fill" : "play.fill", size: 12) {
                    notch.togglePlayPause()
                }
                MediaButton(icon: "forward.fill", size: 10) { notch.nextTrack() }
            }
            if let track = notch.track {
                WaveformIcon(
                    color: inline ? accent : .white.opacity(0.5),
                    isPlaying: track.isPlaying,
                    size: height * 0.42
                )
            }
        }
        .padding(.trailing, 11)
    }
}

@available(macOS 26.0, *)
struct ArtworkThumb: View {
    var image: NSImage?
    var size: CGFloat
    var cornerRadius: CGFloat = 4

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    Color.white.opacity(0.12)
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.45))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

@available(macOS 26.0, *)
struct MediaButton: View {
    var icon: String
    var size: CGFloat
    var action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white.opacity(hovering ? 1 : 0.85))
                .frame(width: size + 12, height: size + 12)
                .background(.white.opacity(hovering ? 0.15 : 0), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

@available(macOS 26.0, *)
struct WaveformIcon: View {
    var color: Color
    var isPlaying: Bool
    var size: CGFloat

    var body: some View {
        Image(systemName: "waveform")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .symbolEffect(.variableColor.iterative, isActive: isPlaying)
            .frame(height: size)
    }
}

@available(macOS 26.0, *)
struct NotchMarqueeText: View {
    var text: String
    var font: Font
    var maxWidth: CGFloat

    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0

    var body: some View {
        Text(text)
            .font(font)
            .lineLimit(1)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                textWidth = width
                guard width > maxWidth else { return }
                let distance = width - maxWidth
                withAnimation(
                    .linear(duration: Double(distance) / 18)
                        .repeatForever(autoreverses: true)
                        .delay(1.2)
                ) {
                    offset = -distance
                }
            }
            .offset(x: offset)
            .frame(width: textWidth == 0 ? nil : min(textWidth, maxWidth), alignment: .leading)
            .clipped()
    }
}
