import Cocoa
import SwiftUI
import Combine

/// Hooks into the macOS application lifecycle for menubar initialization.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    private var menubarController: MenubarController!
    private var environment: AppEnvironment!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - NSApplicationDelegate
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Hide the main window (we are a menubar-only app)
        NSApp.setActivationPolicy(.accessory)
        
        // 2. Initialize the environment and dependency graph
        environment = AppEnvironment()
        
        // 3. Setup the menubar UI
        let menuView = MenubarMenuView(
            callViewModel: environment.callViewModel,
            contactsViewModel: environment.contactsViewModel,
            settingsViewModel: environment.settingsViewModel
        )
        
        menubarController = MenubarController(
            connectionManager: environment.registry.connectionManager,
            rootView: menuView
        )
        
        // 4. Observe Call HUD triggers
        setupCallHUDObserver()
        
        AppLogger.info("Application did finish launching", category: .general)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up connections before exit
        environment?.registry.connectionManager.disconnect()
        AppLogger.info("Application will terminate", category: .general)
    }
    
    // MARK: - Call HUD Observer
    
    private func setupCallHUDObserver() {
        // When the active call state transitions to visible, show the floating HUD.
        environment.callViewModel.$state
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { state in
                if state.isVisible {
                    WindowManager.shared.showCallPopup(viewModel: self.environment.callViewModel)
                }
            }
            .store(in: &cancellables)
    }
}
