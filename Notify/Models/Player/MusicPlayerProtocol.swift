import Foundation
import AppKit

protocol MusicPlayerProtocol: Sendable {
    var bundleId: String { get }
    
    var playbackChangedName: String { get }
    var isOpen: Bool { get }
    var hasPermissionToControl: Bool { get }
    
    var currentTrack: MusicTrack? { get }
    var currentState: MusicPlayerState? { get }
    var playerPosition: Double? { get }
    var isPlayingRadio: Bool { get }
    
    func nextTrack()
    func previousTrack()
    func playPause()
}

extension MusicPlayerProtocol {
    var isFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == bundleId
    }
    
    var isOpen: Bool {
        guard let app = NSWorkspace.shared.runningApplications.filter({ $0.bundleIdentifier == bundleId }).first else {
            return false
        }
        return !app.isTerminated
    }
}
