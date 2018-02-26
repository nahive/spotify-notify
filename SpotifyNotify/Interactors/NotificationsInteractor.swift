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
    
	mutating func showNotification() {
		
		// return if notifications are disabled
		guard preferences.notificationsEnabled else { return }
		
		let isFrontmostSpotify = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == SpotifyConstants.bundleIdentifier
		
		// return if notifications are disabled when in focus
		if isFrontmostSpotify && preferences.notificationsDisableOnFocus { return }
		
		previousTrack = currentTrack
		currentTrack  = spotify?.currentTrack
	
		// return if previous track is same as previous => play/pause and if it's disabled
		guard previousTrack?.id?() != currentTrack?.id?() || preferences.notificationsPlayPause else {
			return
		}
        
		let notification = NSUserNotification()
		
		// decide whether to add progress
        if preferences.showSongProgress {
            let artist = currentTrack?.artist ?? "______"
            let album = currentTrack?.album ?? "______"
            let duration = progress(for: currentTrack)
            
            notification.title = currentTrack?.name
            notification.subtitle = "\(artist) - \(album)"
            notification.informativeText = duration
        } else {
            notification.title = currentTrack?.name
            notification.subtitle = currentTrack?.artist
            notification.informativeText = currentTrack?.album
        }
        
		notification.hasActionButton = true
		notification.actionButtonTitle = "Skip"
		
		// decide whether to add art
		if SystemPreferences.isContentImagePropertyAvailable && preferences.showAlbumArt {
			if let art = currentTrack?.artworkUrl?.url?.image {
				
				// decide whether to add spotify icon
				if preferences.showSpotifyIcon {
					notification.contentImage = art
				} else {
					notification.identityImage = art
					
					// decide whether to round art
					if preferences.roundAlbumArt {
						notification.identityImageStyle = .rounded
					} else {
						notification.identityImageStyle = .normal
					}
				}
			}
		}
		
		// decide whether to add sound
		if preferences.notificationsSound {
			notification.soundName = NSUserNotificationDefaultSoundName
		}
		
        NSUserNotificationCenter.default.removeAllDeliveredNotifications()
		NSUserNotificationCenter.default.deliver(notification)
		
		// remove after userset number of seconds if not taken action
		DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(preferences.notificationsLength)) {
			NSUserNotificationCenter.default.removeDeliveredNotification(notification)
		}
	}
	
	func handleAction() {
        spotify?.nextTrack?()
	}
    
    private func progress(for track: SpotifyTrack?) -> String {
        guard
            let position = spotify?.playerPosition,
            let duration = track?.duration else {
                return "00:00/00:00"
        }
        
        let percentage = position / (Double(duration) / 1000.0)
        
        let progressDone = "▪︎"
        let progressNotDone = "⁃"
        let progressMax = 14
        let currentProgress = Int(Double(progressMax) * percentage)
        
        let progressString = String(repeating: progressDone, count: currentProgress) + String(repeating: progressNotDone, count: progressMax - currentProgress)
        
        let now = convert(seconds: Int(position))
        let length = convert(seconds: duration / 1000)
		
		let nowS = "\(now.minutes)".withLeadingZeroes + ":" + "\(now.seconds)".withLeadingZeroes
		let lengthS = "\(length.minutes)".withLeadingZeroes + ":" + "\(length.seconds)".withLeadingZeroes
		
        return "\(nowS)  \(progressString)  \(lengthS)"
    }
    
    private func convert(seconds: Int) -> (minutes: Int, seconds: Int) {
        return ((seconds % 3600) / 60, (seconds % 3600) % 60)
    }
}

