import Foundation
import ScriptingBridge
import AppKit

final class AppleMusicPlayer: NSObject, MusicPlayerProtocol {
    let bundleId: String
    private var storedApplication: (any AppleMusicApplication)?

    init(bundleId: String) {
        self.bundleId = bundleId
    }

    private var application: (any AppleMusicApplication)? {
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
    
    var isPlayingRadio: Bool {
        guard let application else { return false }
        guard application.playerState == .playing else { return false }
        
        guard let currentTrack = application.currentTrack else {
            return true
        }
        
        let hasValidName = currentTrack.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasValidArtist = currentTrack.artist?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        let hasValidID = currentTrack.databaseID != nil && currentTrack.databaseID != 0
        
        return !hasValidName || !hasValidArtist || !hasValidID
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
    
    func seek(to position: Double) {
        application?.setPlayerPosition?(position)
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
        guard let artwork = self.artworks?().firstObject as? (any AppleMusicArtwork) else {
            return .none
        }

        // The bridge header types `data` as `NSImage`, but Music.app routinely
        // hands back an NSAppleEventDescriptor that ScriptingBridge can't coerce.
        // A Swift `as? NSImage` trusts that static `NSImage` typing and lets the
        // descriptor through, so image selectors (isValid/TIFFRepresentation)
        // crash. Route every candidate through the ObjC runtime so the check
        // uses the real class, and prefer the raw original-format bytes.
        for candidate in [artwork.rawData as AnyObject?, artwork.data as AnyObject?] {
            guard let candidate else { continue }
            if candidate.isKind(of: NSImage.self), let image = candidate as? NSImage, image.isValid {
                return .image(image)
            }
            if let descriptor = candidate as? NSAppleEventDescriptor,
               let image = NSImage(data: descriptor.data) {
                return .image(image)
            }
            if let data = candidate as? Data, let image = NSImage(data: data) {
                return .image(image)
            }
        }
        return .none
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
