import Foundation
import CoreBluetooth

/// Wraps the BLE discovery lifecycle with filtering and auto-timeout.
///
/// Runs a BLE scan for a configurable duration, collects discovered peripherals,
/// deduplicates by identifier, and reports results through a callback.
final class DeviceDiscovery {

    /// A discovered DialWave device with signal strength metadata.
    struct DiscoveredDevice: Identifiable, Sendable {
        /// The unique BLE peripheral identifier.
        let id: UUID
        /// The device name from the BLE advertisement.
        let name: String
        /// Signal strength at discovery time.
        let rssi: Int
        /// The underlying CoreBluetooth peripheral reference.
        let peripheral: CBPeripheral

        /// Whether the signal is strong enough for a reliable connection.
        var isStrongSignal: Bool { rssi > -70 }
    }

    // MARK: - Properties

    private let bluetoothManager: BluetoothManagerProtocol
    private var discoveredDevices: [UUID: DiscoveredDevice] = [:]
    private var scanTimer: Timer?
    private var onDeviceFound: ((DiscoveredDevice) -> Void)?
    private var onScanComplete: (([DiscoveredDevice]) -> Void)?

    /// Default scan duration in seconds.
    private let scanDuration: TimeInterval

    // MARK: - Init

    /// Creates a new discovery session.
    /// - Parameters:
    ///   - bluetoothManager: The Bluetooth manager to perform scanning.
    ///   - scanDuration: How long to scan before stopping. Default is 10 seconds.
    init(bluetoothManager: BluetoothManagerProtocol, scanDuration: TimeInterval = 10.0) {
        self.bluetoothManager = bluetoothManager
        self.scanDuration = scanDuration
    }

    // MARK: - Public API

    /// Begin a timed BLE scan for DialWave devices.
    /// - Parameters:
    ///   - onDeviceFound: Called each time a new unique device is discovered.
    ///   - onComplete: Called when the scan duration expires, with all discovered devices.
    func startDiscovery(onDeviceFound: @escaping (DiscoveredDevice) -> Void,
                        onComplete: @escaping ([DiscoveredDevice]) -> Void) {
        self.onDeviceFound = onDeviceFound
        self.onScanComplete = onComplete
        discoveredDevices.removeAll()

        bluetoothManager.startScanning()
        AppLogger.info("Device discovery started (duration: \(scanDuration)s)", category: .bluetooth)

        scanTimer = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { [weak self] _ in
            self?.finishDiscovery()
        }
    }

    /// Stop discovery immediately without waiting for the timer.
    func stopDiscovery() {
        finishDiscovery()
    }

    // MARK: - Internal

    /// Called by the Bluetooth delegate adapter when a peripheral is found.
    func handleDiscoveredPeripheral(_ peripheral: CBPeripheral, rssi: Int) {
        let device = DiscoveredDevice(
            id: peripheral.identifier,
            name: peripheral.name ?? "Unknown Device",
            rssi: rssi,
            peripheral: peripheral
        )

        guard discoveredDevices[device.id] == nil else { return }

        discoveredDevices[device.id] = device
        onDeviceFound?(device)
        AppLogger.debug("Discovered: \(device.name) (RSSI: \(device.rssi))", category: .bluetooth)
    }

    // MARK: - Private

    private func finishDiscovery() {
        scanTimer?.invalidate()
        scanTimer = nil
        bluetoothManager.stopScanning()

        let devices = Array(discoveredDevices.values).sorted { $0.rssi > $1.rssi }
        onScanComplete?(devices)
        AppLogger.info("Discovery complete — found \(devices.count) device(s)", category: .bluetooth)

        onDeviceFound = nil
        onScanComplete = nil
    }
}
