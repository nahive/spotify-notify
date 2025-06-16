import Foundation

enum NotificationIdentifier: Sendable {
    static let skip = "notification.skip"
    static let category = "notification.category"
}

struct MusicNotification: Sendable {
    let identifier = NSUUID().uuidString
    let title: String
    let subtitle: String?
    let body: String
    let artwork: MusicArtwork?
    
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
        
        artwork = track.artwork
    }
}

extension MusicNotification {
    enum Style {
        case simple, progress(currentTime: String, totalTime: String, percentage: Double)
    }
}
