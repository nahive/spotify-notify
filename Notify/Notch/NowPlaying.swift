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
    var artwork: NSImage?
    var accentColor: Color

    var id: String {
        "\(title)|\(artist ?? "")|\(album ?? "")"
    }
}
