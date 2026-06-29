import SwiftUI

/// Represents the lifecycle of the connection between Mac and the Android companion.
///
/// Drives the menubar icon state, popover status bar, and reconnection logic.
enum ConnectionState: Equatable, Sendable {
    /// No active connection or pairing attempt.
    case disconnected
    /// Bluetooth scanning for nearby DialWave devices.
    case scanning
    /// Attempting Bluetooth BLE connection to a discovered device.
    case bluetoothConnecting
    /// Bluetooth handshake complete, upgrading to WiFi TCP socket.
    case upgrading
    /// Fully connected and idle over WiFi.
    case connected(device: DeviceInfo)
    /// Connected with an active phone call in progress.
    case onCall(device: DeviceInfo, duration: TimeInterval)
    /// A connection error occurred.
    case error(message: String)

    // MARK: - Computed Properties

    /// Whether a usable data channel is currently open.
    var isConnected: Bool {
        switch self {
        case .connected, .onCall: return true
        default: return false
        }
    }

    /// The connected device info, if available.
    var device: DeviceInfo? {
        switch self {
        case .connected(let device), .onCall(let device, _): return device
        default: return nil
        }
    }

    /// Human-readable status text for the popover header.
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .scanning: return "Scanning…"
        case .bluetoothConnecting: return "Connecting…"
        case .upgrading: return "Upgrading to WiFi…"
        case .connected(let device): return "Connected to \(device.name)"
        case .onCall(let device, _): return "On call via \(device.name)"
        case .error(let message): return "Error: \(message)"
        }
    }

    /// SF Symbol name for the menubar status icon.
    var menubarIcon: String {
        switch self {
        case .disconnected, .error: return "phone.badge.xmark"
        case .scanning, .bluetoothConnecting, .upgrading: return "phone.badge.waveform"
        case .connected: return "phone.fill"
        case .onCall: return "phone.connection.fill"
        }
    }

    /// Tint color for the menubar icon.
    var tintColor: Color {
        switch self {
        case .disconnected: return .gray
        case .scanning, .bluetoothConnecting, .upgrading: return .dialwaveOrange
        case .connected: return .dialwaveGreen
        case .onCall: return .dialwavePrimary
        case .error: return .dialwaveRed
        }
    }

    /// The corresponding badge for the status indicator dot.
    var badge: ConnectionBadge {
        switch self {
        case .disconnected, .error: return .disconnected
        case .scanning, .bluetoothConnecting, .upgrading: return .connecting
        case .connected: return .connected
        case .onCall: return .onCall
        }
    }

    // MARK: - Equatable

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.scanning, .scanning),
             (.bluetoothConnecting, .bluetoothConnecting),
             (.upgrading, .upgrading):
            return true
        case (.connected(let a), .connected(let b)):
            return a == b
        case (.onCall(let a, let dA), .onCall(let b, let dB)):
            return a == b && dA == dB
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}
