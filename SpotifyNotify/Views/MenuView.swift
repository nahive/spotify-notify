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
    
    var body: some View {
        VStack {
            Button("Status: \(spotifyInteractor.currentState.localized)") {}
                .disabled(true)
            Divider()
            Button("Previous Song") {
                spotifyInteractor.previousTrack()
            }
            Button("Play/Pause") {
                spotifyInteractor.playPause()
            }
            Button("Next Song") {
                spotifyInteractor.nextTrack()
            }
            Divider()
            if #available(macOS 14.0, *) {
                SettingsLink()
            } else {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
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
