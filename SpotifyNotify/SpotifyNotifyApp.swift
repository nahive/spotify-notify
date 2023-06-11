//
//  SpotifyNotifyApp.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import SwiftUI
import UserNotifications

@main
struct SpotifyNotifyApp: App {
    @StateObject private var spotifyInteractor = SpotifyInteractor()
    @StateObject private var defaultsInteractor = DefaultsInteractor()
    @StateObject private var notificationsInteractor = NotificationsInteractor()
    
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
        }
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        registerForNotifications()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        
        return true
    }
    
    
    /// Setup user notifications using UserNotifications framework
    private func registerForNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        // Check notification authorisation first
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                System.logger.warning("Notification authorisation was denied: \(error)")
            }
        }

        let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")

        let category = UNNotificationCategory(identifier: NotificationIdentifier.category,
                                              actions: [skip],
                                              intentIdentifiers: [],
                                              options: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Force notifications to be shown, even if the SpotifyNotify is in the foreground
        completionHandler([.banner, .sound])
    }

    /// Handle the action buttons
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case NotificationIdentifier.skip:
            SpotifyInteractor().nextTrack()
        default:
            AppOpener.openSpotify()
        }
    }
}
