//
//  ShortcutsInterector.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 26/02/2018.
//  Copyright © 2018 Szymon Maślanka. All rights reserved.
//

import Cocoa
import Magnet
import KeyHolder

final class ShortcutsInteractor {
	func register(combo: KeyCombo) {
		let key = HotKey(identifier: "testKey", keyCombo: combo,
						 target: self,
						 action: #selector(shortcutKeyTapped))
		let result = HotKeyCenter.shared.register(with: key)
		
		print("registered key with result: \(result)")
	}
	
	func unregister() {
		HotKeyCenter.shared.unregisterAll()
	}
    
    @objc private func shortcutKeyTapped() {
        (NSApplication.shared.delegate as? AppDelegate)?.shortcutKeyTapped()
    }
}
