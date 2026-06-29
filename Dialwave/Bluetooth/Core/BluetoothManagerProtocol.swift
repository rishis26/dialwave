import Foundation
import CoreBluetooth

/// Defines the contract for Bluetooth discovery and handshake operations.
///
/// The Mac scans for Android devices advertising the DialWave BLE service,
/// connects, exchanges WiFi IP addresses, then upgrades to a TCP socket.
protocol BluetoothManagerProtocol: AnyObject {
    /// Begin scanning for nearby DialWave-compatible devices.
    func startScanning()
    /// Stop the active BLE scan.
    func stopScanning()
    /// Initiate a BLE connection to the specified peripheral.
    /// - Parameter peripheral: The discovered CBPeripheral to connect to.
    func connect(to peripheral: CBPeripheral)
    /// Disconnect from the currently connected peripheral.
    func disconnect()
    /// Send the handshake payload containing the Mac's local WiFi IP.
    /// - Parameter localIP: The Mac's local IPv4 address for WiFi upgrade.
    func sendHandshake(localIP: String)

    /// The delegate receiving Bluetooth lifecycle callbacks.
    var delegate: BluetoothManagerDelegate? { get set }
}

/// Callbacks for Bluetooth discovery, connection, and handshake events.
protocol BluetoothManagerDelegate: AnyObject {
    /// Called when a new DialWave device is discovered during scanning.
    /// - Parameter peripheral: The discovered BLE peripheral.
    func didDiscoverDevice(_ peripheral: CBPeripheral)
    /// Called when a BLE connection is established.
    /// - Parameter peripheral: The connected peripheral.
    func didConnect(_ peripheral: CBPeripheral)
    /// Called when the handshake response is received with Android's device info.
    /// - Parameter deviceInfo: The paired Android device's identity.
    func didReceiveHandshakeResponse(deviceInfo: DeviceInfo)
    /// Called when the BLE connection is lost.
    func didDisconnect()
    /// Called when a Bluetooth operation fails.
    /// - Parameter error: The error that occurred.
    func didFailWithError(_ error: Error)
}
