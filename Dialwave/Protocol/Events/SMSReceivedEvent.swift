import Foundation

/// Payload sent from Android to Mac when a new SMS message arrives.
///
/// Triggered by Android's `SMS_RECEIVED` broadcast receiver. The Mac saves
/// it to local storage and optionally shows a system notification.
struct SMSReceivedEvent: PayloadCodable {
    /// The incoming SMS message data.
    let message: SMSMessage
}
