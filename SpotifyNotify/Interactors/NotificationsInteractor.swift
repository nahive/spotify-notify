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
			currentTrack?.artworkURL?.asyncImage { art in
				
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
					NSUserNotificationCenter.default.removeAllDeliveredNotifications()
					NSUserNotificationCenter.default.deliver(notification)
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
        spotifyInteractor.nextTrack()
	}
    
    private func progress(for track: Track?) -> String {
        guard
            let position = spotifyInteractor.playerPosition,
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

