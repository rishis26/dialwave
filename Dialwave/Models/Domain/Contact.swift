import Foundation

/// Represents a phone contact synced from the Android device.
///
/// Contacts are fetched via Android's `ContactsContract` and transmitted as JSON
/// during a `CONTACT_SYNC` event. Stored locally in SQLite for offline access.
struct Contact: Codable, Identifiable, Equatable, Hashable, Sendable {
    /// Unique contact identifier from Android's contact database.
    let id: String
    /// Full display name.
    let name: String
    /// All phone numbers associated with this contact.
    let phoneNumbers: [PhoneNumber]
    /// Primary email address, if available.
    let email: String?
    /// JPEG avatar image data, if available.
    let avatarData: Data?

    /// Uppercased initials derived from the contact's name (e.g., "RS" for "Rishi Shah").
    var initials: String {
        name.initials
    }

    /// The first available phone number, or `nil` if the contact has no numbers.
    var primaryNumber: String? {
        phoneNumbers.first?.number
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Contact, rhs: Contact) -> Bool {
        lhs.id == rhs.id
    }
}

/// A labeled phone number belonging to a contact.
struct PhoneNumber: Codable, Equatable, Hashable, Sendable {
    /// The raw phone number string.
    let number: String
    /// A label describing the number type (e.g., "Mobile", "Home", "Work").
    let label: String
}
