//
//  AppDelegate.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
  
  var statusBar: NSStatusItem!
	
  @IBOutlet weak var statusMenu: NSMenu!
  @IBOutlet weak var statusPreferences: NSMenuItem!
  @IBOutlet weak var statusQuit: NSMenuItem!

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var windowNotificationsToggle: NSButton!
  @IBOutlet weak var windowNotificationsPlayPause: NSButton!
  @IBOutlet weak var windowNotificationsSound: NSButton!
  
  @IBOutlet weak var windowNotificationsStartup: NSButton!
  @IBOutlet weak var windowNotificationsMenuIcon: NSPopUpButton!
  @IBOutlet weak var windowNotificationsArt: NSButton!
  @IBOutlet weak var windowNotificationsRoundAlbum: NSButton!
  @IBOutlet weak var windowNotificationsSpotifyIcon: NSButton!
  @IBOutlet weak var windowNotificationsSpotifyFocus: NSButton!
  
  
  @IBOutlet weak var windowSourceButton: NSButton!
  @IBOutlet weak var windowHomeButton: NSButton!
  @IBOutlet weak var windowQuitButton: NSButton!
  
  var currentTrack: Track?
  var previousTrack: Track?

  
  // MARK: system functions
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    setup()
  }
	
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      showPreferences()
    }
    
    return true
  }
  
  func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
    NSWorkspace.shared().launchApplication("Spotify")
  }
  
  func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
    return true
  }
  
  //MARK: setup functions
  
  fileprivate func setup(){
    currentTrack = Track()
    previousTrack = Track()
    
    DistributedNotificationCenter.default().addObserver(self, selector: #selector(AppDelegate.playbackStateChanged(_:)),
                                                                name: NSNotification.Name(rawValue: "com.spotify.client.PlaybackStateChanged"),
                                                                object: nil, suspensionBehavior: .deliverImmediately)
    
    setupIcon()
    setupStartup()
    setupPreferences()
    setupTargets()
  }
  
  
  fileprivate func setupIcon(){
    switch UserPreferences.notificationsMenuIcon {
    case .default:
      statusBar = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
      statusBar.image = NSImage(named: "status_bar_colour.tiff")
      statusBar.menu = statusMenu
      statusBar.image?.isTemplate = false
      statusBar.highlightMode = true
    case .monochromatic:
      statusBar = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
      statusBar.image = NSImage(named: "status_bar_black.tiff")
      statusBar.menu = statusMenu
      statusBar.image?.isTemplate = true
      statusBar.highlightMode = true
    case .disabled:
      statusBar = nil
    }
  }
  
  fileprivate func setupStartup(){
    if UserPreferences.notificationsStartup == 1 {
      GBLaunchAtLogin.addAppAsLoginItem()
    } else {
      GBLaunchAtLogin.removeAppFromLoginItems()
    }
  }
  
  fileprivate func setupPreferences(){
    windowNotificationsToggle.state = (UserPreferences.notificationsEnabled)
    windowNotificationsPlayPause.state = (UserPreferences.notificationsPlayPause)
    windowNotificationsSound.state = (UserPreferences.notificationsSound)
    
    windowNotificationsStartup.state = (UserPreferences.notificationsStartup)
    windowNotificationsMenuIcon.selectItem(at: UserPreferences.notificationsMenuIcon.rawValue)
    windowNotificationsArt.state = (UserPreferences.notificationsArt)
    windowNotificationsRoundAlbum.state = (UserPreferences.notificationsArtRound)
    windowNotificationsSpotifyIcon.state = (UserPreferences.notificationsSpotifyIcon)
    windowNotificationsSpotifyFocus.state = (UserPreferences.notificationsSpotifyFocus)
    
    if !SystemPreferences.isContentImagePropertyAvailable {
      windowNotificationsArt.isEnabled = false
      windowNotificationsArt.state = (0)
    }
    
  }
  
  fileprivate func setupTargets(){
    
    statusPreferences.action = #selector(showPreferences)
    statusQuit.action = #selector(NSApplication.terminate(_:))
    
    windowNotificationsToggle.action = #selector(windowNotificationsToggle(_:))
    windowNotificationsPlayPause.action = #selector(windowNotificationsPlayPause(_:))
    windowNotificationsSound.action = #selector(windowNotificationsSound(_:))
    
    windowNotificationsStartup.action = #selector(windowNotificationsStartup(_:))
    windowNotificationsMenuIcon.action = #selector(windowNotificationsMenuIcon(_:))
    windowNotificationsArt.action = #selector(windowNotificationsArt(_:))
    windowNotificationsRoundAlbum.action = #selector(windowNotificationsArtRound(_:))
    windowNotificationsSpotifyIcon.action = #selector(windowNotificationsSpotifyIcon(_:))
    windowNotificationsSpotifyFocus.action = #selector(windowNotificationsSpotifyFocus(_:))
    
    windowSourceButton.action = #selector(showSource)
    windowHomeButton.action = #selector(showHome)
    windowQuitButton.action = #selector(NSApplication.terminate(_:))
  }
  
  //MARK: spotify notifications
  
  func playbackStateChanged(_ notification: Notification) {
    guard let userInfo = (notification as NSNotification).userInfo else {
      return
    }
    
    let playerStatus = userInfo["Player State"] as? String
    
    if playerStatus == "Playing" {
      
      if NSWorkspace.shared().frontmostApplication?.bundleIdentifier == "com.spotify.client"
        && UserPreferences.notificationsSpotifyFocus == 1 {
        return
      }
      
      previousTrack = currentTrack
      
      currentTrack?.artist = userInfo["Artist"] as? String
      currentTrack?.album = userInfo["Album"] as? String
      currentTrack?.title = userInfo["Name"] as? String
      currentTrack?.trackID = userInfo["Track ID"] as? String
      
      if UserPreferences.notificationsEnabled == 1
        && previousTrack?.trackID != currentTrack?.trackID
      || UserPreferences.notificationsPlayPause == 1 {
        
        let notification = NSUserNotification()
        notification.title = currentTrack?.title
        notification.subtitle = currentTrack?.album
        notification.informativeText = currentTrack?.artist
        
        if SystemPreferences.isContentImagePropertyAvailable
          && UserPreferences.notificationsArt == 1 {
          currentTrack?.fetchAlbumArt({ (image) in
            if UserPreferences.notificationsSpotifyIcon == 1 {
              notification.contentImage = image
            } else {
              
              // adjusting offset for subtitle and informative test
              // \u{200C} is zero width non-joiner - the only thing treated
              // as non space otherwise trimmed in nsusernotification
              let offset = "\u{200C}" + "\u{00a0}\u{00a0}\u{00a0}\u{00a0}\u{00a0}\u{00a0}\u{00a0}"
              notification.subtitle = notification.subtitle!
              notification.informativeText = notification.informativeText!
              
              // private apple apis
              notification.setValue(image, forKey: "_identityImage")
              if UserPreferences.notificationsArtRound == 1 {
                 notification.setValue(2, forKey: "_identityImageStyle")
              } else {
                 notification.setValue(0, forKey: "_identityImageStyle")
              }
             
            }
          })
        }
        
        if UserPreferences.notificationsSound == 1 {
          notification.soundName = NSUserNotificationDefaultSoundName
        }
        
        NSUserNotificationCenter.default.deliver(notification)
        
      }
      
    }
  }
  
  //MARK: helpers
  
  func showSource(){
    NSWorkspace.shared().open(URL(string: "https://github.com/nahive/spotify-notify")!)
  }
  
  func showHome(){
    NSWorkspace.shared().open(URL(string: "https://nahive.github.io")!)
  }
  
  func showPreferences(){
    NSApp.activate(ignoringOtherApps: true)
    window.makeKeyAndOrderFront(nil)
  }
  
  func windowNotificationsToggle(_ sender: NSButton){
    UserPreferences.notificationsEnabled = sender.state
  }
  
  func windowNotificationsPlayPause(_ sender: NSButton){
    UserPreferences.notificationsPlayPause = sender.state
  }
  
  func windowNotificationsSound(_ sender: NSButton){
    UserPreferences.notificationsSound = sender.state
  }
  
  func windowNotificationsStartup(_ sender: NSButton){
    UserPreferences.notificationsStartup = sender.state
    setupStartup()
  }
  
  func windowNotificationsMenuIcon(_ sender: NSPopUpButton){
    UserPreferences.notificationsMenuIcon = UserPreferences.StatusBarIcon(rawValue:sender.indexOfSelectedItem)!
    setupIcon()
  }
  
  func windowNotificationsArt(_ sender: NSButton){
    UserPreferences.notificationsArt = sender.state
  }
  
  func windowNotificationsArtRound(_ sender: NSButton){
    UserPreferences.notificationsArtRound = sender.state
  }
  
  func windowNotificationsSpotifyIcon(_ sender: NSButton){
    UserPreferences.notificationsSpotifyIcon = sender.state
  }
  
  func windowNotificationsSpotifyFocus(_ sender: NSButton){
    UserPreferences.notificationsSpotifyFocus = sender.state
  }

}

