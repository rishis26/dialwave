import Foundation

/// Command sent from Mac to Android to control an active or ringing call.
///
/// When the user clicks Answer, Reject, or Hang Up on the call popup,
/// this command is serialized and sent over the TCP socket.
struct CallControlCommand: PayloadCodable {
    /// The call session identifier (must match the `IncomingCallEvent.callId`).
    let callId: String
    /// The action to perform on the call.
    let action: CallAction
}

/// Actions that can be performed on a phone call.
enum CallAction: String, Codable, Sendable {
    /// Answer a ringing incoming call.
    case answer = "ANSWER"
    /// Reject a ringing incoming call.
    case reject = "REJECT"
    /// Hang up an active call.
    case hangup = "HANGUP"
}
