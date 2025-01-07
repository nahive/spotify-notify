//
//  Track.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation

struct Track: Sendable {
    let id: String
    let name: String
    let album: String?
    let artist: String
    let artworkURL: URL?
    let duration: Int?
    
    init?(id: String?, name: String?, album: String?, artist: String?, artworkURL: URL?, duration: Int?) {
        guard let id, let name, let artist else {
            System.logger.error("not a valid track")
            return nil
        }
        self.id = id
        self.name = name
        self.album = album
        self.artist = artist
        self.artworkURL = artworkURL
        self.duration = duration
    }
}

extension Track: Equatable {
    static func ==(lhs: Track, rhs: Track) -> Bool {
        return lhs.id == rhs.id
    }
    
    static var empty: Self {
        .init(id: UUID().uuidString,
              name: "Unknown",
              album: "Unknown",
              artist: "Unkown",
              artworkURL: nil,
              duration: 0)!
    }
}

extension SpotifyTrack {
    var asTrack: Track? {
        .init(id: id?(), name: name, album: album, artist: artist, artworkURL: artworkUrl?.asURL, duration: duration)
    }
}
