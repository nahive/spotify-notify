//
//  PreferencesView.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa

extension NSNotification.Name {
	static let userPreferencesDidChangeStartup = NSNotification.Name(rawValue: "userPreferencesDidChangeStartup.notification")
	static let userPreferencesDidChangeIcon = NSNotification.Name(rawValue: "userPreferencesDidChangeIcon.notification")
}

final class PreferencesView: NSView {
	@IBOutlet weak var notificationsCheck: NSButton!
	@IBOutlet weak var notificationsPlayPauseCheck: NSButton!
	@IBOutlet weak var notificationsSoundCheck: NSButton!
	@IBOutlet weak var notificationsSpotifyFocusCheck: NSButton!
	
	@IBOutlet weak var startOnLoginCheck: NSButton!
	@IBOutlet weak var showAlbumArtCheck: NSButton!
	@IBOutlet weak var roundAlbumArtCheck: NSButton!
	@IBOutlet weak var showSpotifyIconCheck: NSButton!
	
	@IBOutlet weak var menuIconPopUpButton: NSPopUpButton!
	
	@IBOutlet weak var sourceButton: NSButton!
	@IBOutlet weak var homeButton: NSButton!
	@IBOutlet weak var quitButton: NSButton!
	
	private var preferences = UserPreferences()
	
	override func viewWillDraw() {
		super.viewWillDraw()
		checkAvailability()
		setup()
		setupTargets()
	}
	
	private func checkAvailability() {
		if !SystemPreferences.isContentImagePropertyAvailable {
			showAlbumArtCheck.isEnabled = false
			roundAlbumArtCheck.isEnabled = false
		}
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
		
		menuIconPopUpButton.selectItem(at: preferences.menuIcon.rawValue)
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
		
		menuIconPopUpButton.target = self
		menuIconPopUpButton.action = #selector(menuIconPopUpButtonChanged(sender:))
		
		sourceButton.target = self
		sourceButton.action = #selector(sourceButtonTapped(sender:))
		homeButton.target = self
		homeButton.action = #selector(homeButtonTapped(sender:))
		quitButton.target = self
		quitButton.action = #selector(quitButtonTapped(sender:))
	}
	
	@objc func notificationsCheckTapped(sender: NSButton) {
		preferences.notificationsEnabled = sender.isSelected
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
	}
	
	@objc func roundAlbumArtCheckTapped(sender: NSButton) {
		preferences.roundAlbumArt = sender.isSelected
	}
	
	@objc func showSpotifyIconCheckTapped(sender: NSButton) {
		preferences.showSpotifyIcon = sender.isSelected
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
//		NSApplication.terminate(nil)
	}
}
