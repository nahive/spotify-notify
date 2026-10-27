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
    @ObservationIgnored private var progressTask: Task<Void, Never>?
    @ObservationIgnored private var playbackObservers: [any NSObjectProtocol] = []
    @ObservationIgnored private var workspaceObservers: [any NSObjectProtocol] = []
    @ObservationIgnored private var historySaveTask: Task<Void, Never>?

    // MARK: - Observable State
    private(set) var selection: PlayerSelection = .automatic
    private(set) var currentApplication: SupportedMusicApplication?
    var permissionStatus: MusicPlayerPermissionStatus = .denied
    var currentState: MusicPlayerState?
    var currentTrack: MusicTrack? {
        didSet {
            isFavorited = currentTrack?.isLoved ?? false
            // Pause/resume re-reads the same track; only a new id is a new play.
            guard currentTrack?.id != oldValue?.id else { return }
            scheduleHistorySaveIfNeeded()
        }
    }
    var isPlayingRadio: Bool = false
    var currentProgressPercent: Double = 0
    var currentTrackProgress: String = "--:--"
    var fullTrackDuration: String = "--:--"

    // Playback options. The players post no notification when these change,
    // so they are re-read on bind and whenever the menu opens.
    private(set) var volume: Int = 50
    private(set) var isShuffling = false
    private(set) var repeatMode: RepeatMode = .off
    private(set) var supportedRepeatModes: [RepeatMode] = []
    private(set) var supportsFavorites = false
    private(set) var isFavorited = false

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
        setupPlaybackObservers()
        setupWorkspaceObservers()
    }

    // MARK: - Public Methods
    func set(selection: PlayerSelection) {
        self.selection = selection

        switch selection {
        case .fixed(let application):
            switchTo(application)
        case .automatic:
            switchTo(automaticApplication())
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

    // MARK: - Playback options

    func refreshPlaybackOptions() {
        guard let player, player.isOpen else { return }
        volume = player.volume ?? volume
        isShuffling = player.isShuffling ?? false
        repeatMode = player.repeatMode ?? .off
    }

    func setVolume(_ newVolume: Int) {
        let clamped = min(100, max(0, newVolume))
        // A slider drag fires far more often than the integer value changes;
        // only the changes are worth an Apple Event.
        guard clamped != volume, canControlPlayer() else { return }
        volume = clamped
        player?.setVolume(clamped)
    }

    func toggleShuffle() {
        guard canControlPlayer() else { return }
        isShuffling.toggle()
        player?.setShuffling(isShuffling)
    }

    func cycleRepeatMode() {
        guard canControlPlayer(), !supportedRepeatModes.isEmpty else { return }
        let index = supportedRepeatModes.firstIndex(of: repeatMode) ?? 0
        repeatMode = supportedRepeatModes[(index + 1) % supportedRepeatModes.count]
        player?.setRepeatMode(repeatMode)
    }

    func setFavorited(_ favorited: Bool) {
        guard supportsFavorites, currentTrack != nil, canControlPlayer() else { return }
        isFavorited = favorited
        player?.setCurrentTrackFavorited(favorited)
    }

    /// Plays a track from history in the app that originally played it.
    func play(trackId: String, in application: SupportedMusicApplication) {
        let target = application == currentApplication ? player : application.player
        guard let target, target.isOpen else {
            openApplication(application)
            return
        }

        if !target.play(trackId: trackId) {
            System.log("\(application.appName) could not find track \(trackId)", level: .warning)
            openApplication(application)
        }
    }

    // MARK: - Player selection

    private func switchTo(_ application: SupportedMusicApplication?) {
        unbind()

        currentApplication = application
        player = application?.player

        if let player {
            bind(to: player)
        }
    }

    /// The player that is playing, else the one already followed if it is
    /// running, else any running one; falls back to an installed one so the
    /// menu can still offer to open it.
    private func automaticApplication() -> SupportedMusicApplication? {
        let installed = SupportedMusicApplication.allCases.filter(\.isInstalled)
        let running = installed.filter(\.isRunning)

        if let playing = running.first(where: { $0 == currentApplication ? player?.currentState == .playing : $0.player.currentState == .playing }) {
            return playing
        }
        if let currentApplication, running.contains(currentApplication) {
            return currentApplication
        }
        return running.first ?? currentApplication ?? installed.first
    }

    // MARK: - Observers

    /// Every supported player is observed, not just the followed one, so
    /// automatic mode can switch to whichever starts playing.
    private func setupPlaybackObservers() {
        playbackObservers = SupportedMusicApplication.allCases.map { application in
            DistributedNotificationCenter.default().addObserver(
                forName: application.playbackChangedName,
                object: nil,
                queue: .main
            ) { [weak self] notification in
                guard let state = notification.userInfo?["Player State"] as? String else { return }
                Task { @MainActor in
                    self?.handlePlaybackNotification(from: application, state: state)
                }
            }
        }
    }

    private func setupWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter

        let willSleep = center.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.stopProgressUpdates()
            }
        }

        let didWake = center.addObserver(
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

        // The player posts no playback notification when it launches idle or
        // quits, so without these the menu keeps saying "isn't running" (or
        // keeps showing a stale track) until the next play.
        let didLaunch = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let bundleId = notification.runningApplicationBundleId
            Task { @MainActor in
                self?.handlePlayerLifecycle(bundleId: bundleId, isRunning: true)
            }
        }

        let didTerminate = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let bundleId = notification.runningApplicationBundleId
            Task { @MainActor in
                self?.handlePlayerLifecycle(bundleId: bundleId, isRunning: false)
            }
        }

        workspaceObservers = [willSleep, didWake, didLaunch, didTerminate]
    }

    private func handlePlaybackNotification(from application: SupportedMusicApplication, state: String) {
        guard application == currentApplication else {
            if selection == .automatic, state == "Playing" {
                switchTo(application)
            }
            return
        }

        guard let player else { return }
        handlePlaybackStateChange(state, player: player)
    }

    private func handlePlayerLifecycle(bundleId: String?, isRunning: Bool) {
        guard let application = SupportedMusicApplication.allCases.first(where: { $0.bundleId == bundleId }) else { return }

        if isRunning {
            // A just-launched app can't answer Apple Events yet; probing it now
            // would block the main thread for the full send timeout.
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }

                if application == self.currentApplication {
                    self.updateControlPermissions()
                } else if self.selection == .automatic, self.player?.isOpen != true {
                    self.switchTo(application)
                }
            }
            return
        }

        guard application == currentApplication else { return }

        clearPlayback()
        updateControlPermissions()

        if selection == .automatic,
           let other = SupportedMusicApplication.allCases.first(where: { $0 != application && $0.isRunning }) {
            switchTo(other)
        }
    }

    // MARK: - Binding

    private func unbind() {
        resetPlaybackState()

        stopProgressUpdates()
        historySaveTask?.cancel()
    }

    private func resetPlaybackState() {
        currentState = nil
        currentTrack = nil
        isPlayingRadio = false
        currentProgressPercent = 0
        currentTrackProgress = "--:--"
        fullTrackDuration = "--:--"
    }

    private func clearPlayback() {
        resetPlaybackState()
        stopProgressUpdates()
        UNUserNotificationCenter.current()
            .removeDeliveredNotifications(withIdentifiers: [NotificationIdentifier.nowPlaying])
    }

    /// Re-read the player's real position only every Nth tick; interpolate between.
    private static let progressResyncTicks = 5

    private func startProgressUpdates() {
        stopProgressUpdates()

        progressTask = Task { [weak self] in
            var tick = 0
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, let player = self.player, self.currentState == .playing else { return }
                if tick % Self.progressResyncTicks == 0 {
                    self.updateProgress(player: player)   // one Apple Event
                } else {
                    self.advanceProgressLocally(by: 1)    // no IPC
                }
                tick += 1
            }
        }
    }

    private func stopProgressUpdates() {
        progressTask?.cancel()
        progressTask = nil
    }

    private func bind(to player: any MusicPlayerProtocol) {
        supportedRepeatModes = player.supportedRepeatModes
        supportsFavorites = player.supportsFavorites

        // Never send Apple Events to a closed player: ScriptingBridge would
        // launch it.
        guard player.isOpen else {
            updateControlPermissions()
            return
        }

        readPlayback(from: player)
        refreshPlaybackOptions()

        if currentState == .playing {
            startProgressUpdates()
        }
        updateControlPermissions()
    }

    private func readPlayback(from player: any MusicPlayerProtocol) {
        currentState = player.currentState
        isPlayingRadio = player.isPlayingRadio

        if isPlayingRadio {
            currentTrack = nil
        } else {
            currentTrack = MusicTrack.validated(from: player.currentTrack)
        }

        // Synchronous so the track-change banner, built on a later turn,
        // reads this track's duration rather than the previous one's.
        updateProgress(player: player)
    }

    /// Debounced history save; replaces the old Combine pipeline on
    /// `$currentTrack`. Called from `currentTrack.didSet`. Deduplication of
    /// repeat plays lives in `HistoryInteractor.saveSongIfNeeded`.
    private func scheduleHistorySaveIfNeeded() {
        guard let track = currentTrack else { return }

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
            readPlayback(from: player)
            refreshPlaybackOptions()

            if currentState == .playing {
                startProgressUpdates()
            } else {
                stopProgressUpdates()
            }
        default:
            clearPlayback()
        }
        updateControlPermissions()
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

    private func advanceProgressLocally(by seconds: Double) {
        guard let duration = currentTrack?.duration, duration > 0 else { return }

        let position = min(Double(duration), currentPositionSeconds + seconds)
        currentProgressPercent = position / Double(duration)
        currentTrackProgress = Duration.seconds(position).formatted(.time(pattern: .minuteSecond))
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
                case OSStatus(noErr):
                    System.log("Automation permission granted for \(application.appName)", level: .info)
                case OSStatus(errAEEventNotPermitted):
                    System.log("Automation permission denied for \(application.appName)", level: .warning)
                    self.showSettingsAlert(message: "Missing required automation permissions") {
                        self.openAutomationSettings()
                    }
                case OSStatus(procNotFound):
                    System.log("\(application.appName) not found or not running", level: .warning)
                    self.showSettingsAlert(message: "\(application.appName) is not running") {
                        self.openApplication(application)
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
    /// Opens `application`, or the followed player when nil.
    func openApplication(_ application: SupportedMusicApplication? = nil) {
        guard let application = application ?? currentApplication else { return }
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: application.bundleId) else { return }

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

private extension Notification {
    var runningApplicationBundleId: String? {
        (userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.bundleIdentifier
    }
}

extension SupportedMusicApplication {
    var isRunning: Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleId && !$0.isTerminated }
    }
}
