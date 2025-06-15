//
//  SpotifyNotifyApp.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import SwiftUI
import UserNotifications
import AppKit

@main
struct SpotifyNotifyApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var musicInteractor: MusicInteractor
    @StateObject private var defaultsInteractor: DefaultsInteractor
    @StateObject private var notificationsInteractor: NotificationsInteractor
    
    init() {
        let musicInteractor = MusicInteractor()
        let defaultsInteractor = DefaultsInteractor()
        let notificationsInteractor = NotificationsInteractor(defaultsInteractor: defaultsInteractor, musicInteractor: musicInteractor)
        
        self._musicInteractor = StateObject(wrappedValue: musicInteractor)
        self._defaultsInteractor = StateObject(wrappedValue: defaultsInteractor)
        self._notificationsInteractor = StateObject(wrappedValue: notificationsInteractor)
        
        musicInteractor.set(application: defaultsInteractor.selectedApplication)
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(musicInteractor)
                .environmentObject(notificationsInteractor)
                .environmentObject(defaultsInteractor)
        } label: {
            HStack {
                Image(defaultsInteractor.isMenuIconColored ? "IconStatusBarColor" : "IconStatusBarMonochrome")
            }
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView()
                .environmentObject(musicInteractor)
                .environmentObject(notificationsInteractor)
                .environmentObject(defaultsInteractor)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openSettings) var openSettings
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        System.log("SpotifyNotify application started", level: .info)
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else {
            return true
        }
        // TODO: fix opening settings
        openSettings()
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}


