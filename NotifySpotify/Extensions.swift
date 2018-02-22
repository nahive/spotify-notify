//
//  Extensions.swift
//  SpotifyNotify
//
//  Created by 先生 on 22/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa

extension NSButton {
	var isSelected: Bool {
		get { return state.rawValue == 1 }
		set { state = NSControl.StateValue(rawValue: newValue ? 1 : 0) }
	}
}

extension String {
	var url: URL? { return URL(string: self) }
}
