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
    @Environment(\.openSettings) private var openSettings
    
    @EnvironmentObject var musicInteractor: MusicInteractor
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Menu {
//                Button {
//                    SystemNavigator.openApplication()
//                } label: {
//                    Text("Open Spotify")
//                    Image(systemName: "play.house")
//                }
                Divider()
                Button {
                    openSettings()
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
            
            if let track = musicInteractor.currentTrack {
                PlayerView(musicInteractor: musicInteractor, track: track)
                    .frame(width: 300, height: 100)
                    .padding()
            } else {
                Text("NO TRACKS")
                    .frame(width: 500, height: 200)
                    .padding()
            }
        }
    }
}

private extension MusicPlayerState {
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
