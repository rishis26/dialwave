import SwiftUI

/// Tab displaying app settings, connection status, and pairing controls.
struct SettingsView: View {
    
    @StateObject var viewModel: SettingsViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Connection Status Card
                VStack(spacing: 16) {
                    HStack {
                        StatusIndicatorView(badge: viewModel.connectionState.badge)
                        
                        Text(viewModel.connectionState.displayText)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if viewModel.connectionState.isConnected {
                            Button("Disconnect") {
                                viewModel.disconnect()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.dialwaveRed)
                        } else if viewModel.connectionState == .disconnected || case .error = viewModel.connectionState {
                            Button("Scan for Phone") {
                                viewModel.startScan()
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.dialwavePrimary)
                        }
                    }
                    
                    if viewModel.connectionState == .scanning {
                        Divider()
                        
                        if viewModel.discoveredDevices.isEmpty {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Searching for DialWave devices...")
                                    .font(.caption)
                                    .foregroundColor(.dialwaveSecondary)
                                Spacer()
                            }
                            .padding(.top, 4)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Found Devices")
                                    .font(.caption)
                                    .foregroundColor(.dialwaveSecondary)
                                
                                ForEach(viewModel.discoveredDevices) { device in
                                    HStack {
                                        Text(device.name)
                                        Spacer()
                                        CustomButton(title: "Pair", icon: nil, style: .primary) {
                                            viewModel.pair(with: device)
                                        }
                                        .frame(width: 80)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .dialwaveCard()
                .padding(.horizontal)
                
                // Preferences Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preferences")
                        .font(.headline)
                        .foregroundColor(.dialwaveSecondary)
                    
                    Toggle("Launch DialWave at login", isOn: $viewModel.launchAtLogin)
                        .toggleStyle(.switch)
                    
                    Toggle("Show notifications", isOn: $viewModel.notificationsEnabled)
                        .toggleStyle(.switch)
                    
                    Toggle("Play ringtone for incoming calls", isOn: $viewModel.playRingtone)
                        .toggleStyle(.switch)
                }
                .dialwaveCard()
                .padding(.horizontal)
                
                // Advanced Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Advanced")
                        .font(.headline)
                        .foregroundColor(.dialwaveSecondary)
                    
                    CustomButton(title: "Reset to Defaults", icon: "exclamationmark.triangle", style: .destructive) {
                        viewModel.reset()
                    }
                    
                    Text("Resets all settings and forgets paired devices. Call history and contacts will be preserved.")
                        .font(.caption)
                        .foregroundColor(.dialwaveSecondary)
                }
                .dialwaveCard()
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
        }
    }
}
