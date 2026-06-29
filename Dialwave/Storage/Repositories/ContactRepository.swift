import Foundation

/// Repository for CRUD operations on the contacts database table.
///
/// Handles serialization of the `Contact` model to/from SQLite rows,
/// including JSON encoding of the nested `PhoneNumber` array.
final class ContactRepository: @unchecked Sendable {

    private let db: SQLiteDatabase

    /// Creates a contact repository backed by the given database.
    /// - Parameter database: The SQLite database instance.
    init(database: SQLiteDatabase) {
        self.db = database
    }

    // MARK: - Read

    /// Fetches all contacts, sorted alphabetically by name.
    /// - Returns: An array of `Contact` instances.
    func fetchAll() -> [Contact] {
        let rows = db.executeQuery("SELECT * FROM contacts ORDER BY name COLLATE NOCASE ASC")
        return rows.compactMap { rowToContact($0) }
    }

    /// Searches contacts by name or phone number.
    /// - Parameter query: The search string.
    /// - Returns: Matching contacts.
    func search(query: String) -> [Contact] {
        let searchPattern = "%\(query)%"
        let rows = db.executeQuery(
            "SELECT * FROM contacts WHERE name LIKE ? OR phone_numbers LIKE ? ORDER BY name COLLATE NOCASE ASC",
            values: [searchPattern, searchPattern]
        )
        return rows.compactMap { rowToContact($0) }
    }

    /// Fetches a single contact by ID.
    /// - Parameter id: The contact identifier.
    /// - Returns: The contact, or `nil` if not found.
    func fetchById(_ id: String) -> Contact? {
        let rows = db.executeQuery("SELECT * FROM contacts WHERE id = ?", values: [id])
        return rows.first.flatMap { rowToContact($0) }
    }

    /// Looks up a contact by phone number.
    /// - Parameter number: The phone number to search for.
    /// - Returns: The matching contact, or `nil`.
    func fetchByPhoneNumber(_ number: String) -> Contact? {
        let digits = number.filter { $0.isNumber }
        let rows = db.executeQuery("SELECT * FROM contacts WHERE phone_numbers LIKE ?", values: ["%\(digits)%"])
        return rows.first.flatMap { rowToContact($0) }
    }

    // MARK: - Write

    /// Inserts or updates a single contact.
    /// - Parameter contact: The contact to upsert.
    func upsert(_ contact: Contact) {
        let phoneJSON = encodePhoneNumbers(contact.phoneNumbers)
        db.executeUpdate("""
            INSERT OR REPLACE INTO contacts (id, name, phone_numbers, email, avatar_data, synced_at)
            VALUES (?, ?, ?, ?, ?, ?)
        """, values: [
            contact.id, contact.name, phoneJSON,
            contact.email, contact.avatarData,
            Date().timeIntervalSince1970
        ])
    }

    /// Performs a full sync: replaces all contacts with the given array.
    /// - Parameter contacts: The complete contact list from Android.
    func replaceAll(with contacts: [Contact]) {
        db.transaction {
            db.execute("DELETE FROM contacts")
            for contact in contacts {
                upsert(contact)
            }
            return true
        }
        AppLogger.info("Contact sync complete — \(contacts.count) contacts stored", category: .storage)
    }

    /// Deletes a contact by ID.
    /// - Parameter id: The contact identifier.
    func delete(id: String) {
        db.executeUpdate("DELETE FROM contacts WHERE id = ?", values: [id])
    }

    /// Returns the total number of stored contacts.
    func count() -> Int {
        let rows = db.executeQuery("SELECT COUNT(*) as count FROM contacts")
        return (rows.first?["count"] as? Int64).map { Int($0) } ?? 0
    }

    // MARK: - Mapping

    private func rowToContact(_ row: [String: Any]) -> Contact? {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String,
              let phoneJSON = row["phone_numbers"] as? String else { return nil }

        return Contact(
            id: id,
            name: name,
            phoneNumbers: decodePhoneNumbers(phoneJSON),
            email: row["email"] as? String,
            avatarData: row["avatar_data"] as? Data
        )
    }

    private func encodePhoneNumbers(_ numbers: [PhoneNumber]) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(numbers) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private func decodePhoneNumbers(_ json: String) -> [PhoneNumber] {
        guard let data = json.data(using: .utf8) else { return [] }
        let decoder = JSONDecoder()
        return (try? decoder.decode([PhoneNumber].self, from: data)) ?? []
    }
}
