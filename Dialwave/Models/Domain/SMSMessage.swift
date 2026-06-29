import Foundation

/// Represents a single SMS text message.
///
/// Received from Android via `SMS_RECEIVED` events or loaded from local SQLite storage.
struct SMSMessage: Codable, Identifiable, Sendable {
    /// Unique message identifier.
    let id: String
    /// Thread grouping identifier (matches Android's thread ID).
    let threadId: String
    /// Contact name associated with the number, if resolved.
    let contactName: String?
    /// The phone number of the sender or recipient.
    let phoneNumber: String
    /// The text content of the message.
    let body: String
    /// When the message was sent or received.
    let timestamp: Date
    /// `true` if this message was received from someone else.
    let isIncoming: Bool
    /// Whether the user has read this message.
    var isRead: Bool
}

/// A conversation thread grouping related SMS messages by phone number.
///
/// Computed from the local SMS database by grouping messages with the same `threadId`.
struct SMSThread: Identifiable, Sendable {
    /// The thread grouping identifier.
    let threadId: String
    /// Contact name for this thread, if resolved.
    let contactName: String?
    /// The phone number this thread is associated with.
    let phoneNumber: String
    /// Preview text of the most recent message in the thread.
    let lastMessage: String
    /// Timestamp of the most recent message.
    let lastTimestamp: Date
    /// Number of unread messages in this thread.
    let unreadCount: Int
    /// All messages in this thread, sorted chronologically.
    let messages: [SMSMessage]

    var id: String { threadId }

    /// Display name for the thread: contact name if available, otherwise formatted number.
    var displayName: String {
        contactName ?? phoneNumber.formatPhoneNumber()
    }

    /// Relative time label for the last message (e.g., "2m ago", "Yesterday").
    var lastTimestampLabel: String {
        let interval = Date().timeIntervalSince(lastTimestamp)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = Calendar.current.isDateInYesterday(lastTimestamp) ? "'Yesterday'" : "MMM d"
            return formatter.string(from: lastTimestamp)
        }
    }
}
