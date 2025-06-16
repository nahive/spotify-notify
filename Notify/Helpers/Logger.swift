import Foundation
import os

enum LogLevel {
    case debug, info, warning, error
}

struct System {
    static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Notify", category: "main")
    
    static func log(_ message: String, level: LogLevel = .info) {
        switch level {
        case .debug: logger.debug("\(message)")
        case .info: logger.info("\(message)")
        case .warning: logger.warning("\(message)")
        case .error: logger.error("\(message)")
        }
    }
}
