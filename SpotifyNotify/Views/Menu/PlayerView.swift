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
    let track: MusicTrack
    
    @State private var isHoveringPrevious = false
    @State private var isHoveringPlayPause = false
    @State private var isHoveringNext = false
    
    var body: some View {
        HStack {
            if let artwork = track.artwork {
                switch artwork {
                case .url(let url):
                    ZStack(alignment: .center) {
                        AsyncImage(url: url) { phase in
                            CoverImageView(image: phase.image ?? Image("IconSettings"), album: track.album)
                        }
                        .padding()
                        .frame(width: 200, height: 200)
                    }
                case .image(let image):
                    ZStack(alignment: .center) {
                        CoverImageView(image: Image(nsImage: image), album: track.album)
                        .padding()
                        .frame(width: 200, height: 200)
                    }
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                Text(track.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .animation(.default, value: track.name)
                Text(track.artist)
                    .font(.title3)
                    .foregroundStyle(Color.gray)
                    .animation(.default, value: musicInteractor.currentTrack)
                HStack {
                    Text(musicInteractor.currentTrackProgress)
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    ProgressView(value: musicInteractor.currentProgressPercent, total: 1.0)
                        .tint(Color(.progress))
                    Text(musicInteractor.fullTrackDuration)
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                }
                HStack {
                    Image(systemName: "backward.fill")
                        .frame(width: 20, height: 20)
                        .font(.title3)
                        .padding()
                        .background(Color.primary.opacity(isHoveringPrevious ? 0.3 : 0.1))
                        .clipShape(Circle())
                        .onTapGesture {
                            musicInteractor.previousTrack()
                        }
                        .onHover { isHovering in
                            withAnimation {
                                isHoveringPrevious = isHovering
                            }
                        }
                    
                    Image(systemName: musicInteractor.currentState == .playing ? "pause.fill" : "play.fill")
                        .frame(width: 25, height: 25)
                        .font(.largeTitle)
                        .padding()
                        .background(Color.primary.opacity(isHoveringPlayPause ? 0.3 : 0.1))
                        .clipShape(Circle())
                        .onTapGesture {
                            musicInteractor.playPause()
                        }
                        .onHover { isHovering in
                            withAnimation {
                                isHoveringPlayPause = isHovering
                            }
                        }
                        .contentTransition(.symbolEffect)

                    Image(systemName: "forward.fill")
                        .frame(width: 20, height: 20)
                        .font(.title3)
                        .padding()
                        .background(Color.primary.opacity(isHoveringNext ? 0.3 : 0.1))
                        .clipShape(Circle())
                        .onTapGesture {
                            musicInteractor.nextTrack()
                        }
                        .onHover { isHovering in
                            withAnimation {
                                isHoveringNext = isHovering
                            }
                        }
                }
                Spacer()
            }
            Spacer()
        }
    }
}
