import Foundation

/// Payload sent from Android to Mac when an incoming call is detected.
///
/// Triggered by Android's `PHONE_STATE` broadcast receiver when the state
/// transitions to `RINGING`. The Mac uses this to display the call popup HUD.
struct IncomingCallEvent: PayloadCodable {
    /// Unique identifier for this call session.
    let callId: String
    /// The phone number of the incoming caller.
    let callerNumber: String
    /// The contact name resolved from Android's phonebook, if available.
    let callerName: String?
    /// When the call started ringing.
    let timestamp: Date
}
