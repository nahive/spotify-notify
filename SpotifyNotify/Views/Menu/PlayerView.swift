//
//  File.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2025/01/22.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import SwiftUI

struct PlayerView: View {
    let musicInteractor: MusicInteractor
    let track: MusicTrack?
    
    var body: some View {
        if let track = track {
            PlayingView(musicInteractor: musicInteractor, track: track)
        } else {
            NothingPlayingView(musicInteractor: musicInteractor)
        }
    }
}

struct PlayingView: View {
    let musicInteractor: MusicInteractor
    let track: MusicTrack
    
    @State private var hoverTarget: PlayerHoverTarget = .none
    
    private enum Layout {
        static let albumArtSize: CGFloat = 100
        static let albumArtPadding: CGFloat = 8
        static let buttonPadding: CGFloat = 10
        static let smallButtonSize: CGFloat = 15
        static let playButtonSize: CGFloat = 20
        static let hoverOpacity: CGFloat = 0.3
        static let defaultOpacity: CGFloat = 0.1
        static let buttonSpacing: CGFloat = 8
        static let trackInfoSpacing: CGFloat = 4
    }
    
    var body: some View {
        HStack {
            albumArtworkView
            trackInfoView
            controlButtonsView
        }
    }
    
    private var albumArtworkView: some View {
        Group {
            if let artwork = track.artwork {
                switch artwork {
                case .url(let url):
                    AsyncImage(url: url) { phase in
                        CoverImageView(image: phase.image ?? Image("IconSettings"), album: track.album)
                    }
                    .padding(Layout.albumArtPadding)
                    .frame(width: Layout.albumArtSize, height: Layout.albumArtSize)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .accessibilityLabel("Album artwork for \(track.album ?? track.name)")
                case .image(let image):
                    CoverImageView(image: Image(nsImage: image), album: track.album)
                    .padding(Layout.albumArtPadding)
                    .frame(width: Layout.albumArtSize, height: Layout.albumArtSize)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .accessibilityLabel("Album artwork for \(track.album ?? track.name)")
                }
            }
        }
    }
    
    private var trackInfoView: some View {
        VStack(spacing: Layout.trackInfoSpacing) {
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
                .padding(.top, 10)
        }
    }
    
    private var controlButtonsView: some View {
        HStack(spacing: Layout.buttonSpacing) {
            controlButton(
                systemName: "backward.fill",
                size: Layout.smallButtonSize,
                target: .previous,
                accessibilityLabel: "Previous track",
                accessibilityHint: "Double tap to go to previous track",
                action: musicInteractor.previousTrack
            )
            
            controlButton(
                systemName: musicInteractor.currentState == .playing ? "pause.fill" : "play.fill",
                size: Layout.playButtonSize,
                target: .playPause,
                accessibilityLabel: musicInteractor.currentState == .playing ? "Pause" : "Play",
                accessibilityHint: musicInteractor.currentState == .playing ? "Double tap to pause playback" : "Double tap to start playback",
                action: musicInteractor.playPause
            )
            .contentTransition(.symbolEffect)
            
            controlButton(
                systemName: "forward.fill",
                size: Layout.smallButtonSize,
                target: .next,
                accessibilityLabel: "Next track",
                accessibilityHint: "Double tap to go to next track",
                action: musicInteractor.nextTrack
            )
        }
        .padding(.horizontal, 12)
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
            .font(size == Layout.playButtonSize ? .title2 : .body)
            .padding(Layout.buttonPadding)
            .background(Color.primary.opacity(hoverTarget == target ? Layout.hoverOpacity : Layout.defaultOpacity))
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



private extension PlayingView {
    enum PlayerHoverTarget {
        case none, previous, playPause, next
    }
}

struct CustomProgressView: View {
    @ObservedObject var musicInteractor: MusicInteractor
    
    var body: some View {
        VStack(spacing: 2) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    Rectangle()
                        .fill(.white.gradient)
                        .frame(width: geometry.size.width * CGFloat(musicInteractor.currentProgressPercent), height: 3)
                        .cornerRadius(1.5)
                        .shadow(color: .white.opacity(0.3), radius: 1)
                }
            }
            .frame(height: 3)
            .frame(width: 150)
            
            HStack {
                Text(musicInteractor.currentTrackProgress)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(Color.gray)
                
                Spacer()
                
                Text(musicInteractor.fullTrackDuration)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(Color.gray)
            }
            .frame(width: 150)
        }
    }
}
