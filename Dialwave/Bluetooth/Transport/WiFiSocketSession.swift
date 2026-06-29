import Foundation
import Network

/// Manages the TCP command channel and UDP audio stream over WiFi.
///
/// After Bluetooth handshake completes, this session opens a persistent TCP
/// connection to Android on port 9876 for JSON commands/events, and a UDP
/// channel on port 9877 for real-time Opus audio frames.
actor WiFiSocketSession {

    // MARK: - Constants

    /// TCP port for JSON command/event messages.
    static let tcpPort: UInt16 = 9876
    /// UDP port for audio data streaming.
    static let udpPort: UInt16 = 9877
    /// Maximum TCP message size (256 KB).
    static let maxMessageSize = 256 * 1024
    /// TCP connection timeout in seconds.
    static let connectionTimeout: TimeInterval = 10.0

    // MARK: - State

    private var tcpConnection: NWConnection?
    private var udpConnection: NWConnection?
    private let tcpQueue = DispatchQueue(label: "com.dialwave.tcp", qos: .userInitiated)
    private let udpQueue = DispatchQueue(label: "com.dialwave.udp", qos: .userInteractive)

    /// Whether the TCP command channel is currently open.
    private(set) var isTCPConnected: Bool = false
    /// Whether the UDP audio channel is currently open.
    private(set) var isUDPReady: Bool = false

    // Callbacks
    private var onMessageReceived: ((Message) -> Void)?
    private var onAudioReceived: ((Data) -> Void)?
    private var onDisconnected: (() -> Void)?

    // MARK: - TCP Connection

    /// Open a TCP connection to the Android device at the given IP address.
    /// - Parameters:
    ///   - host: The Android device's WiFi IP address.
    ///   - onMessage: Callback fired when a JSON message is received.
    ///   - onDisconnected: Callback fired when the connection drops.
    func connectTCP(to host: String,
                    onMessage: @escaping (Message) -> Void,
                    onDisconnected: @escaping () -> Void) {
        self.onMessageReceived = onMessage
        self.onDisconnected = onDisconnected

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: Self.tcpPort)
        )

        let params = NWParameters.tcp
        params.requiredInterfaceType = .wifi

        let connection = NWConnection(to: endpoint, using: params)
        self.tcpConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            Task { await self?.handleTCPStateChange(state) }
        }

        connection.start(queue: tcpQueue)
        AppLogger.info("TCP connecting to \(host):\(Self.tcpPort)", category: .network)
    }

    /// Send a `Message` over the TCP channel.
    /// - Parameter message: The message to send.
    func sendMessage(_ message: Message) {
        guard let connection = tcpConnection, isTCPConnected else {
            AppLogger.warning("Cannot send message — TCP not connected", category: .network)
            return
        }

        guard let data = message.encode() else {
            AppLogger.error("Failed to encode message for sending", category: .network)
            return
        }

        // Frame the message: 4-byte big-endian length prefix + JSON data
        var length = UInt32(data.count).bigEndian
        var framedData = Data(bytes: &length, count: 4)
        framedData.append(data)

        connection.send(content: framedData, completion: .contentProcessed { error in
            if let error {
                AppLogger.error("TCP send failed: \(error.localizedDescription)", category: .network)
            } else {
                AppLogger.debug("Sent \(message.type.rawValue) (\(data.count) bytes)", category: .network)
            }
        })
    }

    /// Disconnect both TCP and UDP channels.
    func disconnect() {
        tcpConnection?.cancel()
        tcpConnection = nil
        isTCPConnected = false

        udpConnection?.cancel()
        udpConnection = nil
        isUDPReady = false

        AppLogger.info("WiFi session disconnected", category: .network)
    }

    // MARK: - UDP Audio

    /// Open a UDP channel for audio streaming.
    /// - Parameters:
    ///   - host: The Android device's WiFi IP address.
    ///   - onAudio: Callback fired when an audio frame is received.
    func startAudioStream(to host: String, onAudio: @escaping (Data) -> Void) {
        self.onAudioReceived = onAudio

        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: Self.udpPort)
        )

        let params = NWParameters.udp
        params.requiredInterfaceType = .wifi

        let connection = NWConnection(to: endpoint, using: params)
        self.udpConnection = connection

        connection.stateUpdateHandler = { [weak self] state in
            Task { await self?.handleUDPStateChange(state) }
        }

        connection.start(queue: udpQueue)
        AppLogger.info("UDP audio stream opening to \(host):\(Self.udpPort)", category: .audio)
    }

    /// Send an audio frame over UDP.
    /// - Parameter audioData: The encoded audio data (Opus frame).
    func sendAudio(_ audioData: Data) {
        guard let connection = udpConnection, isUDPReady else { return }

        connection.send(content: audioData, completion: .contentProcessed { error in
            if let error {
                AppLogger.debug("UDP send error: \(error.localizedDescription)", category: .audio)
            }
        })
    }

    /// Stop the UDP audio stream.
    func stopAudioStream() {
        udpConnection?.cancel()
        udpConnection = nil
        isUDPReady = false
        AppLogger.info("UDP audio stream stopped", category: .audio)
    }

    // MARK: - TCP State Handler

    private func handleTCPStateChange(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isTCPConnected = true
            AppLogger.info("TCP connection established", category: .network)
            receiveTCPMessages()
        case .failed(let error):
            isTCPConnected = false
            AppLogger.error("TCP connection failed: \(error.localizedDescription)", category: .network)
            onDisconnected?()
        case .cancelled:
            isTCPConnected = false
            AppLogger.info("TCP connection cancelled", category: .network)
        case .waiting(let error):
            AppLogger.warning("TCP waiting: \(error.localizedDescription)", category: .network)
        default:
            break
        }
    }

    // MARK: - TCP Message Receiving

    /// Reads length-prefixed TCP frames in a loop.
    private nonisolated func receiveTCPMessages() {
        Task { await _receiveTCPMessages() }
    }

    private func _receiveTCPMessages() {
        guard let connection = tcpConnection else { return }

        // Read 4-byte length prefix
        connection.receive(minimumIncompleteLength: 4, maximumLength: 4) { [weak self] data, _, isComplete, error in
            Task {
                guard let self else { return }

                if isComplete || error != nil {
                    await self.handleTCPDisconnect()
                    return
                }

                guard let lengthData = data, lengthData.count == 4 else {
                    await self._receiveTCPMessages()
                    return
                }

                let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
                guard length > 0, length <= Self.maxMessageSize else {
                    AppLogger.warning("Invalid TCP frame length: \(length)", category: .network)
                    await self._receiveTCPMessages()
                    return
                }

                // Read the JSON body
                connection.receive(minimumIncompleteLength: Int(length), maximumLength: Int(length)) { [weak self] bodyData, _, isComplete2, error2 in
                    Task {
                        guard let self else { return }

                        if isComplete2 || error2 != nil {
                            await self.handleTCPDisconnect()
                            return
                        }

                        if let bodyData, let message = Message.from(data: bodyData) {
                            AppLogger.debug("Received \(message.type.rawValue) (\(bodyData.count) bytes)", category: .network)
                            await self.onMessageReceived?(message)
                        }

                        await self._receiveTCPMessages()
                    }
                }
            }
        }
    }

    private func handleTCPDisconnect() {
        isTCPConnected = false
        onDisconnected?()
    }

    // MARK: - UDP State Handler

    private func handleUDPStateChange(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isUDPReady = true
            AppLogger.info("UDP audio channel ready", category: .audio)
            receiveUDPAudio()
        case .failed(let error):
            isUDPReady = false
            AppLogger.error("UDP failed: \(error.localizedDescription)", category: .audio)
        case .cancelled:
            isUDPReady = false
        default:
            break
        }
    }

    private nonisolated func receiveUDPAudio() {
        Task { await _receiveUDPAudio() }
    }

    private func _receiveUDPAudio() {
        guard let connection = udpConnection else { return }

        connection.receiveMessage { [weak self] data, _, _, error in
            Task {
                guard let self else { return }
                if let data, !data.isEmpty {
                    await self.onAudioReceived?(data)
                }
                if error == nil {
                    await self._receiveUDPAudio()
                }
            }
        }
    }
}
