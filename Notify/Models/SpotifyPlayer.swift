//
//  SpotifyPlayer.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2025/01/16.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import Foundation
import ScriptingBridge
import AppKit

final class SpotifyPlayer: NSObject, MusicPlayerProtocol {
    let bundleId: String
    
    init(bundleId: String) {
        self.bundleId = bundleId
    }
    
    private nonisolated(unsafe) var storedApplication: (any SpotifyApplication)?
    
    private var application: (any SpotifyApplication)? {
        get {
            if isOpen {
                if storedApplication == nil {
                    storedApplication = SBApplication(bundleIdentifier: bundleId)
                }
            } else {
                storedApplication = nil
            }
            return storedApplication
        }
    }

    var playbackChangedName: String {
        bundleId + ".PlaybackStateChanged"
    }
    
    var hasPermissionToControl: Bool {
        application?.playerState != .unknown
    }
    
    var currentTrack: MusicTrack? {
        application?.currentTrack?.asMusicTrack
    }
    
    var currentState: MusicPlayerState? {
        application?.playerState?.asMusicPlayerState
    }
    
    var playerPosition: Double? {
        application?.playerPosition
    }
    
    func nextTrack() {
        application?.nextTrack?()
    }
    
    func previousTrack() {
        application?.previousTrack?()
    }
    
    func playPause() {
        application?.playpause?()
    }
}

private extension SpotifyTrack {
    var asMusicTrack: MusicTrack? {
        .init(
            id: id?(), 
            name: name, 
            album: album, 
            artist: artist, 
            artwork: musicArtwork, 
            duration: fixedDuration,
            albumArtist: albumArtist,
            trackNumber: trackNumber,
            discNumber: discNumber,
            playedCount: playedCount,
            rating: popularity, // Spotify uses popularity 0-100
            isStarred: starred,
            spotifyUrl: spotifyUrl
        )
    }
    
    var fixedDuration: Int {
        (duration ?? 0) / 1000
    }
    
    var musicArtwork: MusicArtwork? {
        guard let url = self.artworkUrl?.asURL else {
            return .none
        }
        return .url(url)
    }
}

private extension SpotifyEPlS {
    var asMusicPlayerState: MusicPlayerState {
        switch self {
        case .unknown:
            .unknown
        case .stopped:
            .stopped
        case .playing:
            .playing
        case .paused:
            .paused
        }
    }
}
