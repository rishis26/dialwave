import Cocoa
import SwiftUI

/// A generic NSWindowController for hosting SwiftUI views in a standard window.
final class WindowController<RootView: View>: NSWindowController, NSWindowDelegate {
    
    init(rootView: RootView,
         title: String,
         size: CGSize,
         styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable],
         level: NSWindow.Level = .normal) {
        
        // Use a hosting view with a clear background to support custom shapes
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: size)
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        
        window.title = title
        window.contentView = hostingView
        window.level = level
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        window.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func windowWillClose(_ notification: Notification) {
        // Optionally notify delegates or managers that the window closed
    }
}
