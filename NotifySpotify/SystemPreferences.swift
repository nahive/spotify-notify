//
//  SystemPreferences.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Foundation

struct SystemPreferences {
	static var isContentImagePropertyAvailable: Bool {
		let version = ProcessInfo.processInfo.operatingSystemVersion
		return version.majorVersion == 10 && version.minorVersion >= 9
	}
}
