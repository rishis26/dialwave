import SwiftUI

/// The main entry point for the DialWave macOS application.
@main
struct DialwaveApp: App {
    
    // Inject the App Delegate to handle menubar setup
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We use a Settings scene just to satisfy the App protocol requirements.
        // The actual UI is rendered exclusively via the menubar NSStatusItem and floating windows.
        Settings {
            EmptyView()
        }
    }
}
