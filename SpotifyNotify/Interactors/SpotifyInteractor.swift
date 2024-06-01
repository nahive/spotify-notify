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
import UserNotifications

final class SpotifyInteractor: NSObject, ObservableObject {
    enum Const {
        static let spotifyAppName = "Spotify"
        static let spotifyBundleId = "com.spotify.client"
        static let playbackStateChanged = spotifyBundleId + ".PlaybackStateChanged"
    }
    
    private var spotifyBridge: SpotifyApplication? {
        guard isSpotifyOpen else {
            return nil
        }
        return SBApplication(bundleIdentifier: Const.spotifyBundleId)
    }
    
    private var spotifyApp: NSRunningApplication? {
        NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == Const.spotifyBundleId }
            .first
    }
    
    var isFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Const.spotifyBundleId
    }
    
    private var isSpotifyOpen: Bool {
        guard let spotifyApp else {
            return false
        }
        return !spotifyApp.isTerminated
    }
    
    var currentProgress: Double {
         spotifyBridge?.playerPosition ?? 0
     }
    
    @Published var currentState: SpotifyPlayerState = .unknown
    @Published var currentTrack: Track = .empty
    
    @Published var currentProgressPercent: Double = 0
    @Published var currentTrackProgress: String = "--:--"
    @Published var fullTrackDuration: String = "--:--"
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        currentState = spotifyBridge?.playerState?.asPlayerState ?? .unknown
        currentTrack = spotifyBridge?.currentTrack?.asTrack ?? .empty
        calculateProgress()
        
        DistributedNotificationCenter.default().publisher(for: .init(Const.playbackStateChanged))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                System.logger.info("Received Spotify state change")
                switch state {
                case "Paused", "Playing":
                    self.currentState = self.spotifyBridge?.playerState?.asPlayerState ?? .unknown
                    self.currentTrack = self.spotifyBridge?.currentTrack?.asTrack ?? .empty
                default:
                    self.currentState = .unknown
                    self.currentTrack = .empty
                    self.currentProgressPercent = 0.0
                    self.fullTrackDuration = "--:--"
                }
            })
            .store(in: &cancellables)
        
        DistributedNotificationCenter.default().publisher(for: .init(Const.playbackStateChanged))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .filter { $0 == "Playing" }
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                System.logger.info("Received Spotify track change")
                self.currentTrack = self.spotifyBridge?.currentTrack?.asTrack ?? .empty
            })
            .store(in: &cancellables)
        
        timer.sink { [weak self] _ in
            guard let self, currentState == .playing else { return }
            self.calculateProgress()
        }.store(in: &cancellables)
    }
    
    private func calculateProgress() {
        guard let duration = currentTrack.duration, duration != 0 else {
            currentProgressPercent = 0.0
            currentTrackProgress = "--:--"
            fullTrackDuration = "--:--"
            return
        }
        
        let progress = (self.spotifyBridge?.playerPosition ?? 0) * 1000
        currentProgressPercent = progress / Double(duration)
        currentTrackProgress = Duration.milliseconds(progress).formatted(.time(pattern: .minuteSecond))
        fullTrackDuration = Duration.milliseconds(duration).formatted(.time(pattern: .minuteSecond))
    }
    
    func openSpotify() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.spotify.client") else { return }

        let path = "/bin"
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = [path]
        NSWorkspace.shared.openApplication(at: url,
                                           configuration: configuration,
                                           completionHandler: nil)
    }
    
    func nextTrack() {
        guard let spotifyBridge else {
            openSpotify()
            return
        }
        System.logger.info("Next track")
        spotifyBridge.nextTrack?()
    }
    
    func previousTrack() {
        guard let spotifyBridge else {
            openSpotify()
            return
        }
        System.logger.info("Prev track")
        spotifyBridge.previousTrack?()
    }
    
    func playPause() {
        guard let spotifyBridge else {
            openSpotify()
            return
        }
        System.logger.info("Play/pause")
        spotifyBridge.playpause?()
    }
}

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
