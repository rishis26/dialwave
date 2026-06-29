import Foundation

/// Payload sent from Android to Mac containing synced phonebook contacts.
///
/// Can be a full replacement sync or an incremental update containing only
/// contacts that changed since the last sync timestamp.
struct ContactSyncEvent: PayloadCodable {
    /// The array of contacts being synced.
    let contacts: [Contact]
    /// Total number of contacts on the Android device.
    let totalCount: Int
    /// When this sync was initiated.
    let syncTimestamp: Date
    /// If `true`, only changed contacts are included. If `false`, this is a full replacement.
    let isIncremental: Bool
}
