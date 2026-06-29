import Foundation
import CoreBluetooth

/// Manages BLE scanning, connection, and handshake with Android companion devices.
///
/// Scans for peripherals advertising the DialWave BLE service UUID.
/// Once connected, writes the Mac's local WiFi IP to a characteristic,
/// reads the Android device info response, then hands off to `ConnectionManager`
/// for WiFi TCP upgrade.
final class BluetoothManager: NSObject, BluetoothManagerProtocol {

    // MARK: - Constants

    /// The BLE service UUID advertised by the Android companion app.
    static let serviceUUID = CBUUID(string: "D1A1WAVE-0001-1000-8000-00805F9B34FB")
    /// Characteristic for writing the Mac's local IP during handshake.
    static let writeCharUUID = CBUUID(string: "D1A1WAVE-0002-1000-8000-00805F9B34FB")
    /// Characteristic for reading the Android's device info response.
    static let readCharUUID = CBUUID(string: "D1A1WAVE-0003-1000-8000-00805F9B34FB")

    // MARK: - Properties

    weak var delegate: BluetoothManagerDelegate?

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var readCharacteristic: CBCharacteristic?

    // MARK: - Init

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue(label: "com.dialwave.bluetooth", qos: .userInitiated))
        AppLogger.debug("BluetoothManager initialized", category: .bluetooth)
    }

    // MARK: - BluetoothManagerProtocol

    func startScanning() {
        guard centralManager.state == .poweredOn else {
            AppLogger.warning("Cannot scan — Bluetooth not powered on (state: \(centralManager.state.rawValue))", category: .bluetooth)
            return
        }

        centralManager.scanForPeripherals(
            withServices: [Self.serviceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        AppLogger.info("Started scanning for DialWave devices", category: .bluetooth)
    }

    func stopScanning() {
        centralManager.stopScan()
        AppLogger.info("Stopped BLE scanning", category: .bluetooth)
    }

    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        AppLogger.info("Connecting to peripheral: \(peripheral.name ?? "Unknown")", category: .bluetooth)
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            AppLogger.info("Disconnecting from peripheral: \(peripheral.name ?? "Unknown")", category: .bluetooth)
        }
        connectedPeripheral = nil
        writeCharacteristic = nil
        readCharacteristic = nil
    }

    func sendHandshake(localIP: String) {
        guard let characteristic = writeCharacteristic,
              let peripheral = connectedPeripheral,
              let data = localIP.data(using: .utf8) else {
            AppLogger.error("Cannot send handshake — missing characteristic or peripheral", category: .bluetooth)
            return
        }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        AppLogger.info("Sent handshake with local IP: \(localIP)", category: .bluetooth)
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            AppLogger.info("Bluetooth powered on", category: .bluetooth)
        case .poweredOff:
            AppLogger.warning("Bluetooth powered off", category: .bluetooth)
            delegate?.didDisconnect()
        case .unauthorized:
            AppLogger.error("Bluetooth unauthorized — check System Settings > Privacy > Bluetooth", category: .bluetooth)
        case .unsupported:
            AppLogger.error("Bluetooth not supported on this Mac", category: .bluetooth)
        default:
            AppLogger.debug("Bluetooth state: \(central.state.rawValue)", category: .bluetooth)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        AppLogger.info("Discovered device: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))", category: .bluetooth)
        delegate?.didDiscoverDevice(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        AppLogger.info("Connected to peripheral: \(peripheral.name ?? "Unknown")", category: .bluetooth)
        peripheral.discoverServices([Self.serviceUUID])
        delegate?.didConnect(peripheral)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        AppLogger.error("Failed to connect: \(errorMessage)", category: .bluetooth)
        delegate?.didFailWithError(error ?? NSError(domain: "com.dialwave.bluetooth", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        AppLogger.info("Disconnected from peripheral: \(peripheral.name ?? "Unknown")", category: .bluetooth)
        connectedPeripheral = nil
        writeCharacteristic = nil
        readCharacteristic = nil
        delegate?.didDisconnect()
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            AppLogger.error("Service discovery failed: \(error.localizedDescription)", category: .bluetooth)
            delegate?.didFailWithError(error)
            return
        }

        guard let service = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
            AppLogger.error("DialWave service not found on peripheral", category: .bluetooth)
            return
        }

        peripheral.discoverCharacteristics([Self.writeCharUUID, Self.readCharUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error {
            AppLogger.error("Characteristic discovery failed: \(error.localizedDescription)", category: .bluetooth)
            delegate?.didFailWithError(error)
            return
        }

        for characteristic in service.characteristics ?? [] {
            switch characteristic.uuid {
            case Self.writeCharUUID:
                writeCharacteristic = characteristic
                AppLogger.debug("Found write characteristic", category: .bluetooth)
            case Self.readCharUUID:
                readCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                AppLogger.debug("Found read characteristic — subscribed to notifications", category: .bluetooth)
            default:
                break
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            AppLogger.error("Characteristic update failed: \(error.localizedDescription)", category: .bluetooth)
            return
        }

        guard characteristic.uuid == Self.readCharUUID,
              let data = characteristic.value else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            let deviceInfo = try decoder.decode(DeviceInfo.self, from: data)
            AppLogger.info("Received handshake response from: \(deviceInfo.name)", category: .bluetooth)
            delegate?.didReceiveHandshakeResponse(deviceInfo: deviceInfo)
        } catch {
            AppLogger.error("Failed to decode handshake response: \(error.localizedDescription)", category: .bluetooth)
            delegate?.didFailWithError(error)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            AppLogger.error("Write to characteristic failed: \(error.localizedDescription)", category: .bluetooth)
            delegate?.didFailWithError(error)
        } else {
            AppLogger.debug("Handshake data written successfully", category: .bluetooth)
        }
    }
}
