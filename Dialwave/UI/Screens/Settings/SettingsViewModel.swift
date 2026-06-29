import Foundation
import Combine

/// Drives the settings UI, managing connection status and user preferences.
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    let settingsService: SettingsServiceProtocol
    private let connectionManager: ConnectionManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    
    @Published private(set) var connectionState: ConnectionState = .disconnected
    @Published private(set) var discoveredDevices: [DeviceDiscovery.DiscoveredDevice] = []
    
    // Pass-through preference bindings
    @Published var launchAtLogin: Bool {
        didSet { settingsService.preferences.launchAtLogin = launchAtLogin }
    }
    @Published var notificationsEnabled: Bool {
        didSet { settingsService.preferences.notificationsEnabled = notificationsEnabled }
    }
    @Published var playRingtone: Bool {
        didSet { settingsService.preferences.playRingtone = playRingtone }
    }
    
    // MARK: - Init
    
    init(settingsService: SettingsServiceProtocol, connectionManager: ConnectionManager) {
        self.settingsService = settingsService
        self.connectionManager = connectionManager
        
        self.launchAtLogin = settingsService.preferences.launchAtLogin
        self.notificationsEnabled = settingsService.preferences.notificationsEnabled
        self.playRingtone = settingsService.preferences.playRingtone
        
        setupObservers()
    }
    
    private func setupObservers() {
        connectionManager.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$connectionState)
            
        connectionManager.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredDevices)
            
        settingsService.preferences.$launchAtLogin
            .receive(on: DispatchQueue.main)
            .assign(to: &$launchAtLogin)
            
        settingsService.preferences.$notificationsEnabled
            .receive(on: DispatchQueue.main)
            .assign(to: &$notificationsEnabled)
            
        settingsService.preferences.$playRingtone
            .receive(on: DispatchQueue.main)
            .assign(to: &$playRingtone)
    }
    
    // MARK: - Actions
    
    func startScan() {
        settingsService.startDeviceScan()
    }
    
    func pair(with device: DeviceDiscovery.DiscoveredDevice) {
        settingsService.pairWithDevice(device)
    }
    
    func disconnect() {
        settingsService.disconnectCurrentDevice()
    }
    
    func reset() {
        settingsService.resetToDefaults()
    }
}
