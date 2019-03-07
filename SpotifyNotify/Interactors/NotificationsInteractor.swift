//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import ScriptingBridge

#if canImport(UserNotifications)
import UserNotifications
#endif

final class NotificationsInteractor {
	
	private let preferences = UserPreferences()
	private let spotifyInteractor = SpotifyInteractor()
	
	private var previousTrack: Track?
	private var currentTrack: Track?
    
    func showNotification() {
        
		// return if notifications are disabled
		guard preferences.notificationsEnabled else { return }
		
		// return if notifications are disabled when in focus
		if spotifyInteractor.isFrontmost && preferences.notificationsDisableOnFocus { return }
		
		previousTrack = currentTrack
		currentTrack  = spotifyInteractor.currentTrack
	
		// return if previous track is same as previous => play/pause and if it's disabled
		guard currentTrack != previousTrack || preferences.notificationsPlayPause else {
			return
		}
		
		guard spotifyInteractor.playerState == .some(.playing) else {
			return
		}

        // return if current track is nil
        guard let currentTrack = currentTrack else { return }

        // Create and deliver notifications
        let viewModel = NotificationViewModel(track: currentTrack)
        if #available(macOS 10.14, *) {
            createModernNotification(using: viewModel)
        } else {
            createLegacyNotification(using: viewModel)
        }
	}

    /// Called by notification delegate
    func handleAction() {
        spotifyInteractor.nextTrack()
    }

    // MARK: - Legacy Notifications

    /// Use `NSUserNotificationCenter` to deliver the notification in macOS 10.13 and below
    private func createLegacyNotification(using viewModel: NotificationViewModel) {
        let notification = NSUserNotification()

        notification.identifier = viewModel.identifier
        notification.title = viewModel.title
        notification.subtitle = viewModel.subtitle
        notification.informativeText = viewModel.body
        notification.hasActionButton = true
        notification.actionButtonTitle = "Skip"

        addArtwork(to: notification, using: viewModel)

        // decide whether to add sound
        if preferences.notificationsSound {
            notification.soundName = NSUserNotificationDefaultSoundName
        }

        deliverLegacyNotification(notification)
    }

    private func addArtwork(to notification: NSUserNotification, using viewModel: NotificationViewModel) {
        guard viewModel.shouldShowArtwork else { return }

        viewModel.artworkURL?.asyncImage { art in
            // decide whether to add spotify icon
            if self.preferences.showSpotifyIcon {
                notification.contentImage = art
            } else {
                notification.identityImage = art

                // decide whether to round art
                if self.preferences.roundAlbumArt {
                    notification.identityImageStyle = .rounded
                } else {
                    notification.identityImageStyle = .normal
                }
            }

            // remove previous notification and replace it with one with image
            DispatchQueue.main.async {
                self.deliverLegacyNotification(notification)
            }
        }
    }

    private func deliverLegacyNotification(_ notification: NSUserNotification) {
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
        NSUserNotificationCenter.default.deliver(notification)

        // remove after userset number of seconds if not taken action
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(preferences.notificationsLength)) {
            NSUserNotificationCenter.default.removeDeliveredNotification(notification)
        }
    }

    // MARK: - Modern Notfications

    /// Use `UserNotifications` to deliver the notification in macOS 10.14 and above
    @available(OSX 10.14, *)
    private func createModernNotification(using viewModel: NotificationViewModel) {
        let notification = UNMutableNotificationContent()

        notification.title = viewModel.title
        notification.subtitle = viewModel.subtitle
        notification.body = viewModel.body
        notification.categoryIdentifier = NotificationIdentifier.category

        // decide whether to add sound
        if preferences.notificationsSound {
            notification.sound = .default
        }

        if viewModel.shouldShowArtwork {
            addArtwork(to: notification, using: viewModel)
        } else {
            deliverModernNotification(identifier: viewModel.identifier, content: notification)
        }
    }

    @available(OSX 10.14, *)
    private func addArtwork(to notification: UNMutableNotificationContent, using viewModel: NotificationViewModel) {
        guard viewModel.shouldShowArtwork else { return }

        viewModel.artworkURL?.asyncImage { art in
            // Create a mutable copy of the downloaded artwork
            var artwork = art

            // If user wants round album art, then round the image
            if self.preferences.roundAlbumArt {
                artwork = art?.applyCircularMask()
            }

            // Save the artwork to the temporary directory
            guard let url = artwork?.saveToTemporaryDirectory(withName: "artwork") else { return }

            // Add the attachment to the notification
            do {
                let attachment = try UNNotificationAttachment(identifier: "artwork", url: url)
                notification.attachments = [attachment]
            } catch {
                print("Error creating attachment: " + error.localizedDescription)
            }

            // remove previous notification and replace it with one with image
            DispatchQueue.main.async {
                self.deliverModernNotification(identifier: viewModel.identifier, content: notification)
            }
        }
    }

    /// Deliver notifications using `UNUserNotificationCenter`
    @available(OSX 10.14, *)
    private func deliverModernNotification(identifier: String, content: UNMutableNotificationContent) {
        // Create a request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        let notificationCenter = UNUserNotificationCenter.current()

        // Remove delivered notifications
        notificationCenter.removeAllDeliveredNotifications()

        // Deliver current notification
        notificationCenter.add(request)

        // remove after userset number of seconds if not taken action
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(preferences.notificationsLength)) {
            notificationCenter.removeAllDeliveredNotifications()
        }
    }
}
