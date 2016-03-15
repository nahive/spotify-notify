//
//  Constants.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Foundation

class SystemPreferences {
  static var isContentImagePropertyAvailable: Bool {
    let version = NSProcessInfo.processInfo().operatingSystemVersion
    return version.majorVersion == 10 && version.minorVersion >= 9
  }
}

class UserPreferences {
  
  enum StatusBarIcon: Int {
    case Default, Monochromatic, Disabled
  }
  
  static var notificationsEnabled: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsEnabled")
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsEnabled")
    }
  }
  
  static var notificationsPlayPause: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsPlayPause")
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsPlayPause")
    }
  }
  
  static var notificationsSound: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsSound")
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsSound")
    }
  }
  
  static var notificationsStartup: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsStartup")
    }
    set {     
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsStartup")
    }
  }
  
  static var notificationsMenuIcon: StatusBarIcon {
    get {
      return StatusBarIcon(rawValue: NSUserDefaults.standardUserDefaults().integerForKey("notificationsMenuIcon")) ?? StatusBarIcon.Default
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue.rawValue, forKey: "notificationsMenuIcon")
    }
  }
  
  static var notificationsArt: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsArt")
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsArt")
    }
  }
  
  static var notificationsSpotifyIcon: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsSpotifyIcon")
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsSpotifyIcon")
    }
  }
  
  static var notificationsSpotifyFocus: Int {
    get {
      return NSUserDefaults.standardUserDefaults().integerForKey("notificationsSpotifyFocus")
    }
    set {
      NSUserDefaults.standardUserDefaults().setInteger(newValue, forKey: "notificationsSpotifyFocus")
    }
  }
  
  
}