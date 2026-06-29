import Foundation

/// A protocol that all event and command payload types conform to.
///
/// Provides automatic JSON serialization and deserialization via `Codable`.
/// Every struct in `Protocol/Events/` and `Protocol/Commands/` conforms to this.
protocol PayloadCodable: Codable, Sendable {
    /// Serializes this payload to JSON `Data`.
    /// - Returns: The encoded data, or `nil` if encoding fails.
    func toData() -> Data?

    /// Deserializes a payload from JSON `Data`.
    /// - Parameter data: The raw JSON bytes.
    /// - Returns: An instance of the conforming type, or `nil` if decoding fails.
    static func fromData(_ data: Data) -> Self?
}

extension PayloadCodable {
    func toData() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        do {
            return try encoder.encode(self)
        } catch {
            AppLogger.error("Failed to encode \(Self.self): \(error.localizedDescription)", category: .network)
            return nil
        }
    }

    static func fromData(_ data: Data) -> Self? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            return try decoder.decode(Self.self, from: data)
        } catch {
            AppLogger.error("Failed to decode \(Self.self): \(error.localizedDescription)", category: .network)
            return nil
        }
    }
}
