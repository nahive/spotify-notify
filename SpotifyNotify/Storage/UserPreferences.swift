//
//  UserPreferences.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation
import Magnet

enum StatusBarIcon: Int {
	case `default` = 0
    case monochromatic = 1
    case none = 99
    
    init(value: Int?) {
        guard let value = value else { self = .none; return }
        self = StatusBarIcon(rawValue: value) ?? .none
    }
}

struct UserPreferences {
	private struct Keys {
        static let appAlreadySetup = "already.setup.key"
        
		static let notificationsEnabled = "notifications.enabled.key"
		static let notificationsPlayPause = "notifications.playpause.key"
		static let notificationsSound = "notifications.sound.key"
		static let notificationsDisableOnFocus = "notifications.focus.key"
		static let notificationsLength = "notifications.length.key"
        
		static let startOnLogin = "startonlogin.key"
		static let showAlbumArt = "showalbumart.key"
		static let roundAlbumArt = "roundalbumart.key"
        static let showSongProgress = "songprogress.key"
		
		static let menuIcon = "menuicon.key"
		static let shortcutKeyCode = "shortcut.keycode.key"
		static let shortcutModifiers = "shortcut.modifiers.key"
	}
	
	private let defaults = UserDefaults.standard
    
    var appAlreadySetup: Bool {
        get { return defaults.bool(forKey: Keys.appAlreadySetup) }
        set { defaults.set(newValue, forKey: Keys.appAlreadySetup) }
    }
	
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
    
    var notificationsLength: Int {
        get { return defaults.integer(forKey: Keys.notificationsLength) }
        set { defaults.set(newValue, forKey: Keys.notificationsLength) }
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
	
    var showSongProgress: Bool {
        get { return defaults.bool(forKey: Keys.showSongProgress) }
        set { defaults.set(newValue, forKey: Keys.showSongProgress) }
    }
    
	var menuIcon: StatusBarIcon {
		get { return StatusBarIcon(value: defaults.integer(forKey: Keys.menuIcon)) }
		set { defaults.set(newValue.rawValue, forKey: Keys.menuIcon) }
	}
	
	var shortcut: KeyCombo? {
		get {
			let keycode = defaults.integer(forKey: Keys.shortcutKeyCode)
			let modifiers = defaults.integer(forKey: Keys.shortcutModifiers)
			guard keycode != 0 && modifiers != 0 else { return nil }
			return KeyCombo(QWERTYKeyCode: keycode, carbonModifiers: modifiers)
		}
		set {
			guard let keyCombo = newValue else {
				defaults.set(0, forKey: Keys.shortcutKeyCode)
				defaults.set(0, forKey: Keys.shortcutModifiers)
				return
			}
			
			defaults.set(keyCombo.QWERTYKeyCode, forKey: Keys.shortcutKeyCode)
			defaults.set(keyCombo.modifiers, forKey: Keys.shortcutModifiers)
			
		}
	}
}
