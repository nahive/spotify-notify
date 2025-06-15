//
//  MusicInteractor.swift
//  Notify
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
    private let historyInteractor: HistoryInteractor
    
    private var player: (any MusicPlayerProtocol)?
    var currentApplication: SupportedMusicApplication?
    private var lastSavedTrackId: String?
    
    // Track saving
    private var currentSavedTrack: MusicTrack?
    
    @Published var permissionStatus: MusicPlayerPermissionStatus = .denied

    @Published var currentState: MusicPlayerState?
    @Published var currentTrack: MusicTrack?
    @Published var isPlayingRadio: Bool = false
    
    @Published var currentProgressPercent: Double = 0
    @Published var currentTrackProgress: String = "--:--"
    @Published var fullTrackDuration: String = "--:--"
    
    private var progressTimer: Timer?
    
    var isPlayerFrontmost: Bool {
        player?.isFrontmost ?? false
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(historyInteractor: HistoryInteractor) {
        self.historyInteractor = historyInteractor
    }
    
    func set(application: SupportedMusicApplication?) {
        unbind()
        
        self.currentApplication = application
        self.player = application?.player
        
        if let player {
            bind(to: player)
        }
    }
    
    private func unbind() {
        currentState = nil
        currentTrack = nil
        isPlayingRadio = false
        currentProgressPercent = 0.0
        currentTrackProgress = "--:--"
        fullTrackDuration = "--:--"
        lastSavedTrackId = nil
        currentSavedTrack = nil
        
        stopProgressTimer()
        cancellables.removeAll()
    }
    
    private func startProgressTimer(for player: any MusicPlayerProtocol) {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.currentState == .playing else { return }
                self.calculateProgress(player: player)
            }
        }
    }
    
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    private func bind(to player: any MusicPlayerProtocol) {
        currentState = player.currentState
        isPlayingRadio = player.isPlayingRadio
        
        // Only validate track if not playing radio
        if isPlayingRadio {
            currentTrack = nil
        } else {
            currentTrack = MusicTrack.validated(from: player.currentTrack)
        }
        
        calculateProgress(player: player)
        
        DistributedNotificationCenter.default().publisher(for: .init(player.playbackChangedName))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let self else { return }
                switch state {
                case "Paused", "Playing":
                    self.currentState = player.currentState
                    self.isPlayingRadio = player.isPlayingRadio
                    
                    // Only validate track if not playing radio
                    if self.isPlayingRadio {
                        self.currentTrack = nil
                    } else {
                        self.currentTrack = MusicTrack.validated(from: player.currentTrack)
                    }
                default:
                    self.currentState = nil
                    self.currentTrack = nil
                    self.isPlayingRadio = false
                    self.currentProgressPercent = 0.0
                    self.fullTrackDuration = "--:--"
                }
            })
            .store(in: &cancellables)
        
        // Track song changes for history
        $currentTrack
            .sink(receiveValue: { [weak self] track in
                guard let self, let track, let app = self.currentApplication else { return }
                
                // Only save if it's a different track and we haven't saved it yet
                if track.id != self.currentSavedTrack?.id && track.id != self.lastSavedTrackId {
                    self.historyInteractor.saveSong(from: track, musicApp: app)
                    self.currentSavedTrack = track
                    self.lastSavedTrackId = track.id
                }
            })
            .store(in: &cancellables)
        
        startProgressTimer(for: player)
        
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
            openApplication()
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
                    System.log("Automation permission denied for \(application.appName)", level: .warning)
                    self.showSettingsAlert(message: "Missing required automation permissions") {
                        self.openAutomationSettings()
                    }
                case OSStatus(procNotFound):
                    System.log("\(application.appName) not found or not running", level: .warning)
                    self.showSettingsAlert(message: "\(application.appName) is not running") {
                        self.openApplication()
                    }
                case let status:
                    System.log("Unexpected automation status: \(status) for \(application.appName)", level: .error)
                }
                
                self.updateControlPermissions()
            }
        }
    }
}

extension MusicInteractor {
    func openApplication() {
        guard let player else { return }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: player.bundleId) else { return }

        let path = "/bin"
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.arguments = [path]
        NSWorkspace.shared.openApplication(at: url, configuration: configuration, completionHandler: nil)
    }
    
    func openAutomationSettings() {
        NSWorkspace.shared.open("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation".asURL!)
    }
}
