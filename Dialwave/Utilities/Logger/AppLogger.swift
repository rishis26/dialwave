import os

/// Centralized logging utility for DialWave using Apple's unified logging system.
///
/// All logs are routed through `os.Logger` with subsystem `com.dialwave.app`,
/// making them visible in Console.app and filterable by category.
///
/// Usage:
/// ```swift
/// AppLogger.info("Connected to device", category: .bluetooth)
/// AppLogger.error("Socket dropped unexpectedly", category: .network)
/// ```
enum AppLogger {

    // MARK: - Categories

    /// Log categories for filtering in Console.app.
    enum Category: String {
        case general
        case bluetooth
        case network
        case audio
        case calls
        case sms
        case contacts
        case ui
        case storage
    }

    // MARK: - Private

    private static let subsystem = "com.dialwave.app"

    private static func logger(for category: Category) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    // MARK: - Public API

    /// Log a debug-level message. Visible only during debugging.
    /// - Parameters:
    ///   - message: The log message.
    ///   - category: The log category for filtering. Defaults to `.general`.
    static func debug(_ message: String, category: Category = .general) {
        logger(for: category).debug("[\(category.rawValue.uppercased())] \(message)")
    }

    /// Log an informational message. Standard operational events.
    /// - Parameters:
    ///   - message: The log message.
    ///   - category: The log category for filtering. Defaults to `.general`.
    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("[\(category.rawValue.uppercased())] \(message)")
    }

    /// Log a warning. Non-critical issues that may need attention.
    /// - Parameters:
    ///   - message: The log message.
    ///   - category: The log category for filtering. Defaults to `.general`.
    static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("[\(category.rawValue.uppercased())] \(message)")
    }

    /// Log an error. Critical failures requiring investigation.
    /// - Parameters:
    ///   - message: The log message.
    ///   - category: The log category for filtering. Defaults to `.general`.
    static func error(_ message: String, category: Category = .general) {
        logger(for: category).error("[\(category.rawValue.uppercased())] \(message)")
    }
}
