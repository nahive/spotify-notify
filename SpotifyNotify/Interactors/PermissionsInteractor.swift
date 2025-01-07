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

@MainActor
final class PermissionsInteractor: NSObject, ObservableObject {
    @Published var notificationPermissionEnabled = false
    @Published var automationPermissionEnabled = false
    
    func registerForNotifications(delegate: any UNUserNotificationCenterDelegate) async {
        UNUserNotificationCenter.current().delegate = delegate

        // Check notification authorisation first
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization()
            notificationPermissionEnabled = granted
            System.logger.info("Notification authorisation was granted: \(granted)")
        } catch {
            showAlert(message: "Missing notification permissions", onSettingsTap: self.openNotificationsSettings)
            System.logger.warning("Notification authorisation was denied: \(error)")
        }

        let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")

        let category = UNNotificationCategory(identifier: NotificationIdentifier.category,
                                              actions: [skip],
                                              intentIdentifiers: [],
                                              options: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    func updateNotifications(_ granted: Bool) {
        self.notificationPermissionEnabled = granted
    }
    
    func registerForControl() async {
        Task.detached {
            let targetAEDescriptor = NSAppleEventDescriptor(bundleIdentifier: SpotifyInteractor.Const.spotifyBundleId)
            let status = AEDeterminePermissionToAutomateTarget(targetAEDescriptor.aeDesc, typeWildCard, typeWildCard, true)
            
            Task { @MainActor in
                switch status {
                case noErr:
                    self.automationPermissionEnabled = true
                    System.logger.info("Automation authorisation was granted")
                case OSStatus(errAEEventNotPermitted):
                    self.automationPermissionEnabled = false
                    self.showAlert(message: "Missing required automation permissions", onSettingsTap: self.openAutomationSettings)
                    System.logger.warning("Automation authorisation was denied")
                case OSStatus(procNotFound), _:
                    System.logger.info("Spotify is not running")
                }
            }
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
        NSWorkspace.shared.open("x-apple.systempreferences:com.apple.preference.notifications".asURL!)
    }
    
    func openAutomationSettings() {
        NSWorkspace.shared.open("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation".asURL!)
    }
}
