import Foundation
import Observation
import ScriptingBridge
import AppKit
import UserNotifications

// MARK: - MusicInteractor
@MainActor
@Observable
final class MusicInteractor: AlertDisplayable {

    // MARK: - Dependencies
    @ObservationIgnored private let historyInteractor: HistoryInteractor

    // MARK: - Private Properties
    @ObservationIgnored private var player: (any MusicPlayerProtocol)?
    @ObservationIgnored var currentApplication: SupportedMusicApplication?
    @ObservationIgnored private var progressTask: Task<Void, Never>?
    @ObservationIgnored private var playbackObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var workspaceObservers: [any NSObjectProtocol] = []
    @ObservationIgnored private var historySaveTask: Task<Void, Never>?
    @ObservationIgnored private var lastScheduledHistoryId: String?

    // MARK: - Observable State
    var permissionStatus: MusicPlayerPermissionStatus = .denied
    var currentState: MusicPlayerState?
    var currentTrack: MusicTrack? {
        didSet { scheduleHistorySaveIfNeeded() }
    }
    var isPlayingRadio: Bool = false
    var currentProgressPercent: Double = 0
    var currentTrackProgress: String = "--:--"
    var fullTrackDuration: String = "--:--"

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

    func seek(to percentage: Double) {
        guard canControlPlayer() else { return }
        guard let duration = currentTrack?.duration else { return }

        let position = Double(duration) * percentage

        player?.seek(to: position)

        stopProgressUpdates()

        currentProgressPercent = percentage
        currentTrackProgress = Duration.seconds(position).formatted(.time(pattern: .minuteSecond))

        // Resume progress tracking after seek
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            startProgressUpdates()
        }
    }

    private func setupNotificationObservers() {
        let willSleep = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopProgressUpdates()
            }
        }

        let didWake = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                if let self, self.currentState == .playing {
                    self.startProgressUpdates()
                }
            }
        }

        workspaceObservers = [willSleep, didWake]
    }

    // Owned as a @State object on the App for the process lifetime, so nothing
    // calls this today; it exists so teardown is explicit and testable.
    func tearDown() {
        stopProgressUpdates()
        removePlaybackObserver()
        historySaveTask?.cancel()
        workspaceObservers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        workspaceObservers.removeAll()
    }

    private func unbind() {
        currentState = nil
        currentTrack = nil
        isPlayingRadio = false
        currentProgressPercent = 0.0
        currentTrackProgress = "--:--"
        fullTrackDuration = "--:--"

        stopProgressUpdates()
        removePlaybackObserver()
        historySaveTask?.cancel()
        lastScheduledHistoryId = nil
    }

    private func startProgressUpdates() {
        stopProgressUpdates()

        progressTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                guard let player = self.player, self.currentState == .playing else { continue }
                self.updateProgress(player: player)
            }
        }
    }

    private func stopProgressUpdates() {
        progressTask?.cancel()
        progressTask = nil
    }

    private func removePlaybackObserver() {
        if let playbackObserver {
            DistributedNotificationCenter.default().removeObserver(playbackObserver)
        }
        playbackObserver = nil
    }

    private func bind(to player: any MusicPlayerProtocol) {
        currentState = player.currentState
        isPlayingRadio = player.isPlayingRadio

        if isPlayingRadio {
            currentTrack = nil
        } else {
            currentTrack = MusicTrack.validated(from: player.currentTrack)
        }

        updateProgress(player: player)

        playbackObserver = DistributedNotificationCenter.default().addObserver(
            forName: .init(player.playbackChangedName),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let state = notification.userInfo?["Player State"] as? String else { return }
            Task { @MainActor in
                guard let self, let player = self.player else { return }
                self.handlePlaybackStateChange(state, player: player)
            }
        }

        startProgressUpdates()
        updateControlPermissions()
    }

    /// Debounced, deduplicated history save; replaces the old Combine pipeline
    /// on `$currentTrack`. Called from `currentTrack.didSet`.
    private func scheduleHistorySaveIfNeeded() {
        guard let track = currentTrack, track.id != lastScheduledHistoryId else { return }
        lastScheduledHistoryId = track.id

        historySaveTask?.cancel()
        historySaveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self, let app = self.currentApplication else { return }
            self.historyInteractor.saveSongIfNeeded(from: track, musicApp: app)
        }
    }

    private func handlePlaybackStateChange(_ state: String, player: any MusicPlayerProtocol) {
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
                startProgressUpdates()
            } else {
                stopProgressUpdates()
            }
        default:
            currentState = nil
            currentTrack = nil
            isPlayingRadio = false
            currentProgressPercent = 0.0
            fullTrackDuration = "--:--"
            stopProgressUpdates()
        }
    }

    private func updateProgress(player: any MusicPlayerProtocol) {
        guard let duration = currentTrack?.duration, duration != 0 else {
            currentProgressPercent = 0.0
            currentTrackProgress = "--:--"
            fullTrackDuration = "--:--"
            return
        }

        let position = player.playerPosition ?? 0

        currentProgressPercent = position / Double(duration)
        currentTrackProgress = Duration.seconds(position).formatted(.time(pattern: .minuteSecond))
        fullTrackDuration = Duration.seconds(duration).formatted(.time(pattern: .minuteSecond))
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

        Task {
            do {
                try await NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            } catch {
                System.log("Failed to open player app: \(error)", level: .warning)
            }
        }
    }

    func openAutomationSettings() {
        guard let url = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation".asURL else {
            System.log("Invalid automation settings URL", level: .error)
            return
        }
        NSWorkspace.shared.open(url)
    }
}
