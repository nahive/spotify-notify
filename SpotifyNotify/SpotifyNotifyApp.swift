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
    
    @StateObject private var spotifyInteractor: SpotifyInteractor
    @StateObject private var defaultsInteractor: DefaultsInteractor
    @StateObject private var notificationsInteractor: NotificationsInteractor
    @StateObject private var permissionsInteractor: PermissionsInteractor
    
    init() {
        let spotifyInteractor = SpotifyInteractor()
        let defaultsInteractor = DefaultsInteractor()
        let notificationsInteractor = NotificationsInteractor(defaultsInteractor: defaultsInteractor, spotifyInteractor: spotifyInteractor)
        let permissionsInteractor = PermissionsInteractor()
        
        self._spotifyInteractor = StateObject(wrappedValue: spotifyInteractor)
        self._defaultsInteractor = StateObject(wrappedValue: defaultsInteractor)
        self._notificationsInteractor = StateObject(wrappedValue: notificationsInteractor)
        self._permissionsInteractor = StateObject(wrappedValue: permissionsInteractor)
        
        Task {
            await permissionsInteractor.registerForNotifications(delegate: notificationsInteractor)
            await permissionsInteractor.registerForControl()
        }
    }
    
    var body: some Scene {
        MenuBarExtra {
            MenuView()
                .environmentObject(spotifyInteractor)
                .environmentObject(notificationsInteractor)
                .environmentObject(permissionsInteractor)
        } label: {
            HStack {
                Image(defaultsInteractor.isMenuIconColored ? "IconStatusBarColor" : "IconStatusBarMonochrome")
            }
        }
        .menuBarExtraStyle(.window)
        Window("Settings", id: "settings-window") {
            SettingsView()
                .environmentObject(notificationsInteractor)
                .environmentObject(defaultsInteractor)
                .environmentObject(permissionsInteractor)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.openWindow) var openWindow
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else {
            return true
        }
        // TODO: fix opening settings
        openWindow(id: "settings-window")
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}


