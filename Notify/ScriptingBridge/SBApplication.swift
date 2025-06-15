//
//  ApplicationBridgeProtocol.swift
//  Notify
//
//  Created by Szymon Maślanka on 2025/01/16.
//  Copyright © 2025 Szymon Maślanka. All rights reserved.
//

import ScriptingBridge

@objc protocol SBObjectProtocol: NSObjectProtocol {
    func get() -> Any!
}

@objc protocol SBApplicationProtocol: SBObjectProtocol {
    func activate()
    var delegate: (any SBApplicationDelegate)? { get set }
    var isRunning: Bool { @objc(isRunning) get }
}
