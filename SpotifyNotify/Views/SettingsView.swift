//
//  SettingsView.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    private enum Const {
        static let homepage = "https://nahive.github.io".asURL!
        static let repo = "https://github.com/nahive/spotify-notify".asURL!
    }
    
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    
    var body: some View {
        VStack {
            Image(.iconSettings)
                .resizable()
                .frame(width: 150.0, height: 150.0)
                .fixedSize()
                .padding()
            VStack(alignment: .leading) {
                Toggle(isOn: $defaultsInteractor.shouldStartOnLogin) {
                    Text("Launch on startup")
                }
                Toggle(isOn: $defaultsInteractor.isMenuIconColored) {
                    Text("Show colored menu bar icon")
                }
                Toggle(isOn: $defaultsInteractor.areNotificationsEnabled) {
                    Text("Enable notifications")
                }
                Divider()
                VStack(alignment: .leading) {
                    Toggle(isOn: $defaultsInteractor.shouldShowNotificationOnPlayPause) {
                        Text("Notify on play/pause")
                    }
                    Toggle(isOn: $defaultsInteractor.shouldPlayNotificationsSound) {
                        Text("Play notification sound")
                    }
                    Toggle(isOn: $defaultsInteractor.shouldDisableNotificationsOnFocus) {
                        Text("Disable notifications when Spotify in focused")
                    }
                    Toggle(isOn: $defaultsInteractor.shouldShowAlbumArt) {
                        Text("Include album art")
                    }
                    Toggle(isOn: $defaultsInteractor.shouldRoundAlbumArt) {
                        Text("Round album art")
                    }
                    .padding(.leading)
                    .disabled(!defaultsInteractor.shouldShowAlbumArt)
                    Toggle(isOn: $defaultsInteractor.shouldShowSongProgress) {
                        Text("Show song progress")
                    }
                }
                .padding(.leading)
                .disabled(!defaultsInteractor.areNotificationsEnabled)
            }
            .padding()
            HStack {
                Button("Source") {
                    NSWorkspace.shared.open(Const.repo)
                }
                Button("Home") {
                    NSWorkspace.shared.open(Const.homepage)
                }
                Button("Quit") {
                    NSApp.terminate(nil)
                }
            }
            .padding()
            Text("Created with ❤ by nahive")
                .padding(.bottom)
                .foregroundStyle(Color.gray)
                .font(.system(size: 10))
        }
        .frame(minWidth: 350, maxWidth: 350)
    }
}

struct Settings_Preview: PreviewProvider {
    @StateObject private static var defaultsInteractor = DefaultsInteractor()
    
    static var previews: some View {
        SettingsView()
            .environmentObject(defaultsInteractor)
    }
}
