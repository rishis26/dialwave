import SwiftUI

/// A small secondary popover for quick actions like Quit and Disconnect.
struct QuickActionsPopover: View {
    
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Connection Status
            HStack {
                StatusIndicatorView(badge: settingsViewModel.connectionState.badge)
                Text(settingsViewModel.connectionState.displayText)
                    .font(.caption)
                    .foregroundColor(.dialwaveSecondary)
                Spacer()
            }
            .padding(12)
            
            Divider()
            
            // Actions
            VStack(alignment: .leading, spacing: 4) {
                
                if settingsViewModel.connectionState.isConnected {
                    ActionButton(title: "Disconnect Device", icon: "link.badge.minus") {
                        settingsViewModel.disconnect()
                    }
                } else if settingsViewModel.connectionState == .disconnected {
                    ActionButton(title: "Connect Device", icon: "link.badge.plus") {
                        settingsViewModel.startScan()
                    }
                }
                
                ActionButton(title: "Check for Updates", icon: "arrow.triangle.2.circlepath") {
                    // TODO: Sparkle integration
                }
                
                Divider()
                    .padding(.vertical, 4)
                
                ActionButton(title: "Quit DialWave", icon: "power", isDestructive: true) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(8)
        }
        .frame(width: 200)
    }
}

private struct ActionButton: View {
    let title: String
    let icon: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 16)
                Text(title)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isHovering ? (isDestructive ? Color.dialwaveRed : Color.dialwavePrimary) : Color.clear)
            .foregroundColor(isHovering ? .white : (isDestructive ? .dialwaveRed : .primary))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
