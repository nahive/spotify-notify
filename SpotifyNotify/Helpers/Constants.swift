//
//  Constants.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation

struct SpotifyConstants {
	static let applicationName = "Spotify"
	static let bundleIdentifier = "com.spotify.client"
	
	static let notificationPlaybackChange = bundleIdentifier + ".PlaybackStateChanged"
	static let albumArtURL = "https://embed.spotify.com/oembed/?url="
}

struct NahiveConstraints {
	static let homepage = "https://nahive.github.io".url!
	static let repo = "https://github.com/nahive/spotify-notify".url!
}

struct AppConstants {
	static let bundleIdentifier = "io.nahive.SpotifyNotify"
}

struct NotificationIdentifier {
    static let skip = "notification.skip"
    static let category = "notification.category"
}
