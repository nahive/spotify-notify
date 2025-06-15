//
//  MenuView.swift
//  Notify
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
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    @EnvironmentObject var historyInteractor: HistoryInteractor
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Menu {
                if let selectedApplication = defaultsInteractor.selectedApplication {
                    Button {
                        musicInteractor.openApplication()
                    } label: {
                        Text("Open \(selectedApplication.appName)")
                        Image(systemName: "play.house")
                    }
                    Divider()
                }
                Button {
                    openWindow(id: "history")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Text("Song History")
                    Image(systemName: "clock")
                }
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
            
            PlayerView(musicInteractor: musicInteractor, track: musicInteractor.currentTrack)
                .padding()
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
