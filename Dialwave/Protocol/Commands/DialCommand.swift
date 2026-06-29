import Foundation

/// Command sent from Mac to Android to initiate an outgoing phone call.
///
/// Triggered when the user dials a number from the menubar dial pad or
/// clicks the call button on a contact card.
struct DialCommand: PayloadCodable {
    /// The phone number to dial.
    let phoneNumber: String
    /// The contact name, if dialing from the contacts list.
    let contactName: String?
}
