import Foundation
import SQLite3

/// Thread-safe SQLite database wrapper using prepared statements.
///
/// Provides a low-level interface for executing queries, inserts, and updates.
/// All operations are serialized on a dedicated queue to prevent concurrency issues.
/// Uses Apple's built-in `SQLite3` framework — no external dependencies.
final class SQLiteDatabase: @unchecked Sendable {

    // MARK: - Properties

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.dialwave.sqlite", qos: .utility)

    /// The file URL where the database is stored.
    let databaseURL: URL

    // MARK: - Init / Deinit

    /// Opens or creates a SQLite database at the specified URL.
    /// - Parameter url: The file URL for the database.
    /// - Throws: If the database cannot be opened.
    init(url: URL) throws {
        self.databaseURL = url

        // Ensure the parent directory exists
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var dbPointer: OpaquePointer?
        let result = sqlite3_open_v2(
            url.path,
            &dbPointer,
            SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
            nil
        )

        guard result == SQLITE_OK, let dbPointer else {
            let errorMessage = dbPointer.map { String(cString: sqlite3_errmsg($0)) } ?? "Unknown error"
            throw DatabaseError.openFailed(errorMessage)
        }

        self.db = dbPointer

        // Enable WAL mode for better concurrent read performance
        execute("PRAGMA journal_mode=WAL")
        execute("PRAGMA foreign_keys=ON")

        AppLogger.info("Database opened at \(url.lastPathComponent)", category: .storage)
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    // MARK: - Execute

    /// Executes a SQL statement that does not return results.
    /// - Parameter sql: The SQL string to execute.
    @discardableResult
    func execute(_ sql: String) -> Bool {
        queue.sync {
            var errorMessage: UnsafeMutablePointer<CChar>?
            let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)

            if result != SQLITE_OK {
                let error = errorMessage.map { String(cString: $0) } ?? "Unknown error"
                sqlite3_free(errorMessage)
                AppLogger.error("SQL exec failed: \(error)\nSQL: \(sql)", category: .storage)
                return false
            }
            return true
        }
    }

    // MARK: - Prepared Statements

    /// Executes a parameterized INSERT/UPDATE/DELETE statement.
    /// - Parameters:
    ///   - sql: The SQL string with `?` placeholders.
    ///   - values: The values to bind to the placeholders.
    /// - Returns: `true` if the statement executed successfully.
    @discardableResult
    func executeUpdate(_ sql: String, values: [Any?]) -> Bool {
        queue.sync {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                AppLogger.error("Failed to prepare statement: \(lastErrorMessage())\nSQL: \(sql)", category: .storage)
                return false
            }

            defer { sqlite3_finalize(statement) }
            bindValues(values, to: statement)

            let result = sqlite3_step(statement)
            if result != SQLITE_DONE {
                AppLogger.error("Statement execution failed: \(lastErrorMessage())\nSQL: \(sql)", category: .storage)
                return false
            }
            return true
        }
    }

    /// Executes a parameterized SELECT query and returns results as dictionaries.
    /// - Parameters:
    ///   - sql: The SQL query with `?` placeholders.
    ///   - values: The values to bind to the placeholders.
    /// - Returns: An array of dictionaries, one per result row.
    func executeQuery(_ sql: String, values: [Any?] = []) -> [[String: Any]] {
        queue.sync {
            var statement: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
                AppLogger.error("Failed to prepare query: \(lastErrorMessage())\nSQL: \(sql)", category: .storage)
                return []
            }

            defer { sqlite3_finalize(statement) }
            bindValues(values, to: statement)

            var results: [[String: Any]] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: Any] = [:]
                let columnCount = sqlite3_column_count(statement)

                for i in 0..<columnCount {
                    let name = String(cString: sqlite3_column_name(statement, i))
                    let type = sqlite3_column_type(statement, i)

                    switch type {
                    case SQLITE_INTEGER:
                        row[name] = sqlite3_column_int64(statement, i)
                    case SQLITE_FLOAT:
                        row[name] = sqlite3_column_double(statement, i)
                    case SQLITE_TEXT:
                        if let cString = sqlite3_column_text(statement, i) {
                            row[name] = String(cString: cString)
                        }
                    case SQLITE_BLOB:
                        if let pointer = sqlite3_column_blob(statement, i) {
                            let length = sqlite3_column_bytes(statement, i)
                            row[name] = Data(bytes: pointer, count: Int(length))
                        }
                    case SQLITE_NULL:
                        break
                    default:
                        break
                    }
                }
                results.append(row)
            }
            return results
        }
    }

    /// Executes multiple statements inside a transaction.
    /// - Parameter block: A closure performing database operations. Return `false` to rollback.
    /// - Returns: `true` if the transaction was committed.
    @discardableResult
    func transaction(_ block: () -> Bool) -> Bool {
        execute("BEGIN TRANSACTION")
        if block() {
            execute("COMMIT")
            return true
        } else {
            execute("ROLLBACK")
            return false
        }
    }

    // MARK: - Helpers

    private func bindValues(_ values: [Any?], to statement: OpaquePointer?) {
        for (index, value) in values.enumerated() {
            let position = Int32(index + 1)

            switch value {
            case nil:
                sqlite3_bind_null(statement, position)
            case let intValue as Int:
                sqlite3_bind_int64(statement, position, Int64(intValue))
            case let int64Value as Int64:
                sqlite3_bind_int64(statement, position, int64Value)
            case let doubleValue as Double:
                sqlite3_bind_double(statement, position, doubleValue)
            case let stringValue as String:
                sqlite3_bind_text(statement, position, (stringValue as NSString).utf8String, -1, nil)
            case let dataValue as Data:
                dataValue.withUnsafeBytes { rawBuffer in
                    sqlite3_bind_blob(statement, position, rawBuffer.baseAddress, Int32(dataValue.count), nil)
                }
            case let boolValue as Bool:
                sqlite3_bind_int(statement, position, boolValue ? 1 : 0)
            default:
                let stringRep = "\(value!)"
                sqlite3_bind_text(statement, position, (stringRep as NSString).utf8String, -1, nil)
            }
        }
    }

    private func lastErrorMessage() -> String {
        db.map { String(cString: sqlite3_errmsg($0)) } ?? "No database connection"
    }
}

// MARK: - Errors

/// Database operation errors.
enum DatabaseError: Error, LocalizedError {
    case openFailed(String)
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .openFailed(let message): return "Database open failed: \(message)"
        case .queryFailed(let message): return "Query failed: \(message)"
        }
    }
}
