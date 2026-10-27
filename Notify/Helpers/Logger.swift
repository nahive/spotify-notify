import Foundation
import os

enum LogLevel: String, CaseIterable, Comparable, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
    
    private var rank: Int {
        switch self {
        case .debug: 0
        case .info: 1
        case .warning: 2
        case .error: 3
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

enum System {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "io.nahive.SpotifyNotify"
    private static let loggers = OSAllocatedUnfairLock<[String: Logger]>(initialState: [:])

    private static func logger(for category: String) -> Logger {
        loggers.withLock { cache in
            if let existing = cache[category] { return existing }
            let created = Logger(subsystem: subsystem, category: category)
            cache[category] = created
            return created
        }
    }

    static func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "main",
        file: String = #fileID,
        function: String = #function,
        line: Int = #line
    ) {
        let prefix = switch level {
        case .warning: "⚠️ "
        case .error: "❌ "
        default: ""
        }
        let contextMessage = "\(prefix)[\(file):\(line)] \(function) - \(message)"

        // No `privacy:` specifier on purpose: os.Logger redacts non-literal
        // interpolations in release builds, which is the right posture for a
        // listening-history app.
        logger(for: category).log(level: level.osLogType, "\(contextMessage)")

        #if DEBUG
        print("[\(level.rawValue)] \(contextMessage)")
        #endif
    }
}
