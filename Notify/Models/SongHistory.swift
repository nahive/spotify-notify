import Foundation
import SwiftData

@Model
final class SongHistory {
    var id: UUID
    var trackId: String
    var trackName: String
    var artist: String
    var album: String?
    var duration: Int?
    var playedAt: Date
    var musicApp: String
    var artworkData: Data?
    
    init(
        trackId: String,
        trackName: String,
        artist: String,
        album: String? = nil,
        duration: Int? = nil,
        playedAt: Date = Date(),
        musicApp: String,
        artworkData: Data? = nil
    ) {
        self.id = UUID()
        self.trackId = trackId
        self.trackName = trackName
        self.artist = artist
        self.album = album
        self.duration = duration
        self.playedAt = playedAt
        self.musicApp = musicApp
        self.artworkData = artworkData
    }
    
    var formattedDuration: String {
        guard let duration = duration else { return "--:--" }
        return Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
    }
    
    var formattedPlayedAt: String {
        playedAt.formatted(date: .abbreviated, time: .shortened)
    }
} 
