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
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .warning, .error]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

actor System {
    static let shared = System()
    private let logger: Logger
    private let subsystem: String
    
    private init() {
        self.subsystem = Bundle.main.bundleIdentifier ?? "com.nahive.notify"
        self.logger = Logger(subsystem: subsystem, category: "main")
    }
    
    static func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "main",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        Task {
            await shared.logMessage(
                message,
                level: level,
                category: category,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    private func logMessage(
        _ message: String,
        level: LogLevel,
        category: String,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let contextMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        let categoryLogger = Logger(subsystem: subsystem, category: category)
        
        switch level {
        case .debug:
            categoryLogger.log(level: level.osLogType, "\(contextMessage)")
        case .info:
            categoryLogger.log(level: level.osLogType, "\(contextMessage)")
        case .warning:
            categoryLogger.log(level: level.osLogType, "⚠️ \(contextMessage)")
        case .error:
            categoryLogger.log(level: level.osLogType, "❌ \(contextMessage)")
        }
        
        #if DEBUG
        print("[\(level.rawValue)] \(contextMessage)")
        #endif
    }
}

// MARK: - Convenience Extensions
extension System {
    static func debug(
        _ message: String,
        category: String = "main",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    static func info(
        _ message: String,
        category: String = "main",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    static func warning(
        _ message: String,
        category: String = "main",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    static func error(
        _ message: String,
        category: String = "main",
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
}
