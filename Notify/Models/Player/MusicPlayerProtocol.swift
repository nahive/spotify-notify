import Foundation
import AppKit

enum RepeatMode: Sendable, CaseIterable {
    case off, all, one
}

@MainActor
protocol MusicPlayerProtocol: AnyObject {
    var bundleId: String { get }

    var hasPermissionToControl: Bool { get }

    var currentTrack: MusicTrack? { get }
    var currentState: MusicPlayerState? { get }
    var playerPosition: Double? { get }
    var isPlayingRadio: Bool { get }

    var volume: Int? { get }
    var isShuffling: Bool? { get }
    var repeatMode: RepeatMode? { get }
    /// In the order a repeat button cycles through them.
    var supportedRepeatModes: [RepeatMode] { get }
    var supportsFavorites: Bool { get }

    func nextTrack()
    func previousTrack()
    func playPause()
    func seek(to position: Double)
    func setVolume(_ volume: Int)
    func setShuffling(_ isShuffling: Bool)
    func setRepeatMode(_ mode: RepeatMode)
    func setCurrentTrackFavorited(_ isFavorited: Bool)
    /// Starts playback of a track previously reported by this player.
    /// Returns false when the player can no longer find it.
    func play(trackId: String) -> Bool
}

extension MusicPlayerProtocol {
    var isFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleId
    }

    var isOpen: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId && !$0.isTerminated }
    }
}
