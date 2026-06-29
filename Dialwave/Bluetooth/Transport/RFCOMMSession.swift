import Foundation
import IOBluetooth

/// Fallback RFCOMM serial port session for devices that cannot use WiFi.
///
/// Uses macOS IOBluetooth classic Bluetooth SPP (Serial Port Profile) as an
/// alternative data channel. This is significantly slower than WiFi sockets
/// and is only used when WiFi upgrade fails during handshake.
final class RFCOMMSession: NSObject {

    // MARK: - Constants

    /// The RFCOMM channel ID for the DialWave serial service.
    static let channelID: BluetoothRFCOMMChannelID = 3

    // MARK: - Properties

    private var rfcommChannel: IOBluetoothRFCOMMChannel?
    private var btDevice: IOBluetoothDevice?

    /// Whether the RFCOMM channel is currently open.
    private(set) var isConnected: Bool = false

    /// Callback invoked when data is received over RFCOMM.
    var onDataReceived: ((Data) -> Void)?
    /// Callback invoked when the channel closes.
    var onDisconnected: (() -> Void)?

    // MARK: - Connection

    /// Opens an RFCOMM channel to the device at the given Bluetooth address.
    /// - Parameter bluetoothAddress: The MAC address of the Android device.
    func connect(to bluetoothAddress: String) {
        guard let device = IOBluetoothDevice(addressString: bluetoothAddress) else {
            AppLogger.error("Invalid Bluetooth address: \(bluetoothAddress)", category: .bluetooth)
            return
        }

        self.btDevice = device

        var channel: IOBluetoothRFCOMMChannel?
        let result = device.openRFCOMMChannelSync(
            &channel,
            withChannelID: Self.channelID,
            delegate: self
        )

        if result == kIOReturnSuccess, let channel {
            self.rfcommChannel = channel
            isConnected = true
            AppLogger.info("RFCOMM channel opened to \(bluetoothAddress)", category: .bluetooth)
        } else {
            AppLogger.error("Failed to open RFCOMM channel (result: \(result))", category: .bluetooth)
        }
    }

    /// Sends raw data over the RFCOMM channel.
    /// - Parameter data: The data to transmit.
    func sendData(_ data: Data) {
        guard let channel = rfcommChannel, isConnected else {
            AppLogger.warning("Cannot send — RFCOMM not connected", category: .bluetooth)
            return
        }

        data.withUnsafeBytes { rawBuffer in
            guard let pointer = rawBuffer.baseAddress else { return }
            let mutablePointer = UnsafeMutableRawPointer(mutating: pointer)
            let result = channel.writeSync(mutablePointer, length: UInt16(data.count))
            if result != kIOReturnSuccess {
                AppLogger.error("RFCOMM write failed (result: \(result))", category: .bluetooth)
            }
        }
    }

    /// Closes the RFCOMM channel.
    func disconnect() {
        rfcommChannel?.closeChannel()
        rfcommChannel = nil
        isConnected = false
        btDevice = nil
        AppLogger.info("RFCOMM session disconnected", category: .bluetooth)
    }
}

// MARK: - IOBluetoothRFCOMMChannelDelegate

extension RFCOMMSession: IOBluetoothRFCOMMChannelDelegate {

    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!,
                           data dataPointer: UnsafeMutableRawPointer!,
                           length dataLength: Int) {
        guard let dataPointer else { return }
        let data = Data(bytes: dataPointer, count: dataLength)
        AppLogger.debug("RFCOMM received \(dataLength) bytes", category: .bluetooth)
        onDataReceived?(data)
    }

    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        isConnected = false
        self.rfcommChannel = nil
        AppLogger.info("RFCOMM channel closed by remote", category: .bluetooth)
        onDisconnected?()
    }
}
