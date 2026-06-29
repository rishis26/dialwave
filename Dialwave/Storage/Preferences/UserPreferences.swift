import Foundation
import Combine

/// Type-safe UserDefaults wrapper for persistent app settings.
@MainActor
final class UserPreferences: ObservableObject {
    
    // MARK: - Keys
    
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let notificationsEnabled = "notificationsEnabled"
        static let playRingtone = "playRingtone"
        static let lastSyncedContactCount = "lastSyncedContactCount"
        static let pairedDeviceId = "pairedDeviceId"
    }
    
    // MARK: - Properties
    
    @Published var launchAtLogin: Bool {
        didSet { UserDefaults.standard.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled) }
    }
    
    @Published var playRingtone: Bool {
        didSet { UserDefaults.standard.set(playRingtone, forKey: Keys.playRingtone) }
    }
    
    @Published var lastSyncedContactCount: Int {
        didSet { UserDefaults.standard.set(lastSyncedContactCount, forKey: Keys.lastSyncedContactCount) }
    }
    
    @Published var pairedDeviceId: String? {
        didSet { UserDefaults.standard.set(pairedDeviceId, forKey: Keys.pairedDeviceId) }
    }
    
    // MARK: - Init
    
    init() {
        // Register default values
        UserDefaults.standard.register(defaults: [
            Keys.launchAtLogin: false,
            Keys.notificationsEnabled: true,
            Keys.playRingtone: true,
            Keys.lastSyncedContactCount: 0
        ])
        
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Keys.launchAtLogin)
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        self.playRingtone = UserDefaults.standard.bool(forKey: Keys.playRingtone)
        self.lastSyncedContactCount = UserDefaults.standard.integer(forKey: Keys.lastSyncedContactCount)
        self.pairedDeviceId = UserDefaults.standard.string(forKey: Keys.pairedDeviceId)
    }
    
    // MARK: - Actions
    
    func clearAll() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Keys.launchAtLogin)
        defaults.removeObject(forKey: Keys.notificationsEnabled)
        defaults.removeObject(forKey: Keys.playRingtone)
        defaults.removeObject(forKey: Keys.lastSyncedContactCount)
        defaults.removeObject(forKey: Keys.pairedDeviceId)
        
        // Re-init state
        self.launchAtLogin = false
        self.notificationsEnabled = true
        self.playRingtone = true
        self.lastSyncedContactCount = 0
        self.pairedDeviceId = nil
    }
}
