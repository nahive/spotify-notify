import Foundation
import ScriptingBridge
import AppKit

final class SpotifyPlayer: NSObject, MusicPlayerProtocol {
    let bundleId: String
    
    init(bundleId: String) {
        self.bundleId = bundleId
    }
    
    private var storedApplication: (any SpotifyApplication)?
    
    private var application: (any SpotifyApplication)? {
        get {
            if isOpen {
                if storedApplication == nil {
                    let app = SBApplication(bundleIdentifier: bundleId)
                    // Ticks (1/60 s). The default is ~2 minutes, which would
                    // beachball the menu bar whenever Spotify is unresponsive.
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
        guard let state = application?.playerState else { return false }
        return state != .unknown
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
        // Spotify doesn't have the same radio/station issue as Apple Music
        false
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
        application?.shuffling
    }

    var repeatMode: RepeatMode? {
        application?.repeating.map { $0 ? .all : .off }
    }

    // Spotify's scripting dictionary only exposes repeat as on/off.
    var supportedRepeatModes: [RepeatMode] { [.off, .all] }

    // Spotify's dictionary can read `starred` but not set it.
    var supportsFavorites: Bool { false }

    func setVolume(_ volume: Int) {
        application?.setSoundVolume?(volume)
    }

    func setShuffling(_ isShuffling: Bool) {
        application?.setShuffling?(isShuffling)
    }

    func setRepeatMode(_ mode: RepeatMode) {
        application?.setRepeating?(mode != .off)
    }

    func setCurrentTrackFavorited(_ isFavorited: Bool) {}

    func play(trackId: String) -> Bool {
        guard let application else { return false }
        application.playTrack?(trackId, inContext: nil)
        return true
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
    
    var fixedDuration: Int? {
        guard let duration, duration > 0 else { return nil }
        return duration / 1000
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
