//
//  AppleMusicPlayer.swift
//  Notify
//
//  Created by Szymon Maślanka on 2025/01/16.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//


import Foundation
import ScriptingBridge
import AppKit

final class AppleMusicPlayer: NSObject, MusicPlayerProtocol {
    let bundleId: String
    private let lock = NSLock()
    private nonisolated(unsafe) var _storedApplication: (any AppleMusicApplication)?
    
    init(bundleId: String) {
        self.bundleId = bundleId
    }
    
    private var application: (any AppleMusicApplication)? {
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
        bundleId + ".playerInfo"
    }
    
    var hasPermissionToControl: Bool {
        application?.version?.isEmpty == false
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

private extension AppleMusicTrack {
    var asMusicTrack: MusicTrack? {
        .init(
            id: id, 
            name: name, 
            album: album, 
            artist: artist, 
            artwork: musicArtwork, 
            duration: duration?.asInt,
            albumArtist: albumArtist,
            genre: genre,
            year: year,
            trackNumber: trackNumber,
            discNumber: discNumber,
            playedCount: playedCount,
            rating: rating,
            bpm: bpm,
            bitRate: bitRate,
            isLoved: loved,
            composer: composer,
            releaseDate: releaseDate ?? nil
        )
    }
    
    var id: String? {
        guard let databaseID else {
            return nil
        }
        return "\(databaseID)"
    }
    
    var musicArtwork: MusicArtwork? {
        guard let artwork = self.artworks?().firstObject as? (any AppleMusicArtwork), let data = artwork.data else {
            return .none
        }
        return .image(data)
    }
}

private extension Double {
    var asInt: Int {
        Int(self)
    }
}

private extension AppleMusicEPlS {
    var asMusicPlayerState: MusicPlayerState {
        switch self {
        case .stopped:
            .stopped
        case .playing:
            .playing
        case .paused:
            .paused
        default:
            .unknown
        }
    }
}
