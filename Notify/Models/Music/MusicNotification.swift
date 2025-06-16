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
            case .progress(let progress):
                guard let duration = track.duration else {
                    return "--:--/--:--"
                }

                let percentage = progress / (Double(duration) / 1000.0)

                let progressMax = 14
                let currentProgress = Int(Double(progressMax) * percentage)

                let progressString = "⁃".repeated(currentProgress) +  "-".repeated(progressMax - currentProgress)

                let now = Int(progress).minutesSeconds
                let length = (duration / 1000).minutesSeconds

                let nowS = "\(now.minutes)".withLeadingZeroes + ":" + "\(now.seconds)".withLeadingZeroes
                let lengthS = "\(length.minutes)".withLeadingZeroes + ":" + "\(length.seconds)".withLeadingZeroes

                return "\(nowS)  \(progressString)  \(lengthS)"
            }
            
        }()
        
        artwork = track.artwork
    }
}

extension MusicNotification {
    enum Style {
        case simple, progress(Double)
    }
}
