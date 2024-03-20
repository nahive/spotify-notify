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
    
    @EnvironmentObject var spotifyInteractor: SpotifyInteractor
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    @State private var isHoveringPrevious = false
    @State private var isHoveringPlayPause = false
    @State private var isHoveringNext = false
    @State private var currentTrackDuration = "--:--"
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var currentTrack: Track {
        guard let track = spotifyInteractor.currentTrack else {
            return .init(id: UUID().uuidString,
                         name: "Unknown",
                         album: "Unknown",
                         artist: "Unkown",
                         artworkURL: nil,
                         duration: 0)!
        }
        return track
    }
    
    private var calculatedTrackDuration: String {
        let duration = Duration.seconds(spotifyInteractor.currentProgress)
        return duration.formatted(.time(pattern: .minuteSecond))
    }
    
    private var fullTrackDuration: String {
        guard let trackDuration = currentTrack.duration else {
            return "--:--"
        }
        let duration = Duration.milliseconds(trackDuration)
        return duration.formatted(.time(pattern: .minuteSecond))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Menu {
                Button {
                    AppOpener.openSpotify()
                } label: {
                    Text("Open Spotify")
                    Image(systemName: "play.house")
                }
                Divider()
                if #available(macOS 14.0, *) {
                    SettingsLink {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
                }
                else {
                    Button {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        Text("Settings")
                        Image(systemName: "gear")
                    }
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
                    AsyncImage(url: currentTrack.artworkURL) { phase in
                        CoverImageView(image: phase.image ?? Image("IconSettings"), album: currentTrack.album)
                    }
                    .padding()
                    .frame(width: 200, height: 200)
                }
                
                Spacer()
                
                VStack {
                    Spacer()
                    Text(currentTrack.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(currentTrack.artist)
                        .font(.title3)
                        .foregroundStyle(Color.gray)
                    HStack {
                        Text(currentTrackDuration)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                        ProgressView(value: spotifyInteractor.currentProgressPercent, total: 1.0)
                            .tint(Color(.progress))
                        Text(fullTrackDuration)
                            .font(.caption)
                            .foregroundStyle(Color.gray)
                    }
                    .onAppear {
                        currentTrackDuration = calculatedTrackDuration
                    }
                    .onReceive(timer) { _ in
                        currentTrackDuration = calculatedTrackDuration
                    }
                    HStack {
                        Image(systemName: "backward.fill")
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
                        Image(systemName: spotifyInteractor.currentState == .playing ? "pause.fill" : "play.fill")
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
                        Image(systemName: "forward.fill")
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
    
    @State private var glowYOffset = -5.0
    @State private var glowXOffset = -5.0
    @State private var glowOpacity = 1.0
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
            
            if let album = album {
                Text(album)
                    .padding()
                    .font(.body)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .opacity(shouldShowAlbumName ? 1 : 0)
            }
        }
        .onHover { isHovering in
            withAnimation {
                shouldShowAlbumName = isHovering
            }
        }
    }
}

#Preview {
    MenuView()
        .environmentObject(SpotifyInteractor())
        .environmentObject(NotificationsInteractor())
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
