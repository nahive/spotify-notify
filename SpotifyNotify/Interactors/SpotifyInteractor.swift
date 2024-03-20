//
//  SpotifyInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
import ScriptingBridge
import AppKit
import Combine

enum SpotifyPlayerState {
    case stopped, paused, playing, unknown
}

extension SpotifyEPlS {
    var asPlayerState: SpotifyPlayerState {
        switch self {
        case .paused:
            .paused
        case .playing:
            .playing
        case .stopped:
            .stopped
        default:
            .unknown
        }
    }
}

final class SpotifyInteractor: ObservableObject {
    enum Const {
        static let spotifyAppName = "Spotify"
        static let spotifyBundleId = "com.spotify.client"
        static let notificationPlaybackChange = spotifyBundleId + ".PlaybackStateChanged"
    }
    
    private let spotifyBridge: SpotifyApplication? = SBApplication(bundleIdentifier: Const.spotifyBundleId)
    
    var currentTrack: Track? {
        spotifyBridge?.currentTrack?.asTrack
    }
    
    @Published var currentState: SpotifyPlayerState
    
    var currentProgress: Double {
        spotifyBridge?.playerPosition ?? 0
    }
    
    var currentProgressPercent: Double {
        guard let duration = currentTrack?.duration else {
            return 0.0
        }
        let progress = self.currentProgress * 1000
        return progress / Double(duration)
    }
    
    var isFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Const.spotifyBundleId
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        currentState = spotifyBridge?.playerState?.asPlayerState ?? .unknown
        
        DistributedNotificationCenter.default().publisher(for: .init(Const.notificationPlaybackChange))
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                System.logger.info("Received Spotify state change")
                self.currentState = self.spotifyBridge?.playerState?.asPlayerState ?? .unknown
            })
            .store(in: &cancellables)
    }
    
    func nextTrack() {
        System.logger.info("Next track")
        spotifyBridge?.nextTrack?()
    }
    
    func previousTrack() {
        System.logger.info("Prev track")
        spotifyBridge?.previousTrack?()
    }
    
    func playPause() {
        System.logger.info("Play/pause")
        spotifyBridge?.playpause?()
    }
    
    func play() {
        System.logger.info("Play")
        spotifyBridge?.play?()
    }
    
    func pause() {
        System.logger.info("Pause")
        spotifyBridge?.pause?()
    }
    
    func set(position: Double) {
        System.logger.info("Set position: \(position)")
        spotifyBridge?.setPlayerPosition?(position)
    }
}
