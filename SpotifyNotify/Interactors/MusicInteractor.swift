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
final class MusicInteractor: ObservableObject, AlertDisplayable {
    private var player: (any MusicPlayerProtocol)?
    
    @Published var permissionStatus: MusicPlayerPermissionStatus = .denied

    @Published var currentState: MusicPlayerState?
    @Published var currentTrack: MusicTrack?
    
    @Published var currentProgressPercent: Double = 0
    @Published var currentTrackProgress: String = "--:--"
    @Published var fullTrackDuration: String = "--:--"
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var isPlayerFrontmost: Bool {
        player?.isFrontmost ?? false
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func set(application: SupportedMusicApplication?) {
        unbind()
        
        self.player = application?.player
        
        if let player {
            bind(to: player)
        }
    }
    
    private func unbind() {
        currentState = nil
        currentTrack = nil
        
        cancellables.removeAll()
    }
    
    private func bind(to player: any MusicPlayerProtocol) {
        currentState = player.currentState
        currentTrack = player.currentTrack
        
        calculateProgress(player: player)
        
        DistributedNotificationCenter.default().publisher(for: .init(player.playbackChangedName))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                switch state {
                case "Paused", "Playing":
                    self.currentState = player.currentState
                    self.currentTrack = player.currentTrack
                default:
                    self.currentState = nil
                    self.currentTrack = nil
                    self.currentProgressPercent = 0.0
                    self.fullTrackDuration = "--:--"
                }
            })
            .store(in: &cancellables)
        
        DistributedNotificationCenter.default().publisher(for: .init(player.playbackChangedName))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .filter { $0 == "Playing" }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                self.currentTrack = player.currentTrack
            })
            .store(in: &cancellables)
        
        timer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, currentState == .playing else { return }
                self.calculateProgress(player: player)
        }.store(in: &cancellables)
        
        updateControlPermissions()
    }
    
    func updateControlPermissions() {
        permissionStatus = {
            guard let player, player.isOpen else {
                return .closed
            }
            guard player.hasPermissionToControl else {
                return .denied
            }
            return .granted
        }()
    }

    private func calculateProgress(player: any MusicPlayerProtocol) {
        guard let duration = currentTrack?.duration, duration != 0, let position = player.playerPosition else {
            currentProgressPercent = 0.0
            currentTrackProgress = "--:--"
            fullTrackDuration = "--:--"
            return
        }
    
        currentProgressPercent = position / Double(duration)
        currentTrackProgress = Duration.seconds(position).formatted(.time(pattern: .minuteSecond))
        fullTrackDuration = Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
    }

    func nextTrack() {
        guard canControlPlayer() else { return }
        player?.nextTrack()
    }
    
    func previousTrack() {
        guard canControlPlayer() else { return }
        player?.previousTrack()
    }
    
    func playPause() {
        guard canControlPlayer() else { return }
        player?.playPause()
    }
    
    private func canControlPlayer() -> Bool {
        guard let player else { return false }
        guard player.isOpen else {
            SystemNavigator.openApplication(bundleId: player.bundleId)
            return false
        }
        return true
    }
}

// MARK: app permissions
extension MusicInteractor {
    func registerForAutomation(for application: SupportedMusicApplication) {
        Task.detached {
            let targetAEDescriptor = NSAppleEventDescriptor(bundleIdentifier: application.bundleId)
            let status = AEDeterminePermissionToAutomateTarget(targetAEDescriptor.aeDesc, typeWildCard, typeWildCard, true)
            
            Task { @MainActor in
                switch status {
                case OSStatus(errAEEventNotPermitted):
                    self.showSettingsAlert(message: "Missing required automation permissions") {
                        SystemNavigator.openAutomationSettings()
                    }
                case OSStatus(procNotFound), _:
                    self.showSettingsAlert(message: "\(application.appName) is not running") {
                        SystemNavigator.openApplication(application)
                    }
                }
                
                self.updateControlPermissions()
            }
        }
    }
}
