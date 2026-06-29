import SwiftUI

/// The root SwiftUI view hosted inside the menubar popover.
struct MenubarMenuView: View {
    
    @State private var selectedTab: AppTab = .calls
    @State private var showingQuickActions: Bool = false
    
    let callViewModel: CallPopupViewModel
    let contactsViewModel: ContactsListViewModel
    let settingsViewModel: SettingsViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Content Area
            TabView(selection: $selectedTab) {
                // Calls Tab
                VStack {
                    Text("Call History")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("Call history will appear here.")
                        .foregroundColor(.dialwaveSecondary)
                    Spacer()
                }
                .tag(AppTab.calls)
                
                // Contacts Tab
                ContactsListView(viewModel: contactsViewModel)
                    .tag(AppTab.contacts)
                
                // Messages Tab
                VStack {
                    Text("Messages")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Text("SMS messages will appear here.")
                        .foregroundColor(.dialwaveSecondary)
                    Spacer()
                }
                .tag(AppTab.sms)
                
                // Settings Tab
                SettingsView(viewModel: settingsViewModel)
                    .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            Divider()
            
            // Bottom Tab Bar
            HStack(spacing: 0) {
                ForEach(AppTab.allCases) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? .dialwavePrimary : .dialwaveSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        // Selection background highlight
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.dialwavePrimary.opacity(0.1) : Color.clear)
                                .padding(.horizontal, 4)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.dialwaveBackground)
        }
        .frame(width: 320, height: 440)
        .overlay(alignment: .topTrailing) {
            // Quick Actions Button
            Button {
                showingQuickActions.toggle()
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.dialwaveSecondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .padding(12)
            .popover(isPresented: $showingQuickActions, arrowEdge: .bottom) {
                QuickActionsPopover(settingsViewModel: settingsViewModel)
            }
        }
    }
}
