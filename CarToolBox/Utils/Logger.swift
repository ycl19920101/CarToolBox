//
//  Logger.swift
//  CarToolBox
//
//  Created by Claude on 2026/3/12.
//

import Foundation

/// Log level for filtering output
enum LogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case none = 100  // Disable all logs

    var prefix: String {
        switch self {
        case .verbose: return "📝"
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .none: return ""
        }
    }

    var name: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        case .none: return ""
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Unified logger for the entire app
final class Logger {
    static let shared = Logger()

    /// Minimum log level to output (logs below this level will be filtered)
    var minimumLevel: LogLevel = {
        #if DEBUG
        return .debug
        #else
        return .warning
        #endif
    }()

    /// Whether to include file/line/function info
    var includeLocation: Bool = true

    /// Whether to include timestamp
    var includeTimestamp: Bool = true

    private init() {}

    // MARK: - Core Logging

    func log(
        _ level: LogLevel,
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLevel else { return }

        var output = ""

        // Timestamp
        if includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            output += "[\(formatter.string(from: Date()))] "
        }

        // Level
        output += "\(level.prefix) [\(level.name)] "

        // Location (simplified)
        if includeLocation {
            let fileName = (file as NSString).lastPathComponent
            output += "[\(fileName):\(line)] "
        }

        // Message
        output += message()

        print(output)
    }

    // MARK: - Convenience Methods

    func verbose(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.verbose, message(), file: file, function: function, line: line)
    }

    func debug(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.debug, message(), file: file, function: function, line: line)
    }

    func info(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.info, message(), file: file, function: function, line: line)
    }

    func warning(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.warning, message(), file: file, function: function, line: line)
    }

    func error(
        _ message: @autoclosure () -> String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(.error, message(), file: file, function: function, line: line)
    }

    // MARK: - Network Logging

    func logRequest(
        url: String,
        method: String,
        headers: [String: String]? = nil,
        body: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var output = "🚀 REQUEST: \(method) \(url)"
        if let headers = headers, !headers.isEmpty {
            output += "\n📋 Headers: \(headers)"
        }
        if let body = body {
            // Mask sensitive data
            let maskedBody = maskSensitiveData(body)
            output += "\n📦 Body: \(maskedBody)"
        }
        debug(output, file: file, function: function, line: line)
    }

    func logResponse(
        url: String,
        statusCode: Int,
        data: String? = nil,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var output = "📥 RESPONSE: \(statusCode) \(url)"
        if let error = error {
            output += "\n❌ Error: \(error.localizedDescription)"
            log(.error, output, file: file, function: function, line: line)
        } else {
            if let data = data {
                output += "\n📄 Data: \(data)"
            }
            debug(output, file: file, function: function, line: line)
        }
    }

    // MARK: - Separator

    func separator(
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        debug("========================================", file: file, function: function, line: line)
    }

    // MARK: - Private

    private func maskSensitiveData(_ text: String) -> String {
        var result = text
        // Mask passwords
        result = result.replacingOccurrences(
            of: "\"password\"\\s*:\\s*\"[^\"]*\"",
            with: "\"password\":\"***\"",
            options: .regularExpression
        )
        // Mask tokens
        result = result.replacingOccurrences(
            of: "\"(access_token|refresh_token|token)\"\\s*:\\s*\"[^\"]*\"",
            with: "\"$1\":\"***\"",
            options: .regularExpression
        )
        return result
    }
}

// MARK: - Global Logger Functions (for convenience)

func logVerbose(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.verbose(message(), file: file, function: function, line: line)
}

func logDebug(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.debug(message(), file: file, function: function, line: line)
}

func logInfo(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.info(message(), file: file, function: function, line: line)
}

func logWarning(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.warning(message(), file: file, function: function, line: line)
}

func logError(
    _ message: @autoclosure () -> String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
) {
    Logger.shared.error(message(), file: file, function: function, line: line)
}

// MARK: - Module-specific Logger Extensions

extension Logger {
    /// Auth module logger
    static let auth = ModuleLogger(module: "Auth")

    /// Community module logger
    static let community = ModuleLogger(module: "Community")

    /// Vehicle module logger
    static let vehicle = ModuleLogger(module: "Vehicle")

    /// General module logger
    static let general = ModuleLogger(module: "App")

    /// Notification module logger
    static let notification = ModuleLogger(module: "Notification")
}

// MARK: - Objective-C Bridge

/// Bridge class for Objective-C logging
@objc public class OCLogger: NSObject {
    @objc public static func debug(_ module: String, message: String) {
        Logger.shared.debug("[\(module)] \(message)")
    }

    @objc public static func info(_ module: String, message: String) {
        Logger.shared.info("[\(module)] \(message)")
    }

    @objc public static func warning(_ module: String, message: String) {
        Logger.shared.warning("[\(module)] \(message)")
    }

    @objc public static func error(_ module: String, message: String) {
        Logger.shared.error("[\(module)] \(message)")
    }

    @objc public static func separator(_ module: String) {
        Logger.shared.debug("[\(module)] ========================================")
    }

    @objc public static func logRequest(_ module: String, method: String, url: String, headers: [String: String]?, body: String?) {
        var output = "🚀 REQUEST: \(method) \(url)"
        if let headers = headers, !headers.isEmpty {
            output += "\n📋 Headers: \(headers)"
        }
        if let body = body {
            let maskedBody = maskSensitiveData(body)
            output += "\n📦 Body: \(maskedBody)"
        }
        Logger.shared.debug("[\(module)] \(output)")
    }

    @objc public static func logResponse(_ module: String, url: String, statusCode: Int, data: String?, errorMessage: String?) {
        var output = "📥 RESPONSE: \(statusCode) \(url)"
        if let errorMessage = errorMessage {
            output += "\n❌ Error: \(errorMessage)"
            Logger.shared.error("[\(module)] \(output)")
        } else {
            if let data = data {
                output += "\n📄 Data: \(data)"
            }
            Logger.shared.debug("[\(module)] \(output)")
        }
    }

    private static func maskSensitiveData(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(
            of: "\"password\"\\s*:\\s*\"[^\"]*\"",
            with: "\"password\":\"***\"",
            options: .regularExpression
        )
        result = result.replacingOccurrences(
            of: "\"(access_token|refresh_token|token)\"\\s*:\\s*\"[^\"]*\"",
            with: "\"$1\":\"***\"",
            options: .regularExpression
        )
        return result
    }
}

/// Module-specific logger wrapper
struct ModuleLogger {
    let module: String

    func verbose(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.verbose("[\(module)] \(message())", file: file, function: function, line: line)
    }

    func debug(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.debug("[\(module)] \(message())", file: file, function: function, line: line)
    }

    func info(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.info("[\(module)] \(message())", file: file, function: function, line: line)
    }

    func warning(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.warning("[\(module)] \(message())", file: file, function: function, line: line)
    }

    func error(_ message: @autoclosure () -> String, file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.error("[\(module)] \(message())", file: file, function: function, line: line)
    }

    func separator(file: String = #file, function: String = #function, line: Int = #line) {
        Logger.shared.debug("[\(module)] ========================================", file: file, function: function, line: line)
    }
}
