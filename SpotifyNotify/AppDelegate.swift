//
//  AppDelegate.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	
	@IBOutlet weak var preferencesWindow: NSWindow!
	@IBOutlet weak var statusMenu: NSMenu!
	@IBOutlet weak var statusPreferences: NSMenuItem!
	@IBOutlet weak var statusQuit: NSMenuItem!
	
	fileprivate var preferences = UserPreferences()
	fileprivate var notificationsInteractor = NotificationsInteractor()
	
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
	
	fileprivate func setupTargets(){
		statusPreferences.action = #selector(showPreferences)
		statusQuit.action = #selector(NSApplication.terminate(_:))
	}
    
    fileprivate func setupFirstRun() {
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
	
	@objc fileprivate func showPreferences(){
		NSApp.activate(ignoringOtherApps: true)
		preferencesWindow.makeKeyAndOrderFront(nil)
	}
	
	@objc fileprivate func playbackStateChanged(_ notification: Notification) {
		notificationsInteractor.handlePlaybackChange(from: notification)
	}
}

// MARK: notification delegates
extension AppDelegate: NSUserNotificationCenterDelegate {
	func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
		
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

