//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import ScriptingBridge

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

        /// return if current track is nil
        guard let currentTrack = currentTrack else { return }

        let viewModel = NotificationViewModel(track: currentTrack)
        createLegacyNotification(using: viewModel)
	}

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

    /// Called by notification delegate
	func handleAction() {
        spotifyInteractor.nextTrack()
	}
}
