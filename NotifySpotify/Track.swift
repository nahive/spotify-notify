//
//  Track.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Foundation
import AppKit

struct Track {
  var title: String?
  var artist: String?
  var album: String?
  var albumArt: NSImage?
  var trackID: String?
  
  mutating func fetchAlbumArt(closure: (image: NSImage?) -> ()) {
    
    guard let trackID = trackID else {
      closure(image: nil)
      return
    }
    
    let spotifyLocation = "https://embed.spotify.com/oembed/?url=\(trackID)"
    
    guard
      let spotifyURL = NSURL(string: spotifyLocation),
      let spotifyData = NSData(contentsOfURL: spotifyURL) else {
        closure(image: nil)
        return
    }
    
    guard
      let thumbnailLocation = try! NSJSONSerialization
        .JSONObjectWithData(spotifyData, options: .AllowFragments)["thumbnail_url"] as? String else {
          closure(image: nil)
          return
    }
    
    guard
    let thumbnailURL = NSURL(string: thumbnailLocation),
    let thumbnailData = NSData(contentsOfURL: thumbnailURL) else {
      closure(image: nil)
      return
    }
    
    albumArt = NSImage(data: thumbnailData)
    
    closure(image: albumArt)
    
  }
  
}