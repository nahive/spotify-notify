import Foundation
import SwiftData

@Model
final class AlbumArtwork {
    @Attribute(.unique) var id: UUID
    var album: String
    var artist: String
    @Attribute(.externalStorage)
    var artworkData: Data
    var createdAt: Date
    
    @Relationship(inverse: \SongHistory.artwork)
    var songs: [SongHistory] = []
    
    init(album: String, artist: String, artworkData: Data) {
        self.id = UUID()
        self.album = album
        self.artist = artist
        self.artworkData = artworkData
        self.createdAt = Date()
    }
}

@Model
final class SongHistory {
    @Attribute(.unique)
    var id: UUID
    var trackId: String
    var trackName: String
    @Attribute(.spotlight)
    var artist: String
    var album: String?
    var albumArtist: String?
    var duration: Int?
    var playedAt: Date
    var musicApp: String
    
    @Relationship
    var artwork: AlbumArtwork?
    
    // Additional track information
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    var discNumber: Int?
    var playedCount: Int?
    var rating: Int? // 0-100 for Apple Music, 0-100 for Spotify popularity
    var bpm: Int? // Apple Music only
    var bitRate: Int? // Apple Music only
    var isLoved: Bool? // Apple Music only
    var isStarred: Bool? // Spotify only
    var composer: String? // Apple Music only
    var spotifyUrl: String? // Spotify only
    var releaseDate: Date? // Apple Music only
    
    init(
        trackId: String,
        trackName: String,
        artist: String,
        album: String? = nil,
        albumArtist: String? = nil,
        duration: Int? = nil,
        playedAt: Date = Date(),
        musicApp: String,
        artwork: AlbumArtwork? = nil,
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
        self.id = UUID()
        self.trackId = trackId
        self.trackName = trackName
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.duration = duration
        self.playedAt = playedAt
        self.musicApp = musicApp
        self.artwork = artwork
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
    
    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        return Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
    }
    
    var formattedPlayedAt: String {
        playedAt.formatted(date: .abbreviated, time: .shortened)
    }
    
    var formattedYear: String {
        guard let year = year else { return "Unknown" }
        return String(year)
    }
    
    var formattedTrackNumber: String {
        guard let trackNumber = trackNumber else { return "Unknown" }
        if let discNumber = discNumber, discNumber > 1 {
            return "\(discNumber).\(trackNumber)"
        }
        return String(trackNumber)
    }
    
    var formattedRating: String {
        guard let rating = rating else { return "N/A" }
        if musicApp == "Spotify" {
            return "\(rating)% popularity"
        } else {
            let stars = rating / 20 // Convert 0-100 to 0-5 stars
            return String(repeating: "★", count: stars) + String(repeating: "☆", count: 5 - stars)
        }
    }
    
    var formattedBitRate: String {
        guard let bitRate = bitRate else { return "N/A" }
        return "\(bitRate) kbps"
    }
    
    var formattedBpm: String {
        guard let bpm = bpm else { return "N/A" }
        return "\(bpm) BPM"
    }
} 
