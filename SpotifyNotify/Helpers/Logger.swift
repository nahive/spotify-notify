//
//  Logger.swift
//  SpotifyNotify
//
//  Created by Szymon Maślanka on 2023/06/12.
//  Copyright © 2023 Szymon Maślanka. All rights reserved.
//

import Foundation
import os

enum LogLevel {
    case debug, info, warning, error
}

struct System {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "SpotifyNotify", category: "main")
    
    static func log(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: logger.debug("\(message)")
        case .info: logger.info("\(message)")
        case .warning: logger.warning("\(message)")
        case .error: logger.error("\(message)")
        }
    }
}
