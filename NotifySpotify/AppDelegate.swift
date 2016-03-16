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

  
  //MARK: system functions
  
  func applicationDidFinishLaunching(aNotification: NSNotification) {
    setup()
  }

  func applicationWillTerminate(aNotification: NSNotification) {
    // Insert code here to tear down your application
  }
  
  func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      showPreferences()
    }
    
    return true
  }
  
  func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
    NSWorkspace.sharedWorkspace().launchApplication("Spotify")
  }
  
  func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
    return true
  }
  
  //MARK: setup functions
  
  private func setup(){
    currentTrack = Track()
    previousTrack = Track()
    
    NSDistributedNotificationCenter.defaultCenter().addObserver(self, selector: Selector("playbackStateChanged:"),
                                                                name: "com.spotify.client.PlaybackStateChanged",
                                                                object: nil, suspensionBehavior: .DeliverImmediately)
    
    setupIcon()
    setupStartup()
    setupPreferences()
    setupTargets()
  }
  
  
  private func setupIcon(){
    switch UserPreferences.notificationsMenuIcon {
    case .Default:
      statusBar = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
      statusBar.image = NSImage(named: "status_bar_colour.tiff")
      statusBar.menu = statusMenu
      statusBar.image?.template = false
      statusBar.highlightMode = true
    case .Monochromatic:
      statusBar = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
      statusBar.image = NSImage(named: "status_bar_black.tiff")
      statusBar.menu = statusMenu
      statusBar.image?.template = true
      statusBar.highlightMode = true
    case .Disabled:
      statusBar = nil
    }
  }
  
  private func setupStartup(){
    if UserPreferences.notificationsStartup == 1 {
      GBLaunchAtLogin.addAppAsLoginItem()
    } else {
      GBLaunchAtLogin.removeAppFromLoginItems()
    }
  }
  
  private func setupPreferences(){
    windowNotificationsToggle.state = (UserPreferences.notificationsEnabled)
    windowNotificationsPlayPause.state = (UserPreferences.notificationsPlayPause)
    windowNotificationsSound.state = (UserPreferences.notificationsSound)
    
    windowNotificationsStartup.state = (UserPreferences.notificationsStartup)
    windowNotificationsMenuIcon.selectItemAtIndex(UserPreferences.notificationsMenuIcon.rawValue)
    windowNotificationsArt.state = (UserPreferences.notificationsArt)
    windowNotificationsRoundAlbum.state = (UserPreferences.notificationsArtRound)
    windowNotificationsSpotifyIcon.state = (UserPreferences.notificationsSpotifyIcon)
    windowNotificationsSpotifyFocus.state = (UserPreferences.notificationsSpotifyFocus)
    
    if !SystemPreferences.isContentImagePropertyAvailable {
      windowNotificationsArt.enabled = false
      windowNotificationsArt.state = (0)
    }
    
  }
  
  private func setupTargets(){
    
    statusPreferences.action = Selector("showPreferences")
    statusQuit.action = Selector("terminate:")
    
    windowNotificationsToggle.action = Selector("windowNotificationsToggle:")
    windowNotificationsPlayPause.action = Selector("windowNotificationsPlayPause:")
    windowNotificationsSound.action = Selector("windowNotificationsSound:")
    
    windowNotificationsStartup.action = Selector("windowNotificationsStartup:")
    windowNotificationsMenuIcon.action = Selector("windowNotificationsMenuIcon:")
    windowNotificationsArt.action = Selector("windowNotificationsArt:")
    windowNotificationsRoundAlbum.action = Selector("windowNotificationsArtRound:")
    windowNotificationsSpotifyIcon.action = Selector("windowNotificationsSpotifyIcon:")
    windowNotificationsSpotifyFocus.action = Selector("windowNotificationsSpotifyFocus:")
    
    windowSourceButton.action = Selector("showSource")
    windowHomeButton.action = Selector("showHome")
    windowQuitButton.action = Selector("terminate:")
  }
  
  //MARK: spotify notifications
  
  func playbackStateChanged(notification: NSNotification) {
    guard let userInfo = notification.userInfo else {
      return
    }
    
    let playerStatus = userInfo["Player State"] as? String
    
    if playerStatus == "Playing" {
      
      if NSWorkspace.sharedWorkspace().frontmostApplication?.bundleIdentifier == "com.spotify.client"
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
        
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
        
      }
      
    }
  }
  
  
  //MARK: helpers
  
  func showSource(){
    NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://github.com/nahive/spotify-notify")!)
  }
  
  func showHome(){
    NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://nahive.github.io")!)
  }
  
  func showPreferences(){
    NSApp.activateIgnoringOtherApps(true)
    window.makeKeyAndOrderFront(nil)
  }
  
  func windowNotificationsToggle(sender: NSButton){
    UserPreferences.notificationsEnabled = sender.state
  }
  
  func windowNotificationsPlayPause(sender: NSButton){
    UserPreferences.notificationsPlayPause = sender.state
  }
  
  func windowNotificationsSound(sender: NSButton){
    UserPreferences.notificationsSound = sender.state
  }
  
  func windowNotificationsStartup(sender: NSButton){
    UserPreferences.notificationsStartup = sender.state
    setupStartup()
  }
  
  func windowNotificationsMenuIcon(sender: NSPopUpButton){
    UserPreferences.notificationsMenuIcon = UserPreferences.StatusBarIcon(rawValue:sender.indexOfSelectedItem)!
    setupIcon()
  }
  
  func windowNotificationsArt(sender: NSButton){
    UserPreferences.notificationsArt = sender.state
  }
  
  func windowNotificationsArtRound(sender: NSButton){
    UserPreferences.notificationsArtRound = sender.state
  }
  
  func windowNotificationsSpotifyIcon(sender: NSButton){
    UserPreferences.notificationsSpotifyIcon = sender.state
  }
  
  func windowNotificationsSpotifyFocus(sender: NSButton){
    UserPreferences.notificationsSpotifyFocus = sender.state
  }

}

