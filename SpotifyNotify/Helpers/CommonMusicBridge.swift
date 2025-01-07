//
//  CommonMusicBridge.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2025/01/07.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import Foundation

protocol CommonMusicConfig {
    var appName: String { get }
    var bundleId: String { get }
    var playbackChangedName: String { get }
    
    var bridge: any CommonMusicPlayerBridge { get }
}

protocol CommonMusicPlayerBridge: SBApplicationProtocol {
    var currentTrack: Track { get }
    var currentState: MusicPlayerState { get }
    var playerPosition: Double { get }
    
    func nextTrack()
    func previousTrack()
    func playPause()
}

enum MusicPlayerState {
    case stopped, paused, playing, unknown
}
