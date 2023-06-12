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
    @StateObject private var spotifyInteractor = SpotifyInteractor()
    @StateObject private var defaultsInteractor = DefaultsInteractor()
    @StateObject private var notificationsInteractor = NotificationsInteractor()
    @StateObject private var permissionsInteractor = PermissionsInteractor()
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("SpotifyNotify", image: defaultsInteractor.isMenuIconColored ? "IconStatusBarColor" : "IconStatusBarMonochrome") {
            MenuView()
                .environmentObject(spotifyInteractor)
                .environmentObject(notificationsInteractor)
        }
        Settings {
            SettingsView()
                .environmentObject(defaultsInteractor)
                .environmentObject(permissionsInteractor)
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let interactor = PermissionsInteractor()
        interactor.registerForNotifications()
        interactor.registerForControl()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        
        return true
    }
}
