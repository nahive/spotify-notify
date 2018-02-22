//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import ScriptingBridge

struct NotificationsInteractor {
	
	private let preferences = UserPreferences()
	
	private var previousTrack: Track?
	private var currentTrack: Track?
	
	mutating func handlePlaybackChange(from notification: Notification) {
		
		// return if notifications are disabled
		guard preferences.notificationsEnabled else { return }
		
		let isFrontmostSpotify = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == SpotifyConstants.bundleIdentifier
		
		// return if notifications are disabled when in focus
		if isFrontmostSpotify && preferences.notificationsDisableOnFocus { return }
		
		// return if something is wrong with user info
		guard
		 	let userInfo = notification.userInfo,
			let status = userInfo["Player State"] as? String,
			status == "Playing" else {
			return
		}
		
		previousTrack = currentTrack
		currentTrack  = Track(id: userInfo["Track ID"] as? String,
						  title: userInfo["Name"] as? String,
						  artist: userInfo["Artist"] as? String,
						  album: userInfo["Album"] as? String)
	
		// return if previous track is same as previous => play/pause and if it's disabled
		guard previousTrack != currentTrack || preferences.notificationsPlayPause else {
			return
		}
		
		let notification = NSUserNotification()
		notification.title = currentTrack?.title
		notification.subtitle = currentTrack?.album
		notification.informativeText = currentTrack?.artist
		notification.hasActionButton = true
		notification.actionButtonTitle = "Skip"
		
		if SystemPreferences.isContentImagePropertyAvailable && preferences.showAlbumArt {
			if let art = currentTrack?.albumArt {
				if preferences.showSpotifyIcon {
					notification.contentImage = art
				} else {
					// private apple apis
					notification.setValue(art, forKey: "_identityImage")
					if preferences.roundAlbumArt {
						notification.setValue(2, forKey: "_identityImageStyle")
					} else {
						notification.setValue(0, forKey: "_identityImageStyle")
					}
				}
			}
		}
		
		if preferences.notificationsSound {
			notification.soundName = NSUserNotificationDefaultSoundName
		}
		
		NSUserNotificationCenter.default.deliver(notification)
		
		// remove after 5 seconds if not taken action
		DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
			NSUserNotificationCenter.default.removeDeliveredNotification(notification)
		}
	}
	
	func handleAction() {
		let spotify = SpotifyWrapper.application()
		spotify?.nextTrack()
	}
}
