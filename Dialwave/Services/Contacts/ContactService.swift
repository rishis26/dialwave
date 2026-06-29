import Foundation
import Combine

@MainActor
final class ContactService: ContactServiceProtocol, ObservableObject {
    
    // MARK: - Dependencies
    
    private let connectionManager: ConnectionManager
    private let contactRepository: ContactRepository
    
    // MARK: - Init
    
    init(connectionManager: ConnectionManager, contactRepository: ContactRepository) {
        self.connectionManager = connectionManager
        self.contactRepository = contactRepository
    }
    
    // MARK: - Message Handling
    
    func handleMessage(_ message: Message) {
        guard message.type == .contactSync else { return }
        
        if let event = message.decode(as: ContactSyncEvent.self) {
            handleContactSync(event)
        }
    }
    
    private func handleContactSync(_ event: ContactSyncEvent) {
        AppLogger.info("Received contact sync (incremental: \(event.isIncremental), count: \(event.contacts.count))", category: .contacts)
        
        if event.isIncremental {
            for contact in event.contacts {
                contactRepository.upsert(contact)
            }
        } else {
            contactRepository.replaceAll(with: event.contacts)
        }
    }
    
    // MARK: - Commands
    
    func requestSync() {
        AppLogger.info("Requesting full contact sync", category: .contacts)
        let message = Message(type: .contactSync)
        connectionManager.sendMessage(message)
    }
    
    // MARK: - Queries
    
    func fetchContacts() -> [Contact] {
        contactRepository.fetchAll()
    }
    
    func searchContacts(query: String) -> [Contact] {
        if query.trimmingCharacters(in: .whitespaces).isEmpty {
            return fetchContacts()
        }
        return contactRepository.search(query: query)
    }
    
    func lookupContact(by number: String) -> Contact? {
        contactRepository.fetchByPhoneNumber(number)
    }
}
