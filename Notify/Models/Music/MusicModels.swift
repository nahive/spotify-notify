import Foundation
import AppKit

enum NotifyError: LocalizedError {
    case permissionDenied
    case applicationNotFound
    case invalidTrack
    case automationError(String)
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied: 
            return "Automation permission denied"
        case .applicationNotFound: 
            return "Music application not found"
        case .invalidTrack: 
            return "Invalid track data"
        case .automationError(let message):
            return "Automation error: \(message)"
        }
    }
}

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
    
    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: self.bundleId) != nil
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
    
    // Extended metadata
    let albumArtist: String?
    let genre: String?
    let year: Int?
    let trackNumber: Int?
    let discNumber: Int?
    let playedCount: Int?
    let rating: Int?
    let bpm: Int?
    let bitRate: Int?
    let isLoved: Bool?
    let isStarred: Bool?
    let composer: String?
    let spotifyUrl: String?
    let releaseDate: Date?
    
    init?(
        id: String?, 
        name: String?, 
        album: String?, 
        artist: String?, 
        artwork: MusicArtwork?, 
        duration: Int?,
        albumArtist: String? = nil,
        genre: String? = nil,
        year: Int? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        playedCount: Int? = nil,
        rating: Int? = nil,
        bpm: Int? = nil,
        bitRate: Int? = nil,
        isLoved: Bool? = nil,
        isStarred: Bool? = nil,
        composer: String? = nil,
        spotifyUrl: String? = nil,
        releaseDate: Date? = nil
    ) {
        guard let id, let name, let artist else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.album = album
        self.artist = artist
        self.artwork = artwork
        self.duration = duration
        self.albumArtist = albumArtist
        self.genre = genre
        self.year = year
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.playedCount = playedCount
        self.rating = rating
        self.bpm = bpm
        self.bitRate = bitRate
        self.isLoved = isLoved
        self.isStarred = isStarred
        self.composer = composer
        self.spotifyUrl = spotifyUrl
        self.releaseDate = releaseDate
    }
}

