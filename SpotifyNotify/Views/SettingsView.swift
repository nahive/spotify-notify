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
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    var body: some View {
        VStack {
            Image(.iconSettings)
                .resizable()
                .frame(width: 150.0, height: 150.0)
                .fixedSize()
                .padding()
            VStack(alignment: .leading) {
                LaunchAtLogin.Toggle("Launch on startup")
                Toggle(isOn: $defaultsInteractor.deprecated_isMenuIconVisible) {
                    Text("Show menu bar icon")
                }
                .disabled(true)
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
                        Text("Display notification on play | pause")
                    }
                    Toggle(isOn: $defaultsInteractor.shouldPlayNotificationsSound) {
                        Text("Play notification sound")
                    }
                    Toggle(isOn: $defaultsInteractor.shouldDisableNotificationsOnFocus) {
                        Text("Disable notifications when Spotify is focused")
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
                        Text("Display song progress in notification")
                    }
                }
                .padding(.leading)
                .disabled(!defaultsInteractor.areNotificationsEnabled)
                Divider()
                    .padding()
                VStack(alignment: .leading){
                    Text("Show notification on shortcut")
                    ShortcutView(notificationsInteractor: notificationsInteractor, keyCombo: $defaultsInteractor.shortcut)
                        .frame(minHeight: 30, maxHeight: 30)
                }.padding(.horizontal)
            }
            .padding()
            HStack {
                VStack {
                    HStack(alignment: .center) {
                        Circle()
                            .foregroundStyle(permissionsInteractor.notificationPermissionEnabled ? Color.green : Color.red)
                            .frame(width: 8)
                        Text("Notification permissions")
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
                        Text("Automation permissions")
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
    
    private let notificationsInteractor: NotificationsInteractor
    
    @Binding private var keyCombo: KeyCombo?
    
    init(notificationsInteractor: NotificationsInteractor, keyCombo: Binding<KeyCombo?>) {
        self.notificationsInteractor = notificationsInteractor
        self._keyCombo = keyCombo
    }
    
    func makeNSView(context: Context) -> RecordView {
        let view = RecordView(frame: .zero)
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
    
    @MainActor
    class Coordinator: NSObject, @preconcurrency RecordViewDelegate {
        var parent: ShortcutView
        
        init(parent: ShortcutView) {
            self.parent = parent
        }
        
        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
            self.parent.keyCombo = keyCombo
            
            if let keyCombo {
                let hotKey = HotKey(identifier: "showKey", keyCombo: keyCombo) { key in
                    self.parent.notificationsInteractor.forceShowNotification()
                }
                HotKeyCenter.shared.register(with: hotKey)
            } else {
                HotKeyCenter.shared.unregisterAll()
            }
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
