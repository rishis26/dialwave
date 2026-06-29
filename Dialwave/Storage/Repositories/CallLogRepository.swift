import Foundation

/// Repository for CRUD operations on the call_log database table.
///
/// Provides query methods for the call history UI including filtered views
/// for missed, incoming, and outgoing calls.
final class CallLogRepository: @unchecked Sendable {

    private let db: SQLiteDatabase

    /// Creates a call log repository backed by the given database.
    /// - Parameter database: The SQLite database instance.
    init(database: SQLiteDatabase) {
        self.db = database
    }

    // MARK: - Read

    /// Fetches all call records, most recent first.
    /// - Parameter limit: Maximum number of records to return. Default is 100.
    /// - Returns: An array of `CallRecord` instances.
    func fetchAll(limit: Int = 100) -> [CallRecord] {
        let rows = db.executeQuery(
            "SELECT * FROM call_log ORDER BY timestamp DESC LIMIT ?",
            values: [limit]
        )
        return rows.compactMap { rowToCallRecord($0) }
    }

    /// Fetches call records filtered by call type.
    /// - Parameters:
    ///   - type: The call type to filter by.
    ///   - limit: Maximum number of records to return.
    /// - Returns: Matching call records.
    func fetchByType(_ type: CallType, limit: Int = 50) -> [CallRecord] {
        let rows = db.executeQuery(
            "SELECT * FROM call_log WHERE type = ? ORDER BY timestamp DESC LIMIT ?",
            values: [type.rawValue, limit]
        )
        return rows.compactMap { rowToCallRecord($0) }
    }

    /// Fetches unread (missed) calls.
    /// - Returns: Unread call records.
    func fetchUnread() -> [CallRecord] {
        let rows = db.executeQuery(
            "SELECT * FROM call_log WHERE is_read = 0 AND type = ? ORDER BY timestamp DESC",
            values: [CallType.missed.rawValue]
        )
        return rows.compactMap { rowToCallRecord($0) }
    }

    /// Fetches call records for a specific phone number.
    /// - Parameter phoneNumber: The phone number to filter by.
    /// - Returns: Matching call records.
    func fetchByPhoneNumber(_ phoneNumber: String) -> [CallRecord] {
        let digits = phoneNumber.filter { $0.isNumber }
        let rows = db.executeQuery(
            "SELECT * FROM call_log WHERE REPLACE(REPLACE(REPLACE(phone_number, '-', ''), '(', ''), ')', '') LIKE ? ORDER BY timestamp DESC",
            values: ["%\(digits)%"]
        )
        return rows.compactMap { rowToCallRecord($0) }
    }

    // MARK: - Write

    /// Inserts or updates a call record.
    /// - Parameter record: The call record to upsert.
    func upsert(_ record: CallRecord) {
        db.executeUpdate("""
            INSERT OR REPLACE INTO call_log (id, contact_name, phone_number, type, duration, timestamp, is_read)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, values: [
            record.id, record.contactName, record.phoneNumber,
            record.type.rawValue, record.duration,
            record.timestamp.timeIntervalSince1970,
            record.isRead
        ])
    }

    /// Inserts multiple call records in a single transaction.
    /// - Parameter records: The call records to insert.
    func insertBatch(_ records: [CallRecord]) {
        db.transaction {
            for record in records {
                upsert(record)
            }
            return true
        }
        AppLogger.info("Inserted \(records.count) call log records", category: .storage)
    }

    /// Marks a call record as read.
    /// - Parameter id: The call record identifier.
    func markAsRead(_ id: String) {
        db.executeUpdate("UPDATE call_log SET is_read = 1 WHERE id = ?", values: [id])
    }

    /// Marks all missed calls as read.
    func markAllAsRead() {
        db.execute("UPDATE call_log SET is_read = 1 WHERE is_read = 0")
    }

    /// Deletes a call record by ID.
    /// - Parameter id: The call record identifier.
    func delete(id: String) {
        db.executeUpdate("DELETE FROM call_log WHERE id = ?", values: [id])
    }

    /// Returns the count of unread missed calls.
    func unreadCount() -> Int {
        let rows = db.executeQuery(
            "SELECT COUNT(*) as count FROM call_log WHERE is_read = 0 AND type = ?",
            values: [CallType.missed.rawValue]
        )
        return (rows.first?["count"] as? Int64).map { Int($0) } ?? 0
    }

    // MARK: - Mapping

    private func rowToCallRecord(_ row: [String: Any]) -> CallRecord? {
        guard let id = row["id"] as? String,
              let phoneNumber = row["phone_number"] as? String,
              let typeRaw = row["type"] as? String,
              let type = CallType(rawValue: typeRaw),
              let timestamp = row["timestamp"] as? Double else { return nil }

        return CallRecord(
            id: id,
            contactName: row["contact_name"] as? String,
            phoneNumber: phoneNumber,
            type: type,
            duration: (row["duration"] as? Double) ?? 0,
            timestamp: Date(timeIntervalSince1970: timestamp),
            isRead: ((row["is_read"] as? Int64) ?? 0) == 1
        )
    }
}
