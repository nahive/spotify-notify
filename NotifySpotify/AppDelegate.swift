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
  @IBOutlet weak var windowNotificationsToggle: NSPopUpButton!
  @IBOutlet weak var windowNotificationsPlayPause: NSPopUpButton!
  @IBOutlet weak var windowNotificationsSound: NSPopUpButton!
  
  @IBOutlet weak var windowNotificationsStartup: NSPopUpButton!
  @IBOutlet weak var windowNotificationsMenuIcon: NSPopUpButton!
  @IBOutlet weak var windowNotificationsArt: NSPopUpButton!
  @IBOutlet weak var windowNotificationsSpotifyIcon: NSPopUpButton!
  @IBOutlet weak var windowNotificationsSpotifyFocus: NSPopUpButton!
  
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
    if UserPreferences.notificationsStartup == 0 {
      GBLaunchAtLogin.addAppAsLoginItem()
    } else {
      GBLaunchAtLogin.removeAppFromLoginItems()
    }
  }
  
  private func setupPreferences(){
    windowNotificationsToggle.selectItemAtIndex(UserPreferences.notificationsEnabled)
    windowNotificationsPlayPause.selectItemAtIndex(UserPreferences.notificationsPlayPause)
    windowNotificationsSound.selectItemAtIndex(UserPreferences.notificationsSound)
    
    windowNotificationsStartup.selectItemAtIndex(UserPreferences.notificationsStartup)
    windowNotificationsMenuIcon.selectItemAtIndex(UserPreferences.notificationsMenuIcon.rawValue)
    windowNotificationsArt.selectItemAtIndex(UserPreferences.notificationsArt)
    windowNotificationsSpotifyIcon.selectItemAtIndex(UserPreferences.notificationsSpotifyIcon)
    windowNotificationsSpotifyFocus.selectItemAtIndex(UserPreferences.notificationsSpotifyFocus)
    
    if !SystemPreferences.isContentImagePropertyAvailable {
      windowNotificationsArt.enabled = false
      windowNotificationsArt.selectItemAtIndex(1)
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
      
      if NSWorkspace.sharedWorkspace().frontmostApplication?.bundleIdentifier == ".com.spotify.client"
        && UserPreferences.notificationsSpotifyFocus == 0 {
        return
      }
      
      previousTrack = currentTrack
      
      currentTrack?.artist = userInfo["Artist"] as? String
      currentTrack?.album = userInfo["Album"] as? String
      currentTrack?.title = userInfo["Name"] as? String
      currentTrack?.trackID = userInfo["Track ID"] as? String
      
      if UserPreferences.notificationsEnabled == 0
        && previousTrack?.trackID != currentTrack?.trackID
      || UserPreferences.notificationsPlayPause == 0 {
        
        let notification = NSUserNotification()
        notification.title = currentTrack?.title
        notification.subtitle = currentTrack?.album
        notification.informativeText = currentTrack?.artist
        
        if SystemPreferences.isContentImagePropertyAvailable
          && UserPreferences.notificationsArt == 0 {
          currentTrack?.fetchAlbumArt({ (image) in
            if UserPreferences.notificationsSpotifyIcon == 0 {
              notification.contentImage = image
            } else {
              // private apple apis
              notification.setValue(image, forKey: "_identityImage")
              notification.setValue(2, forKey: "_identityImageStyle")
            }
          })
        }
        
        if UserPreferences.notificationsSound == 0 {
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
  
  func windowNotificationsToggle(sender: NSPopUpButton){
    UserPreferences.notificationsEnabled = sender.indexOfSelectedItem
  }
  
  func windowNotificationsPlayPause(sender: NSPopUpButton){
    UserPreferences.notificationsPlayPause = sender.indexOfSelectedItem
  }
  
  func windowNotificationsSound(sender: NSPopUpButton){
    UserPreferences.notificationsSound = sender.indexOfSelectedItem
  }
  
  func windowNotificationsStartup(sender: NSPopUpButton){
    UserPreferences.notificationsStartup = sender.indexOfSelectedItem
    setupStartup()
  }
  
  func windowNotificationsMenuIcon(sender: NSPopUpButton){
    UserPreferences.notificationsMenuIcon = UserPreferences.StatusBarIcon(rawValue:sender.indexOfSelectedItem)!
    setupIcon()
  }
  
  func windowNotificationsArt(sender: NSPopUpButton){
    UserPreferences.notificationsArt = sender.indexOfSelectedItem
  }
  
  func windowNotificationsSpotifyIcon(sender: NSPopUpButton){
    UserPreferences.notificationsSpotifyIcon = sender.indexOfSelectedItem
  }
  
  func windowNotificationsSpotifyFocus(sender: NSPopUpButton){
    UserPreferences.notificationsSpotifyFocus = sender.indexOfSelectedItem
  }

}

