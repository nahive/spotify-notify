//
//  Track.swift
//  NotifySpotify
//
//  Created by Szymon Maślanka on 15/03/16.
//  Copyright © 2016 Szymon Maślanka. All rights reserved.
//

import Foundation

extension SpotifyTrack {
	var track: Track {
		return Track(id: id?(),
					 name: name,
					 album: album,
					 artist: artist,
					 artworkURL: artworkUrl?.url,
					 duration: duration)
	}
}

struct Track {
	let id: String?
	let name: String?
	let album: String?
	let artist: String?
	let artworkURL: URL?
	let duration: Int?
	
	var artworkData: Data? {
		guard let id = id else { return nil }
		let spotifyLocation = SpotifyConstants.albumArtURL + id
		
		guard
			let spotifyURL = URL(string: spotifyLocation),
			let spotifyData = try? Data(contentsOf: spotifyURL) else {
				return nil
		}
		
		guard
			let thumbnailObject = try! JSONSerialization.jsonObject(with: spotifyData, options: .allowFragments) as? [String:AnyObject],
			let thumbnailLocation = thumbnailObject["thumbnail_url"] as? String else {
				return nil
		}
		
		guard
			let thumbnailURL = URL(string: thumbnailLocation),
			let thumbnailData = try? Data(contentsOf: thumbnailURL) else {
				return nil
		}
		
		return thumbnailData
	}
}

extension Track: Equatable {
	static func ==(lhs: Track, rhs: Track) -> Bool {
		return lhs.id == rhs.id
	}
}
