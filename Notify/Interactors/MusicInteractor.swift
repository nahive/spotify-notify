import Foundation
import ScriptingBridge
import AppKit
import Combine
import UserNotifications

// MARK: - MusicInteractor
@MainActor
final class MusicInteractor: ObservableObject, AlertDisplayable {
    
    // MARK: - Dependencies
    private let historyInteractor: HistoryInteractor
    
    // MARK: - Private Properties
    private var player: (any MusicPlayerProtocol)?
    var currentApplication: SupportedMusicApplication?
    private var progressTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var permissionStatus: MusicPlayerPermissionStatus = .denied
    @Published var currentState: MusicPlayerState?
    @Published var currentTrack: MusicTrack?
    @Published var isPlayingRadio: Bool = false
    @Published var currentProgressPercent: Double = 0
    @Published var currentTrackProgress: String = "--:--"
    @Published var fullTrackDuration: String = "--:--"
    
    // MARK: - Computed Properties
    var isPlayerFrontmost: Bool {
        player?.isFrontmost ?? false
    }
    
    var currentPositionSeconds: Double {
        guard let duration = currentTrack?.duration else { return 0 }
        return currentProgressPercent * Double(duration)
    }
    
    // MARK: - Initialization
    init(historyInteractor: HistoryInteractor) {
        self.historyInteractor = historyInteractor
        setupNotificationObservers()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    func set(application: SupportedMusicApplication?) {
        unbind()
        
        self.currentApplication = application
        self.player = application?.player
        
        if let player {
            bind(to: player)
        }
    }
    
    func updateControlPermissions() {
        let newStatus: MusicPlayerPermissionStatus = {
            guard let player, player.isOpen else {
                return .closed
            }
            guard player.hasPermissionToControl else {
                return .denied
            }
            return .granted
        }()
        
        if permissionStatus != newStatus {
            permissionStatus = newStatus
        }
    }
    
    func nextTrack() {
        guard canControlPlayer() else { return }
        
        Task {
            let player = await MainActor.run { self.player }
            await performPlayerAction {
                player?.nextTrack()
            }
        }
    }
    
    func previousTrack() {
        guard canControlPlayer() else { return }
        
        Task {
            let player = await MainActor.run { self.player }
            await performPlayerAction {
                player?.previousTrack()
            }
        }
    }
    
    func playPause() {
        guard canControlPlayer() else { return }
        
        Task {
            let player = await MainActor.run { self.player }
            await performPlayerAction {
                player?.playPause()
            }
        }
    }
    
    func seek(to percentage: Double) {
        guard canControlPlayer() else { return }
        guard let duration = currentTrack?.duration else { return }
        
        let position = Double(duration) * percentage
        
        Task {
            let player = await MainActor.run { self.player }
            await performPlayerAction {
                player?.seek(to: position)
            }
            
            await stopProgressTimer()
            
            await MainActor.run {
                currentProgressPercent = percentage
                currentTrackProgress = Duration.seconds(position).formatted(.time(pattern: .minuteSecond))
            }
            
            // Resume progress tracking after seek
            try? await Task.sleep(for: .milliseconds(500))
            
            if let player = player {
                await startProgressTimer(for: player)
            }
        }
    }
    
    private func setupNotificationObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.stopProgressTimer()
            }
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if let self, let player = self.player, self.currentState == .playing {
                    await self.startProgressTimer(for: player)
                }
            }
        }
    }
    
    nonisolated private func cleanup() {
        Task { @MainActor in
            stopProgressTimer()
            cancellables.removeAll()
        }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    private func unbind() {
        currentState = nil
        currentTrack = nil
        isPlayingRadio = false
        currentProgressPercent = 0.0
        currentTrackProgress = "--:--"
        fullTrackDuration = "--:--"

        stopProgressTimer()
        cancellables.removeAll()
    }
    
    @MainActor
    private func startProgressTimer(for player: any MusicPlayerProtocol) {
        stopProgressTimer()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.currentState == .playing else { return }
                await self.updateProgress(player: player)
            }
        }
    }
    
    @MainActor
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
        
        Task {
            await updateProgress(player: player)
        }
        
        // Bind to playback changes
        DistributedNotificationCenter.default().publisher(for: .init(player.playbackChangedName))
            .compactMap { $0.userInfo?["Player State"] as? String }
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                
                Task { @MainActor in
                    await self.handlePlaybackStateChange(state, player: player)
                }
            }
            .store(in: &cancellables)
        
        // Save track history
        $currentTrack
            .compactMap { $0 }
            .removeDuplicates { $0.id == $1.id }
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] track in
                guard let self, let app = self.currentApplication else { return }
                
                Task {
                    await self.historyInteractor.saveSongIfNeeded(from: track, musicApp: app)
                }
            }
            .store(in: &cancellables)
        
        startProgressTimer(for: player)
        updateControlPermissions()
    }
    
    private func handlePlaybackStateChange(_ state: String, player: any MusicPlayerProtocol) async {
        switch state {
        case "Paused", "Playing":
            currentState = player.currentState
            isPlayingRadio = player.isPlayingRadio
            
            if isPlayingRadio {
                currentTrack = nil
            } else {
                currentTrack = MusicTrack.validated(from: player.currentTrack)
            }
            
            if currentState == .playing {
                startProgressTimer(for: player)
            } else {
                stopProgressTimer()
            }
        default:
            currentState = nil
            currentTrack = nil
            isPlayingRadio = false
            currentProgressPercent = 0.0
            fullTrackDuration = "--:--"
            stopProgressTimer()
        }
    }

    private func updateProgress(player: any MusicPlayerProtocol) async {
        guard let duration = currentTrack?.duration, duration != 0 else {
            await MainActor.run {
                currentProgressPercent = 0.0
                currentTrackProgress = "--:--"
                fullTrackDuration = "--:--"
            }
            return
        }
        
        let position = await withCheckedContinuation { continuation in
            // Perform potentially blocking operation off main thread
            Task.detached {
                let pos = player.playerPosition ?? 0
                continuation.resume(returning: pos)
            }
        }
        
        await MainActor.run {
            currentProgressPercent = position / Double(duration)
            currentTrackProgress = Duration.seconds(position).formatted(.time(pattern: .minuteSecond))
            fullTrackDuration = Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
        }
    }
    
    private func canControlPlayer() -> Bool {
        guard let player else { return false }
        guard player.isOpen else {
            openApplication()
            return false
        }
        return true
    }
    
    private func performPlayerAction(_ action: @escaping @Sendable () -> Void) async {
        await withCheckedContinuation { continuation in
            Task.detached {
                action()
                continuation.resume()
            }
        }
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
