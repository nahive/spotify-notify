//
//  SpotifyPlayer.swift
//  Notify
//
//  Created by Szymon Maślanka on 2025/01/16.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import Foundation
import ScriptingBridge
import AppKit

final class SpotifyPlayer: NSObject, MusicPlayerProtocol {
    let bundleId: String
    private let lock = NSLock()
    private nonisolated(unsafe) var _storedApplication: (any SpotifyApplication)?
    
    init(bundleId: String) {
        self.bundleId = bundleId
    }
    
    private var application: (any SpotifyApplication)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            
            if isOpen {
                if _storedApplication == nil {
                    _storedApplication = SBApplication(bundleIdentifier: bundleId)
                }
            } else {
                _storedApplication = nil
            }
            return _storedApplication
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
    var asMusicTrack: MusicTrack?{
        .init(id: id?(), name: name, album: album, artist: artist, artwork: musicArtwork, duration: fixedDuration)
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
