//
//  Track.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Foundation
import AppKit

typealias FetchingResult = (Result) -> Void
enum Result { case success(NSImage), error(String) }

struct Track {
	let id: String?
	let title: String?
	let artist: String?
	let album: String?
	var albumArt: NSImage?
	
	private let baseSpotifyURL = "https://embed.spotify.com/oembed/?url="
	
	mutating func albumArt(result: FetchingResult) {
		
		guard let id = id else {
			return result(.error("No track id"))
		}
		
		let spotifyLocation = baseSpotifyURL + "\(id)"
		
		// holy moly this guard ;o
		guard
			let spotifyURL = URL(string: spotifyLocation),
			let spotifyData = try? Data(contentsOf: spotifyURL),
			let albumAny = try? JSONSerialization.jsonObject(with: spotifyData, options: .allowFragments),
			let albumJSON = albumAny as? [String: AnyObject],
			let albumLocation = albumJSON["album_url"] as? String,
			let albumURL = URL(string: albumLocation),
			let albumData = try? Data(contentsOf: albumURL),
			let albumImage = NSImage(data: albumData) else {
				return result(.error("Problem with parsing data from spotify"))
		}
		
		albumArt = albumImage
		result(.success(albumImage))
	}
}

extension Track {
	init() {
		self.init(id: nil, title: nil, artist: nil, album: nil, albumArt: nil)
	}
}
