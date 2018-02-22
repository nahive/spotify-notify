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
	var albumArt: NSImage? { return fetchAlbumArt() }
	
	private func fetchAlbumArt() -> NSImage? {
		
		guard let id = id else {
			print("No track id")
			return nil
		}
		
		let spotifyLocation = SpotifyConstants.albumArtURL + "\(id)"
		
		// holy moly this guard ;o
		guard
			let spotifyURL = URL(string: spotifyLocation),
			let spotifyData = try? Data(contentsOf: spotifyURL) else {
				print("Problem with finding url for album")
				return nil
		}
		
		guard
			let albumAny = try? JSONSerialization.jsonObject(with: spotifyData, options: .allowFragments),
			let albumJSON = albumAny as? [String: AnyObject],
			let albumLocation = albumJSON["thumbnail_url"] as? String,
			let albumURL = URL(string: albumLocation) else {
				print("Problem with finding album art url")
				return nil
		}
		
		guard
			let albumData = try? Data(contentsOf: albumURL),
			let albumImage = NSImage(data: albumData) else {
				print("Problem with parsing data from spotify")
				return nil
		}
		
		return albumImage
	}
}

extension Track: Equatable {
	static func ==(lhs: Track, rhs: Track) -> Bool {
		return lhs.id == rhs.id
	}
}
