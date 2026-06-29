import Cocoa
import SwiftUI
import Combine

/// Manages the `NSStatusItem` in the macOS menubar and its associated popover.
@MainActor
final class MenubarController {
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    
    private let connectionManager: ConnectionManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(connectionManager: ConnectionManager, rootView: some View) {
        self.connectionManager = connectionManager
        
        setupPopover(with: rootView)
        setupStatusItem()
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupPopover(with rootView: some View) {
        let hostingView = NSHostingController(rootView: rootView)
        
        popover = NSPopover()
        popover.contentSize = PopoverSize.compact.dimensions
        popover.behavior = .transient
        popover.contentViewController = hostingView
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Setup custom view for the button to support rendering the color dot alongside the icon
            let buttonView = MenubarButtonView(frame: NSRect(x: 0, y: 0, width: 36, height: 22))
            
            // Link button click to toggle action
            button.target = self
            button.action = #selector(togglePopover(_:))
            button.addSubview(buttonView)
            
            // Layout constraints
            buttonView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                buttonView.centerXAnchor.constraint(equalTo: button.centerXAnchor),
                buttonView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
                buttonView.widthAnchor.constraint(equalToConstant: 36),
                buttonView.heightAnchor.constraint(equalToConstant: 22)
            ])
        }
    }
    
    private func setupObservers() {
        connectionManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenubarAppearance(for: state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Appearance
    
    private func updateMenubarAppearance(for state: ConnectionState) {
        guard let button = statusItem.button,
              let customView = button.subviews.first as? MenubarButtonView else { return }
        
        customView.update(iconName: state.menubarIcon, badgeColor: NSColor(state.badge.color))
    }
    
    // MARK: - Actions
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
    
    private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
    }
    
    /// Resize the popover dynamically (e.g. when changing tabs).
    func resizePopover(to size: PopoverSize) {
        popover.contentSize = size.dimensions
    }
}

// MARK: - Custom Button View

/// Custom NSView for the menubar button to render an SF Symbol and a colored status dot side-by-side.
private class MenubarButtonView: NSView {
    
    private let iconImageView = NSImageView()
    private let badgeLayer = CAShapeLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        
        iconImageView.imageScaling = .scaleProportionallyDown
        iconImageView.contentTintColor = .labelColor
        iconImageView.frame = NSRect(x: 4, y: 3, width: 16, height: 16)
        addSubview(iconImageView)
        
        badgeLayer.path = CGPath(ellipseIn: CGRect(x: 0, y: 0, width: 6, height: 6), transform: nil)
        badgeLayer.frame = CGRect(x: 24, y: 8, width: 6, height: 6)
        layer?.addSublayer(badgeLayer)
    }
    
    func update(iconName: String, badgeColor: NSColor) {
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            let config = NSImage.SymbolConfiguration(textStyle: .body, scale: .medium)
            iconImageView.image = image.withSymbolConfiguration(config)
        }
        badgeLayer.fillColor = badgeColor.cgColor
    }
}
