import Foundation
import SwiftData

@Model
final class SongHistory {
    var id: UUID
    var trackId: String
    var trackName: String
    var artist: String
    var album: String?
    var albumArtist: String?
    var duration: Int?
    var playedAt: Date
    var musicApp: String
    var artworkData: Data?
    var actualListeningTime: Int? // Actual time listened in seconds
    
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
        artworkData: Data? = nil,
        actualListeningTime: Int? = nil,
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
        self.artworkData = artworkData
        self.actualListeningTime = actualListeningTime
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
    
    var formattedActualListeningTime: String {
        guard let actualListeningTime = actualListeningTime else { return "--:--" }
        return Duration.seconds(actualListeningTime).formatted(.time(pattern: .minuteSecond))
    }
    
    var listeningCompletionPercentage: Double {
        guard let duration = duration, 
              let actualListeningTime = actualListeningTime,
              duration > 0 else { return 0.0 }
        return min(Double(actualListeningTime) / Double(duration), 1.0) * 100
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
