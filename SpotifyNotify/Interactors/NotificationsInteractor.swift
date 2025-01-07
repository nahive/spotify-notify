//
//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
@preconcurrency import Combine
@preconcurrency import UserNotifications
import AppKit

@MainActor
final class NotificationsInteractor: NSObject, ObservableObject {
    let defaultsInteractor: DefaultsInteractor
    let musicInteractor: MusicInteractor
    
    private var previousTrack: Track?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(defaultsInteractor: DefaultsInteractor, musicInteractor: MusicInteractor) {
        self.defaultsInteractor = defaultsInteractor
        self.musicInteractor = musicInteractor
        
        super.init()
        
        musicInteractor.$currentTrack
            .sink(receiveValue: { [weak self] in
                guard let self else { return }
                self.showNotification($0)
            })
            .store(in: &cancellables)
    }
    
    func forceShowNotification() {
        guard musicInteractor.currentTrack != .empty else { return }
        createNotification(model: .init(track: musicInteractor.currentTrack,
                                        showSongProgress: defaultsInteractor.shouldShowSongProgress,
                                        songProgress: musicInteractor.currentProgress))
    }
    
    func showNotification(_ track: Track) {
        System.logger.info("Starting notification flow")
        
        // return if current track is nil
        guard track != .empty else {
            System.logger.info("⚠ music has no track available")
            return
        }
        
        // return if notifications are disabled
        guard defaultsInteractor.areNotificationsEnabled else {
            System.logger.warning("⚠ notification disabled")
            return
        }
        
        // return if notifications are disabled when in focus
        if musicInteractor.isFrontmost, defaultsInteractor.shouldDisableNotificationsOnFocus {
            System.logger.info("⚠ music is frontmost")
            return
        }
    
        // return if previous track is same as previous => play/pause and if it's disabled
        guard track != previousTrack || defaultsInteractor.shouldShowNotificationOnPlayPause else {
            System.logger.info("⚠ music is changing from play/pause")
            return
        }
        
        guard musicInteractor.currentState == .playing else {
            System.logger.info("⚠ music is not playing")
            return
        }
        
        previousTrack = track

        // Create and deliver notifications
        createNotification(model: .init(track: track,
                                        showSongProgress: defaultsInteractor.shouldShowSongProgress,
                                        songProgress: musicInteractor.currentProgress))
    }
    
    private func createNotification(model: MusicNotification) {
        System.logger.info("Creating notification")
        
        let notification = UNMutableNotificationContent()

        notification.title = model.title
        notification.subtitle = model.subtitle
        notification.body = model.body
        notification.categoryIdentifier = NotificationIdentifier.category

        // decide whether to add sound
        if defaultsInteractor.shouldPlayNotificationsSound {
            notification.sound = .default
        }
        
        if defaultsInteractor.shouldShowAlbumArt {
            System.logger.info("Creating notification with artwork")
            deliverNotificationWithArtwork(notification: notification, model: model)
        } else {
            System.logger.info("Creating notification without artwork")
            DispatchQueue.main.async { [weak self] in
                self?.deliverNotification(identifier: model.identifier, notification: notification)
            }
        }
    }
    
    private func deliverNotificationWithArtwork(notification: UNMutableNotificationContent, model: MusicNotification) {
        guard let url = model.artworkURL else {
            System.logger.info("Creating notification with artwork failed, resolving to normal")
            DispatchQueue.main.async { [weak self] in
                self?.deliverNotification(identifier: model.identifier, notification: notification)
            }
            return
        }

        Task {
            var artwork = try await url.asyncImage
            
            if defaultsInteractor.shouldRoundAlbumArt {
                artwork = artwork.withCircularMask
            }
            
            guard let url = artwork.saveToTemporaryDirectory(withName: "artwork") else { return }
            
            do {
                let attachment = try UNNotificationAttachment(identifier: "artwork", url: url)
                notification.attachments = [attachment]
            } catch {
                print("Error creating attachment: " + error.localizedDescription)
            }

            DispatchQueue.main.async { [weak self] in
                self?.deliverNotification(identifier: model.identifier, notification: notification)
            }
        }

    }
    
    private func deliverNotification(identifier: String, notification: UNMutableNotificationContent) {
        // Create a request
        let request = UNNotificationRequest(identifier: identifier, content: notification, trigger: nil)

        let notificationCenter = UNUserNotificationCenter.current()

        // Deliver current notification
        notificationCenter.add(request)

        // remove after userset number of seconds if not taken action
        if !defaultsInteractor.shouldKeepNotificationsOnScreen {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(defaultsInteractor.notificationLength)) {
                notificationCenter.removeAllDeliveredNotifications()
            }
        }
    }
}

extension NotificationsInteractor: @preconcurrency UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Force notifications to be shown, even if the SpotifyNotify is in the foreground
        [.banner, .sound]
    }
    
    /// Handle the action buttons
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        switch response.actionIdentifier {
        case NotificationIdentifier.skip:
            musicInteractor.nextTrack()
        default:
            musicInteractor.openApplication()
        }
    }
}


enum ImageError: Error {
    case notAnImage
}

private extension URL {
    var image: NSImage? {
        guard let data = try? Data(contentsOf: self) else { return nil }
        return NSImage(data: data)
    }
    
    var asyncImage: NSImage {
        get async throws {
            let (data, _) = try await URLSession.shared.data(from: self)
            guard let image = NSImage(data: data) else {
                throw ImageError.notAnImage
            }
            return image
        }
    }
}

// TODO: fix this
extension NSImage: @unchecked @retroactive Sendable {}

private extension NSImage {
    enum Const {
        static let bundleId = "io.nahive.SpotifyNotify"
    }
    
    /// Save an NSImage to a temporary directory
    ///
    /// - Parameter name: The file name, to use
    /// - Returns: A URL if saving is successful, or nil if there was an error
    func saveToTemporaryDirectory(withName name: String) -> URL? {
        guard let data = tiffRepresentation else { return nil }

        let fileManager = FileManager.default
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let bundleURL = tempURL.appendingPathComponent(Const.bundleId, isDirectory: true)

        do {
            try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
            let fileURL = bundleURL.appendingPathComponent(name + ".png")

            try NSBitmapImageRep(data: data)?
                .representation(using: .png, properties: [:])?
                .write(to: fileURL)

            return fileURL
        } catch {
            print("Error: " + error.localizedDescription)
        }

        return nil
    }
    
    // Apply circular mask
    var withCircularMask: NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        let frame = NSRect(origin: .zero, size: size)
        NSBezierPath(ovalIn: frame).addClip()
        draw(at: .zero, from: frame, operation: .sourceOver, fraction: 1)

        image.unlockFocus()
        return image
    }
}
