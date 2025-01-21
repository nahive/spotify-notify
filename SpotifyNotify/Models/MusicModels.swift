//
//  MusicModels.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2025/01/16.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import Foundation
import AppKit

enum SupportedMusicApplication: String, CaseIterable {
    case applemusic, spotify
    
    var appName: String {
        switch self {
        case .spotify:
            "Spotify"
        case .applemusic:
            "Apple Music"
        }
    }
    
    var bundleId: String {
        switch self {
        case .spotify:
            "com.spotify.client"
        case .applemusic:
            "com.apple.Music"
        }
    }
    
    var player: any MusicPlayerProtocol {
        switch self {
        case .spotify:
            SpotifyPlayer(bundleId: bundleId)
        case .applemusic:
            AppleMusicPlayer(bundleId: bundleId)
        }
    }
}

enum MusicPlayerState: Sendable {
    case stopped, paused, playing, unknown
}

enum MusicPlayerPermissionStatus: Sendable {
    case granted, closed, denied
}

enum MusicArtwork: Sendable, Equatable {
    case url(URL), image(NSImage)
}

struct MusicTrack: Sendable, Equatable {
    let id: String
    let name: String
    let album: String?
    let artist: String
    let artwork: MusicArtwork?
    let duration: Int?
    
    init?(id: String?, name: String?, album: String?, artist: String?, artwork: MusicArtwork?, duration: Int?) {
        guard let id, let name, let artist else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.album = album
        self.artist = artist
        self.artwork = artwork
        self.duration = duration
    }
}
