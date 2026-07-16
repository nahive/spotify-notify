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
struct PlayingView: View {
    let musicInteractor: MusicInteractor
    let track: MusicTrack
    
    var body: some View {
        HStack(spacing: 12) {
            albumArtworkView
            trackInfoView
            Spacer(minLength: 0)
            controlButtonsView
        }
        .padding(.trailing, 40)
    }
    
    // MARK: - Private View Components
    private var albumArtworkView: some View {
        AlbumArtworkView(track: track)
    }
    
    private var trackInfoView: some View {
        VStack(spacing: 4) {
            MarqueeText(
                text: track.name,
                font: .title2.weight(.semibold),
                maxWidth: 130,
                speed: 30,
                fadeEdges: true
            )
            .foregroundStyle(.primary)
            .id("menu-title-\(track.id)")
            .accessibilityLabel("Track name")
            .accessibilityValue(track.name)

            MarqueeText(
                text: track.artist,
                font: .subheadline,
                maxWidth: 130,
                speed: 30,
                fadeEdges: true
            )
            .foregroundStyle(.secondary)
            .id("menu-artist-\(track.id)")
            .accessibilityLabel("Artist name")
            .accessibilityValue(track.artist)

            CustomProgressView(musicInteractor: musicInteractor)
                .padding(.top, 12)
        }
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 8) {
            PlayerControlButton(
                systemName: "backward.fill",
                accessibilityLabel: "Previous track",
                accessibilityHint: "Go to previous track",
                action: musicInteractor.previousTrack
            )

            PlayerControlButton(
                systemName: musicInteractor.currentState == .playing ? "pause.fill" : "play.fill",
                font: .title2,
                accessibilityLabel: musicInteractor.currentState == .playing ? "Pause" : "Play",
                accessibilityHint: musicInteractor.currentState == .playing ? "Pause playback" : "Start playback",
                action: musicInteractor.playPause
            )
            .contentTransition(.symbolEffect)

            PlayerControlButton(
                systemName: "forward.fill",
                accessibilityLabel: "Next track",
                accessibilityHint: "Go to next track",
                action: musicInteractor.nextTrack
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - CustomProgressView
private struct CustomProgressView: View {
    let musicInteractor: MusicInteractor
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    private var displayProgress: Double {
        isDragging ? dragProgress : musicInteractor.currentProgressPercent
    }
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: isDragging ? 3 : 1.5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: isDragging ? 6 : 3)
                    
                    RoundedRectangle(cornerRadius: isDragging ? 3 : 1.5)
                        .fill(Color.primary.gradient)
                        .frame(
                            width: geometry.size.width * CGFloat(displayProgress), 
                            height: isDragging ? 6 : 3
                        )
                        .shadow(color: .primary.opacity(0.2), radius: 2)
                }
                .animation(.easeInOut(duration: 0.2), value: isDragging)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let progress = max(0, min(1, value.location.x / geometry.size.width))
                            dragProgress = progress
                            isDragging = true
                        }
                        .onEnded { _ in
                            musicInteractor.seek(to: dragProgress)
                            isDragging = false
                        }
                )
            }
            .frame(width: 130, height: 6)
            
            HStack {
                Text(musicInteractor.currentTrackProgress)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(musicInteractor.fullTrackDuration)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 130)
        }
    }
}

// MARK: - AlbumArtworkView
struct AlbumArtworkView: View {
    let track: MusicTrack
    
    var body: some View {
        Group {
            if let artwork = track.artwork {
                switch artwork {
                case .url(let url):
                    AsyncImage(url: url) { phase in
                        CoverImageView(image: phase.image ?? Image("IconSettings"), album: track.album)
                    }
                    .albumArtworkModifier()
                    .accessibilityLabel("Album artwork for \(track.album ?? track.name)")
                    
                case .image(let image):
                    CoverImageView(image: Image(nsImage: image), album: track.album)
                    .albumArtworkModifier()
                    .accessibilityLabel("Album artwork for \(track.album ?? track.name)")
                }
            }
        }
    }
}

// MARK: - View Extensions
private extension View {
    func albumArtworkModifier() -> some View {
        self
            .padding(8)
            .frame(width: 100, height: 100)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - CoverImageView
private struct CoverImageView: View {
    @State private var shouldShowAlbumName = false
    @State private var isHovering = false
    
    let image: Image
    let album: String?
    
    var body: some View {
        ZStack {
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blur(radius: 100)
                .offset(x: 0, y: 5)
                .opacity(shouldShowAlbumName ? 0.3 : 1)
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blur(radius: 20)
                .offset(x: 0, y: 5)
                .opacity(shouldShowAlbumName ? 0.3 : 1)
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(shouldShowAlbumName ? 0.3 : 1)
                .blur(radius: isHovering ? 2 : 0)
            
            if let album = album {
                Text(album)
                    .padding()
                    .font(.body)
                    .minimumScaleFactor(0.8)
                    .shadow(color: Color.black, radius: 3)
                    .opacity(shouldShowAlbumName ? 1 : 0)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
                shouldShowAlbumName = hovering
            }
        }
        .animation(.default, value: image)
    }
}
