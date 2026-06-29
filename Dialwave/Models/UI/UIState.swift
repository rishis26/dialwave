import SwiftUI

/// Tab identifiers for the main menubar popover navigation.
enum AppTab: String, CaseIterable, Identifiable {
    case calls = "Calls"
    case contacts = "Contacts"
    case sms = "Messages"
    case settings = "Settings"

    var id: String { rawValue }

    /// SF Symbol icon name for each tab.
    var icon: String {
        switch self {
        case .calls: return "phone"
        case .contacts: return "person.2"
        case .sms: return "message"
        case .settings: return "gear"
        }
    }
}

/// Popover display size variants.
enum PopoverSize {
    case compact
    case expanded

    /// The popover dimensions for each size.
    var dimensions: CGSize {
        switch self {
        case .compact: return CGSize(width: 320, height: 400)
        case .expanded: return CGSize(width: 360, height: 500)
        }
    }
}

/// Tracks the state of the incoming call popup window.
struct CallPopupState {
    /// Whether the call popup is currently visible.
    var isVisible: Bool = false
    /// The name of the caller, if resolved from contacts.
    var callerName: String?
    /// The raw phone number of the caller.
    var callerNumber: String = ""
    /// Whether the call has been answered (affects button layout).
    var isAnswered: Bool = false
    /// Elapsed time since the call was answered, in seconds.
    var callDuration: TimeInterval = 0
}

/// Visual badge state for the menubar connection indicator.
enum ConnectionBadge: Equatable {
    /// Not connected — gray dot.
    case disconnected
    /// Searching or handshaking — yellow pulsing dot.
    case connecting
    /// Connected and idle — solid green dot.
    case connected
    /// Active call in progress — animated purple dot.
    case onCall

    /// The display color for the badge.
    var color: Color {
        switch self {
        case .disconnected: return .gray
        case .connecting: return .dialwaveOrange
        case .connected: return .dialwaveGreen
        case .onCall: return .dialwavePrimary
        }
    }

    /// Whether this badge should pulse-animate.
    var shouldAnimate: Bool {
        switch self {
        case .connecting, .onCall: return true
        case .disconnected, .connected: return false
        }
    }
}
