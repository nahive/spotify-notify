//
//  SpotifyInteractor.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 27/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import AppKit
import ScriptingBridge

final class SpotifyInteractor {    
	private let spotify: SpotifyApplication? = SBApplication(bundleIdentifier: SpotifyConstants.bundleIdentifier)
	
	var isFrontmost: Bool { return spotify?.frontmost ?? false }
	
	var currentTrack: Track? { return spotify?.currentTrack?.track }
	var soundVolume: Int? { return spotify?.soundVolume }
	var playerState: SpotifyEPlS? { return spotify?.playerState }
	var playerPosition: Double? { return spotify?.playerPosition }
	
	func nextTrack() {
		spotify?.nextTrack?()
	}
	
	func previousTrack() {
		spotify?.previousTrack?()
	}
	
	func playPause() {
		spotify?.playpause?()
	}
	
	func play() {
		spotify?.play?()
	}
	
	func pause() {
		spotify?.pause?()
	}
}
