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
import Combine

struct SettingsView: View {
    @EnvironmentObject var defaultsInteractor: DefaultsInteractor
    @EnvironmentObject var musicInteractor: MusicInteractor
    @EnvironmentObject var notificationsInteractor: NotificationsInteractor
    
    var body: some View {
        TabView {
            GeneralSettingsView(defaultsInteractor: defaultsInteractor,
                                musicInteractor: musicInteractor,
                                notificationsInteractor: notificationsInteractor)
                .tabItem {
                    Label("General", systemImage: "tray.and.arrow.down.fill")
                }
            
            NotificationSettingsView(defaultsInteractor: defaultsInteractor)
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "person")
                }
        }
        .tabViewStyle(.automatic)
        .padding()
    }
}


private struct GeneralSettingsView: View {
    enum SelectableMusicApplication: CaseIterable {
        case none, spotify, applemusic
        
        var name: String {
            switch self {
            case .none:
                return "None"
            case .spotify:
                return "Spotify"
            case .applemusic:
                return "Apple Music"
            }
        }
    }
    
    let defaultsInteractor: DefaultsInteractor
    let musicInteractor: MusicInteractor
    let notificationsInteractor: NotificationsInteractor
    
    @State private var timerCancellable: AnyCancellable?
    
    // TODO: not perfect way to refresh - refactor that
    @State private var refreshID: UUID = .init()
    
    init(defaultsInteractor: DefaultsInteractor,
         musicInteractor: MusicInteractor,
         notificationsInteractor: NotificationsInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.musicInteractor = musicInteractor
        self.notificationsInteractor = notificationsInteractor
    }
    
    var body: some View {
        VStack {
            HStack {
                ForEach(SupportedMusicApplication.allCases, id: \.rawValue) { app in
                    ZStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 50, height: 50)
                        } else {
                            Text(app.appName)
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding(5)
                    .background(defaultsInteractor.selectedApplication == app ? app.color.opacity(0.5) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        defaultsInteractor.selectedApplication = app
                    }
                }
            }
            VStack {
                HStack(alignment: .center) {
                    Circle()
                        .foregroundStyle(notificationsInteractor.areNotificationsEnabled ? Color.green : Color.red)
                        .frame(width: 8)
                    Text("Notification permissions")
                }
                if !notificationsInteractor.areNotificationsEnabled {
                    Button("Notification settings") {
//                        permissionsInteractor.registerForNotifications(delegate: notificationsInteractor)
                    }
                }
            }
            
            VStack {
                HStack(alignment: .center) {
                    switch musicInteractor.permissionStatus {
                    case .granted:
                        Circle()
                            .foregroundStyle(Color.green)
                            .frame(width: 8)
                    case .closed:
                        Circle()
                            .foregroundStyle(Color.yellow)
                            .frame(width: 8)
                    case .denied:
                        Circle()
                            .foregroundStyle(Color.red)
                            .frame(width: 8)
                    }
                    Text("Automation permissions")
                }
            }
        }
        .onChange(of: defaultsInteractor.selectedApplication) {
            musicInteractor.set(application: $0)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                notificationsInteractor.updateNotificationsPermissions()
                musicInteractor.updateControlPermissions()
                refreshID = .init()
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
    }
}

private extension SupportedMusicApplication {
    var color: Color {
        switch self {
        case .applemusic:
            .appleMusic
        case .spotify:
            .spotify
        }
    }
    
    var icon: NSImage? {
        switch self {
        case .spotify:
            getAppIcon(for: bundleId)
        case .applemusic:
            getAppIcon(for: bundleId)
        }
    }
    
    private func getAppIcon(for bundleIdentifier: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}

private extension GeneralSettingsView.SelectableMusicApplication {
    var asSupportedMusicApplication: SupportedMusicApplication? {
        switch self {
        case .spotify:
            .spotify
        case .applemusic:
            .applemusic
        case .none:
            nil
        }
    }
}


private extension Optional<SupportedMusicApplication> {
    var asSelectableMusicApplication: GeneralSettingsView.SelectableMusicApplication {
        switch self {
        case .spotify:
            .spotify
        case .applemusic:
            .applemusic
        case .none:
            .none
        }
    }
}

private struct NotificationSettingsView: View {
    let defaultsInteractor: DefaultsInteractor
    
    var body: some View {
        VStack(alignment: .leading) {
            LaunchAtLogin.Toggle("Launch on startup")
            Toggle(isOn: defaultsInteractor.$isMenuIconColored) {
                Text("Show colored menu bar icon")
            }
            Divider()
                .padding()
            Toggle(isOn: defaultsInteractor.$areNotificationsEnabled) {
                Text("Enable notifications")
            }
            VStack(alignment: .leading) {
                Toggle(isOn: defaultsInteractor.$shouldKeepNotificationsOnScreen) {
                    Text("Keep notifications on screen (swipe right to hide)")
                }
                Toggle(isOn: defaultsInteractor.$shouldShowNotificationOnPlayPause) {
                    Text("Display notification on play | pause")
                }
                Toggle(isOn: defaultsInteractor.$shouldPlayNotificationsSound) {
                    Text("Play notification sound")
                }
                Toggle(isOn: defaultsInteractor.$shouldDisableNotificationsOnFocus) {
                    Text("Disable notifications when Spotify is focused")
                }
                Toggle(isOn: defaultsInteractor.$shouldShowAlbumArt) {
                    Text("Include album art")
                }
                Toggle(isOn: defaultsInteractor.$shouldShowSongProgress) {
                    Text("Display song progress in notification")
                }
            }
            .padding(.leading)
            .disabled(!defaultsInteractor.areNotificationsEnabled)
            Divider()
                .padding()
            //                VStack(alignment: .leading){
            //                    Text("Show notification on shortcut")
            //                    ShortcutView(notificationsInteractor: notificationsInteractor, keyCombo: $defaultsInteractor.shortcut)
            //                        .frame(minHeight: 30, maxHeight: 30)
            //                }.padding(.horizontal)
        }
        .padding()
    }
}

private struct AboutSettingsView: View {
    private enum Const {
        static let homepage = "https://nahive.github.io".asURL!
        static let repo = "https://github.com/nahive/spotify-notify".asURL!
    }
    
    var body: some View {
        VStack {
            Image(.iconSettings)
                .resizable()
                .frame(width: 150.0, height: 150.0)
                .fixedSize()
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
    }
}


//struct ShortcutView: NSViewRepresentable {
//    typealias NSViewType = RecordView
//
//    private let notificationsInteractor: NotificationsInteractor
//
//    @Binding private var keyCombo: KeyCombo?
//
//    init(notificationsInteractor: NotificationsInteractor, keyCombo: Binding<KeyCombo?>) {
//        self.notificationsInteractor = notificationsInteractor
//        self._keyCombo = keyCombo
//    }
//
//    func makeNSView(context: Context) -> RecordView {
//        let view = RecordView(frame: .zero)
//        view.cornerRadius = 5
//        view.delegate = context.coordinator
//        return view
//    }
//
//    func updateNSView(_ recordView: RecordView, context: Context) {
//        recordView.keyCombo = keyCombo
//    }
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(parent: self)
//    }
//
//    @MainActor
//    class Coordinator: NSObject, @preconcurrency RecordViewDelegate {
//        var parent: ShortcutView
//
//        init(parent: ShortcutView) {
//            self.parent = parent
//        }
//
//        func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
//            self.parent.keyCombo = keyCombo
//
//            if let keyCombo {
//                let hotKey = HotKey(identifier: "showKey", keyCombo: keyCombo) { key in
//                    self.parent.notificationsInteractor.forceShowNotification()
//                }
//                HotKeyCenter.shared.register(with: hotKey)
//            } else {
//                HotKeyCenter.shared.unregisterAll()
//            }
//        }
//
//        func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
//            true
//        }
//
//        func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
//            true
//        }
//
//        func recordViewDidEndRecording(_ recordView: RecordView) {
//            // nothing
//        }
//    }
//}

struct Settings_Preview: PreviewProvider {
    @StateObject private static var defaultsInteractor = DefaultsInteractor()
    
    static var previews: some View {
        SettingsView()
            .environmentObject(defaultsInteractor)
    }
}
