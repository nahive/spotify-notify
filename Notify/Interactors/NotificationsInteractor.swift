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

    init(defaultsInteractor: DefaultsInteractor, musicInteractor: MusicInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.musicInteractor = musicInteractor

        super.init()

        UNUserNotificationCenter.current().delegate = self

        observeTrackChanges()
        updateNotificationsPermissions()
    }

    /// Notifies on every track publication after the initial value, mirroring
    /// the old `$currentTrack.dropFirst()` Combine pipeline.
    private func observeTrackChanges() {
        let musicInteractor = musicInteractor
        trackObservationTask = Task { [weak self] in
            var isFirst = true
            for await track in Observations({ musicInteractor.currentTrack }) {
                guard let self else { return }
                if isFirst {
                    isFirst = false
                    continue
                }
                self.showNotification(track)
            }
        }
    }

    // MARK: notification permissions
    func registerForNotifications() {
        Task {
            do {
                let _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            } catch {
                showSettingsAlert(message: "Missing notification permissions") {
                    openNotificationsSettings()
                }
            }
            
            let skip = UNNotificationAction(identifier: NotificationIdentifier.skip, title: "Skip")
            
            let category = UNNotificationCategory(identifier: NotificationIdentifier.category,
                                                  actions: [skip],
                                                  intentIdentifiers: [],
                                                  options: [])
            
            UNUserNotificationCenter.current().setNotificationCategories([category])
            
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
        showNotification(track)
    }
    
    private func showNotification(_ track: MusicTrack?) {
        guard
            let track,
            defaultsInteractor.areNotificationsEnabled,
            defaultsInteractor.shouldShowNotificationOnPlayPause,
            musicInteractor.currentState == .playing
        else {
            return
        }
        
        if defaultsInteractor.shouldDisableNotificationsOnFocus && musicInteractor.isPlayerFrontmost {
            return
        }

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
        notification.categoryIdentifier = NotificationIdentifier.category

        if defaultsInteractor.shouldPlayNotificationsSound {
            notification.sound = .default
        }
        
        Task {
            if defaultsInteractor.shouldShowAlbumArt, let artwork = track.artwork, let attachment = await createArtworkAttachment(artwork: artwork) {
                notification.attachments = [attachment]
            }
            deliverNotification(identifier: model.identifier, notification: notification)
        }
    }
    
    private func createArtworkAttachment(artwork: MusicArtwork) async -> UNNotificationAttachment? {
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
        
        return try? UNNotificationAttachment(identifier: "artwork", url: fileURL)
    }
    
    private func saveArtworkTemporarly(_ image: NSImage) -> URL? {
        guard let data = image.tiffRepresentation else { return nil }

        let bundleURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("io.nahive.notify.temp", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            let fileURL = bundleURL.appendingPathComponent("artwork" + ".png")

            try NSBitmapImageRep(data: data)?.representation(using: .png, properties: [:])?.write(to: fileURL)

            return fileURL
        } catch {
            System.log("Failed to save artwork to temp file: \(error)", level: .warning)
        }

        return nil
    }

    private func deliverNotification(identifier: String, notification: UNMutableNotificationContent) {
        UNUserNotificationCenter.current().add(.init(identifier: identifier, content: notification, trigger: nil))
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
        switch response.actionIdentifier {
        case NotificationIdentifier.skip:
            musicInteractor.nextTrack()
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
    var image: NSImage? {
        guard let data = try? Data(contentsOf: self) else { return nil }
        return NSImage(data: data)
    }
    
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
