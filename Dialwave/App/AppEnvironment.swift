import SwiftUI

/// Top-level environment container injected into the SwiftUI view hierarchy.
@MainActor
final class AppEnvironment: ObservableObject {
    
    // MARK: - Properties
    
    let registry: ServiceRegistry
    
    // View Models
    let callViewModel: CallPopupViewModel
    let contactsViewModel: ContactsListViewModel
    let settingsViewModel: SettingsViewModel
    
    // MARK: - Init
    
    init() {
        do {
            self.registry = try ServiceRegistry()
            
            self.callViewModel = CallPopupViewModel(callService: registry.callService)
            self.contactsViewModel = ContactsListViewModel(
                contactService: registry.contactService,
                callService: registry.callService
            )
            self.settingsViewModel = SettingsViewModel(
                settingsService: registry.settingsService,
                connectionManager: registry.connectionManager
            )
            
            AppLogger.info("AppEnvironment fully initialized", category: .general)
        } catch {
            // In a real production app, we'd show a fatal error screen.
            // For now, crash early if SQLite fails to initialize.
            fatalError("Failed to initialize ServiceRegistry: \(error.localizedDescription)")
        }
    }
}
