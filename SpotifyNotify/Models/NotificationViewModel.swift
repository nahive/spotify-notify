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
    let artworkURL: URL?

    /// Defaults to show if, for any reason, Spotify returns nil
    private let unknownArtist = "Unknown Artist"
    private let unknownAlbum = "Unknown Album"
    private let unknownTrack = "Unknown Track"

    init(track: Track, showSongProgress: Bool, songProgress: Double?) {
        
        func progress(for track: Track) -> String {
            guard let songProgress = songProgress, let duration = track.duration else {
                    return "00:00/00:00"
            }

            let percentage = songProgress / (Double(duration) / 1000.0)

            let progressMax = 14
            let currentProgress = Int(Double(progressMax) * percentage)

            let progressString = "⁃".repeated(currentProgress) +  "-".repeated(progressMax - currentProgress)

            let now = Int(songProgress).minutesSeconds
            let length = (duration / 1000).minutesSeconds

            let nowS = "\(now.minutes)".withLeadingZeroes + ":" + "\(now.seconds)".withLeadingZeroes
            let lengthS = "\(length.minutes)".withLeadingZeroes + ":" + "\(length.seconds)".withLeadingZeroes

            return "\(nowS)  \(progressString)  \(lengthS)"
        }
        
        let name = track.name ?? unknownTrack
        let artist = track.artist ?? unknownArtist
        let album = track.album ?? unknownAlbum
 
        title = name
        subtitle = showSongProgress ? "\(artist) - \(album)" : artist
        body = showSongProgress ? progress(for: track) : album
        artworkURL = track.artworkURL
    }
}

private extension Int {
    var minutesSeconds: (minutes: Int, seconds: Int) {
        ((self % 3600) / 60, (self % 3600) % 60)
    }
}

private extension String {
    func repeated(_ count: Int) -> String {
        String(repeating: self, count: count)
    }
}
