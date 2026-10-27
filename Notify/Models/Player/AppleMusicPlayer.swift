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
                    let app = SBApplication(bundleIdentifier: bundleId)
                    // Ticks (1/60 s). The default is ~2 minutes, which would
                    // beachball the menu bar whenever Music is unresponsive.
                    app?.timeout = 120
                    storedApplication = app
                }
            } else {
                storedApplication = nil
            }
            return storedApplication
        }
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

    // MARK: Playback options

    var volume: Int? {
        application?.soundVolume
    }

    var isShuffling: Bool? {
        application?.shuffleEnabled
    }

    var repeatMode: RepeatMode? {
        application?.songRepeat.map { mode in
            switch mode {
            case .off: .off
            case .one: .one
            case .all: .all
            }
        }
    }

    var supportedRepeatModes: [RepeatMode] { [.off, .all, .one] }

    var supportsFavorites: Bool { true }

    func setVolume(_ volume: Int) {
        application?.setSoundVolume?(volume)
    }

    func setShuffling(_ isShuffling: Bool) {
        application?.setShuffleEnabled?(isShuffling)
    }

    func setRepeatMode(_ mode: RepeatMode) {
        let value: AppleMusicERpt = switch mode {
        case .off: .off
        case .one: .one
        case .all: .all
        }
        application?.setSongRepeat?(value)
    }

    func setCurrentTrackFavorited(_ isFavorited: Bool) {
        application?.currentTrack?.setFavorited?(isFavorited)
    }

    func play(trackId: String) -> Bool {
        guard let databaseID = Int(trackId),
              let library = (application?.sources?().firstObject as? any AppleMusicSource)?
                .libraryPlaylists?().firstObject as? any AppleMusicPlaylist,
              let tracks = library.tracks?() else { return false }

        // A single `whose` Apple Event; iterating the library would send one
        // event per track.
        let matches = tracks.filtered(using: NSPredicate(format: "databaseID == %ld", databaseID)) as NSArray
        guard let track = matches.firstObject as? any AppleMusicTrack else { return false }

        track.playOnce?(true)
        return true
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
            // Music renamed "loved" to "favorited"; `loved` is no longer in
            // its scripting dictionary and always reads nil.
            isLoved: favorited ?? loved,
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
