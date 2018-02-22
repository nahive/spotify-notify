//
//  UserPreferences.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation

enum StatusBarIcon: Int {
	case `default`, monochromatic, disabled
	
	init(value: Int) {
		if let icon = StatusBarIcon(rawValue: value) { self = icon }
		else { self = .default }
	}
}

struct UserPreferences {
	private struct Keys {
		static let notificationsEnabled = "notifications.enabled.key"
		static let notificationsPlayPause = "notifications.playpause.key"
		static let notificationsSound = "notifications.sound.key"
		static let notificationsDisableOnFocus = "notifications.focus.key"
		
		static let startOnLogin = "startonlogin.key"
		static let showAlbumArt = "showalbumart.key"
		static let roundAlbumArt = "roundalbumart.key"
		static let showSpotifyIcon = "spotifyicon.key"
		
		static let menuIcon = "menuicon.key"
	}
	
	private let defaults = UserDefaults.standard
	
	var notificationsEnabled: Bool {
		get { return defaults.bool(forKey: Keys.notificationsEnabled) }
		set { defaults.set(newValue, forKey: Keys.notificationsEnabled) }
	}
	
	var notificationsPlayPause: Bool {
		get { return defaults.bool(forKey: Keys.notificationsPlayPause) }
		set { defaults.set(newValue, forKey: Keys.notificationsPlayPause) }
	}
	
	var notificationsSound: Bool {
		get { return defaults.bool(forKey: Keys.notificationsSound) }
		set { defaults.set(newValue, forKey: Keys.notificationsSound) }
	}
	
	var notificationsDisableOnFocus: Bool {
		get { return defaults.bool(forKey: Keys.notificationsDisableOnFocus) }
		set { defaults.set(newValue, forKey: Keys.notificationsDisableOnFocus) }
	}
	
	var startOnLogin: Bool {
		get { return defaults.bool(forKey: Keys.startOnLogin) }
		set { defaults.set(newValue, forKey: Keys.startOnLogin) }
	}
	
	var showAlbumArt: Bool {
		get { return defaults.bool(forKey: Keys.showAlbumArt) }
		set { defaults.set(newValue, forKey: Keys.showAlbumArt) }
	}
	
	var roundAlbumArt: Bool {
		get { return defaults.bool(forKey: Keys.roundAlbumArt) }
		set { defaults.set(newValue, forKey: Keys.roundAlbumArt) }
	}
	
	var showSpotifyIcon: Bool {
		get { return defaults.bool(forKey: Keys.showSpotifyIcon) }
		set { 	defaults.set(newValue, forKey: Keys.showSpotifyIcon) }
	}
	
	var menuIcon: StatusBarIcon {
		get { return StatusBarIcon(value: defaults.integer(forKey: Keys.menuIcon)) }
		set { defaults.set(newValue.rawValue, forKey: Keys.menuIcon) }
	}
}
