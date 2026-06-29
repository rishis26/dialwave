import Cocoa
import SwiftUI

/// Manages the lifecycle of floating app windows (like the incoming call popup).
@MainActor
final class WindowManager {
    
    // MARK: - Shared Instance
    
    static let shared = WindowManager()
    
    // MARK: - Properties
    
    private var callWindowController: WindowController<CallPopupView>?
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - API
    
    /// Shows the incoming/active call floating window.
    func showCallPopup(viewModel: CallPopupViewModel) {
        if let existing = callWindowController {
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        let view = CallPopupView(viewModel: viewModel)
        let controller = WindowController(
            rootView: view,
            title: "DialWave Call",
            size: CGSize(width: 300, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            level: .floating
        )
        
        // Customize window to look like a HUD
        if let window = controller.window {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            
            // Position in top right corner
            if let screen = NSScreen.main {
                let frame = window.frame
                let screenFrame = screen.visibleFrame
                let origin = NSPoint(
                    x: screenFrame.maxX - frame.width - 20,
                    y: screenFrame.maxY - frame.height - 20
                )
                window.setFrameOrigin(origin)
            }
        }
        
        controller.showWindow(nil)
        self.callWindowController = controller
    }
    
    /// Closes the call popup window.
    func closeCallPopup() {
        callWindowController?.close()
        callWindowController = nil
    }
}
