import Foundation

/// Repository for CRUD operations on the sms_messages database table.
///
/// Provides thread-grouped message queries for the SMS conversation UI.
final class SMSRepository: @unchecked Sendable {

    private let db: SQLiteDatabase

    /// Creates an SMS repository backed by the given database.
    /// - Parameter database: The SQLite database instance.
    init(database: SQLiteDatabase) {
        self.db = database
    }

    // MARK: - Read

    /// Fetches all SMS threads (conversations), sorted by most recent message.
    ///
    /// Groups messages by `thread_id` and returns a summary for each conversation.
    /// - Returns: An array of `SMSThread` instances.
    func fetchThreads() -> [SMSThread] {
        // Get distinct thread IDs with latest message info
        let threadRows = db.executeQuery("""
            SELECT thread_id, phone_number, contact_name,
                   MAX(timestamp) as last_timestamp,
                   SUM(CASE WHEN is_read = 0 AND is_incoming = 1 THEN 1 ELSE 0 END) as unread_count
            FROM sms_messages
            GROUP BY thread_id
            ORDER BY last_timestamp DESC
        """)

        return threadRows.compactMap { row -> SMSThread? in
            guard let threadId = row["thread_id"] as? String,
                  let phoneNumber = row["phone_number"] as? String,
                  let lastTimestamp = row["last_timestamp"] as? Double else { return nil }

            let messages = fetchMessages(forThread: threadId)
            let lastMessage = messages.last?.body ?? ""

            return SMSThread(
                threadId: threadId,
                contactName: row["contact_name"] as? String,
                phoneNumber: phoneNumber,
                lastMessage: lastMessage,
                lastTimestamp: Date(timeIntervalSince1970: lastTimestamp),
                unreadCount: (row["unread_count"] as? Int64).map { Int($0) } ?? 0,
                messages: messages
            )
        }
    }

    /// Fetches all messages in a specific thread, sorted chronologically.
    /// - Parameter threadId: The thread identifier.
    /// - Returns: An array of `SMSMessage` instances.
    func fetchMessages(forThread threadId: String) -> [SMSMessage] {
        let rows = db.executeQuery(
            "SELECT * FROM sms_messages WHERE thread_id = ? ORDER BY timestamp ASC",
            values: [threadId]
        )
        return rows.compactMap { rowToSMSMessage($0) }
    }

    /// Fetches all unread incoming messages.
    /// - Returns: Unread SMS messages.
    func fetchUnread() -> [SMSMessage] {
        let rows = db.executeQuery(
            "SELECT * FROM sms_messages WHERE is_read = 0 AND is_incoming = 1 ORDER BY timestamp DESC"
        )
        return rows.compactMap { rowToSMSMessage($0) }
    }

    // MARK: - Write

    /// Inserts or updates a single message.
    /// - Parameter message: The SMS message to upsert.
    func upsert(_ message: SMSMessage) {
        db.executeUpdate("""
            INSERT OR REPLACE INTO sms_messages (id, thread_id, contact_name, phone_number, body, timestamp, is_incoming, is_read)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, values: [
            message.id, message.threadId, message.contactName,
            message.phoneNumber, message.body,
            message.timestamp.timeIntervalSince1970,
            message.isIncoming, message.isRead
        ])
    }

    /// Marks all messages in a thread as read.
    /// - Parameter threadId: The thread identifier.
    func markThreadAsRead(_ threadId: String) {
        db.executeUpdate(
            "UPDATE sms_messages SET is_read = 1 WHERE thread_id = ? AND is_read = 0",
            values: [threadId]
        )
    }

    /// Deletes a single message.
    /// - Parameter id: The message identifier.
    func delete(id: String) {
        db.executeUpdate("DELETE FROM sms_messages WHERE id = ?", values: [id])
    }

    /// Deletes an entire thread and all its messages.
    /// - Parameter threadId: The thread identifier.
    func deleteThread(_ threadId: String) {
        db.executeUpdate("DELETE FROM sms_messages WHERE thread_id = ?", values: [threadId])
    }

    /// Returns the total count of unread incoming messages.
    func totalUnreadCount() -> Int {
        let rows = db.executeQuery(
            "SELECT COUNT(*) as count FROM sms_messages WHERE is_read = 0 AND is_incoming = 1"
        )
        return (rows.first?["count"] as? Int64).map { Int($0) } ?? 0
    }

    // MARK: - Mapping

    private func rowToSMSMessage(_ row: [String: Any]) -> SMSMessage? {
        guard let id = row["id"] as? String,
              let threadId = row["thread_id"] as? String,
              let phoneNumber = row["phone_number"] as? String,
              let body = row["body"] as? String,
              let timestamp = row["timestamp"] as? Double else { return nil }

        return SMSMessage(
            id: id,
            threadId: threadId,
            contactName: row["contact_name"] as? String,
            phoneNumber: phoneNumber,
            body: body,
            timestamp: Date(timeIntervalSince1970: timestamp),
            isIncoming: ((row["is_incoming"] as? Int64) ?? 1) == 1,
            isRead: ((row["is_read"] as? Int64) ?? 0) == 1
        )
    }
}
