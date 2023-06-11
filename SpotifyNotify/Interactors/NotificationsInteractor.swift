//
//  NotificationsInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/11.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
import Combine
import UserNotifications
import AppKit

final class NotificationsInteractor: ObservableObject {
    let defaultsInteractor: DefaultsInteractor = .init()
    let spotifyInteractor: SpotifyInteractor = .init()
    
    private var previousTrack: Track?
    private var currentTrack: Track?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        spotifyInteractor.$currentState
            .sink(receiveValue: { [weak self] _ in
                guard let self else { return }
                self.showNotification()
            })
            .store(in: &cancellables)
    }
    
    private func showNotification() {
        // return if notifications are disabled
        guard defaultsInteractor.areNotificationsEnabled else {
            print("⚠ notification disabled")
            return
        }
        
        // return if notifications are disabled when in focus
        if spotifyInteractor.isFrontmost, defaultsInteractor.shouldDisableNotificationsOnFocus {
            print("⚠ spotify is frontmost")
            return
        }
        
        previousTrack = currentTrack
        currentTrack  = spotifyInteractor.currentTrack
    
        // return if previous track is same as previous => play/pause and if it's disabled
        guard currentTrack != previousTrack || defaultsInteractor.shouldShowNotificationOnPlayPause else {
            print("⚠ spotify is changing from play/pause")
            return
        }
        
        guard spotifyInteractor.currentState == .playing else {
            print("⚠ spotify is not playing")
            return
        }

        // return if current track is nil
        guard let currentTrack = currentTrack else {
            print("⚠ spotify has no track available")
            return
        }

        // Create and deliver notifications
        createNotification(model: .init(track: currentTrack,
                                        showSongProgress: defaultsInteractor.shouldShowSongProgress,
                                        songProgress: spotifyInteractor.currentProgress))
    }
    
    private func createNotification(model: Notification) {
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
            deliverNotificationWithArtwork(notification: notification, model: model)
        } else {
            deliverNotification(identifier: model.identifier, notification: notification)
        }
    }
    
    private func deliverNotificationWithArtwork(notification: UNMutableNotificationContent, model: Notification) {
        guard let url = model.artworkURL else { return }

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

        // Remove delivered notifications
        notificationCenter.removeAllDeliveredNotifications()

        // Deliver current notification
        notificationCenter.add(request)

        // remove after userset number of seconds if not taken action
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(defaultsInteractor.notificationLength)) {
            notificationCenter.removeAllDeliveredNotifications()
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
