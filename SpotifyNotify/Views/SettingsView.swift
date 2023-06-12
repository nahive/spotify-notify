//
//  SettingsView.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import SwiftUI
import KeyHolder
import Magnet
import LaunchAtLogin

struct SettingsView: View {
    
    private enum Const {
        static let homepage = "https://nahive.github.io".asURL!
        static let repo = "https://github.com/nahive/spotify-notify".asURL!
    }
    
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    @EnvironmentObject var permissionsInteractor: PermissionsInteractor
    
    var body: some View {
        VStack {
            Image(.iconSettings)
                .resizable()
                .frame(width: 150.0, height: 150.0)
                .fixedSize()
                .padding()
            VStack(alignment: .leading) {
                LaunchAtLogin.Toggle("Launch on startup")
                Toggle(isOn: $defaultsInteractor.isMenuIconColored) {
                    Text("Show colored menu bar icon")
                }
                Divider()
                    .padding()
                Toggle(isOn: $defaultsInteractor.areNotificationsEnabled) {
                    Text("Enable notifications")
                }
                VStack(alignment: .leading) {
                    Toggle(isOn: $defaultsInteractor.shouldKeepNotificationsOnScreen) {
                        Text("Keep notifications on screen (swipe right to hide)")
                    }
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
                Divider()
                    .padding()
                VStack(alignment: .leading){
                    Text("Show notification on shortcut")
                    ShortcutView(keyCombo: $defaultsInteractor.shortcut)
                        .frame(minHeight: 30)
                }.padding(.horizontal)
            }
            .padding()
            HStack {
                VStack {
                    HStack(alignment: .center) {
                        Circle()
                            .foregroundStyle(permissionsInteractor.notificationPermissionEnabled ? Color.green : Color.red)
                            .frame(width: 8)
                        Text("Notification permisions")
                    }
                    if !permissionsInteractor.notificationPermissionEnabled {
                        Button("Notification settings") {
                            permissionsInteractor.openNotificationsSettings()
                        }
                    }
                }

                VStack {
                    HStack(alignment: .center) {
                        Circle()
                            .foregroundStyle(permissionsInteractor.automationPermissionEnabled ? Color.green : Color.red)
                            .frame(width: 8)
                        Text("Automation permisions")
                    }
                    if !permissionsInteractor.automationPermissionEnabled {
                        Button("Automation settings") {
                            permissionsInteractor.openAutomationSettings()
                        }
                    }
                }
            }

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
        .frame(minWidth: 400, maxWidth: 400)
    }
}

struct ShortcutView: NSViewRepresentable {
    typealias NSViewType = RecordView
    
    @Binding private var keyCombo: KeyCombo?
    
    init(keyCombo: Binding<KeyCombo?>) {
        self._keyCombo = keyCombo
    }
    
    func makeNSView(context: Context) -> RecordView {
        let view = RecordView(frame: .zero)
        view.tintColor = .gray
        view.cornerRadius = 5
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ recordView: RecordView, context: Context) {
        recordView.keyCombo = keyCombo
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, RecordViewDelegate {
        var parent: ShortcutView
        
        init(parent: ShortcutView) {
            self.parent = parent
        }
        
        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            self.parent.keyCombo = keyCombo
        }
        
        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
            true
        }
        
        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
            true
        }
        
        func recordViewDidEndRecording(_ recordView: RecordView) {
            // nothing
        }
    }
}

struct Settings_Preview: PreviewProvider {
    @StateObject private static var defaultsInteractor = DefaultsInteractor()
    @StateObject private static var permissionsIteractor = PermissionsInteractor()
    
    static var previews: some View {
        SettingsView()
            .environmentObject(defaultsInteractor)
            .environmentObject(permissionsIteractor)
    }
}
