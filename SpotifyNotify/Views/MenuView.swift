//
//  MenuView.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import SwiftUI
import AppKit

struct MenuView: View {
    @Environment(\.openWindow) private var openWindow
    
    @EnvironmentObject var spotifyInteractor: SpotifyInteractor
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    @State private var isHoveringPrevious = false
    @State private var isHoveringPlayPause = false
    @State private var isHoveringNext = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Menu {
                Button {
                    spotifyInteractor.openSpotify()
                } label: {
                    Text("Open Spotify")
                    Image(systemName: "play.house")
                }
                Divider()
                Button {
                    openWindow(id: "settings-window")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Text("Settings")
                    Image(systemName: "gear")
                }
                Button {
                    NSApp.terminate(nil)
                } label: {
                    Text("Quit")
                    Image(systemName: "power")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuIndicator(.hidden)
            .menuStyle(.borderlessButton)
            .frame(width: 25, height: 20)
            .padding()
            
            HStack {
                ZStack(alignment: .center) {
                    AsyncImage(url: spotifyInteractor.currentTrack.artworkURL) { phase in
                        CoverImageView(image: phase.image ?? Image("IconSettings"), album: spotifyInteractor.currentTrack.album)
                    }
                    .padding()
                    .frame(width: 200, height: 200)
                }
                
                Spacer()
                
                VStack {
                    Spacer()
                    Text(spotifyInteractor.currentTrack.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                        .animation(.default, value: spotifyInteractor.currentTrack)
                    Text(spotifyInteractor.currentTrack.artist)
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                        .animation(.default, value: spotifyInteractor.currentTrack)
                    HStack {
                        Text(spotifyInteractor.currentTrackProgress)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        ProgressView(value: spotifyInteractor.currentProgressPercent, total: 1.0)
                            .tint(Color(.progress))
                        Text(spotifyInteractor.fullTrackDuration)
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
                                spotifyInteractor.previousTrack()
                            }
                            .onHover { isHovering in
                                withAnimation {
                                    isHoveringPrevious = isHovering
                                }
                            }
                        if #available(macOS 14.0, *) {
                            Image(systemName: spotifyInteractor.currentState == .playing ? "pause.fill" : "play.fill")
                                .frame(width: 25, height: 25)
                                .font(.largeTitle)
                                .padding()
                                .background(Color.primary.opacity(isHoveringPlayPause ? 0.3 : 0.1))
                                .clipShape(Circle())
                                .onTapGesture {
                                    spotifyInteractor.playPause()
                                }
                                .onHover { isHovering in
                                    withAnimation {
                                        isHoveringPlayPause = isHovering
                                    }
                                }
                                .contentTransition(.symbolEffect)
                        }
                        else {
                            Image(systemName: spotifyInteractor.currentState == .playing ? "pause.fill" : "play.fill")
                                .frame(width: 25, height: 25)
                                .font(.largeTitle)
                                .padding()
                                .background(Color.primary.opacity(isHoveringPlayPause ? 0.3 : 0.1))
                                .clipShape(Circle())
                                .onTapGesture {
                                    spotifyInteractor.playPause()
                                }
                                .onHover { isHovering in
                                    withAnimation {
                                        isHoveringPlayPause = isHovering
                                    }
                                }
                                .animation(.default, value: spotifyInteractor.currentState == .playing)
                        }

                        Image(systemName: "forward.fill")
                            .frame(width: 20, height: 20)
                            .font(.title3)
                            .padding()
                            .background(Color.primary.opacity(isHoveringNext ? 0.3 : 0.1))
                            .clipShape(Circle())
                            .onTapGesture {
                                spotifyInteractor.nextTrack()
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
            .frame(width: 500, height: 200)
            .padding()
        }
    }
}

private struct CoverImageView: View {
    @State private var shouldShowAlbumName = false
    
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
            
            if let album = album {
                Text(album)
                    .padding()
                    .font(.body)
                    .minimumScaleFactor(0.8)
                    .shadow(color: Color.black, radius: 3)
                    .opacity(shouldShowAlbumName ? 1 : 0)
            }
        }
        .onHover { isHovering in
            withAnimation {
                shouldShowAlbumName = isHovering
            }
        }
        .animation(.default, value: image)
    }
}

private extension SpotifyPlayerState {
    var localized: String {
        switch self {
        case .paused:
            "Paused"
        case .stopped:
            "Stopped"
        case .playing:
            "Playing"
        case .unknown:
            "Unknown"
        }
    }
}
