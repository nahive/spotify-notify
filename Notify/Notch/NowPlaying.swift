import AppKit
import SwiftUI

/// Value snapshot of the current track, shaped for the notch UI.
struct NowPlaying: Equatable, Sendable {
    /// Siri-glass purple, used when no accent could be extracted from artwork.
    static let fallbackAccent = Color(red: 0.66, green: 0.40, blue: 1.00)

    var title: String
    var artist: String?
    var album: String?
    var isPlaying: Bool
    var duration: TimeInterval?
    /// Playback position at `elapsedCapturedAt`. Captured from MusicInteractor's
    /// 1 Hz poll when this snapshot is rebuilt, so `elapsed(at:)` can interpolate
    /// without the notch re-rendering on every poll tick.
    var elapsedBase: TimeInterval?
    var elapsedCapturedAt: Date
    var artwork: NSImage?
    var accentColor: Color
    var bundleIdentifier: String?

    var id: String {
        "\(title)|\(artist ?? "")|\(album ?? "")"
    }

    func elapsed(at date: Date = .now) -> TimeInterval? {
        guard let elapsedBase else { return nil }
        guard isPlaying else { return elapsedBase }
        let value = elapsedBase + date.timeIntervalSince(elapsedCapturedAt)
        if let duration { return min(value, duration) }
        return value
    }
}
