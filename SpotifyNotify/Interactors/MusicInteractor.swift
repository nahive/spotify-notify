//
//  MusicInteractor.swift
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

@MainActor
final class MusicInteractor: ObservableObject {
    
    private let config: any CommonMusicConfig
    
    private var bridge: (any CommonMusicPlayerBridge)? {
        guard isApplicationOpen else {
            return nil
        }
        return SBApplication(bundleIdentifier: config.bundleId) as? (any CommonMusicPlayerBridge)
    }

    private var application: NSRunningApplication? {
        NSWorkspace.shared.runningApplications
            .filter { $0.bundleIdentifier == config.bundleId }
            .first
    }

    var isFrontmost: Bool {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier == config.bundleId
    }

    private var isApplicationOpen: Bool {
        guard let application else {
            return false
        }
        return !application.isTerminated
    }
    
    var currentProgress: Double {
         bridge?.playerPosition ?? 0
     }
    
    @Published var currentState: MusicPlayerState = .unknown
    @Published var currentTrack: Track = .empty
    
    @Published var currentProgressPercent: Double = 0
    @Published var currentTrackProgress: String = "--:--"
    @Published var fullTrackDuration: String = "--:--"
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var cancellables = Set<AnyCancellable>()
    
    init(config: any CommonMusicConfig) {
        self.config = config
        
        currentState = bridge?.currentState ?? .unknown
        currentTrack = bridge?.currentTrack ?? .empty
        
        calculateProgress()
        
        DistributedNotificationCenter.default().publisher(for: .init(config.playbackChangedName))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                System.logger.info("Received \(config.appName) state change")
                switch state {
                case "Paused", "Playing":
                    self.currentState = self.bridge?.currentState ?? .unknown
                    self.currentTrack = self.bridge?.currentTrack ?? .empty
                default:
                    self.currentState = .unknown
                    self.currentTrack = .empty
                    self.currentProgressPercent = 0.0
                    self.fullTrackDuration = "--:--"
                }
            })
            .store(in: &cancellables)
        
        DistributedNotificationCenter.default().publisher(for: .init(config.playbackChangedName))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .filter { $0 == "Playing" }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                System.logger.info("Received \(config.appName) track change")
                self.currentTrack = self.bridge?.currentTrack ?? .empty
            })
            .store(in: &cancellables)
        
        timer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
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
        
        let progress = (self.bridge?.playerPosition ?? 0) * 1000
        currentProgressPercent = progress / Double(duration)
        currentTrackProgress = Duration.milliseconds(progress).formatted(.time(pattern: .minuteSecond))
        fullTrackDuration = Duration.milliseconds(duration).formatted(.time(pattern: .minuteSecond))
    }
   
    func openApplication() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: config.bundleId) else { return }

        let path = "/bin"
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = [path]
        NSWorkspace.shared.openApplication(at: url,
                                           configuration: configuration,
                                           completionHandler: nil)
    }

    func nextTrack() {
        guard let bridge else {
            openApplication()
            return
        }
        bridge.nextTrack()
        
        System.logger.info("Next track")
    }
    
    func previousTrack() {
        guard let bridge else {
            openApplication()
            return
        }
        bridge.previousTrack()
        
        System.logger.info("Prev track")
    }
    
    func playPause() {
        guard let bridge else {
            openApplication()
            return
        }
        bridge.playPause()
        
        System.logger.info("Play/pause")
    }
}
