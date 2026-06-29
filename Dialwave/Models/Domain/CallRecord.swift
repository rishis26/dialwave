import Foundation

/// Represents a single entry in the phone's call history.
///
/// Synced from Android's `CallLog.Calls` content provider and stored locally
/// in SQLite for browsing and callback functionality.
struct CallRecord: Codable, Identifiable, Sendable {
    /// Unique identifier for this call record.
    let id: String
    /// Contact name associated with the number, if resolved.
    let contactName: String?
    /// The phone number involved in the call.
    let phoneNumber: String
    /// Whether this was incoming, outgoing, or missed.
    let type: CallType
    /// Call duration in seconds (0 for missed/rejected calls).
    let duration: TimeInterval
    /// When the call occurred.
    let timestamp: Date
    /// Whether the user has seen this entry in the call log.
    var isRead: Bool

    /// Human-readable duration string (e.g., "2m 34s", "0s").
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        if totalSeconds <= 0 { return "0s" }

        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
        }
        return "\(seconds)s"
    }

    /// Relative timestamp string for the call log UI.
    ///
    /// Returns "Today 2:30 PM", "Yesterday 4:15 PM", or "Jun 15, 2:30 PM" for older dates.
    var formattedTimestamp: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        let timeString = formatter.string(from: timestamp)

        if calendar.isDateInToday(timestamp) {
            return "Today \(timeString)"
        } else if calendar.isDateInYesterday(timestamp) {
            return "Yesterday \(timeString)"
        } else {
            formatter.dateFormat = "MMM d"
            let dateString = formatter.string(from: timestamp)
            return "\(dateString), \(timeString)"
        }
    }
}

/// The direction and outcome of a phone call.
enum CallType: String, Codable, Sendable {
    /// An inbound call that was answered.
    case incoming
    /// An outbound call initiated by the user.
    case outgoing
    /// An inbound call that was not answered.
    case missed

    /// SF Symbol icon name for the call type.
    var iconName: String {
        switch self {
        case .incoming: return "phone.arrow.down.left"
        case .outgoing: return "phone.arrow.up.right"
        case .missed: return "phone.arrow.down.left"
        }
    }

    /// Display color for the call type indicator.
    var displayColor: String {
        switch self {
        case .incoming: return "green"
        case .outgoing: return "blue"
        case .missed: return "red"
        }
    }
}
