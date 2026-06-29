import Foundation

/// Defines operations for managing app settings and device pairing.
@MainActor
protocol SettingsServiceProtocol: AnyObject {
    
    /// The underlying preferences object for SwiftUI bindings.
    var preferences: UserPreferences { get }
    
    /// Initiate a scan for new Android devices.
    func startDeviceScan()
    
    /// Connect and pair with a discovered device.
    func pairWithDevice(_ device: DeviceDiscovery.DiscoveredDevice)
    
    /// Disconnect from the currently active device.
    func disconnectCurrentDevice()
    
    /// Clear all settings and pairing data.
    func resetToDefaults()
}
