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
}

extension Track: Equatable {
	static func ==(lhs: Track, rhs: Track) -> Bool {
		return lhs.id == rhs.id
	}
}
