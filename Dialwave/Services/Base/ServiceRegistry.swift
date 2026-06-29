import Foundation

/// Dependency injection container for all core app services.
///
/// Ensures services are instantiated once and can easily access each other.
/// Injected into the SwiftUI environment as a single object.
@MainActor
final class ServiceRegistry: ObservableObject {
    
    // MARK: - Core Dependencies
    
    let db: SQLiteDatabase
    let connectionManager: ConnectionManager
    let userPreferences: UserPreferences
    
    // MARK: - Repositories
    
    let contactRepository: ContactRepository
    let callLogRepository: CallLogRepository
    let smsRepository: SMSRepository
    
    // MARK: - Services
    
    let callService: CallServiceProtocol
    let contactService: ContactServiceProtocol
    let smsService: SMSServiceProtocol
    let notificationService: NotificationServiceProtocol
    let settingsService: SettingsServiceProtocol
    
    // MARK: - Init
    
    init() throws {
        // 1. Initialize core infrastructure
        let documentsURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbURL = documentsURL.appendingPathComponent("Dialwave").appendingPathComponent("dialwave.sqlite")
        
        self.db = try SQLiteDatabase(url: dbURL)
        DatabaseSchema.migrateIfNeeded(in: db)
        DatabaseSchema.createTables(in: db)
        
        self.connectionManager = ConnectionManager()
        self.userPreferences = UserPreferences()
        
        // 2. Initialize repositories
        self.contactRepository = ContactRepository(database: db)
        self.callLogRepository = CallLogRepository(database: db)
        self.smsRepository = SMSRepository(database: db)
        
        // 3. Initialize feature services
        self.notificationService = NotificationService()
        
        self.callService = CallService(
            connectionManager: connectionManager,
            callLogRepository: callLogRepository,
            notificationService: notificationService
        )
        
        self.contactService = ContactService(
            connectionManager: connectionManager,
            contactRepository: contactRepository
        )
        
        self.smsService = SMSService(
            connectionManager: connectionManager,
            smsRepository: smsRepository,
            notificationService: notificationService
        )
        
        self.settingsService = SettingsService(
            preferences: userPreferences,
            connectionManager: connectionManager
        )
        
        // 4. Wire up connection manager message routing
        setupMessageRouting()
        
        AppLogger.info("ServiceRegistry fully initialized", category: .general)
    }
    
    private func setupMessageRouting() {
        connectionManager.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                guard let self else { return }
                
                switch message.type {
                case .callIncoming, .callHangup, .callLogSync:
                    self.callService.handleMessage(message)
                case .contactSync:
                    self.contactService.handleMessage(message)
                case .smsReceived:
                    self.smsService.handleMessage(message)
                case .error:
                    AppLogger.error("Received protocol error", category: .network)
                default:
                    AppLogger.debug("Unhandled message type: \(message.type.rawValue)", category: .general)
                }
            }
        }
    }
}
