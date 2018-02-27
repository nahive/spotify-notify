//
//  AppDelegate.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Cocoa
import ServiceManagement
import ScriptingBridge

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var preferencesWindow: NSWindow!
	@IBOutlet weak var statusMenu: NSMenu!
	@IBOutlet weak var statusStatus: NSMenuItem!
	@IBOutlet weak var statusPrevious: NSMenuItem!
	@IBOutlet weak var statusPlay: NSMenuItem!
	@IBOutlet weak var statusNext: NSMenuItem!
	@IBOutlet weak var statusPreferences: NSMenuItem!
	@IBOutlet weak var statusQuit: NSMenuItem!
	
	fileprivate var preferences = UserPreferences()
	fileprivate let notificationsInteractor = NotificationsInteractor()
	fileprivate let shortcutsInteractor = ShortcutsInteractor()
	fileprivate let spotifyInteractor = SpotifyInteractor()
	
	var statusBar: NSStatusItem!
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		setup()
	}
	
	func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
		guard flag else { return true }
		
		showPreferences()
		return true
	}
}

// MARK: setup functions

extension AppDelegate {
	fileprivate func setup(){
		setupObservers()
		setupMenuBarIcon()
		setupStartup()
		setupTargets()
        setupFirstRun()
		setupShortcuts()
	}
	
	private func setupObservers() {
		let center = DistributedNotificationCenter.default()
		
		center.addObserver(self, selector: #selector(playbackStateChanged),
						   name: NSNotification.Name(rawValue: SpotifyConstants.notificationPlaybackChange),
						   object: nil, suspensionBehavior: .deliverImmediately)
		
		center.addObserver(self, selector: #selector(setupStartup),
						   name: .userPreferencesDidChangeStartup, object: nil)
		
		center.addObserver(self, selector: #selector(setupMenuBarIcon),
						   name: .userPreferencesDidChangeIcon, object: nil)
		
		
		NSUserNotificationCenter.default.delegate = self
	}
	
	@objc private func setupMenuBarIcon(){
		switch preferences.menuIcon {
		case .default:
			statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
			statusBar.image = #imageLiteral(resourceName: "IconStatusBarColor")
			statusBar.menu = statusMenu
			statusBar.image?.isTemplate = false
			statusBar.highlightMode = true
		case .monochromatic:
			statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
			statusBar.image =  #imageLiteral(resourceName: "IconStatusBarBlack")
			statusBar.menu = statusMenu
			statusBar.image?.isTemplate = true
			statusBar.highlightMode = true
		case .none:
			statusBar = nil
		}
	}
	
	@objc private func setupStartup(){
		if preferences.startOnLogin {
			SMLoginItemSetEnabled("io.nahive.SpotifyNotify".cfString, true)
		} else {
            SMLoginItemSetEnabled("io.nahive.SpotifyNotify".cfString, false)
		}
	}
	
	private func setupTargets(){
		statusPrevious.action = #selector(previousSong)
		statusPlay.action = #selector(playPause)
		statusNext.action = #selector(nextSong)
		statusPreferences.action = #selector(showPreferences)
		statusQuit.action = #selector(NSApplication.terminate(_:))
	}
    
    private func setupFirstRun() {
        if !preferences.isNotFirstRun {
            preferences.isNotFirstRun = true
            preferences.notificationsEnabled = true
            preferences.notificationsPlayPause = true
            preferences.notificationsSound = false
            preferences.notificationsDisableOnFocus = true
            preferences.notificationsLength = 5
            preferences.startOnLogin = false
            preferences.showAlbumArt = true
            preferences.roundAlbumArt = false
            preferences.showSpotifyIcon = true
            preferences.showSongProgress = false
            preferences.menuIcon = .default
        }
    }
	
	fileprivate func setupShortcuts() {
		guard let shortcut = preferences.shortcut else { return }
		shortcutsInteractor.register(combo: shortcut)
	}
	
	@objc fileprivate func previousSong(){
		spotifyInteractor.previousTrack()
	}
	
	@objc fileprivate func playPause(){
		spotifyInteractor.playPause()
	}
	
	@objc fileprivate func nextSong(){
		spotifyInteractor.nextTrack()
	}
	
	@objc fileprivate func showPreferences(){
		NSApp.activate(ignoringOtherApps: true)
		preferencesWindow.makeKeyAndOrderFront(nil)
	}
	
	@objc fileprivate func playbackStateChanged(_ notification: Notification) {
		notificationsInteractor.showNotification()
		updateStatus()
	}
	
	@objc func shortcutKeyTapped() {
		notificationsInteractor.showNotification()
	}
	
	private func updateStatus() {
		switch spotifyInteractor.playerState {
		case .playing?:
			statusStatus.title = "Status: Playing"
		case .paused?:
			statusStatus.title = "Status: Paused"
		case .stopped?:
			statusStatus.title = "Status: Stopped"
		case .none:
			statusStatus.title = "Status: Unavailable"
		}
	}
}

// MARK: notification delegates
extension AppDelegate: NSUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
		// nothing
	}
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
		switch notification.activationType {
		case .actionButtonClicked:
			notificationsInteractor.handleAction()
		default:
			NSWorkspace.shared.launchApplication(SpotifyConstants.applicationName)
		}
		
	}
	
	func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
		return true
	}
}

