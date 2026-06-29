import Foundation

/// Defines operations for managing and syncing phonebook contacts.
@MainActor
protocol ContactServiceProtocol: AnyObject {
    
    /// Handle an incoming protocol message related to contacts.
    func handleMessage(_ message: Message)
    
    /// Request a full contact sync from the Android device.
    func requestSync()
    
    /// Fetches all contacts stored locally.
    func fetchContacts() -> [Contact]
    
    /// Searches local contacts by name or phone number.
    func searchContacts(query: String) -> [Contact]
    
    /// Looks up a contact by their phone number.
    func lookupContact(by number: String) -> Contact?
}
