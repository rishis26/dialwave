import Foundation
import Combine

/// Drives the contacts list UI, handling search and dialing.
@MainActor
final class ContactsListViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let contactService: ContactServiceProtocol
    private let callService: CallServiceProtocol
    
    // MARK: - Published State
    
    @Published var searchQuery: String = ""
    @Published private(set) var contacts: [Contact] = []
    @Published private(set) var isSyncing: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(contactService: ContactServiceProtocol, callService: CallServiceProtocol) {
        self.contactService = contactService
        self.callService = callService
        
        // Debounce search query to avoid thrashing the database
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func refreshContacts() {
        performSearch(query: searchQuery)
    }
    
    func requestSync() {
        isSyncing = true
        contactService.requestSync()
        
        // Fake timeout for UI loader since sync happens async via events
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isSyncing = false
            self?.refreshContacts()
        }
    }
    
    func dial(contact: Contact) {
        guard let number = contact.primaryNumber else { return }
        callService.dial(number: number, contactName: contact.name)
    }
    
    // MARK: - Private
    
    private func performSearch(query: String) {
        contacts = contactService.searchContacts(query: query)
    }
}
