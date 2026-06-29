import Foundation

/// Command sent from Mac to Android to dispatch an outgoing SMS message.
///
/// Triggered when the user composes and sends a reply from the SMS popover.
/// Android executes the send via `SmsManager`.
struct SMSCommand: PayloadCodable {
    /// The phone number to send the SMS to.
    let recipientNumber: String
    /// The text body of the message.
    let body: String
    /// The existing thread ID to append to, if replying in a conversation.
    let threadId: String?
}
