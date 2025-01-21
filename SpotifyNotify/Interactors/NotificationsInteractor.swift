//
//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
import Combine
@preconcurrency import UserNotifications
import AppKit

@MainActor
final class NotificationsInteractor: NSObject, ObservableObject, AlertDisplayable {
    private let defaultsInteractor: DefaultsInteractor
    private let musicInteractor: MusicInteractor
    
    @Published var areNotificationsEnabled: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(defaultsInteractor: DefaultsInteractor, musicInteractor: MusicInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.musicInteractor = musicInteractor
        
        super.init()
        
        UNUserNotificationCenter.current().delegate = self
        
        musicInteractor.$currentTrack
            .dropFirst()
            .sink(receiveValue: { [weak self] in
                guard let self else { return }
                self.showNotification($0)
            })
            .store(in: &cancellables)
        
        updateNotificationsPermissions()
    }

    // MARK: notification permissions
    func registerForNotifications() async {
        do {
            let _ = try await UNUserNotificationCenter.current().requestAuthorization()
        } catch {
            showSettingsAlert(message: "Missing notification permissions") {
                SystemNavigator.openNotificationsSettings()
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

        let model = MusicNotification(track: track, style: .simple)
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
        let image: NSImage? = await {
            switch artwork {
            case .url(let url):
                return await url.asyncImage
            case .image(let image):
                return image
            }
        }()
        
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
            print("couldn't save file")
        }

        return nil
    }

    private func deliverNotification(identifier: String, notification: UNMutableNotificationContent) {
        UNUserNotificationCenter.current().add(.init(identifier: identifier, content: notification, trigger: nil))

        if !defaultsInteractor.shouldKeepNotificationsOnScreen {
            Task { @MainActor in
                try await Task.sleep(for: .seconds(defaultsInteractor.notificationLength))
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
        }
    }
}

// MARK: notification delegate
extension NotificationsInteractor: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case NotificationIdentifier.skip:
            musicInteractor.nextTrack()
        default:
            guard let application = defaultsInteractor.selectedApplication else { return }
            SystemNavigator.openApplication(application)
        }
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
            try? await URLSession.shared.data(from: self).0.asNSImage
        }
    }
}
        
private extension Data {
    var asNSImage: NSImage? {
        NSImage(data: self)
    }
}
                
// TODO: fix this
extension NSImage: @unchecked @retroactive Sendable {}
