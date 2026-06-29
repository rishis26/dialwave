import Foundation
import CoreBluetooth
import Combine

/// Orchestrates the full connection lifecycle: BLE discovery → handshake → WiFi upgrade.
///
/// Acts as the central coordinator between `BluetoothManager`, `DeviceDiscovery`,
/// and `WiFiSocketSession`. The rest of the app interacts with connections
/// exclusively through this class.
@MainActor
final class ConnectionManager: ObservableObject {

    // MARK: - Published State

    /// The current connection lifecycle state.
    @Published private(set) var state: ConnectionState = .disconnected
    /// Discovered devices during the most recent scan.
    @Published private(set) var discoveredDevices: [DeviceDiscovery.DiscoveredDevice] = []

    // MARK: - Dependencies

    private let bluetoothManager: BluetoothManager
    private let discovery: DeviceDiscovery
    private let wifiSession: WiFiSocketSession
    private let networkReachability: NetworkReachability

    /// Callback invoked when a protocol message is received over TCP.
    var onMessageReceived: ((Message) -> Void)?

    // MARK: - Private

    private var heartbeatTimer: Timer?
    private var lastPongTime: Date?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var currentDeviceInfo: DeviceInfo?

    // MARK: - Init

    init(bluetoothManager: BluetoothManager = BluetoothManager(),
         networkReachability: NetworkReachability = NetworkReachability()) {
        self.bluetoothManager = bluetoothManager
        self.networkReachability = networkReachability
        self.discovery = DeviceDiscovery(bluetoothManager: bluetoothManager)
        self.wifiSession = WiFiSocketSession()
        self.bluetoothManager.delegate = self
        AppLogger.info("ConnectionManager initialized", category: .network)
    }

    // MARK: - Public API

    /// Begin scanning for nearby DialWave-compatible Android devices.
    func startScanning() {
        state = .scanning
        discoveredDevices.removeAll()
        discovery.startDiscovery(
            onDeviceFound: { [weak self] device in
                Task { @MainActor in
                    self?.discoveredDevices.append(device)
                }
            },
            onComplete: { [weak self] devices in
                Task { @MainActor in
                    if devices.isEmpty {
                        self?.state = .disconnected
                        AppLogger.info("Scan complete — no devices found", category: .bluetooth)
                    }
                }
            }
        )
    }

    /// Connect to a discovered device by initiating BLE pairing.
    /// - Parameter device: The discovered BLE device to connect to.
    func connectToDevice(_ device: DeviceDiscovery.DiscoveredDevice) {
        state = .bluetoothConnecting
        bluetoothManager.connect(to: device.peripheral)
    }

    /// Disconnect from the current device and clean up all sessions.
    func disconnect() {
        stopHeartbeat()
        Task {
            await wifiSession.disconnect()
        }
        bluetoothManager.disconnect()
        state = .disconnected
        currentDeviceInfo = nil
        reconnectAttempts = 0
        AppLogger.info("Disconnected from device", category: .network)
    }

    /// Send a protocol message to the connected Android device.
    /// - Parameter message: The message to send over TCP.
    func sendMessage(_ message: Message) {
        Task {
            await wifiSession.sendMessage(message)
        }
    }

    /// Send audio data to the connected Android device.
    /// - Parameter audioData: Raw audio frame data.
    func sendAudio(_ audioData: Data) {
        Task {
            await wifiSession.sendAudio(audioData)
        }
    }

    /// Begin streaming audio for an active call.
    func startAudioStream() {
        guard let device = currentDeviceInfo else { return }
        Task {
            await wifiSession.startAudioStream(to: device.ipAddress) { [weak self] data in
                Task { @MainActor in
                    // Forward audio data to the audio engine for playback
                    AppLogger.debug("Received audio frame: \(data.count) bytes", category: .audio)
                    _ = self // retain reference
                }
            }
        }
    }

    /// Stop audio streaming.
    func stopAudioStream() {
        Task {
            await wifiSession.stopAudioStream()
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.sendMessage(Message.ping())

                // Check if the last pong was too old (missed 2 consecutive heartbeats)
                if let lastPong = self.lastPongTime,
                   Date().timeIntervalSince(lastPong) > 35 {
                    AppLogger.warning("Heartbeat timeout — attempting reconnection", category: .network)
                    self.attemptReconnection()
                }
            }
        }
        AppLogger.debug("Heartbeat started (interval: 15s)", category: .network)
    }

    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        lastPongTime = nil
    }

    // MARK: - Reconnection

    private func attemptReconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            AppLogger.error("Max reconnect attempts reached — giving up", category: .network)
            disconnect()
            return
        }

        reconnectAttempts += 1
        AppLogger.info("Reconnection attempt \(reconnectAttempts)/\(maxReconnectAttempts)", category: .network)

        Task {
            await wifiSession.disconnect()
        }

        // If we have device info, try direct WiFi reconnection
        if let device = currentDeviceInfo {
            state = .upgrading
            upgradeToWiFi(deviceInfo: device)
        } else {
            startScanning()
        }
    }

    // MARK: - WiFi Upgrade

    private func upgradeToWiFi(deviceInfo: DeviceInfo) {
        currentDeviceInfo = deviceInfo

        Task {
            await wifiSession.connectTCP(
                to: deviceInfo.ipAddress,
                onMessage: { [weak self] message in
                    Task { @MainActor in
                        self?.handleReceivedMessage(message)
                    }
                },
                onDisconnected: { [weak self] in
                    Task { @MainActor in
                        AppLogger.warning("TCP connection lost", category: .network)
                        self?.attemptReconnection()
                    }
                }
            )
        }

        state = .connected(device: deviceInfo)
        reconnectAttempts = 0
        lastPongTime = Date()
        startHeartbeat()
        AppLogger.info("Upgraded to WiFi — connected to \(deviceInfo.name)", category: .network)
    }

    // MARK: - Message Handling

    private func handleReceivedMessage(_ message: Message) {
        switch message.type {
        case .pong:
            lastPongTime = Date()
        case .ping:
            sendMessage(Message.pong())
        default:
            onMessageReceived?(message)
        }
    }
}

// MARK: - BluetoothManagerDelegate

extension ConnectionManager: BluetoothManagerDelegate {
    nonisolated func didDiscoverDevice(_ peripheral: CBPeripheral) {
        // Handled via DeviceDiscovery
    }

    nonisolated func didConnect(_ peripheral: CBPeripheral) {
        Task { @MainActor in
            state = .upgrading
            guard let localIP = networkReachability.currentIP else {
                AppLogger.error("Cannot send handshake — no local WiFi IP available", category: .bluetooth)
                state = .error(message: "WiFi not connected")
                return
            }
            bluetoothManager.sendHandshake(localIP: localIP)
        }
    }

    nonisolated func didReceiveHandshakeResponse(deviceInfo: DeviceInfo) {
        Task { @MainActor in
            upgradeToWiFi(deviceInfo: deviceInfo)
        }
    }

    nonisolated func didDisconnect() {
        Task { @MainActor in
            if state.isConnected {
                attemptReconnection()
            }
        }
    }

    nonisolated func didFailWithError(_ error: Error) {
        Task { @MainActor in
            state = .error(message: error.localizedDescription)
            AppLogger.error("Bluetooth error: \(error.localizedDescription)", category: .bluetooth)
        }
    }
}
