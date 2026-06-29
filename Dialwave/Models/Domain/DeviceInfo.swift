import Foundation

/// Represents a connected Android device's identity and capabilities.
///
/// Sent during the Bluetooth handshake and stored locally for reconnection.
struct DeviceInfo: Codable, Identifiable, Equatable, Sendable {
    /// Unique device identifier (UUID assigned during first pairing).
    let id: String
    /// User-visible device name (e.g., "Samsung Galaxy S23").
    let name: String
    /// Device model identifier (e.g., "SM-S911B").
    let model: String
    /// Android version string (e.g., "14").
    let androidVersion: String
    /// The device's local WiFi IPv4 address.
    let ipAddress: String
    /// The device's Bluetooth MAC address.
    let bluetoothAddress: String
    /// Timestamp of the last successful communication.
    var lastSeen: Date
    /// Current battery level percentage, if available.
    var batteryLevel: Int?
}
