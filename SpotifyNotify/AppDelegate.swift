//
//  AppDelegate.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Cocoa
import LaunchAtLogin
import ScriptingBridge
import UserNotifications

extension Notification.Name {
	static let killLauncher = Notification.Name("kill.launcher.notification")
}

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
		guard !flag else { return true }
		
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
        setupUserNotifications()
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
        statusBar = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusBar.menu = statusMenu
        statusBar.button?.image?.isTemplate = false
        statusBar.button?.cell?.isHighlighted = true
        
		switch preferences.menuIcon {
		case .default:
            statusBar.button?.image = #imageLiteral(resourceName: "IconStatusBarColor")
		case .monochromatic:
            statusBar.button?.image =  #imageLiteral(resourceName: "IconStatusBarBlack")
		case .none:
			statusBar = nil
		}
	}
	
	@objc private func setupStartup(){
        LaunchAtLogin.isEnabled = preferences.startOnLogin
	}
	
	private func setupTargets(){
		statusPrevious.action = #selector(previousSong)
		statusPlay.action = #selector(playPause)
		statusNext.action = #selector(nextSong)
		statusPreferences.action = #selector(showPreferences)
		statusQuit.action = #selector(NSApplication.terminate(_:))
	}
    
    private func setupFirstRun() {
        guard !preferences.appAlreadySetup else { return }
        
        preferences.appAlreadySetup = true
        preferences.notificationsEnabled = true
        preferences.notificationsPlayPause = true
        preferences.notificationsSound = false
        preferences.notificationsDisableOnFocus = true
        preferences.notificationsLength = 5
        preferences.startOnLogin = false
        preferences.showAlbumArt = true
        preferences.roundAlbumArt = false
        preferences.showSongProgress = false
        preferences.menuIcon = .default
    }
	
	fileprivate func setupShortcuts() {
		guard let shortcut = preferences.shortcut else { return }
		shortcutsInteractor.register(combo: shortcut)
	}

    /// Setup user notifications using UserNotifications framework
    @available(OSX 10.14, *)
    private func setupUserNotifications() {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self

        // Check notification authorisation first
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if let error = error {
                print("Notification authorisation was denied: \(error)")
            }
        }

        setNotificationCategories()
    }

    /// Add Skip and Close buttons to the notification
    @available(OSX 10.14, *)
    private func setNotificationCategories() {
        let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")

        let category = UNNotificationCategory(identifier: NotificationIdentifier.category,
                                              actions: [skip],
                                              intentIdentifiers: [],
                                              options: [])

        UNUserNotificationCenter.current().setNotificationCategories([category])
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
        // guard against reopening spotify on closing
        guard notification.userInfo?["Player State"] as? String != "Stopped" else { return }
        
        notificationsInteractor.showNotification()
		updateStatus()
	}
	
	func shortcutKeyTapped() {
		notificationsInteractor.showNotification()
	}
	
	private func updateStatus() {
		switch spotifyInteractor.playerState {
        case .unknown?:
            statusStatus.title = "Status: Unknown"
		case .playing?:
			statusStatus.title = "Status: Playing"
		case .paused?:
			statusStatus.title = "Status: Paused"
		case .stopped?:
			statusStatus.title = "Status: Stopped"
		case .none:
			statusStatus.title = "Status: Unavailable"
        default:
            break
		}
	}
}

// MARK: notification NSUserNotificationCenterDelegate
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

// MARK: UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Force notifications to be shown, even if the SpotifyNotify is in the foreground
        completionHandler([.alert, .sound])
    }

    /// Handle the action buttons
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case NotificationIdentifier.skip:
            notificationsInteractor.handleAction()
        default:
            NSWorkspace.shared.launchApplication(SpotifyConstants.applicationName)
        }
    }
}
