//
//  Notification.swift
//  SpotifyNotify
//
//  Created by Paul Williamson on 07/03/2019.
//  Copyright © 2019 Szymon Maślanka. All rights reserved.
//

import Foundation

/// A notification view model for setting up a notification
struct NotificationViewModel {
    let identifier = NSUUID().uuidString
    let title: String
    let subtitle: String
    let body: String
    let shouldShowArtwork: Bool
    let artworkURL: URL?
    let needsNotificationSound: Bool

    /// Defaults to show if, for any reason, Spotify returns nil
    private static let unknownArtist = "Unknown Artist"
    private static let unknownAlbum = "Unknown Album"
    private static let unknownTrack = "Unknown Track"

    init(track: Track) {
        let preferences = UserPreferences()
        // decide whether to add progress
        if preferences.showSongProgress {
            let artist = track.artist ?? NotificationViewModel.unknownArtist
            let album = track.album ?? NotificationViewModel.unknownAlbum
            let duration = NotificationViewModel.progress(for: track)

            title = track.name ?? NotificationViewModel.unknownTrack
            subtitle = "\(artist) - \(album)"
            body = duration
        } else {
            title = track.name ?? NotificationViewModel.unknownTrack
            subtitle = track.artist ?? NotificationViewModel.unknownArtist
            body = track.album ?? NotificationViewModel.unknownAlbum
        }

        shouldShowArtwork = SystemPreferences.isContentImagePropertyAvailable && preferences.showAlbumArt
        artworkURL = track.artworkURL
        needsNotificationSound = preferences.notificationsSound
    }

    private static func progress(for track: Track) -> String {
        guard
            let position = SpotifyInteractor().playerPosition,
            let duration = track.duration else {
                return "00:00/00:00"
        }

        let percentage = position / (Double(duration) / 1000.0)

        let progressDone = "▪︎"
        let progressNotDone = "⁃"
        let progressMax = 14
        let currentProgress = Int(Double(progressMax) * percentage)

        let progressString = String(repeating: progressDone, count: currentProgress) + String(repeating: progressNotDone, count: progressMax - currentProgress)

        let now = convert(seconds: Int(position))
        let length = convert(seconds: duration / 1000)

        let nowS = "\(now.minutes)".withLeadingZeroes + ":" + "\(now.seconds)".withLeadingZeroes
        let lengthS = "\(length.minutes)".withLeadingZeroes + ":" + "\(length.seconds)".withLeadingZeroes

        return "\(nowS)  \(progressString)  \(lengthS)"
    }

    private static func convert(seconds: Int) -> (minutes: Int, seconds: Int) {
        return ((seconds % 3600) / 60, (seconds % 3600) % 60)
    }
}
