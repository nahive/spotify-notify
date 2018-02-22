//
//  UserPreferences.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation

struct UserPreferences {
	
	enum StatusBarIcon: Int {
		case `default`, monochromatic, disabled
	}
	
	static var notificationsEnabled: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsEnabled")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsEnabled")
		}
	}
	
	static var notificationsPlayPause: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsPlayPause")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsPlayPause")
		}
	}
	
	static var notificationsSound: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsSound")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsSound")
		}
	}
	
	static var notificationsStartup: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsStartup")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsStartup")
		}
	}
	
	static var notificationsMenuIcon: StatusBarIcon {
		get {
			return StatusBarIcon(rawValue: UserDefaults.standard.integer(forKey: "notificationsMenuIcon")) ?? StatusBarIcon.default
		}
		set {
			UserDefaults.standard.set(newValue.rawValue, forKey: "notificationsMenuIcon")
		}
	}
	
	static var notificationsArt: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsArt")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsArt")
		}
	}
	
	static var notificationsArtRound: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsArtRound")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsArtRound")
		}
	}
	
	static var notificationsSpotifyIcon: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsSpotifyIcon")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsSpotifyIcon")
		}
	}
	
	static var notificationsSpotifyFocus: Int {
		get {
			return UserDefaults.standard.integer(forKey: "notificationsSpotifyFocus")
		}
		set {
			UserDefaults.standard.set(newValue, forKey: "notificationsSpotifyFocus")
		}
	}
	
	
}