import SwiftUI

/// Minimal pill row for screens without a physical notch: a single centered
/// line of track text with an equalizer.
struct CenteredPill: View {
    let notch: NotchInteractor
    var accent: Color

    var body: some View {
        HStack(spacing: 10) {
            if let track = notch.track {
                MarqueeText(
                    text: track.artist.map { "\(track.title) — \($0)" } ?? track.title,
                    font: .system(size: 11, weight: .medium),
                    maxWidth: 210
                )
                .foregroundStyle(.white.opacity(0.9))
                .id("mini-\(track.id)")
                Spacer(minLength: 10)
                WaveformIcon(color: accent, isPlaying: track.isPlaying, size: 11)
            } else {
                Text("Nothing playing")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        // Well clear of the side sweeps, which cut ~33pt in at the text baseline.
        .padding(.horizontal, 66)
    }
}

/// Minimal pill row for screens with a physical notch: track text and an
/// equalizer on wings either side of the camera housing.
struct PillWings: View {
    let notch: NotchInteractor
    var metrics: NotchMetrics
    var wingWidth: CGFloat
    var accent: Color

    var body: some View {
        let height = metrics.notchSize.height
        HStack(spacing: 0) {
            leftWing
                .frame(width: wingWidth, height: height)
            Color.clear
                .frame(width: metrics.notchSize.width, height: height)
            rightWing(height: height)
                .frame(width: wingWidth, height: height)
        }
    }

    private var leftWing: some View {
        HStack(spacing: 7) {
            if let track = notch.track {
                MarqueeText(
                    text: track.artist.map { "\(track.title) — \($0)" } ?? track.title,
                    font: .system(size: 10.5, weight: .medium),
                    maxWidth: wingWidth - 72
                )
                .foregroundStyle(.white.opacity(0.85))
                .id("mini-\(track.id)")
            }
            Spacer(minLength: 0)
        }
        // Well clear of the side sweep, which cuts ~33pt in at the text baseline.
        .padding(.leading, 60)
    }

    private func rightWing(height: CGFloat) -> some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            if let track = notch.track {
                WaveformIcon(color: .white.opacity(0.5), isPlaying: track.isPlaying, size: height * 0.42)
            }
        }
        .padding(.trailing, 60)
    }
}

/// The card of artwork, track detail and playback controls revealed beneath the
/// pill on hover.
struct ExpandedCard: View {
    let notch: NotchInteractor
    var accent: Color

    var body: some View {
        if let track = notch.track {
            VStack(spacing: 0) {
                // Artwork + track detail on top so a long title has the full
                // width to itself and can never squeeze the controls.
                HStack(spacing: 12) {
                    ArtworkThumb(image: track.artwork, size: 48, cornerRadius: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        MarqueeText(
                            text: track.title,
                            font: .system(size: 13, weight: .semibold),
                            maxWidth: 230
                        )
                        .id("card-title-\(track.id)")
                        if let artist = track.artist {
                            MarqueeText(
                                text: artist,
                                font: .system(size: 11),
                                maxWidth: 230
                            )
                            .foregroundStyle(.white.opacity(0.6))
                            .id("card-artist-\(track.id)")
                        }
                    }
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 8)
                // Controls on their own row, pinned to the bottom.
                HStack(spacing: 32) {
                    MediaButton(icon: "backward.fill", size: 14) { notch.previousTrack() }
                    MediaButton(icon: track.isPlaying ? "pause.fill" : "play.fill", size: 19) {
                        notch.togglePlayPause()
                    }
                    MediaButton(icon: "forward.fill", size: 14) { notch.nextTrack() }
                }
            }
            // Sits inside the card's side walls, which the stretched top
            // flares push in to x = 20.
            .padding(.horizontal, 28)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

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

