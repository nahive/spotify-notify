import SwiftUI

// MARK: - PlayerView
struct PlayerView: View {
    let musicInteractor: MusicInteractor
    let track: MusicTrack?

    var body: some View {
        if let track = track {
            PlayingView(musicInteractor: musicInteractor, track: track)
        } else if musicInteractor.isPlayingRadio {
            RadioPlayingView(musicInteractor: musicInteractor)
        } else {
            NothingPlayingView(musicInteractor: musicInteractor)
        }
    }
}

// MARK: - PlayingView
/// Mini-player: artwork and title, a full-width scrubber, one transport row
/// with shuffle/repeat at its ends, and volume.
struct PlayingView: View {
    let musicInteractor: MusicInteractor
    let track: MusicTrack

    /// Menu content width; `MenuView` sizes the panel from it.
    static let width: CGFloat = 320
    private static let artworkSize: CGFloat = 64
    /// Header text width: what's left beside the artwork, minus room for the
    /// menu's ⋯ button overlaid at the top-trailing corner.
    private static let textWidth = width - artworkSize - 12 - 28

    private var subtitle: String {
        guard let album = track.album, !album.isEmpty else { return track.artist }
        return "\(track.artist) — \(album)"
    }

    var body: some View {
        VStack(spacing: 14) {
            header
            ScrubberView(musicInteractor: musicInteractor)
            transportRow
            VolumeView(musicInteractor: musicInteractor)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            AlbumArtworkView(track: track, size: Self.artworkSize)

            VStack(alignment: .leading, spacing: 3) {
                MarqueeText(
                    text: track.name,
                    font: .system(size: 15, weight: .semibold),
                    maxWidth: Self.textWidth,
                    fadeEdges: true
                )
                .foregroundStyle(.primary)
                .id("menu-title-\(track.id)")
                .accessibilityLabel("Track name")
                .accessibilityValue(track.name)

                MarqueeText(
                    text: subtitle,
                    font: .system(size: 12),
                    maxWidth: Self.textWidth,
                    fadeEdges: true
                )
                .foregroundStyle(.primary.opacity(0.75))
                .id("menu-subtitle-\(track.id)")
                .accessibilityLabel("Artist and album")
                .accessibilityValue(subtitle)
            }

            Spacer(minLength: 0)
        }
    }

    private var transportRow: some View {
        let isPlaying = musicInteractor.currentState == .playing

        return HStack {
            OptionToggleButton(
                systemName: "shuffle",
                isOn: musicInteractor.isShuffling,
                label: musicInteractor.isShuffling ? "Shuffle on" : "Shuffle off",
                action: musicInteractor.toggleShuffle
            )
            Spacer()
            PlayerControlButton(
                systemName: "backward.fill",
                font: .system(size: 18, weight: .semibold),
                size: 36,
                accessibilityLabel: "Previous track",
                action: musicInteractor.previousTrack
            )
            Spacer()
            PlayerControlButton(
                systemName: isPlaying ? "pause.fill" : "play.fill",
                font: .system(size: 28, weight: .semibold),
                size: 48,
                accessibilityLabel: isPlaying ? "Pause" : "Play",
                action: musicInteractor.playPause
            )
            .contentTransition(.symbolEffect(.replace))
            Spacer()
            PlayerControlButton(
                systemName: "forward.fill",
                font: .system(size: 18, weight: .semibold),
                size: 36,
                accessibilityLabel: "Next track",
                action: musicInteractor.nextTrack
            )
            Spacer()
            OptionToggleButton(
                systemName: musicInteractor.repeatMode == .one ? "repeat.1" : "repeat",
                isOn: musicInteractor.repeatMode != .off,
                label: repeatLabel,
                action: musicInteractor.cycleRepeatMode
            )
        }
    }

    private var repeatLabel: String {
        switch musicInteractor.repeatMode {
        case .off: "Repeat off"
        case .all: "Repeat all"
        case .one: "Repeat one"
        }
    }
}

// MARK: - ScrubberView
private struct ScrubberView: View {
    let musicInteractor: MusicInteractor

    var body: some View {
        VStack(spacing: 4) {
            CapsuleSlider(
                value: musicInteractor.currentProgressPercent,
                accessibilityLabel: "Playback position",
                accessibilityValue: "\(musicInteractor.currentTrackProgress) of \(musicInteractor.fullTrackDuration)",
                onCommit: musicInteractor.seek(to:)
            )

            HStack {
                Text(musicInteractor.currentTrackProgress)
                Spacer()
                Text(musicInteractor.fullTrackDuration)
            }
            .font(.system(size: 10, weight: .medium).monospacedDigit())
            .foregroundStyle(.primary.opacity(0.7))
            .accessibilityHidden(true)
        }
    }
}

// MARK: - VolumeView
private struct VolumeView: View {
    let musicInteractor: MusicInteractor

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
            CapsuleSlider(
                value: Double(musicInteractor.volume) / 100,
                accessibilityLabel: "Volume",
                accessibilityValue: "\(musicInteractor.volume)%",
                onChange: { musicInteractor.setVolume(Int(($0 * 100).rounded())) }
            )
            Image(systemName: "speaker.wave.3.fill")
        }
        .font(.system(size: 10))
        .foregroundStyle(.primary.opacity(0.7))
    }
}

// MARK: - CapsuleSlider
/// Thin capsule track shared by the scrubber and volume: thickens on hover and
/// while dragging. `onChange` fires live; `onCommit` once on release.
struct CapsuleSlider: View {
    let value: Double
    let accessibilityLabel: String
    let accessibilityValue: String
    var onChange: ((Double) -> Void)?
    var onCommit: ((Double) -> Void)?

    @State private var dragValue: Double?
    @State private var isHovering = false

    private var isActive: Bool { isHovering || dragValue != nil }

    var body: some View {
        let shown = min(1, max(0, dragValue ?? value))

        GeometryReader { geo in
            let height: CGFloat = isActive ? 6 : 4
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.15))
                Capsule()
                    .fill(.primary.opacity(isActive ? 0.95 : 0.75))
                    .frame(width: geo.size.width * shown)
            }
            .frame(height: height)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let fraction = min(1, max(0, drag.location.x / max(geo.size.width, 1)))
                        dragValue = fraction
                        onChange?(fraction)
                    }
                    .onEnded { _ in
                        if let dragValue {
                            onCommit?(dragValue)
                        }
                        dragValue = nil
                    }
            )
        }
        .frame(height: 14)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.15), value: isActive)
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityAdjustableAction { direction in
            let next = min(1, max(0, value + (direction == .increment ? 0.05 : -0.05)))
            onChange?(next)
            onCommit?(next)
        }
    }
}

// MARK: - OptionToggleButton
private struct OptionToggleButton: View {
    let systemName: String
    let isOn: Bool
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary.opacity(isOn ? 1 : 0.55))
                .frame(width: 28, height: 28)
                .background(.primary.opacity(isOn ? 0.12 : 0), in: Circle())
                .contentShape(Circle())
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(PressScaleButtonStyle())
        .help(label)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

// MARK: - AlbumArtworkView
struct AlbumArtworkView: View {
    let track: MusicTrack
    var size: CGFloat

    var body: some View {
        Group {
            switch track.artwork {
            case .url(let url):
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        placeholder
                    }
                }
            case .image(let image):
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case nil:
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.primary.opacity(0.1), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
        .help(track.album ?? track.name)
        .accessibilityLabel(track.artwork == nil ? "No album artwork" : "Album artwork for \(track.album ?? track.name)")
    }

    private var placeholder: some View {
        ZStack {
            Rectangle().fill(.quaternary)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
        }
    }
}
