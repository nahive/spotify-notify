import Foundation

enum NotificationIdentifier: Sendable {
    static let skip = "notification.skip"
    static let favorite = "notification.favorite"
    static let unfavorite = "notification.unfavorite"
    static let category = "notification.category"
    /// Players that support favorites get a second action, and which one
    /// depends on the track's current state.
    static let favoriteCategory = "notification.category.favorite"
    static let unfavoriteCategory = "notification.category.unfavorite"
    /// userInfo key: the track a banner was built for, so its actions can't
    /// hit a track that started after delivery.
    static let trackIdKey = "trackId"
    /// Stable across deliveries so each banner replaces the previous one
    /// instead of stacking a permanent entry per track in Notification Center.
    static let nowPlaying = "notification.nowplaying"
}

struct MusicNotification: Sendable {
    let identifier = NotificationIdentifier.nowPlaying
    let title: String
    let subtitle: String?
    let body: String
    
    init(track: MusicTrack, style: Style) {
        title = track.name
        
        subtitle = {
            switch style {
            case .simple:
                return track.album
            case .progress:
                if let album = track.album {
                    return "\(track.artist) - \(album)"
                } else {
                    return track.artist
                }
            }
        }()
        
        body = {
            switch style {
            case .simple:
                return track.artist
            case .progress(let currentTime, let totalTime, let percentage):
                let progressMax = 10
                let currentProgress = max(0, min(progressMax, Int(Double(progressMax) * percentage)))
                let remaining = progressMax - currentProgress
                let progressString = "●".repeated(currentProgress) + "○".repeated(remaining)

                return "\(currentTime) \(progressString) \(totalTime)"
            }
            
        }()
    }
}

extension MusicNotification {
    enum Style {
        case simple, progress(currentTime: String, totalTime: String, percentage: Double)
    }
}
