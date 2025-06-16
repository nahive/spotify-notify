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
    @StateObject var musicInteractor: MusicInteractor
    let track: MusicTrack
    
    @State private var hoverTarget: PlayerHoverTarget = .none
    
    var body: some View {
        HStack {
            albumArtworkView
            trackInfoView
            controlButtonsView
        }
    }
    
    // MARK: - Private View Components
    private var albumArtworkView: some View {
        AlbumArtworkView(track: track)
    }
    
    private var trackInfoView: some View {
        VStack(spacing: 4) {
            Text(track.name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .animation(.default, value: track.name)
                .accessibilityLabel("Track name")
                .accessibilityValue(track.name)
            Text(track.artist)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(.default, value: musicInteractor.currentTrack)
                .accessibilityLabel("Artist name")
                .accessibilityValue(track.artist)
            CustomProgressView(musicInteractor: musicInteractor)
                .padding(.top, 12)
        }
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: 8) {
            controlButton(
                systemName: "backward.fill",
                size: 15,
                target: .previous,
                accessibilityLabel: "Previous track",
                accessibilityHint: "Double tap to go to previous track",
                action: musicInteractor.previousTrack
            )
            
            controlButton(
                systemName: musicInteractor.currentState == .playing ? "pause.fill" : "play.fill",
                size: 20,
                target: .playPause,
                accessibilityLabel: musicInteractor.currentState == .playing ? "Pause" : "Play",
                accessibilityHint: musicInteractor.currentState == .playing ? "Double tap to pause playback" : "Double tap to start playback",
                action: musicInteractor.playPause
            )
            .contentTransition(.symbolEffect)
            
            controlButton(
                systemName: "forward.fill",
                size: 15,
                target: .next,
                accessibilityLabel: "Next track",
                accessibilityHint: "Double tap to go to next track",
                action: musicInteractor.nextTrack
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private func controlButton(
        systemName: String,
        size: CGFloat,
        target: PlayerHoverTarget,
        accessibilityLabel: String,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) -> some View {
        Image(systemName: systemName)
            .frame(width: size, height: size)
            .font(size == 20 ? .title2 : .body)
            .padding(10)
            .background(Color.primary.opacity(hoverTarget == target ? 0.3 : 0.1))
            .clipShape(Circle())
            .scaleEffect(hoverTarget == target ? 1.1 : 1.0)
            .shadow(color: .primary.opacity(0.2), radius: hoverTarget == target ? 4 : 0)
            .onTapGesture(perform: action)
            .onHover { isHovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    hoverTarget = isHovering ? target : .none
                }
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - PlayerHoverTarget
private extension PlayingView {
    enum PlayerHoverTarget {
        case none, previous, playPause, next
    }
}

// MARK: - CustomProgressView
struct CustomProgressView: View {
    @ObservedObject var musicInteractor: MusicInteractor
    @State private var isDragging = false
    @State private var dragProgress: Double = 0
    
    private var displayProgress: Double {
        isDragging ? dragProgress : musicInteractor.currentProgressPercent
    }
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: isDragging ? 6 : 3)
                        .cornerRadius(isDragging ? 3 : 1.5)
                    
                    Rectangle()
                        .fill(.white.gradient)
                        .frame(
                            width: geometry.size.width * CGFloat(displayProgress), 
                            height: isDragging ? 6 : 3
                        )
                        .cornerRadius(isDragging ? 3 : 1.5)
                        .shadow(color: .white.opacity(0.3), radius: 2)
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
            .frame(width: 150, height: 6)
            
            HStack {
                Text(musicInteractor.currentTrackProgress)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(Color.white.opacity(0.3))
                
                Spacer()
                
                Text(musicInteractor.fullTrackDuration)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .frame(width: 150)
        }
    }
}
