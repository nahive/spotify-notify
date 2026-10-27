import Foundation
import Observation
@preconcurrency import UserNotifications
import AppKit

@MainActor
@Observable
final class NotificationsInteractor: NSObject, AlertDisplayable {
    @ObservationIgnored private let defaultsInteractor: DefaultsInteractor
    @ObservationIgnored private let musicInteractor: MusicInteractor

    var areNotificationsEnabled: Bool = false

    @ObservationIgnored private var trackObservationTask: Task<Void, Never>?
    @ObservationIgnored private var presentTask: Task<Void, Never>?

    init(defaultsInteractor: DefaultsInteractor, musicInteractor: MusicInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.musicInteractor = musicInteractor

        super.init()

        UNUserNotificationCenter.current().delegate = self

        // Must be unconditional: the old call site only ran on the
        // authorization-request path, so already-authorized users got banners
        // whose category matched nothing and never saw the Skip action.
        registerCategories()

        observeTrackChanges()
        updateNotificationsPermissions()
    }

    private struct PlaybackSnapshot: Equatable, Sendable {
        let trackId: String?
        let state: MusicPlayerState?
    }

    private enum Trigger {
        case trackChanged, playbackToggled
    }

    /// Keyed on track id and player state rather than the whole `MusicTrack`:
    /// re-reading the same track on pause/resume must not look like a track
    /// change, and the initial value at launch is skipped.
    private func observeTrackChanges() {
        let musicInteractor = musicInteractor
        trackObservationTask = Task { [weak self] in
            var previous: PlaybackSnapshot?
            for await snapshot in Observations({
                PlaybackSnapshot(trackId: musicInteractor.currentTrack?.id, state: musicInteractor.currentState)
            }) {
                guard let self else { return }
                defer { previous = snapshot }

                guard let last = previous, let track = musicInteractor.currentTrack else { continue }
                if snapshot.trackId != last.trackId {
                    self.showNotification(track, trigger: .trackChanged)
                } else if snapshot.state != last.state {
                    self.showNotification(track, trigger: .playbackToggled)
                }
            }
        }
    }

    // MARK: notification permissions
    private func registerCategories() {
        let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")
        let favorite = UNNotificationAction(identifier: NotificationIdentifier.favorite,
                                            title: "Favorite",
                                            icon: UNNotificationActionIcon(systemImageName: "star"))
        let unfavorite = UNNotificationAction(identifier: NotificationIdentifier.unfavorite,
                                              title: "Remove Favorite",
                                              icon: UNNotificationActionIcon(systemImageName: "star.slash"))

        func category(_ identifier: String, _ actions: [UNNotificationAction]) -> UNNotificationCategory {
            UNNotificationCategory(identifier: identifier, actions: actions, intentIdentifiers: [], options: [])
        }

        UNUserNotificationCenter.current().setNotificationCategories([
            category(NotificationIdentifier.category, [skip]),
            category(NotificationIdentifier.favoriteCategory, [skip, favorite]),
            category(NotificationIdentifier.unfavoriteCategory, [skip, unfavorite]),
        ])
    }

    func registerForNotifications() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
                if !granted {
                    showSettingsAlert(message: "Missing notification permissions") {
                        openNotificationsSettings()
                    }
                }
            } catch {
                showSettingsAlert(message: "Missing notification permissions") {
                    openNotificationsSettings()
                }
            }

            updateNotificationsPermissions()
        }
    }
    
    func updateNotificationsPermissions() {
        Task {
            areNotificationsEnabled = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .authorized
        }
    }
    
    // MARK: delivering notifications
    func forceShowNotification() {
        guard let track = musicInteractor.currentTrack else { return }
        present(track)   // explicit user action: bypass all gates
    }

    private func showNotification(_ track: MusicTrack, trigger: Trigger) {
        guard defaultsInteractor.areNotificationsEnabled else { return }

        switch trigger {
        case .trackChanged:
            guard musicInteractor.currentState == .playing else { return }
        case .playbackToggled:
            // The play/pause toggle only adds these; it must not gate track changes.
            guard defaultsInteractor.shouldShowNotificationOnPlayPause else { return }
        }

        if defaultsInteractor.shouldDisableNotificationsOnFocus && musicInteractor.isPlayerFrontmost {
            return
        }

        present(track)
    }

    private func present(_ track: MusicTrack) {
        let model = MusicNotification(
            track: track,
            style: defaultsInteractor.shouldShowSongProgress ?
                .progress(
                    currentTime: musicInteractor.currentTrackProgress,
                    totalTime: musicInteractor.fullTrackDuration,
                    percentage: musicInteractor.currentProgressPercent
                ) :
                .simple
        )
        let notification = UNMutableNotificationContent()

        notification.title = model.title
        if let subtitle = model.subtitle {
            notification.subtitle = subtitle
        }
        notification.body = model.body
        notification.categoryIdentifier = switch (musicInteractor.supportsFavorites, musicInteractor.isFavorited) {
        case (false, _): NotificationIdentifier.category
        case (true, false): NotificationIdentifier.favoriteCategory
        case (true, true): NotificationIdentifier.unfavoriteCategory
        }
        notification.userInfo = [NotificationIdentifier.trackIdKey: track.id]

        if defaultsInteractor.shouldPlayNotificationsSound {
            notification.sound = .default
        }

        // Chained rather than cancelled: a cancelled delivery would orphan its
        // temp artwork file. Banners coalesce anyway via the stable identifier.
        let previous = presentTask
        presentTask = Task { [weak self] in
            await previous?.value
            guard let self else { return }

            var temporaryFile: URL?
            if self.defaultsInteractor.shouldShowAlbumArt,
               let artwork = track.artwork,
               let (attachment, url) = await self.createArtworkAttachment(artwork: artwork) {
                notification.attachments = [attachment]
                temporaryFile = url
            }

            await self.deliverNotification(identifier: model.identifier, notification: notification)

            if let temporaryFile {
                try? FileManager.default.removeItem(at: temporaryFile)
            }
        }
    }
    
    private func createArtworkAttachment(artwork: MusicArtwork) async -> (attachment: UNNotificationAttachment, url: URL)? {
        let image: NSImage?

        switch artwork {
        case .url(let url):
            image = await url.asyncImage
        case .image(let nsImage):
            image = nsImage
        }

        guard let image, let fileURL = saveArtworkTemporarly(image) else {
            return nil
        }

        guard let attachment = try? UNNotificationAttachment(identifier: fileURL.lastPathComponent, url: fileURL) else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        return (attachment, fileURL)
    }

    private func saveArtworkTemporarly(_ image: NSImage) -> URL? {
        guard let data = image.tiffRepresentation else { return nil }

        let bundleURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("io.nahive.notify.temp", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            // Unique per delivery: a fixed name races when two tracks change in
            // quick succession and the second banner attaches a partial write.
            let fileURL = bundleURL.appendingPathComponent("\(UUID().uuidString).png")

            try NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:])?.write(to: fileURL)

            return fileURL
        } catch {
            System.log("Failed to save artwork to temp file: \(error)", level: .warning)
        }

        return nil
    }

    private func deliverNotification(identifier: String, notification: UNMutableNotificationContent) async {
        do {
            try await UNUserNotificationCenter.current().add(.init(identifier: identifier, content: notification, trigger: nil))
        } catch {
            System.log("Failed to deliver notification: \(error)", level: .warning)
        }
    }
}

// MARK: notification delegate
extension NotificationsInteractor: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        var options: UNNotificationPresentationOptions = [.banner]
        if defaultsInteractor.shouldPlayNotificationsSound {
            options.insert(.sound)
        }
        return options
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let trackId = response.notification.request.content.userInfo[NotificationIdentifier.trackIdKey] as? String
        let isCurrentTrack = trackId != nil && trackId == musicInteractor.currentTrack?.id

        switch response.actionIdentifier {
        case NotificationIdentifier.skip:
            musicInteractor.nextTrack()
        case NotificationIdentifier.favorite, NotificationIdentifier.unfavorite:
            guard isCurrentTrack else {
                System.log("Ignoring favorite action for a track that is no longer playing", level: .info)
                return
            }
            musicInteractor.setFavorited(response.actionIdentifier == NotificationIdentifier.favorite)
        default:
            musicInteractor.openApplication()
        }
    }
}

extension NotificationsInteractor {
    func openNotificationsSettings() {
        guard let url = "x-apple.systempreferences:com.apple.preference.notifications".asURL else {
            System.log("Invalid notification settings URL", level: .error)
            return
        }
        NSWorkspace.shared.open(url)
    }
}

// MARK: misc
private extension URL {
    var asyncImage: NSImage? {
        get async {
            do {
                let (data, _) = try await URLSession.shared.data(from: self)
                return data.asNSImage
            } catch {
                System.log("Failed to load image from URL: \(self), error: \(error)", level: .warning)
                return nil
            }
        }
    }
}
        
private extension Data {
    var asNSImage: NSImage? {
        NSImage(data: self)
    }
}
