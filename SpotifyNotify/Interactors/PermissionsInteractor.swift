//
//  PermissionsInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/12.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
import UserNotifications
import AppKit

final class PermissionsInteractor: NSObject, ObservableObject {
    
    @Published var notificationPermissionEnabled = false
    @Published var automationPermissionEnabled = false
    
    func registerForNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        // Check notification authorisation first
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { [weak self] (granted, error) in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.notificationPermissionEnabled = granted
            }
            
            if let error = error {
                System.logger.warning("Notification authorisation was denied: \(error)")
                DispatchQueue.main.async {
                    self.showAlert(message: "Missing notification permissions", onSettingsTap: self.openNotificationsSettings)
                }
            } else {
                System.logger.info("Notification authorisation was granted: \(granted)")
            }
        }

        let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")

        let category = UNNotificationCategory(identifier: NotificationIdentifier.category,
                                              actions: [skip],
                                              intentIdentifiers: [],
                                              options: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func registerForControl() {
        let targetAEDescriptor = NSAppleEventDescriptor(bundleIdentifier: SpotifyInteractor.Const.spotifyBundleId)
        let status = AEDeterminePermissionToAutomateTarget(targetAEDescriptor.aeDesc, typeWildCard, typeWildCard, true)
        
        switch status {
        case noErr:
            automationPermissionEnabled = true
            System.logger.info("Automation authorisation was granted")
        case OSStatus(errAEEventNotPermitted):
            automationPermissionEnabled = false
            showAlert(message: "Missing automation permissions", onSettingsTap: openAutomationSettings)
            System.logger.warning("Automation authorisation was denied")
        case OSStatus(procNotFound), _:
            System.logger.info("Spotify is not running")
        }
    }

    private func showAlert(message: String, onSettingsTap: () -> Void) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = message
        alert.addButton(withTitle: "Go to Settings")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn:
            onSettingsTap()
        default:
            break
        }
    }
    
    func openNotificationsSettings() {
        NSWorkspace.shared.open("com.apple.preference.notifications".asURL!)
    }
    
    func openAutomationSettings() {
        NSWorkspace.shared.open("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation".asURL!)
    }
}

extension PermissionsInteractor: UNUserNotificationCenterDelegate {
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
