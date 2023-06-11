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
    
    var isFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Const.spotifyBundleId
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        currentState = spotifyBridge?.playerState?.asPlayerState ?? .unknown
        
        DistributedNotificationCenter.default().publisher(for: .init(Const.notificationPlaybackChange))
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                self.currentState = self.spotifyBridge?.playerState?.asPlayerState ?? .unknown
            })
            .store(in: &cancellables)
    }
    
    func nextTrack() {
        spotifyBridge?.nextTrack?()
    }
    
    func previousTrack() {
        spotifyBridge?.previousTrack?()
    }
    
    func playPause() {
        spotifyBridge?.playpause?()
    }
    
    func play() {
        spotifyBridge?.play?()
    }
    
    func pause() {
        spotifyBridge?.pause?()
    }
}
