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
            MarqueeText(
                text: track.name,
                font: .title2.weight(.semibold),
                color: .primary
            )
            .accessibilityLabel("Track name")
            .accessibilityValue(track.name)
            
            MarqueeText(
                text: track.artist,
                font: .subheadline,
                color: .secondary
            )
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
                    // Background track
                    RoundedRectangle(cornerRadius: isDragging ? 3 : 1.5)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: isDragging ? 6 : 3)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: isDragging ? 3 : 1.5)
                        .fill(.white.gradient)
                        .frame(
                            width: geometry.size.width * CGFloat(displayProgress), 
                            height: isDragging ? 6 : 3
                        )
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

// MARK: - MarqueeText
private struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    
    @State private var offset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var textWidth: CGFloat = 0
    @State private var shouldAnimate = false
    @State private var animationTask: Task<Void, Never>?
    
    private let animationSpeed: Double = 30
    private let pauseDuration: Double = 1.5
    
    var body: some View {
        GeometryReader { geometry in
            if shouldAnimate {
                TimelineView(.animation(minimumInterval: 1.0/60.0)) { _ in
                    textView(alignment: .leading)
                        .offset(x: offset)
                }
                .mask(gradientMask)
            } else {
                textView(alignment: .center)
            }
        }
        .frame(height: nsFont.capHeight + nsFont.leading)
        .onAppear {
            Task {
                await measureTextWidth()
                updateAnimation()
            }
        }
        .onChange(of: text) { _, _ in
            Task {
                await measureTextWidth()
                updateAnimation()
            }
        }
        .onDisappear {
            animationTask?.cancel()
        }
    }
    
    private func textView(alignment: Alignment) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .fixedSize(horizontal: true, vertical: false)
            .frame(maxWidth: .infinity, alignment: alignment)
            .background(
                GeometryReader { textGeometry in
                    Color.clear
                        .onAppear {
                            handleGeometryChange(textGeometry.size.width)
                        }
                        .onChange(of: textGeometry.size.width) { _, newWidth in
                            handleGeometryChange(newWidth)
                        }
                }
            )
    }
    
    private var nsFont: NSFont {
        switch font {
        case .title2:
            return NSFont.preferredFont(forTextStyle: .title2)
        case .subheadline:
            return NSFont.preferredFont(forTextStyle: .subheadline)
        default:
            if font == .title2.weight(.semibold) {
                return NSFont.systemFont(ofSize: NSFont.preferredFont(forTextStyle: .title2).pointSize, weight: .semibold)
            } else {
                return NSFont.systemFont(ofSize: 17)
            }
        }
    }
    
    private var gradientMask: some View {
        HStack(spacing: 0) {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 0.1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 20)
            
            Rectangle()
                .fill(.black)
            
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .black, location: 0.9),
                    .init(color: .clear, location: 1)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 20)
        }
    }
    
    @MainActor
    private func measureTextWidth() async {
        let attributes = [NSAttributedString.Key.font: nsFont]
        let size = (text as NSString).size(withAttributes: attributes)
        textWidth = size.width
    }
    
    private func handleGeometryChange(_ width: CGFloat) {
        containerWidth = width
        updateAnimation()
    }
    
    private func updateAnimation() {
        let needsAnimation = textWidth > containerWidth && containerWidth > 0
        
        animationTask?.cancel()
        offset = 0
        shouldAnimate = needsAnimation
        
        if shouldAnimate {
            startMarqueeAnimation()
        }
    }
    
    private func startMarqueeAnimation() {
        guard shouldAnimate, textWidth > containerWidth else { return }
        
        animationTask = Task { @MainActor in
            let scrollDistance = max(0, textWidth - containerWidth + 30)
            let duration = scrollDistance / animationSpeed
            
            while shouldAnimate && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(pauseDuration))
                guard shouldAnimate && !Task.isCancelled else { break }
                
                withAnimation(.linear(duration: duration)) {
                    offset = -scrollDistance
                }
                
                try? await Task.sleep(for: .seconds(duration))
                guard shouldAnimate && !Task.isCancelled else { break }
                
                try? await Task.sleep(for: .seconds(pauseDuration))
                guard shouldAnimate && !Task.isCancelled else { break }
                
                withAnimation(.linear(duration: duration)) {
                    offset = 0
                }
                
                try? await Task.sleep(for: .seconds(duration))
                guard shouldAnimate && !Task.isCancelled else { break }
            }
        }
    }
}


