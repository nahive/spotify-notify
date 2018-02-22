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
	
	private var previousTrack: SpotifyTrack?
	private var currentTrack: SpotifyTrack?
    private let spotify: SpotifyApplication? = SBApplication(bundleIdentifier: SpotifyConstants.bundleIdentifier)
    
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
		currentTrack  = spotify?.currentTrack
	
		// return if previous track is same as previous => play/pause and if it's disabled
		guard previousTrack?.id?() != currentTrack?.id?() || preferences.notificationsPlayPause else {
			return
		}
        
		let notification = NSUserNotification()
        
//        if preferences.showSongProgress {
//            let artist = currentTrack?.artist ?? "______"
//            let album = currentTrack?.album ?? "______"
//            let progress = Int(spotify?.playerPosition ?? 0.0).duration
//            let duration = currentTrack?.duration?.duration ?? "00:00"
//
//            notification.title = currentTrack?.name
//            notification.subtitle = "\(artist) - \(album)"
//            notification.informativeText = "\(progress) (\(duration))"
//        } else {
            notification.title = currentTrack?.name
            notification.subtitle = currentTrack?.artist
            notification.informativeText = currentTrack?.album
//        }
        
		notification.hasActionButton = true
		notification.actionButtonTitle = "Skip"
        
        notification.additionalActions = [.init(identifier: "previous", title: "Previous"),
                                            ]
		
		if SystemPreferences.isContentImagePropertyAvailable && preferences.showAlbumArt {
			if let art = currentTrack?.artworkUrl?.url?.image {
				if preferences.showSpotifyIcon {
					notification.contentImage = art
				} else {
					notification.identityImage = art
					if preferences.roundAlbumArt {
						notification.identityImageStyle = .rounded
					} else {
						notification.identityImageStyle = .normal
					}
				}
			}
		}
		
		if preferences.notificationsSound {
			notification.soundName = NSUserNotificationDefaultSoundName
		}
		
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
		NSUserNotificationCenter.default.deliver(notification)
		
		// remove after 5 seconds if not taken action
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(preferences.notificationsLength)) {
			NSUserNotificationCenter.default.removeDeliveredNotification(notification)
		}
	}
	
	func handleAction() {
        spotify?.nextTrack?()
	}
}

