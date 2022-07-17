//
//  PreferencesView.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import KeyHolder
import Magnet

final class RecordingView: RecordView { }

extension NSNotification.Name {
	static let userPreferencesDidChangeStartup = NSNotification.Name(rawValue: "userPreferencesDidChangeStartup.notification")
	static let userPreferencesDidChangeIcon = NSNotification.Name(rawValue: "userPreferencesDidChangeIcon.notification")
}

final class PreferencesView: NSVisualEffectView {
	@IBOutlet weak var notificationsCheck: NSButton!
	@IBOutlet weak var notificationsPlayPauseCheck: NSButton!
	@IBOutlet weak var notificationsSoundCheck: NSButton!
	@IBOutlet weak var notificationsSpotifyFocusCheck: NSButton!
	
	@IBOutlet weak var startOnLoginCheck: NSButton!
	@IBOutlet weak var showAlbumArtCheck: NSButton!
	@IBOutlet weak var roundAlbumArtCheck: NSButton!
	@IBOutlet weak var showSpotifyIconCheck: NSButton!
    @IBOutlet weak var showSongProgressCheck: NSButton!
    
    @IBOutlet weak var notificationLengthField: NSTextField!
    @IBOutlet weak var notificationLengthChanger: NSStepper!
    
    @IBOutlet weak var menuIconCheck: NSButton!
	@IBOutlet weak var menuIconPopUpButton: NSPopUpButton!
	
	@IBOutlet weak var recordShortcutView: RecordingView! {
		didSet {
			recordShortcutView.cornerRadius = 14
			recordShortcutView.tintColor = .darkGray
		}
	}
	
	@IBOutlet weak var sourceButton: NSButton!
	@IBOutlet weak var homeButton: NSButton!
	@IBOutlet weak var quitButton: NSButton!
	
	private var preferences = UserPreferences()
	private let shortcutsInteractor = ShortcutsInteractor()
	
	override func viewWillDraw() {
		super.viewWillDraw()
		checkAvailability()
		setup()
        checkCompability()
		setupTargets()
	}
	
	private func checkAvailability() {
		if !SystemPreferences.isContentImagePropertyAvailable {
			showAlbumArtCheck.isEnabled = false
			roundAlbumArtCheck.isEnabled = false
		}
	}
    
    private func checkCompability() {
        notificationsPlayPauseCheck.isEnabled = preferences.notificationsEnabled
        notificationsSoundCheck.isEnabled = preferences.notificationsEnabled
        notificationsSpotifyFocusCheck.isEnabled = preferences.notificationsEnabled
        showAlbumArtCheck.isEnabled = preferences.notificationsEnabled
        showSpotifyIconCheck.isEnabled = preferences.notificationsEnabled
        roundAlbumArtCheck.isEnabled = preferences.notificationsEnabled && preferences.showAlbumArt
        showSongProgressCheck.isEnabled = preferences.notificationsEnabled
        menuIconPopUpButton.isEnabled = preferences.menuIcon != .none
    }
	
	private func setup() {
		notificationsCheck.isSelected = preferences.notificationsEnabled
		notificationsPlayPauseCheck.isSelected = preferences.notificationsPlayPause
		notificationsSoundCheck.isSelected = preferences.notificationsSound
		notificationsSpotifyFocusCheck.isSelected = preferences.notificationsDisableOnFocus
		
		startOnLoginCheck.isSelected = preferences.startOnLogin
		showAlbumArtCheck.isSelected = preferences.showAlbumArt
		roundAlbumArtCheck.isSelected = preferences.roundAlbumArt
		showSpotifyIconCheck.isSelected = preferences.showSpotifyIcon
        showSongProgressCheck.isSelected = preferences.showSongProgress
		
        notificationLengthField.doubleValue = Double(preferences.notificationsLength)
        notificationLengthChanger.integerValue = preferences.notificationsLength
        
        menuIconCheck.isSelected = preferences.menuIcon != .none
        if preferences.menuIcon != .none { menuIconPopUpButton.selectItem(at: preferences.menuIcon.rawValue) }
		
		recordShortcutView.keyCombo = preferences.shortcut
	}
	
	private func setupTargets() {
        notificationsCheck.target = self
        notificationsCheck.action = #selector(notificationsCheckTapped(sender:))
		notificationsPlayPauseCheck.target = self
		notificationsPlayPauseCheck.action = #selector(notificationsPlayPauseCheckTapped(sender:))
		notificationsSoundCheck.target = self
		notificationsSoundCheck.action = #selector(notificationsSoundCheckTapped(sender:))
		notificationsSpotifyFocusCheck.target = self
		notificationsSpotifyFocusCheck.action = #selector(notificationsSpotifyFocusCheckTapped(sender:))
	
		startOnLoginCheck.target = self
		startOnLoginCheck.action = #selector(startOnLoginCheckTapped(sender:))
		showAlbumArtCheck.target = self
		showAlbumArtCheck.action = #selector(showAlbumArtCheckTapped(sender:))
		roundAlbumArtCheck.target = self
		roundAlbumArtCheck.action = #selector(roundAlbumArtCheckTapped(sender:))
		showSpotifyIconCheck.target = self
		showSpotifyIconCheck.action = #selector(showSpotifyIconCheckTapped(sender:))
        showSongProgressCheck.target = self
        showSongProgressCheck.action = #selector(showSongProgressCheckTapped(sender:))
        
        notificationLengthField.target = self
        notificationLengthField.action = #selector(notificationLengthFieldChanged(sender:))
        notificationLengthChanger.target = self
        notificationLengthChanger.action = #selector(notificationLengthChangerTapped(sender:))
		
        menuIconCheck.target = self
        menuIconCheck.action = #selector(menuIconCheckTapped(sender:))
		menuIconPopUpButton.target = self
		menuIconPopUpButton.action = #selector(menuIconPopUpButtonChanged(sender:))
		
		recordShortcutView.delegate = self
		
		sourceButton.target = self
		sourceButton.action = #selector(sourceButtonTapped(sender:))
		homeButton.target = self
		homeButton.action = #selector(homeButtonTapped(sender:))
		quitButton.target = self
		quitButton.action = #selector(quitButtonTapped(sender:))
	}
    
	@objc func notificationsCheckTapped(sender: NSButton) {
		preferences.notificationsEnabled = sender.isSelected
        checkCompability()
	}
	
	@objc func notificationsPlayPauseCheckTapped(sender: NSButton) {
		preferences.notificationsPlayPause = sender.isSelected
	}
	
	@objc func notificationsSoundCheckTapped(sender: NSButton) {
		preferences.notificationsSound = sender.isSelected
	}
	
	@objc func notificationsSpotifyFocusCheckTapped(sender: NSButton) {
		preferences.notificationsDisableOnFocus = sender.isSelected
	}
	
	@objc func startOnLoginCheckTapped(sender: NSButton) {
		preferences.startOnLogin = sender.isSelected
		DistributedNotificationCenter.default().post(name: .userPreferencesDidChangeStartup, object: nil)
	}
	
	@objc func showAlbumArtCheckTapped(sender: NSButton) {
		preferences.showAlbumArt = sender.isSelected
        checkCompability()
	}
	
	@objc func roundAlbumArtCheckTapped(sender: NSButton) {
		preferences.roundAlbumArt = sender.isSelected
	}
	
	@objc func showSpotifyIconCheckTapped(sender: NSButton) {
		preferences.showSpotifyIcon = sender.isSelected
	}
    
    @objc func showSongProgressCheckTapped(sender: NSButton) {
        preferences.showSongProgress = sender.isSelected
    }
    
    @objc func notificationLengthFieldChanged(sender: NSTextField) {
        guard sender.doubleValue >= 1.0 else {
            notificationLengthField.integerValue = 1
            preferences.notificationsLength = 1
            notificationLengthField.doubleValue = 1.0
            return
        }
        
        preferences.notificationsLength = Int(sender.doubleValue)
        notificationLengthChanger.integerValue = Int(sender.doubleValue)
    }
    
    @objc func notificationLengthChangerTapped(sender: NSStepper) {
        guard sender.integerValue >= 1 else {
            notificationLengthField.integerValue = 1
            preferences.notificationsLength = 1
            notificationLengthField.doubleValue = 1
            return
        }
        
        preferences.notificationsLength = Int(sender.integerValue)
        notificationLengthField.doubleValue = Double(sender.integerValue)
    }
	
    @objc func menuIconCheckTapped(sender: NSButton) {
        if sender.isSelected {
            preferences.menuIcon = StatusBarIcon(value: menuIconPopUpButton.indexOfSelectedItem)
        } else {
            preferences.menuIcon = .none
        }

        DistributedNotificationCenter.default().post(name: .userPreferencesDidChangeIcon, object: nil)
    }
    
	@objc func menuIconPopUpButtonChanged(sender: NSPopUpButton) {
		preferences.menuIcon = StatusBarIcon(value: sender.indexOfSelectedItem)
		DistributedNotificationCenter.default().post(name: .userPreferencesDidChangeIcon, object: nil)
	}
	
	@objc func sourceButtonTapped(sender: NSButton) {
		NSWorkspace.shared.open(NahiveConstraints.repo)
	}
	
	@objc func homeButtonTapped(sender: NSButton) {
		NSWorkspace.shared.open(NahiveConstraints.homepage)
	}
	
	@objc func quitButtonTapped(sender: NSButton) {
        NSApplication.shared.terminate(sender)
	}
}

extension PreferencesView: RecordViewDelegate {
    func recordView(_ recordView: RecordView, didChangeKeyCombo keyCombo: KeyCombo?) {
        guard let keyCombo = keyCombo else {
            recordViewDidClearShortcut(recordView)
            return
        }
        
        shortcutsInteractor.register(combo: keyCombo)
        preferences.shortcut = keyCombo
    }
    
	func recordViewShouldBeginRecording(_ recordView: RecordView) -> Bool {
		return true
	}
	
	func recordView(_ recordView: RecordView, canRecordKeyCombo keyCombo: KeyCombo) -> Bool {
		return true
	}
	
	func recordViewDidClearShortcut(_ recordView: RecordView) {
		shortcutsInteractor.unregister()
		preferences.shortcut = nil
	}
	
	func recordViewDidEndRecording(_ recordView: RecordView) {
		// nothing
	}
}
