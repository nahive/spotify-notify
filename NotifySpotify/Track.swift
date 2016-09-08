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
  
  mutating func fetchAlbumArt(_ closure: (_ image: NSImage?) -> ()) {
    
    guard let trackID = trackID else {
      closure(nil)
      return
    }
    
    let spotifyLocation = "https://embed.spotify.com/oembed/?url=\(trackID)"
    
    guard
      let spotifyURL = URL(string: spotifyLocation),
      let spotifyData = try? Data(contentsOf: spotifyURL) else {
        closure(nil)
        return
    }

    guard
      let thumbnailObject = try! JSONSerialization.jsonObject(with: spotifyData, options: .allowFragments) as? [String:AnyObject],
      let thumbnailLocation = thumbnailObject["thumbnail_url"] as? String else {
          closure(nil)
          return
    }
    
    guard
    let thumbnailURL = URL(string: thumbnailLocation),
    let thumbnailData = try? Data(contentsOf: thumbnailURL) else {
      closure(nil)
      return
    }
    
    albumArt = NSImage(data: thumbnailData)
    
    closure(albumArt)
    
  }
  
}
