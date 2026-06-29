import Foundation

/// The root envelope for every message exchanged over the TCP socket.
///
/// Every JSON frame sent between Mac and Android is a `Message`. The `type` field
/// determines how to interpret the `payload`. The payload itself is encoded as
/// a nested JSON blob conforming to `PayloadCodable`.
///
/// Wire format example:
/// ```json
/// {
///   "id": "550e8400-e29b-41d4-a716-446655440000",
///   "type": "CALL_INCOMING",
///   "timestamp": 1719657600.0,
///   "payload": "{\"callId\":\"abc\",\"callerNumber\":\"+919876543210\"}"
/// }
/// ```
struct Message: Codable, Sendable {

    /// Unique identifier for this message (UUID string).
    let id: String

    /// The message classification tag.
    let type: MessageType

    /// Unix timestamp (seconds since 1970) when the message was created.
    let timestamp: Date

    /// JSON-encoded payload data. Interpretation depends on `type`.
    let payload: Data?

    // MARK: - Initializer

    /// Creates a new message with the given type and optional payload.
    /// - Parameters:
    ///   - type: The message type tag.
    ///   - payload: Optional encoded payload data.
    init(type: MessageType, payload: Data? = nil) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date()
        self.payload = payload
    }

    // MARK: - Factory Methods

    /// Creates a PING heartbeat message.
    static func ping() -> Message {
        Message(type: .ping)
    }

    /// Creates a PONG heartbeat response.
    static func pong() -> Message {
        Message(type: .pong)
    }

    /// Creates a CONNECTION_ACK acknowledgement message.
    static func ack() -> Message {
        Message(type: .connectionAck)
    }

    /// Creates an ERROR message with a reason string payload.
    /// - Parameter reason: A human-readable error description.
    static func error(reason: String) -> Message {
        let errorPayload = ErrorPayload(reason: reason)
        return Message(type: .error, payload: errorPayload.toData())
    }

    // MARK: - Payload Decoding

    /// Decodes the payload data as the specified `PayloadCodable` type.
    /// - Parameter type: The expected payload type.
    /// - Returns: The decoded instance, or `nil` if payload is missing or invalid.
    func decode<T: PayloadCodable>(as type: T.Type) -> T? {
        guard let payload else {
            AppLogger.warning("Cannot decode payload: data is nil for message \(self.type.rawValue)", category: .network)
            return nil
        }
        return T.fromData(payload)
    }

    // MARK: - Encoding

    /// Encodes the entire `Message` to JSON `Data` for transmission.
    /// - Returns: The encoded data, or `nil` if encoding fails.
    func encode() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        do {
            return try encoder.encode(self)
        } catch {
            AppLogger.error("Failed to encode Message: \(error.localizedDescription)", category: .network)
            return nil
        }
    }

    /// Decodes a `Message` from raw JSON data received over the socket.
    /// - Parameter data: The raw JSON bytes.
    /// - Returns: The decoded message, or `nil` if parsing fails.
    static func from(data: Data) -> Message? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            return try decoder.decode(Message.self, from: data)
        } catch {
            AppLogger.error("Failed to decode Message from data: \(error.localizedDescription)", category: .network)
            return nil
        }
    }
}

// MARK: - Error Payload

/// A simple payload carrying an error reason string.
struct ErrorPayload: PayloadCodable {
    let reason: String
}
