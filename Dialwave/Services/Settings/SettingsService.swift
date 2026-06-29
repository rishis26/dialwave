import Foundation
import Combine
import ServiceManagement

@MainActor
final class SettingsService: SettingsServiceProtocol, ObservableObject {
    
    // MARK: - Dependencies
    
    let preferences: UserPreferences
    private let connectionManager: ConnectionManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(preferences: UserPreferences, connectionManager: ConnectionManager) {
        self.preferences = preferences
        self.connectionManager = connectionManager
        
        setupObservers()
    }
    
    private func setupObservers() {
        // Automatically sync login item state when preference changes
        preferences.$launchAtLogin
            .dropFirst()
            .sink { [weak self] enabled in
                self?.toggleLaunchAtLogin(enabled)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - API
    
    func startDeviceScan() {
        AppLogger.info("Starting manual device scan from settings", category: .ui)
        connectionManager.startScanning()
    }
    
    func pairWithDevice(_ device: DeviceDiscovery.DiscoveredDevice) {
        AppLogger.info("Pairing with device: \(device.name)", category: .bluetooth)
        preferences.pairedDeviceId = device.id.uuidString
        connectionManager.connectToDevice(device)
    }
    
    func disconnectCurrentDevice() {
        AppLogger.info("Disconnecting current device", category: .network)
        connectionManager.disconnect()
    }
    
    func resetToDefaults() {
        AppLogger.warning("Resetting app to default settings", category: .storage)
        disconnectCurrentDevice()
        preferences.clearAll()
        toggleLaunchAtLogin(false)
    }
    
    // MARK: - Private
    
    private func toggleLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                AppLogger.info("Registered app for login launch", category: .general)
            } else {
                try SMAppService.mainApp.unregister()
                AppLogger.info("Unregistered app from login launch", category: .general)
            }
        } catch {
            AppLogger.error("Failed to configure login launch: \(error.localizedDescription)", category: .general)
        }
    }
}
